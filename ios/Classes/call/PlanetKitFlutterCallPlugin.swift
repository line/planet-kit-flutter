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

import Flutter
import Foundation
import PlanetKit

extension PlanetKitCall: PluginInstance {
    var instanceId: String {
        return uuid.uuidString
    }
}

class PlanetKitFlutterCallPlugin {
    
    private let nativeInstances: PlanetKitFlutterNativeInstances
    private let eventStreamHandler: PlanetKitFlutterStreamHandler
    private let backgroundEventStreamHandler: PlanetKitFlutterStreamHandler
    private var myStatusDelegates: [String : Weak<PlanetKitMyMediaStatusDelegate>] = [:]
    private var peerAudioDescriptionDelegates: [String : PeerAudioDescriptionDelegate] = [:]
    private var backgroundCalls: [String: PlanetKitCall] = [:]
    
    init(nativeInstances: PlanetKitFlutterNativeInstances, eventStreamHandler: PlanetKitFlutterStreamHandler, backgroundEventStreamHandler: PlanetKitFlutterStreamHandler) {
        self.nativeInstances = nativeInstances
        self.eventStreamHandler = eventStreamHandler
        self.backgroundEventStreamHandler = backgroundEventStreamHandler
        
        // Register this delegate with broadcaster to receive events from background-verified calls
        // Regular calls (makeCall, verifyCall) bypass the broadcaster
        PlanetKitFlutterCallDelegateBroadcaster.shared.registerDelegate(self)
        PlanetKitLog.v("#flutter PlanetKitFlutterCallPlugin registered with broadcaster")
    }
    
    /**
     * Unregister from the broadcaster when this plugin is being cleaned up
     */
    func dispose() {
        PlanetKitFlutterCallDelegateBroadcaster.shared.unregisterDelegate(self)
        PlanetKitLog.v("#flutter PlanetKitFlutterCallPlugin unregistered from broadcaster")
    }

    // MARK: Background call management
    func addBackgroundCall(_ call: PlanetKitCall) {
        backgroundCalls[call.instanceId] = call
    }

    func adoptBackgroundCall(callId: String, nativeInstances: PlanetKitFlutterNativeInstances) -> Bool {
        if let call = backgroundCalls.removeValue(forKey: callId) {
            nativeInstances.add(key: callId, instance: call)
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }

                let event = AdoptBackgroundCallEvent(id: callId)
                let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
                self.backgroundEventStreamHandler.eventSink?(encodedEvent)
            }
            return true
        }
        return false
    }
    
    func acceptCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: CallParams.AcceptCallParam.self)
        
        guard let call = nativeInstances.get(key: param.callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(param.callId) \(param.useResponderPreparation)")
            result(false)
            return
        }
        
        call.acceptCall(startMessage: nil, useResponderPreparation: param.useResponderPreparation, initialMyVideoState: param.initialMyVideoState)
        result(true)
    }
    
    func endCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: CallParams.EndCallParam.self)
        
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
        
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: CallParams.EndCallWithErrorParam.self)
        
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
        
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: CallParams.MuteMyAudioParam.self)
        
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
        
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: CallParams.SpeakerOutParam.self)
        
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
        
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: CallParams.HoldCallParam.self)
        
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
        
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: CallParams.RequestPeerMuteParam.self)
        
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
        
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: CallParams.SilencePeerAudioParam.self)
        
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


extension PlanetKitFlutterCallPlugin {
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

extension PlanetKitFlutterCallPlugin: PlanetKitCallDelegate {
    // for screen share, process it inside the plugin for user convenience.
    public func didStartMyBroadcast(_ call: PlanetKit.PlanetKitCall) {
        PlanetKitLog.v("#flutter \(#function)")
        call.startMyScreenShare() { success in
            if !success {
                call.stopMyBroadcast()
            }
        }
    }

    public func didFinishMyBroadcast(_ call: PlanetKit.PlanetKitCall) {
        PlanetKitLog.v("#flutter \(#function)")
        call.stopMyScreenShare() { success in
        }
    }

    public func didErrorMyBroadcast(_ call: PlanetKit.PlanetKitCall, error: PlanetKit.PlanetKitScreenShare.BroadcastError) {
        PlanetKitLog.v("#flutter \(#function)")
        call.stopMyScreenShare() { success in
        }
    }
    
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
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            
            PlanetKitLog.v("#flutter \(#function) \(disconnected.reason)")
            let event = DisconnectedCallEvent(id: call.instanceId, disconnectReason: disconnected.reason, disconnectSource: disconnected.source, userCode: disconnected.userCode, byRemote: disconnected.byRemote)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            eventStreamHandler.eventSink?(encodedEvent)
            
            if let removed = myStatusDelegates.removeValue(forKey: call.instanceId), let delegate = removed.value {
                call.myMediaStatus.removeHandler(delegate) { success in
                    if !success {
                        PlanetKitLog.e("#flutter \(#function) failed to remove handler")
                    }
                }
            }

            if backgroundCalls.keys.contains(call.instanceId) {
                PlanetKitLog.v("#flutter \(#function) background call")
                _ = backgroundCalls.removeValue(forKey: call.instanceId)
                self.backgroundEventStreamHandler.eventSink?(encodedEvent)
            } else {
                peerAudioDescriptionDelegates.removeValue(forKey: call.instanceId)
                nativeInstances.remove(key: call.myMediaStatus.instanceId)
                self.eventStreamHandler.eventSink?(encodedEvent)
            }
        }
    }
    
    public func didVerify(_ call: PlanetKit.PlanetKitCall, peerStartMessage: PlanetKit.PlanetKitCallStartMessage?, peerUseResponderPreparation: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }

            PlanetKitLog.v("#flutter \(#function)")
            let event = VerifiedCallEvent(id: call.instanceId, peerUseResponderPreparation: peerUseResponderPreparation)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)

            if backgroundCalls.keys.contains(call.instanceId) {
                PlanetKitLog.v("#flutter \(#function) background call")
                self.backgroundEventStreamHandler.eventSink?(encodedEvent)
            } else {
                self.eventStreamHandler.eventSink?(encodedEvent)
            }
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
    
    // MARK: video events
    public func peerVideoDidPause(_ call: PlanetKitCall, reason: PlanetKitVideoPauseReason) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = PeerVideoDidPauseEvent(id: call.instanceId, reason: reason)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }

    public func peerVideoDidResume(_ call: PlanetKitCall) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = PeerVideoDidResumeEvent(id: call.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func videoEnabledByPeer(_ call: PlanetKitCall) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = VideoEnabledByPeerEvent(id: call.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func videoDisabledByPeer(_ call: PlanetKitCall, reason: PlanetKitMediaDisableReason) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = VideoDisabledByPeerEvent(id: call.instanceId, reason: reason)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }

    public func didDetectMyVideoNoSource(_ call: PlanetKitCall) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = DetectedMyVideoNoSourceEvent(id: call.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func peerDidStartScreenShare(_ call: PlanetKitCall) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = PeerDidStartScreenShareEvent(id: call.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func peerDidStopScreenShare(_ call: PlanetKitCall, reason: Int32) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = PeerDidStopScreenShareEvent(id: call.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
}

// MARK: video methods
extension PlanetKitFlutterCallPlugin {
    
    func enableVideo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: CallParams.EnableVideoParam.self)
        
        let callId = param.callId
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        call.enableVideo(initialMyVideoState: param.initialMyVideoState) { success in
            result(success)
        }
    }
    
    func disableVideo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: CallParams.DisableVideoParam.self)
        
        let callId = param.callId
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        call.disableVideo(reason: param.reason) { success in
            result(success)
        }
    }
    
    func pauseMyVideo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let callId = call.arguments as! String
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        call.pauseMyVideo() { success in
            result(success)
        }
    }
    
    func resumeMyVideo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let callId = call.arguments as! String
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        call.resumeMyVideo() { success in
            result(success)
        }
    }
    
    func addMyVideoView(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: CallParams.AddVideoViewParam.self)
        
        guard let call = nativeInstances.get(key: param.callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(param.callId)")
            result(false)
            return
        }
        
        guard let view = PlanetKitFlutterVideoViews.shared.getView(id: param.viewId) else {
            PlanetKitLog.e("#flutter \(#function) view not found \(param.viewId)")
            result(false)
            return
        }
        
        call.myVideoStream.addReceiver(view.delegate)
        PlanetKitFlutterVideoViews.shared.retain(id: param.viewId)
        
        result(true)
    }
    
    func addPeerVideoView(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: CallParams.AddVideoViewParam.self)
        
        guard let call = nativeInstances.get(key: param.callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(param.callId)")
            result(false)
            return
        }
        
        guard let view = PlanetKitFlutterVideoViews.shared.getView(id: param.viewId) else {
            PlanetKitLog.e("#flutter \(#function) view not found \(param.viewId)")
            result(false)
            return
        }
        
        call.peerVideoStream.addReceiver(view.delegate)
        PlanetKitFlutterVideoViews.shared.retain(id: param.viewId)

        result(true)
    }
    
    func removeMyVideoView(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: CallParams.RemoveVideoViewParam.self)
        
        guard let call = nativeInstances.get(key: param.callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(param.callId)")
            result(false)
            return
        }
        
        guard let view = PlanetKitFlutterVideoViews.shared.getView(id: param.viewId) else {
            PlanetKitLog.e("#flutter \(#function) view not found \(param.viewId)")
            result(false)
            return
        }
        
        
        call.myVideoStream.removeReceiver(view.delegate)
        PlanetKitFlutterVideoViews.shared.release(id: param.viewId)

        result(true)
    }
    
    func removePeerVideoView(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: CallParams.RemoveVideoViewParam.self)
        
        guard let call = nativeInstances.get(key: param.callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(param.callId)")
            result(false)
            return
        }
        
        guard let view = PlanetKitFlutterVideoViews.shared.getView(id: param.viewId) else {
            PlanetKitLog.e("#flutter \(#function) view not found \(param.viewId)")
            result(false)
            return
        }
        
        call.peerVideoStream.removeReceiver(view.delegate)
        PlanetKitFlutterVideoViews.shared.release(id: param.viewId)
        
        result(true)
    }
}

// Statistics
extension PlanetKitFlutterCallPlugin {
    func getStatistics(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let callId = call.arguments as! String
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(nil)
            return
        }
        
        guard let statistics = call.statistics else {
            result(nil)
            return
        }
        
        let encodedStatistics = PlanetKitFlutterPlugin.encode(data: statistics)
        
        result(encodedStatistics)
    }
}

class PeerAudioDescriptionDelegate: PlanetKitPeerAudioDescriptionDelegate {
    let callId: String
    let eventStreamHandler: PlanetKitFlutterStreamHandler
    
    init(callId: String, eventStreamHandler: PlanetKitFlutterStreamHandler) {
        self.callId = callId
        self.eventStreamHandler = eventStreamHandler
    }
    
    func peerAudioDescriptionsDidUpdate(_ descriptions: [PlanetKit.PlanetKitPeerAudioDescription], averageVolumeLevel: Int8) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            let event = PeerAudioDescriptionUpdateEvent(id: callId, averageVolumeLevel: Int(averageVolumeLevel))
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            eventStreamHandler.eventSink?(encodedEvent)
        }
    }
}

extension PlanetKitFlutterCallPlugin {
    func setPeerAudioDescriptionDelegate(call: PlanetKitCall ) {
        let delegate = PeerAudioDescriptionDelegate(callId: call.instanceId, eventStreamHandler: eventStreamHandler)
        peerAudioDescriptionDelegates[call.instanceId] = delegate
        call.peerAudioDescriptionReceiver = delegate
    }
}
// Screen share
extension PlanetKitFlutterCallPlugin {
    func addPeerScreenShareView(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: CallParams.AddVideoViewParam.self)
        
        guard let call = nativeInstances.get(key: param.callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(param.callId)")
            result(false)
            return
        }
        
        guard let view = PlanetKitFlutterVideoViews.shared.getView(id: param.viewId) else {
            PlanetKitLog.e("#flutter \(#function) view not found \(param.viewId)")
            result(false)
            return
        }
        
        
        call.addPeerScreenShareView(delegate: view.delegate)
        PlanetKitFlutterVideoViews.shared.retain(id: param.viewId)

        result(true)
    }
    
    func removePeerScreenShareView(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: CallParams.RemoveVideoViewParam.self)
        
        guard let call = nativeInstances.get(key: param.callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(param.callId)")
            result(false)
            return
        }
        
        guard let view = PlanetKitFlutterVideoViews.shared.getView(id: param.viewId) else {
            PlanetKitLog.e("#flutter \(#function) view not found \(param.viewId)")
            result(false)
            return
        }
        
        
        call.removePeerScreenShareView(delegate: view.delegate)
        PlanetKitFlutterVideoViews.shared.release(id: param.viewId)

        result(true)
    }
}
