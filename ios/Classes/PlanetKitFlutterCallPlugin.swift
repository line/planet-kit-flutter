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

//
//  PlanetKitFlutterPlugin+InterceptedAudio.swift
//  planet_kit_flutter
//
//  Created by USER on 4/18/24.
//


import Flutter
import Foundation
import PlanetKit

extension PlanetKitCall: PluginInstance {
    var instanceId: String {
        return uuid.uuidString
    }
}

class PlanetKitFlutterCallPlugin {
    let nativeInstances: PlanetKitFlutterNativeInstances
    let eventStreamHandler: PlanetKitFlutterStreamHandler
    var myStatusDelegates: [String : Weak<PlanetKitMyMediaStatusDelegate>] = [:]
    
    init(nativeInstances: PlanetKitFlutterNativeInstances, eventStreamHandler: PlanetKitFlutterStreamHandler) {
        self.nativeInstances = nativeInstances
        self.eventStreamHandler = eventStreamHandler
    }
    
   
    func acceptCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: AcceptCallParam.self)

        guard let call = nativeInstances.get(key: param.callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(param.callId) \(param.useResponderPreparation)")
            result(false)
            return
        }
        
        call.acceptCall(startMessage: nil, useResponderPreparation: param.useResponderPreparation)
        result(true)
    }
    
    func endCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: EndCallParam.self)
        
        guard let call = nativeInstances.get(key: param.callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(param.callId)")
            result(false)
            return
        }
        
        if let userReleasePhrase = param.userReleasePhrase {
            call.endCall(normalUserReleaseCode: userReleasePhrase)
        }
        else {
            call.endCall()
        }
        result(true)
    }
    
    func endCallWithError(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: EndCallWithErrorParam.self)
        
        guard let call = nativeInstances.get(key: param.callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(param.callId)")
            result(false)
            return
        }
        
        call.endCall(errorUserReleaseCode: param.userReleasePhrase)
        result(true)
    }
    
    func muteMyAudio(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: MuteMyAudioParam.self)

        guard let call = nativeInstances.get(key: param.callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(param.callId)")
            result(false)
            return
        }
        
        call.muteMyAudio(param.mute) { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }
    
    func speakerOut(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: SpeakerOutParam.self)
        
        let callId = param.callId
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        call.audioManager.speakerOut(param.speakerOut)
        result(true)
    }
    
    func isMyAudioMuted(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let callId = call.arguments as! String
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        result(call.isMyAudioMuted)
    }
    
    func isPeerAudioMuted(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let callId = call.arguments as! String
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        result(call.isPeerAudioMuted)
    }
    
    func isSpeakerOut(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let callId = call.arguments as! String
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        result(call.audioManager.isSpeakerOut)
    }
    
    func isPeerAudioSilenced(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let callId = call.arguments as! String
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        result(call.isPeerAudioSilenced)
    }
    
    func notifyCallKitAudioActivation(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let callId = call.arguments as! String
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        call.notifyCallKitAudioActivation()
        result(true)
    }
    
    func finishPreparation(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let callId = call.arguments as! String
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        call.finishPreparation()
        result(true)
    }
    
    func hold(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: HoldCallParam.self)
        
        let callId = param.callId
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        call.hold(reason: param.reason) { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }
    
    func unhold(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let callId = call.arguments as! String
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        call.unhold() { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }
    
    func isOnHold(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let callId = call.arguments as! String
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        result(call.isOnHold)
    }
    
    func requestPeerMute(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: RequestPeerMuteParam.self)
        
        guard let call = nativeInstances.get(key: param.callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(param.callId)")
            result(false)
            return
        }
        
        call.requestPeerMute(param.mute) { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }
    
    func silencePeerAudio(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: SilencePeerAudioParam.self)
        
        guard let call = nativeInstances.get(key: param.callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(param.callId)")
            result(false)
            return
        }
        
        call.silencePeerAudio(param.silent) { success in 
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }
}




extension PlanetKitFlutterCallPlugin: PlanetKitCallDelegate {
    public func didWaitConnect(_ call: PlanetKit.PlanetKitCall) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            
            let event = WaitConnectCallEvent(id: call.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func didConnect(_ call: PlanetKit.PlanetKitCall, connected: PlanetKit.PlanetKitCallConnectedParam) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            
            let event = ConnectedCallEvent(id: call.instanceId, isInResponderPreparation: connected.isInResponderPreparation, shouldFinishPreparation: connected.shouldFinishPreparation)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func didDisconnect(_ call: PlanetKit.PlanetKitCall, disconnected: PlanetKit.PlanetKitDisconnectedParam) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function) \(disconnected.reason)")
            let event = DisconnectedCallEvent(id: call.instanceId, disconnectReason: disconnected.reason, disconnectSource: disconnected.source, byRemote: disconnected.byRemote)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
            
            if let removed = self.myStatusDelegates.removeValue(forKey: call.instanceId), let delegate = removed.value {
                call.myMediaStatus.removeHandler(delegate) { success in
                    if !success {
                        PlanetKitLog.e("#flutter \(#function) failed to remove handler")
                    }
                }
            }
        }
    }
    
    public func didVerify(_ call: PlanetKit.PlanetKitCall, peerStartMessage: PlanetKit.PlanetKitCallStartMessage?, peerUseResponderPreparation: Bool) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = VerifiedCallEvent(id: call.instanceId, peerUseResponderPreparation: peerUseResponderPreparation)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func didFinishPreparation(_ call: PlanetKit.PlanetKitCall) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = FinishPreparationCallEvent(id: call.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func peerMicDidMute(_ call: PlanetKitCall) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = PeerMicMutedCallEvent(id: call.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func peerMicDidUnmute(_ call: PlanetKitCall) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = PeerMicUnmutedCallEvent(id: call.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func networkDidUnavailable(_ call: PlanetKitCall, isPeer: Bool, willDisconnected seconds: TimeInterval) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = NetworkUnavailableCallEvent(id: call.instanceId, isPeer: isPeer, willDisconnect: seconds)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func networkDidReavailable(_ call: PlanetKitCall, isPeer: Bool) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = NetworkReavailableCallEvent(id: call.instanceId, isPeer: isPeer)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func peerDidHold(_ call: PlanetKitCall, reason: String?) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = PeerHoldCallEvent(id: call.instanceId, reason: reason)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func peerDidUnhold(_ call: PlanetKitCall) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = PeerUnholdCallEvent(id: call.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func myMuteRequestedByPeer(_ call: PlanetKitCall, mute: Bool) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = MyAudioMuteRequestByPeerEvent(id: call.instanceId, mute: mute)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    
    public func getMyMediaStatus(call: FlutterMethodCall, delegate: PlanetKitMyMediaStatusDelegate, result: @escaping FlutterResult) {
        let callId = call.arguments as! String
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(nil)
            return
        }
        
        myStatusDelegates[callId] = Weak<PlanetKitMyMediaStatusDelegate>(value: delegate)
        
        call.myMediaStatus.addHandler(delegate) { success in
            guard success else {
                PlanetKitLog.e("#flutter \(#function) failed to add handler")
                result(nil)
                return
            }
            
            self.nativeInstances.add(key: call.myMediaStatus.instanceId, instance: call.myMediaStatus)
            result(call.myMediaStatus.instanceId)
        }
    }
}
