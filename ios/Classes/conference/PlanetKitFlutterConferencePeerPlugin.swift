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
import Foundation

extension PlanetKitConferencePeer: PluginInstance {
    var instanceId: String {
        return "\(Unmanaged<AnyObject>.passUnretained(self).toOpaque())"
    }
}

struct GetHoldStatusResponse: Encodable {
    let isOnHold: Bool
    let reason: String?
}

class PlanetKitFlutterConferencePeerPlugin {
    let nativeInstances: PlanetKitFlutterNativeInstances
    let eventStreamHandler: PlanetKitFlutterStreamHandler
    
    init(nativeInstances: PlanetKitFlutterNativeInstances, eventStreamHandler: PlanetKitFlutterStreamHandler) {
        self.nativeInstances = nativeInstances
        self.eventStreamHandler = eventStreamHandler
    }
    
    func getHoldStatus(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let id = call.arguments as! String
        
        guard let peer = nativeInstances.get(key: id) as? PlanetKitConferencePeer else {
            PlanetKitLog.e("#flutter \(#function) call not found \(id)")
            result(nil)
            return
        }
        
        let response = GetHoldStatusResponse(isOnHold: peer.holdStatus.isOnHold, reason: peer.holdStatus.holdReason)
        
        let encodedResponse = PlanetKitFlutterPlugin.encode(data: response)
        result(encodedResponse)
    }
    
    func isMuted(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let id = call.arguments as! String
        guard let peer = nativeInstances.get(key: id) as? PlanetKitConferencePeer else {
            PlanetKitLog.e("#flutter \(#function) call not found \(id)")
            result(false)
            return
        }
        
        result(peer.isMuted)
    }
    
    func getVideoStatus(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let id = call.arguments as! String
        
        guard let peer = nativeInstances.get(key: id) as? PlanetKitConferencePeer else {
            PlanetKitLog.e("#flutter \(#function) call not found \(id)")
            result(nil)
            return
        }
        
        guard let videoStatus = try? peer.videoStatus(subgroupName: nil) else {
            PlanetKitLog.e("#flutter \(#function) videoStatus is nil")
            result(nil)
            return
        }
        
        let encodedResponse = PlanetKitFlutterPlugin.encode(data: videoStatus)
        result(encodedResponse)
    }
    
    func getScreenShareState(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let id = call.arguments as! String
        
        guard let peer = nativeInstances.get(key: id) as? PlanetKitConferencePeer else {
            PlanetKitLog.e("#flutter \(#function) call not found \(id)")
            result(nil)
            return
        }
        
        guard let screenShareState = try? peer.screenShareStatus(subgroupName: nil).state else {
            PlanetKitLog.e("#flutter \(#function) screenShareState is nil")
            result(nil)
            return
        }
        
        result(screenShareState.rawValue)
    }
}
