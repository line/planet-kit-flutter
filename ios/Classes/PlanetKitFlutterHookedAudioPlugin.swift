// Copyright 2024 LINE Plus Corporation
//
// LINE Plus Corporation licenses this file to you under the Apache License,
// version 2.0 (the "License"); you may not use this file except in compliance
// with the License. You may obtain a copy of the License at:
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

import Foundation
import PlanetKit
import Flutter

extension PlanetKitInterceptedAudio: PluginInstance {
    var instanceId: String {
        return "\(Unmanaged<AnyObject>.passUnretained(self).toOpaque())"
    }
}

class PlanetKitFlutterHookedAudioPlugin {
    let nativeInstances: PlanetKitFlutterNativeInstances
    let hookedAudioStreamHandler: PlanetKitFlutterStreamHandler
    init(nativeInstances: PlanetKitFlutterNativeInstances, hookedAudioStreamHandler: PlanetKitFlutterStreamHandler) {
        self.nativeInstances = nativeInstances
        self.hookedAudioStreamHandler = hookedAudioStreamHandler
    }
}

extension PlanetKitFlutterHookedAudioPlugin {
    func enableHookMyAudio(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let callId = call.arguments as! String
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        call.enableInterceptMyAudio(delegate: self) { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) api failed")
            }
            result(success)
        }
    }
    
    func disableHookMyAudio(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let callId = call.arguments as! String
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        call.disableInterceptMyAudio() { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) api failed")
            }
            result(success)
        }
    }
    
    func putHookedMyAudioBack(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        let args = call.arguments as! Dictionary<String, Any>
        let jsonData = try! JSONSerialization.data(withJSONObject: args, options: [])
        let param = try! JSONDecoder().decode(PutHookedAudioBackParam.self, from: jsonData)
        
        let callId = param.callId
        let audioId = param.audioId
        
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }

        guard let audio = nativeInstances.get(key: audioId) as? PlanetKitInterceptedAudio else {
            PlanetKitLog.e("#flutter \(#function) audio not found \(audioId)")
            result(false)
            return
        }
        
        let ret = call.putInterceptedMyAudioBack(audio: audio)
        
        if !ret {
            PlanetKitLog.e("#flutter \(#function) putInterceptedMyAudioBack \(ret)")
        }
        
        result(ret)
    }
    
    func isHookMyAudioEnabled(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let callId = call.arguments as! String
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        result(call.isInterceptMyAudioEnabled)
    }
    
    func setHookedAudioData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        let args = call.arguments as! Dictionary<String, Any>
        
        guard let audioId = args["audioId"] as? String,
              let data = args["data"] as? FlutterStandardTypedData else {
            PlanetKitLog.e("#flutter \(#function) failed to get parameter")
            result(false)
            return
        }
        
        guard let audio = nativeInstances.get(key: audioId) as? PlanetKitInterceptedAudio else {
            PlanetKitLog.e("#flutter \(#function) call not found \(audioId)")
            result(false)
            return
        }
        
        audio.data = data.data
        result(true)
    }
}

extension PlanetKitFlutterHookedAudioPlugin: PlanetKitCallInterceptedAudioDelegate {
    public func didIntercept(_ call: PlanetKitCall, audio: PlanetKitInterceptedAudio) {
        nativeInstances.add(key: audio.instanceId, instance: audio)

        let data: [String : Any] = [ "callId" : call.instanceId,
                                     "audioId" : audio.instanceId,
                                     "sampleRate" : audio.sampleRate,
                                     "channel" : audio.channel,
                                     "sampleType" : audio.sampleType.rawValue,
                                     "sampleCount" : audio.sampleCount,
                                     "seq" : audio.seq,
                                     "data" : audio.data]
        
        hookedAudioStreamHandler.eventSink?(data)
    }
}
