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

class VideoOutputDelegates: PlanetKitVideoOutputDelegate {
    private var delegates: [Weak<PlanetKitVideoOutputDelegate>] = []
    private let lock = NSLock()
    
    var count: Int {
        lock.lock()
        defer {
            lock.unlock()
        }
        return delegates.count
    }
    
    func add(delegate: PlanetKitVideoOutputDelegate) {
        lock.lock()
        defer {
            lock.unlock()
        }
        delegates.append(Weak<PlanetKitVideoOutputDelegate>(value: delegate))
    }
    
    func remove(delegate: PlanetKitVideoOutputDelegate) {
        lock.lock()
        defer {
            lock.unlock()
        }
        delegates.removeAll(where: {$0 === delegate})
    }
    
    func videoOutput(_ videoBuffer: PlanetKitVideoBuffer) {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        for delegate in delegates {
            delegate.value?.videoOutput(videoBuffer)
        }
    }
}


class PlanetKitFlutterCallPlugin {
    
    private let nativeInstances: PlanetKitFlutterNativeInstances
    private let eventStreamHandler: PlanetKitFlutterStreamHandler
    private var myStatusDelegates: [String : Weak<PlanetKitMyMediaStatusDelegate>] = [:]
    
    private var myVideoDelegates: [String : VideoOutputDelegates] = [:]
    private var peerVideoDelegates: [String : VideoOutputDelegates] = [:]
    
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
        
        let callId = call.arguments as! String
        guard let call = nativeInstances.get(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        call.enableVideo() { success in
            result(success)
        }
    }
    
    func disableVideo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: DisableVideoParam.self)
        
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
            if success {
                // TOBEDEL: This code will be deleted in PlanetKit 5.5.
                // pause resume api will control the camera device in the future.
                call.stopPreview()
            }
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
            if success {
                // TOBEDEL: This code will be deleted in PlanetKit 5.5.
                // pause resume api will control the camera device in the future.
                call.startPreview()
            }
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
        
        // TODO: remove startPreview() call in PlanetKit 5.5
        if myVideoDelegates[call.instanceId] == nil {
            let delegates = VideoOutputDelegates()
            myVideoDelegates[call.instanceId] = delegates
            call.myVideoReceiver = delegates
            call.startPreview()
        }
        myVideoDelegates[call.instanceId]?.add(delegate: view.delegate)

        
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
        
        if peerVideoDelegates[call.instanceId] == nil {
            let delegates = VideoOutputDelegates()
            peerVideoDelegates[call.instanceId] = delegates
            call.peerVideoReceiver = delegates
        }
        peerVideoDelegates[call.instanceId]?.add(delegate: view.delegate)
        
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
        
        
        guard let delegates = myVideoDelegates[call.instanceId] else {
            PlanetKitLog.e("#flutter \(#function) delegates not found \(param.viewId)")
            result(false)
            return
        }
        
        delegates.remove(delegate: view.delegate)
        
        // TODO: remove stopPreview() call in PlanetKit 5.5
        if delegates.count == 0 {
            myVideoDelegates.removeValue(forKey: call.instanceId)
            call.stopPreview()
            call.myVideoReceiver = nil
        }

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
        
        
        guard let delegates = peerVideoDelegates[call.instanceId] else {
            PlanetKitLog.e("#flutter \(#function) delegates not found \(param.viewId)")
            result(false)
            return
        }
        
        delegates.remove(delegate: view.delegate)
        
        if delegates.count == 0 {
            peerVideoDelegates.removeValue(forKey: call.instanceId)
            call.peerVideoReceiver = nil
        }

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
        
        // note: Implementation is difference from video view because
        // PlanetKitCall.addPeerScreenShareView support adding multiple views
        call.addPeerScreenShareView(delegate: view.delegate)
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
        
        // note: Implementation is difference from video view because
        // PlanetKitCall.addPeerScreenShareView support adding multiple views
        call.removePeerScreenShareView(delegate: view.delegate)
        result(true)
    }
}
