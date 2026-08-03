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

    // Retain per-call, per-stream data session sessions and delegates.
    // Native sessions hold delegates weakly and the Dart side routes by streamId,
    // so the plugin must keep strong references keyed by callId + streamId.
    private var outboundDataSessions: [String: [UInt32: PlanetKitOutboundDataSession]] = [:]
    private var inboundDataSessions: [String: [UInt32: PlanetKitInboundDataSession]] = [:]
    private var outboundDataSessionDelegates: [String: [UInt32: PlanetKitFlutterCallOutboundDataSessionDelegate]] = [:]
    private var inboundDataSessionDelegates: [String: [UInt32: PlanetKitFlutterCallInboundDataSessionDelegate]] = [:]
    
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
        PlanetKitLog.v("#flutter \(#function)")
        
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
        PlanetKitLog.v("#flutter \(#function)")
        
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
        PlanetKitLog.v("#flutter \(#function)")
        
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
        PlanetKitLog.v("#flutter \(#function)")
        
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
        PlanetKitLog.v("#flutter \(#function)")
        
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
        PlanetKitLog.v("#flutter \(#function)")
        
        let callId = call.arguments as! String
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        result(call.isMyAudioMuted)
    }
    
    func isPeerAudioMuted(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        
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
        PlanetKitLog.v("#flutter \(#function)")
        
        let callId = call.arguments as! String
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        result(call.isPeerAudioSilenced)
    }
    
    func notifyCallKitAudioActivation(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        
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
        PlanetKitLog.v("#flutter \(#function)")
        
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
        PlanetKitLog.v("#flutter \(#function)")
        
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
        PlanetKitLog.v("#flutter \(#function)")
        
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
        PlanetKitLog.v("#flutter \(#function)")
        
        let callId = call.arguments as! String
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        result(call.isOnHold)
    }
    
    func requestPeerMute(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        
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
        PlanetKitLog.v("#flutter \(#function)")
        
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
            
            let event = ConnectedCallEvent(id: call.instanceId, isInResponderPreparation: connected.isInResponderPreparation, shouldFinishPreparation: connected.shouldFinishPreparation, isDataSessionSupported: connected.isDataSessionSupported)
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

            // Data session state must be released on every disconnect,
            // including background-adopted calls, to avoid leaking the
            // retained native sessions and delegates for the process lifetime.
            outboundDataSessions.removeValue(forKey: call.instanceId)
            inboundDataSessions.removeValue(forKey: call.instanceId)
            outboundDataSessionDelegates.removeValue(forKey: call.instanceId)
            inboundDataSessionDelegates.removeValue(forKey: call.instanceId)

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

    // MARK: contents sharing events
    public func peerDidSetSharedContents(_ call: PlanetKitCall, data: Data, elapsed: TimeInterval) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = PeerSharedContentsSetCallEvent(id: call.instanceId, data: data, elapsed: elapsed)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }

    public func peerDidUnsetSharedContents(_ call: PlanetKitCall) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = PeerSharedContentsUnsetCallEvent(id: call.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }

    public func peerDidSetExclusivelySharedContents(_ call: PlanetKitCall, data: Data, elapsed: TimeInterval) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = PeerExclusivelySharedContentsSetCallEvent(id: call.instanceId, data: data, elapsed: elapsed)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }

    public func peerDidUnsetExclusivelySharedContents(_ call: PlanetKitCall) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = PeerExclusivelySharedContentsUnsetCallEvent(id: call.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }

    // MARK: short data events
    public func didReceiveShortData(_ call: PlanetKitCall, dataType: String, data: Data) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = ShortDataReceivedCallEvent(id: call.instanceId, dataType: dataType, data: data)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }

    // MARK: data session events
    public func dataSessionIncoming(_ call: PlanetKitCall, streamId: PlanetKitDataSessionStreamId, type: PlanetKitDataSessionType) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = DataSessionIncomingCallEvent(id: call.instanceId, streamId: streamId, dataSessionType: type.rawValue)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
}

// MARK: contents sharing methods
extension PlanetKitFlutterCallPlugin {
    func setSharedContents(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        guard let args = call.arguments as? Dictionary<String, Any> else {
            PlanetKitLog.e("#flutter \(#function) failed to get parameter")
            result(false)
            return
        }

        guard let callId = args["callId"] as? String,
              let data = args["data"] as? FlutterStandardTypedData else {
            PlanetKitLog.e("#flutter \(#function) failed to get parameter")
            result(false)
            return
        }

        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }

        call.setSharedContents(data: data.data) { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }

    func unsetSharedContents(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        guard let callId = call.arguments as? String else {
            PlanetKitLog.e("#flutter \(#function) failed to get parameter")
            result(false)
            return
        }

        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }

        call.unsetSharedContents() { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }

    func setExclusivelySharedContents(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        guard let args = call.arguments as? Dictionary<String, Any> else {
            PlanetKitLog.e("#flutter \(#function) failed to get parameter")
            result(false)
            return
        }

        guard let callId = args["callId"] as? String,
              let data = args["data"] as? FlutterStandardTypedData else {
            PlanetKitLog.e("#flutter \(#function) failed to get parameter")
            result(false)
            return
        }

        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }

        call.setExclusivelySharedContents(data: data.data) { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }

    func unsetExclusivelySharedContents(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        guard let callId = call.arguments as? String else {
            PlanetKitLog.e("#flutter \(#function) failed to get parameter")
            result(false)
            return
        }

        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }

        call.unsetExclusivelySharedContents() { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }
}

// MARK: video methods
extension PlanetKitFlutterCallPlugin {
    
    func enableVideo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        
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
        PlanetKitLog.v("#flutter \(#function)")
        
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
        PlanetKitLog.v("#flutter \(#function)")
        
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
        PlanetKitLog.v("#flutter \(#function)")
        
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
        PlanetKitLog.v("#flutter \(#function)")
        
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
        PlanetKitLog.v("#flutter \(#function)")
        
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
        PlanetKitLog.v("#flutter \(#function)")
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
        PlanetKitLog.v("#flutter \(#function)")
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
        PlanetKitLog.v("#flutter \(#function)")
        
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
        PlanetKitLog.v("#flutter \(#function)")
        
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
        PlanetKitLog.v("#flutter \(#function)")

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

    func startMyScreenShare(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) iOS uses broadcast extension for screen share send")
        result(false)
    }

    func stopMyScreenShare(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) iOS uses broadcast extension for screen share send")
        result(false)
    }
}

// Short data
extension PlanetKitFlutterCallPlugin {
    func sendShortData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")

        guard let args = call.arguments as? Dictionary<String, Any>,
              let callId = args["callId"] as? String,
              let type = args["type"] as? String,
              let data = args["data"] as? FlutterStandardTypedData else {
            PlanetKitLog.e("#flutter \(#function) invalid arguments")
            result(false)
            return
        }

        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }

        call.sendShortData(type: type, data: data.data) { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }
}

// Data session
extension PlanetKitFlutterCallPlugin {
    func makeOutboundDataSession(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")

        guard let args = call.arguments as? Dictionary<String, Any>,
              let callId = args["callId"] as? String,
              let streamIdInt = args["streamId"] as? Int,
              let typeInt = args["type"] as? Int else {
            PlanetKitLog.e("#flutter \(#function) invalid arguments")
            result(PlanetKitDataSessionFailReason.internal.rawValue)
            return
        }

        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(PlanetKitDataSessionFailReason.internal.rawValue)
            return
        }

        guard let type = PlanetKitDataSessionType(rawValue: typeInt) else {
            PlanetKitLog.e("#flutter \(#function) invalid type \(typeInt)")
            result(PlanetKitDataSessionFailReason.invalidType.rawValue)
            return
        }

        let streamId = UInt32(streamIdInt)
        let delegate = PlanetKitFlutterCallOutboundDataSessionDelegate(callId: callId, streamId: streamId, eventStreamHandler: eventStreamHandler)

        call.makeOutboundDataSession(streamId: streamId, type: type, delegate: delegate) { [weak self] session, failReason in
            guard let `self` = self else {
                result(failReason.rawValue)
                return
            }

            if failReason == .none, let session = session {
                self.outboundDataSessionDelegates[callId, default: [:]][streamId] = delegate
                self.outboundDataSessions[callId, default: [:]][streamId] = session
            }
            else {
                PlanetKitLog.e("#flutter \(#function) failed with reason \(failReason)")
            }
            result(failReason.rawValue)
        }
    }

    func makeInboundDataSession(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")

        guard let args = call.arguments as? Dictionary<String, Any>,
              let callId = args["callId"] as? String,
              let streamIdInt = args["streamId"] as? Int else {
            PlanetKitLog.e("#flutter \(#function) invalid arguments")
            result(PlanetKitDataSessionFailReason.internal.rawValue)
            return
        }

        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(PlanetKitDataSessionFailReason.internal.rawValue)
            return
        }

        let streamId = UInt32(streamIdInt)
        let delegate = PlanetKitFlutterCallInboundDataSessionDelegate(callId: callId, streamId: streamId, eventStreamHandler: eventStreamHandler)

        call.makeInboundDataSession(streamId: streamId, delegate: delegate) { [weak self] session, failReason in
            guard let `self` = self else {
                result(failReason.rawValue)
                return
            }

            if failReason == .none, let session = session {
                self.inboundDataSessionDelegates[callId, default: [:]][streamId] = delegate
                self.inboundDataSessions[callId, default: [:]][streamId] = session
            }
            else {
                PlanetKitLog.e("#flutter \(#function) failed with reason \(failReason)")
            }
            result(failReason.rawValue)
        }
    }

    func unsupportInboundDataSession(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")

        guard let args = call.arguments as? Dictionary<String, Any>,
              let callId = args["callId"] as? String,
              let streamIdInt = args["streamId"] as? Int else {
            PlanetKitLog.e("#flutter \(#function) invalid arguments")
            result(false)
            return
        }

        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }

        let streamId = UInt32(streamIdInt)
        call.unsupportInboundDataSession(streamId: streamId)

        inboundDataSessions[callId]?.removeValue(forKey: streamId)
        inboundDataSessionDelegates[callId]?.removeValue(forKey: streamId)

        result(true)
    }

    func getOutboundDataSession(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")

        guard let args = call.arguments as? Dictionary<String, Any>,
              let callId = args["callId"] as? String,
              let streamIdInt = args["streamId"] as? Int else {
            PlanetKitLog.e("#flutter \(#function) invalid arguments")
            result(nil)
            return
        }

        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(nil)
            return
        }

        let streamId = UInt32(streamIdInt)
        guard let session = call.getOutboundDataSession(streamId: streamId) else {
            result(nil)
            return
        }

        result(session.type.rawValue)
    }

    func getInboundDataSession(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")

        guard let args = call.arguments as? Dictionary<String, Any>,
              let callId = args["callId"] as? String,
              let streamIdInt = args["streamId"] as? Int else {
            PlanetKitLog.e("#flutter \(#function) invalid arguments")
            result(nil)
            return
        }

        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(nil)
            return
        }

        let streamId = UInt32(streamIdInt)
        guard let session = call.getInboundDataSession(streamId: streamId) else {
            result(nil)
            return
        }

        result(session.type.rawValue)
    }

    func dataSessionSend(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")

        guard let args = call.arguments as? Dictionary<String, Any>,
              let callId = args["callId"] as? String,
              let streamIdInt = args["streamId"] as? Int,
              let data = args["data"] as? FlutterStandardTypedData,
              let timestampInt = args["timestamp"] as? Int else {
            PlanetKitLog.e("#flutter \(#function) invalid arguments")
            result(false)
            return
        }

        let streamId = UInt32(streamIdInt)
        guard let session = outboundDataSessions[callId]?[streamId] else {
            PlanetKitLog.e("#flutter \(#function) outbound data session not found \(callId) \(streamId)")
            result(false)
            return
        }

        let sent = session.send(data: data.data, timestamp: UInt64(bitPattern: Int64(timestampInt)))
        result(sent)
    }

    func dataSessionChangeDestination(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")

        guard let args = call.arguments as? Dictionary<String, Any>,
              let callId = args["callId"] as? String,
              let streamIdInt = args["streamId"] as? Int else {
            PlanetKitLog.e("#flutter \(#function) invalid arguments")
            result(false)
            return
        }

        let peerUserId = args["peerUserId"] as? String
        let peerServiceId = args["peerServiceId"] as? String

        let streamId = UInt32(streamIdInt)
        guard let session = outboundDataSessions[callId]?[streamId] else {
            PlanetKitLog.e("#flutter \(#function) outbound data session not found \(callId) \(streamId)")
            result(false)
            return
        }

        // Guard both fields (mirrors the Android side); if either is missing,
        // fall back to nil = all peers rather than force-unwrapping.
        let peerId: PlanetKitUserId?
        if let peerUserId = peerUserId, let peerServiceId = peerServiceId {
            peerId = PlanetKitUserId(id: peerUserId, serviceId: peerServiceId)
        } else {
            peerId = nil
        }
        session.changeDestination(streamId: streamId, peerId: peerId) { success in
            result(success)
        }
    }
}
