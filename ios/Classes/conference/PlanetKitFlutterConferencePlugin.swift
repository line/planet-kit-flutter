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

extension PlanetKitConference: PluginInstance {
    var instanceId: String {
        return uuid.uuidString
    }
}

class PlanetKitFlutterConferencePlugin {
    let nativeInstances: PlanetKitFlutterNativeInstances
    let eventStreamHandler: PlanetKitFlutterStreamHandler
    var myStatusDelegates: [String : Weak<PlanetKitMyMediaStatusDelegate>] = [:]

    // Retain per-conference, per-stream data session sessions and delegates.
    // Native sessions hold delegates weakly and the Dart side routes by streamId,
    // so the plugin must keep strong references keyed by conferenceId + streamId.
    private var outboundDataSessions: [String: [UInt32: PlanetKitOutboundDataSession]] = [:]
    private var inboundDataSessions: [String: [UInt32: PlanetKitInboundDataSession]] = [:]
    private var outboundDataSessionDelegates: [String: [UInt32: PlanetKitFlutterConferenceOutboundDataSessionDelegate]] = [:]
    private var inboundDataSessionDelegates: [String: [UInt32: PlanetKitFlutterConferenceInboundDataSessionDelegate]] = [:]
    
    init(nativeInstances: PlanetKitFlutterNativeInstances, eventStreamHandler: PlanetKitFlutterStreamHandler) {
        self.nativeInstances = nativeInstances
        self.eventStreamHandler = eventStreamHandler
    }
    
    func leaveConference(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        let id = call.arguments as! String
        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(false)
            return
        }
        
        conference.leaveConference()
        result(true)
    }
    
    func muteMyAudio(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: ConferenceParams.MuteMyAudioParam.self)

        guard let conference = nativeInstances.get(key: param.id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(param.id)")
            result(false)
            return
        }
        conference.muteMyAudio(param.mute) { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }
    
    func speakerOut(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")

        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: ConferenceParams.SpeakerOutParam.self)
        
        guard let conference = nativeInstances.get(key: param.id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(param.id)")
            result(false)
            return
        }
        
        conference.audioManager.speakerOut(param.speakerOut)
        result(true)
    }
    
    func isSpeakerOut(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let id = call.arguments as! String
        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(false)
            return
        }
        
        result(conference.audioManager.isSpeakerOut)
    }
    
    func isOnHold(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        let id = call.arguments as! String
        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(false)
            return
        }
        
        result(conference.isOnHold)
    }
    
    
    func notifyCallKitAudioActivation(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        let id = call.arguments as! String
        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(false)
            return
        }
        
        conference.notifyCallKitAudioActivation()
        result(true)
    }
    
    func silencePeersAudio(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: ConferenceParams.SilencePeersAudioParam.self)
        
        guard let conference = nativeInstances.get(key: param.id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(param.id)")
            result(false)
            return
        }
        
        conference.silencePeersAudio(param.silent) { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }
    
    func isPeersAudioSilenced(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        let id = call.arguments as! String
        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(false)
            return
        }
        
        result(conference.isPeersAudioSilenced)
    }
    
    func requestPeerMute(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: ConferenceParams.RequestPeerMuteParam.self)
        
        guard let conference = nativeInstances.get(key: param.id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(param.id)")
            result(false)
            return
        }
        
        let userId = PlanetKitUserId(id: param.peerId.userId, serviceId: param.peerId.serviceId)

        conference.requestPeerMute(param.mute, peerId: userId) { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }
    
    func requestPeersMute(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: ConferenceParams.RequestPeersMuteParam.self)
        
        guard let conference = nativeInstances.get(key: param.id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(param.id)")
            result(false)
            return
        }

        conference.requestPeersMute(param.mute) { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }
    
    func hold(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: ConferenceParams.HoldConferenceParam.self)
        
        guard let conference = nativeInstances.get(key: param.id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(param.id)")
            result(false)
            return
        }
        
        conference.hold(reason: param.reason) { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }
    
    func unhold(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        let id = call.arguments as! String

        
        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(false)
            return
        }
        
        conference.unhold() { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }
    
    func getMyMediaStatus(call: FlutterMethodCall, delegate: PlanetKitMyMediaStatusDelegate, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        let id = call.arguments as! String
        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(false)
            return
        }
        
        myStatusDelegates[id] = Weak<PlanetKitMyMediaStatusDelegate>(value: delegate)

        conference.myMediaStatus.addHandler(delegate) { success in
            guard success else {
                PlanetKitLog.e("#flutter \(#function) failed to add handler")
                result(nil)
                return
            }
            
            self.nativeInstances.add(key: conference.myMediaStatus.instanceId, instance: conference.myMediaStatus)
            result(conference.myMediaStatus.instanceId)
        }
    }
    
    func createPeerControl(call: FlutterMethodCall, delegate: PlanetKitPeerControlDelegate, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: ConferenceParams.CreatePeerControlParam.self)
        
        guard let conference = nativeInstances.get(key: param.conferenceId) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(param.conferenceId)")
            result(nil)
            return
        }
        
        guard let conferencePeer = nativeInstances.get(key: param.peerId) as? PlanetKitConferencePeer else {
            PlanetKitLog.e("#flutter \(#function) conference peer not found \(param.peerId)")
            result(nil)
            return
        }
        
        guard let peerControl = conference.createPeerControl(peer: conferencePeer) else {
            PlanetKitLog.e("#flutter \(#function) createPeerControl returned nil")
            result(nil)
            return
        }
        
        nativeInstances.add(key: peerControl.instanceId, instance: peerControl)
        result(peerControl.instanceId)
    }
    
    func addMyVideoView(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: ConferenceParams.AddVideoViewParam.self)

        guard let conference = nativeInstances.get(key: param.conferenceId) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) call not found \(param.conferenceId)")
            result(false)
            return
        }
        
        guard let view = PlanetKitFlutterVideoViews.shared.getView(id: param.viewId) else {
            PlanetKitLog.e("#flutter \(#function) view not found \(param.viewId)")
            result(false)
            return
        }
        
        conference.myVideoStream.addReceiver(view.delegate)
        PlanetKitFlutterVideoViews.shared.retain(id: param.viewId)
        
        result(true)
    }
    
    func removeMyVideoView(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: ConferenceParams.RemoveVideoViewParam.self)
        
        guard let conference = nativeInstances.get(key: param.conferenceId) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) call not found \(param.conferenceId)")
            result(false)
            return
        }
        
        guard let view = PlanetKitFlutterVideoViews.shared.getView(id: param.viewId) else {
            PlanetKitLog.e("#flutter \(#function) view not found \(param.viewId)")
            result(false)
            return
        }
        
        conference.myVideoStream.removeReceiver(view.delegate)
        PlanetKitFlutterVideoViews.shared.release(id: param.viewId)
        
        result(true)
    }
    
    
    func enableVideo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: ConferenceParams.EnableVideoParam.self)

        let id = param.conferenceId
        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(false)
            return
        }
        
        conference.enableVideo(initialMyVideoState: param.initialMyVideoState) { success in
            PlanetKitLog.v("#flutter \(#function) result: \(success)")
            result(success)
            return
        }
    }
    
    func disableVideo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        
        let id = call.arguments as! String
        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(false)
            return
        }
        
        conference.disableVideo() { success in
            PlanetKitLog.v("#flutter \(#function) result: \(success)")
            result(success)
            return
        }
    }
    
    func pauseMyVideo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        
        let id = call.arguments as! String
        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) call not found \(id)")
            result(false)
            return
        }
        
        conference.pauseMyVideo() { success in
            result(success)
        }
    }
    
    func resumeMyVideo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        
        let id = call.arguments as! String
        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) call not found \(id)")
            result(false)
            return
        }
        
        conference.resumeMyVideo() { success in
            result(success)
        }
    }
}

extension PlanetKitFlutterConferencePlugin: PlanetKitConferenceDelegate {
    // for screen share, process it inside the plugin for user convenience.
    public func didStartMyBroadcast(_ conference: PlanetKit.PlanetKitConference) {
        PlanetKitLog.v("#flutter \(#function)")
        conference.startMyScreenShare(subgroupName: nil) { success in
            if !success {
                conference.stopMyBroadcast()
            }
        }
    }

    public func didFinishMyBroadcast(_ conference: PlanetKit.PlanetKitConference) {
        PlanetKitLog.v("#flutter \(#function)")
        conference.stopMyScreenShare() { success in
        }
    }

    public func didErrorMyBroadcast(_ conference: PlanetKit.PlanetKitConference, error: PlanetKit.PlanetKitScreenShare.BroadcastError) {
        PlanetKitLog.v("#flutter \(#function)")
        conference.stopMyScreenShare() { success in
        }
    }
    
    
    func didConnect(_ conference: PlanetKit.PlanetKitConference, connected: PlanetKit.PlanetKitConferenceConnectedParam) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = ConferenceEvents.ConnectedEvent(id: conference.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    func didDisconnect(_ conference: PlanetKit.PlanetKitConference, disconnected: PlanetKit.PlanetKitDisconnectedParam) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = ConferenceEvents.DisconnectedEvent(id: conference.instanceId, disconnectReason: disconnected.reason, disconnectSource: disconnected.source, userCode: disconnected.userCode, byRemote: disconnected.byRemote)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
            self.outboundDataSessions.removeValue(forKey: conference.instanceId)
            self.inboundDataSessions.removeValue(forKey: conference.instanceId)
            self.outboundDataSessionDelegates.removeValue(forKey: conference.instanceId)
            self.inboundDataSessionDelegates.removeValue(forKey: conference.instanceId)
            self.nativeInstances.remove(key: conference.myMediaStatus.instanceId)
        }
    }

    // MARK: data session events
    func dataSessionIncoming(_ conference: PlanetKitConference, streamId: PlanetKitDataSessionStreamId, subgroup: PlanetKitSubgroup?, type: PlanetKitDataSessionType) {
        // Subgroup data sessions are out of scope; only handle main room (subgroup == nil).
        guard subgroup == nil else {
            PlanetKitLog.v("#flutter \(#function) ignoring subgroup data session")
            return
        }
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = ConferenceEvents.DataSessionIncomingEvent(id: conference.instanceId, streamId: streamId, dataSessionType: type.rawValue)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    func peerListDidUpdate(_ conference: PlanetKit.PlanetKitConference, updated: PlanetKit.PlanetKitConferencePeerListUpdateParam) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            var added: [ConferenceEvents.InitialPeerInfo] = []
            var removed: [String] = []
            
            for addedPeer in updated.addedPeers {
                let info = ConferenceEvents.InitialPeerInfo(id: addedPeer.instanceId, userId: addedPeer.id.id, serviceId: addedPeer.id.serviceId, isDataSessionSupported: addedPeer.isDataSessionSupported)
                added.append(info)
                self.nativeInstances.add(key: addedPeer.instanceId, instance: addedPeer)
            }
            
            for removedPeer in updated.removedPeers {
                removed.append(removedPeer.instanceId)
                self.nativeInstances.remove(key: removedPeer.instanceId)
            }
            
            let event = ConferenceEvents.PeerListUpdateEvent(id: conference.instanceId, added: added, removed: removed, totalPeersCount: conference.peersCount)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    func peersVideoDidUpdate(_ conference: PlanetKit.PlanetKitConference, updated: PlanetKit.PlanetKitConferenceVideoUpdateParam) {
        // do nothing
    }
    
    func peersDidHold(_ conference: PlanetKitConference, peerHolds: [PlanetKitConferencePeerHold]) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            var peers: [ConferenceEvents.PeerHoldEventData] = []

            for peerHold in peerHolds {
                let peerHoldData = ConferenceEvents.PeerHoldEventData(peer: peerHold.peer.instanceId, reason: peerHold.reason)
                peers.append(peerHoldData)
            }
            

            let event = ConferenceEvents.PeersHoldEvent(id: conference.instanceId, peers: peers)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    func peersDidUnhold(_ conference: PlanetKitConference, peers: [PlanetKitConferencePeer]) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            var unholdPeers: [String] = []

            for peer in peers {
                unholdPeers.append(peer.instanceId)
            }
            

            let event = ConferenceEvents.PeersUnholdEvent(id: conference.instanceId, peers: unholdPeers)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    func peersMicDidMute(_ conference: PlanetKitConference, peers: [PlanetKitConferencePeer]) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            var micMutePeers: [String] = []
            
            for peer in peers {
                micMutePeers.append(peer.instanceId)
            }
            
            let event = ConferenceEvents.PeersMicMuteEvent(id: conference.instanceId, peers: micMutePeers)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    func peersMicDidUnmute(_ conference: PlanetKitConference, peers: [PlanetKitConferencePeer]) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            var micUnmutePeers: [String] = []
            
            for peer in peers {
                micUnmutePeers.append(peer.instanceId)
            }
            
            let event = ConferenceEvents.PeersMicUnmuteEvent(id: conference.instanceId, peers: micUnmutePeers)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    func myMuteRequestedByPeer(_ conference: PlanetKitConference, peer: PlanetKitConferencePeer, mute: Bool) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = ConferenceEvents.MyAudioMuteRequestedByPeerEvent(id: conference.instanceId, peer: peer.instanceId, mute: mute)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    func networkDidUnavailable(_ conference: PlanetKitConference, willDisconnected seconds: TimeInterval) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = ConferenceEvents.NetworkDidUnavailableEvent(id: conference.instanceId, willDisconnectSec: Int(seconds))
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    func networkDidReavailable(_ conference: PlanetKitConference) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = ConferenceEvents.NetworkDidReavailableEvent(id: conference.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }

    func myScreenShareDidStopByHold(_ conference: PlanetKitConference) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = ConferenceEvents.MyScreenShareStoppedByHoldEvent(id: conference.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }

    // MARK: contents sharing events
    func peersDidSetSharedContents(_ conference: PlanetKitConference, sharedContents: [PlanetKitConferenceSetSharedContent]) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            var contents: [ConferenceEvents.PeerSharedContentsData] = []

            for sharedContent in sharedContents {
                let content = ConferenceEvents.PeerSharedContentsData(peer: sharedContent.peer.instanceId, data: sharedContent.data, elapsed: sharedContent.elapsedSeconds)
                contents.append(content)
            }

            let event = ConferenceEvents.PeersSharedContentsSetEvent(id: conference.instanceId, contents: contents)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }

    // MARK: short data events
    func didReceiveShortData(_ conference: PlanetKitConference, senderId: PlanetKitUserId, dataType: String, data: Data) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = ConferenceEvents.ShortDataReceivedEvent(id: conference.instanceId, userId: senderId.id, serviceId: senderId.serviceId, dataType: dataType, data: data)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    func peersDidUnsetSharedContents(_ conference: PlanetKitConference, peers: [PlanetKitConferencePeer]) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            var unsetPeers: [String] = []

            for peer in peers {
                unsetPeers.append(peer.instanceId)
            }

            let event = ConferenceEvents.PeersSharedContentsUnsetEvent(id: conference.instanceId, peers: unsetPeers)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }

    func peerDidSetExclusivelySharedContents(_ conference: PlanetKitConference, peer: PlanetKitConferencePeer, data: Data, elapsed: TimeInterval) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = ConferenceEvents.PeerExclusivelySharedContentsSetEvent(id: conference.instanceId, peer: peer.instanceId, data: data, elapsed: elapsed)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }

    func peerDidUnsetExclusivelySharedContents(_ conference: PlanetKitConference, peer: PlanetKitConferencePeer) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = ConferenceEvents.PeerExclusivelySharedContentsUnsetEvent(id: conference.instanceId, peer: peer.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }

    func peerDidSetRoomSharedContents(_ conference: PlanetKitConference, peerId: PlanetKitUserId, data: Data, elapsed: TimeInterval) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = ConferenceEvents.PeerRoomSharedContentsSetEvent(id: conference.instanceId, userId: peerId.id, serviceId: peerId.serviceId, data: data, elapsed: elapsed)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }

    func peerDidUnsetRoomSharedContents(_ conference: PlanetKitConference, peerId: PlanetKitUserId) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = ConferenceEvents.PeerRoomSharedContentsUnsetEvent(id: conference.instanceId, userId: peerId.id, serviceId: peerId.serviceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
}

// MARK: contents sharing methods
extension PlanetKitFlutterConferencePlugin {
    func setSharedContents(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        guard let args = call.arguments as? Dictionary<String, Any> else {
            PlanetKitLog.e("#flutter \(#function) failed to get parameter")
            result(false)
            return
        }

        guard let id = args["id"] as? String,
              let data = args["data"] as? FlutterStandardTypedData else {
            PlanetKitLog.e("#flutter \(#function) failed to get parameter")
            result(false)
            return
        }

        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(false)
            return
        }

        conference.setSharedContents(data: data.data) { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }

    func unsetSharedContents(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        guard let id = call.arguments as? String else {
            PlanetKitLog.e("#flutter \(#function) failed to get parameter")
            result(false)
            return
        }

        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(false)
            return
        }

        conference.unsetSharedContents() { success in
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

        guard let id = args["id"] as? String,
              let data = args["data"] as? FlutterStandardTypedData else {
            PlanetKitLog.e("#flutter \(#function) failed to get parameter")
            result(false)
            return
        }

        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(false)
            return
        }

        conference.setExclusivelySharedContents(data: data.data) { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }

    func unsetExclusivelySharedContents(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        guard let id = call.arguments as? String else {
            PlanetKitLog.e("#flutter \(#function) failed to get parameter")
            result(false)
            return
        }

        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(false)
            return
        }

        conference.unsetExclusivelySharedContents() { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }

    func setRoomSharedContents(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        guard let args = call.arguments as? Dictionary<String, Any> else {
            PlanetKitLog.e("#flutter \(#function) failed to get parameter")
            result(false)
            return
        }

        guard let id = args["id"] as? String,
              let data = args["data"] as? FlutterStandardTypedData else {
            PlanetKitLog.e("#flutter \(#function) failed to get parameter")
            result(false)
            return
        }

        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(false)
            return
        }

        conference.setRoomSharedContents(data: data.data) { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }

    func unsetRoomSharedContents(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        guard let id = call.arguments as? String else {
            PlanetKitLog.e("#flutter \(#function) failed to get parameter")
            result(false)
            return
        }

        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(false)
            return
        }

        conference.unsetRoomSharedContents() { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }
}

// Statistics
extension PlanetKitFlutterConferencePlugin {
    func getStatistics(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")
        
        let conferenceId = call.arguments as! String
        guard let conference = nativeInstances.get(key: conferenceId) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) call not found \(conferenceId)")
            result(nil)
            return
        }
        
        guard let statistics = conference.statistics else {
            result(nil)
            return
        }
        
        let encodedStatistics = PlanetKitFlutterPlugin.encode(data: statistics)

        result(encodedStatistics)
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
extension PlanetKitFlutterConferencePlugin {
    func sendShortData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")

        guard let args = call.arguments as? Dictionary<String, Any>,
              let id = args["id"] as? String,
              let type = args["type"] as? String,
              let data = args["data"] as? FlutterStandardTypedData else {
            PlanetKitLog.e("#flutter \(#function) invalid arguments")
            result(false)
            return
        }

        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(false)
            return
        }

        conference.sendShortData(type: type, data: data.data) { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }

    func sendShortDataToPeer(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")

        guard let args = call.arguments as? Dictionary<String, Any>,
              let id = args["id"] as? String,
              let type = args["type"] as? String,
              let data = args["data"] as? FlutterStandardTypedData,
              let peerIdDict = args["peerId"] as? Dictionary<String, Any>,
              let userId = peerIdDict["userId"] as? String,
              let serviceId = peerIdDict["serviceId"] as? String else {
            PlanetKitLog.e("#flutter \(#function) invalid arguments")
            result(false)
            return
        }

        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(false)
            return
        }

        let peerId = PlanetKitUserId(id: userId, serviceId: serviceId)

        conference.sendShortData(peerId: peerId, type: type, data: data.data) { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }
}

// Data session
extension PlanetKitFlutterConferencePlugin {
    func makeOutboundDataSession(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")

        guard let args = call.arguments as? Dictionary<String, Any>,
              let id = args["id"] as? String,
              let streamIdInt = args["streamId"] as? Int,
              let typeInt = args["type"] as? Int else {
            PlanetKitLog.e("#flutter \(#function) invalid arguments")
            result(PlanetKitDataSessionFailReason.internal.rawValue)
            return
        }

        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(PlanetKitDataSessionFailReason.internal.rawValue)
            return
        }

        guard let type = PlanetKitDataSessionType(rawValue: typeInt) else {
            PlanetKitLog.e("#flutter \(#function) invalid type \(typeInt)")
            result(PlanetKitDataSessionFailReason.invalidType.rawValue)
            return
        }

        let streamId = UInt32(streamIdInt)
        let delegate = PlanetKitFlutterConferenceOutboundDataSessionDelegate(conferenceId: id, streamId: streamId, eventStreamHandler: eventStreamHandler)

        conference.makeOutboundDataSession(streamId: streamId, type: type, delegate: delegate) { [weak self] session, failReason in
            guard let `self` = self else {
                result(failReason.rawValue)
                return
            }

            if failReason == .none, let session = session {
                self.outboundDataSessionDelegates[id, default: [:]][streamId] = delegate
                self.outboundDataSessions[id, default: [:]][streamId] = session
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
              let id = args["id"] as? String,
              let streamIdInt = args["streamId"] as? Int else {
            PlanetKitLog.e("#flutter \(#function) invalid arguments")
            result(PlanetKitDataSessionFailReason.internal.rawValue)
            return
        }

        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(PlanetKitDataSessionFailReason.internal.rawValue)
            return
        }

        let streamId = UInt32(streamIdInt)
        let delegate = PlanetKitFlutterConferenceInboundDataSessionDelegate(conferenceId: id, streamId: streamId, eventStreamHandler: eventStreamHandler)

        conference.makeInboundDataSession(streamId: streamId, delegate: delegate) { [weak self] session, failReason in
            guard let `self` = self else {
                result(failReason.rawValue)
                return
            }

            if failReason == .none, let session = session {
                self.inboundDataSessionDelegates[id, default: [:]][streamId] = delegate
                self.inboundDataSessions[id, default: [:]][streamId] = session
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
              let id = args["id"] as? String,
              let streamIdInt = args["streamId"] as? Int else {
            PlanetKitLog.e("#flutter \(#function) invalid arguments")
            result(false)
            return
        }

        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(false)
            return
        }

        let streamId = UInt32(streamIdInt)
        conference.unsupportInboundDataSession(streamId: streamId)

        inboundDataSessions[id]?.removeValue(forKey: streamId)
        inboundDataSessionDelegates[id]?.removeValue(forKey: streamId)

        result(true)
    }

    func getOutboundDataSession(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")

        guard let args = call.arguments as? Dictionary<String, Any>,
              let id = args["id"] as? String,
              let streamIdInt = args["streamId"] as? Int else {
            PlanetKitLog.e("#flutter \(#function) invalid arguments")
            result(nil)
            return
        }

        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(nil)
            return
        }

        let streamId = UInt32(streamIdInt)
        guard let session = conference.getOutboundDataSession(streamId: streamId) else {
            result(nil)
            return
        }

        result(session.type.rawValue)
    }

    func getInboundDataSession(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")

        guard let args = call.arguments as? Dictionary<String, Any>,
              let id = args["id"] as? String,
              let streamIdInt = args["streamId"] as? Int else {
            PlanetKitLog.e("#flutter \(#function) invalid arguments")
            result(nil)
            return
        }

        guard let conference = nativeInstances.get(key: id) as? PlanetKitConference else {
            PlanetKitLog.e("#flutter \(#function) conference not found \(id)")
            result(nil)
            return
        }

        let streamId = UInt32(streamIdInt)
        guard let session = conference.getInboundDataSession(streamId: streamId) else {
            result(nil)
            return
        }

        result(session.type.rawValue)
    }

    func dataSessionSend(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")

        guard let args = call.arguments as? Dictionary<String, Any>,
              let id = args["id"] as? String,
              let streamIdInt = args["streamId"] as? Int,
              let data = args["data"] as? FlutterStandardTypedData,
              let timestampInt = args["timestamp"] as? Int else {
            PlanetKitLog.e("#flutter \(#function) invalid arguments")
            result(false)
            return
        }

        let streamId = UInt32(streamIdInt)
        guard let session = outboundDataSessions[id]?[streamId] else {
            PlanetKitLog.e("#flutter \(#function) outbound data session not found \(id) \(streamId)")
            result(false)
            return
        }

        let sent = session.send(data: data.data, timestamp: UInt64(bitPattern: Int64(timestampInt)))
        result(sent)
    }

    func dataSessionChangeDestination(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function)")

        guard let args = call.arguments as? Dictionary<String, Any>,
              let id = args["id"] as? String,
              let streamIdInt = args["streamId"] as? Int else {
            PlanetKitLog.e("#flutter \(#function) invalid arguments")
            result(false)
            return
        }

        let peerUserId = args["peerUserId"] as? String
        let peerServiceId = args["peerServiceId"] as? String

        let streamId = UInt32(streamIdInt)
        guard let session = outboundDataSessions[id]?[streamId] else {
            PlanetKitLog.e("#flutter \(#function) outbound data session not found \(id) \(streamId)")
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
