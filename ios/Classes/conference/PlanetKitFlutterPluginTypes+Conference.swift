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

struct ConferenceParams {
    struct UserId: Decodable {
        let userId: String
        let serviceId: String
    }
    
    struct HoldConferenceParam: Decodable {
        let id: String
        let reason: String?
    }
    
    struct MuteMyAudioParam: Decodable {
        let id: String
        let mute: Bool
    }
    
    struct RequestPeerMuteParam: Decodable {
        let id: String
        let mute: Bool
        let peerId: UserId
    }
    
    struct RequestPeersMuteParam: Decodable {
        let id: String
        let mute: Bool
    }
    
    struct SilencePeersAudioParam: Decodable {
        let id: String
        let silent: Bool
    }
    
    struct SpeakerOutParam: Decodable {
        let id: String
        let speakerOut: Bool
    }
    
    struct JoinConferenceParam: Decodable {
        let myUserId: String
        let myServiceId: String
        let roomId: String
        let roomServiceId: String
        let accessToken: String
        let endTonePath: String?
        
        let allowConferenceWithoutMic: Bool?
        let enableAudioDescription: Bool?
        let audioDescriptionUpdateIntervalMs: Int?
        let mediaType: PlanetKitMediaType
        let enableStatistics: Bool
        
        let screenShareKey: ScreenShareKey?
        let initialMyVideoState: PlanetKitInitialMyVideoState
        let appServerData: String?
    }
    
    struct CreatePeerControlParam: Decodable {
        let conferenceId: String
        let peerId: String
    }
    
    struct AddVideoViewParam: Decodable {
        let conferenceId: String
        let viewId: String
    }
    
    struct RemoveVideoViewParam: Decodable {
        let conferenceId: String
        let viewId: String
    }
    
    struct EnableVideoParam: Decodable {
        let conferenceId: String
        let initialMyVideoState: PlanetKitInitialMyVideoState
    }
}



struct JoinConferenceResponse: Encodable {
    let id: String?
    let failReason: PlanetKitStartFailReason
}



enum ConferenceEventType: Int, Encodable {
    case connected = 0
    case disconnected = 1
    case peerListUpdate = 2
    case peersMicMute = 3
    case peersMicUnmute = 4
    case peersHold = 5
    case peersUnhold = 6
    case networkUnavailable = 7
    case networkReavailable = 8
    case myAudioMuteRequestedByPeer = 9

    // MARK: short data
    case shortDataReceived = 10

    // MARK: contents sharing
    case peersSharedContentsSet = 11
    case peersSharedContentsUnset = 12
    case peerExclusivelySharedContentsSet = 13
    case peerExclusivelySharedContentsUnset = 14
    case peerRoomSharedContentsSet = 15
    case peerRoomSharedContentsUnset = 16

    // MARK: data session
    case dataSessionIncoming = 17
    case dataSessionInboundReceived = 18
    case dataSessionInboundClosed = 19
    case dataSessionOutboundClosed = 20
    case dataSessionOutboundTooLongQueuedData = 21

    // MARK: screen share
    case myScreenShareStoppedByHold = 22
}


protocol ConferenceEvent: Encodable {
    var type: EventType { get }
    var id: String { get }
    var subType: ConferenceEventType { get }
}

struct ConferenceEvents {
    struct ConnectedEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .connected
        
        init(id: String) {
            self.id = id
        }
    }
    
    struct DisconnectedEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .disconnected
        let disconnectReason: PlanetKitDisconnectReason
        let disconnectSource: PlanetKitDisconnectSource
        let userCode: String?
        let byRemote: Bool
        
        init(id: String, disconnectReason: PlanetKitDisconnectReason, disconnectSource: PlanetKitDisconnectSource, userCode: String?, byRemote: Bool) {
            self.id = id
            self.disconnectReason = disconnectReason
            self.disconnectSource = disconnectSource
            self.userCode = userCode
            self.byRemote = byRemote
        }
    }
    
    struct InitialPeerInfo: Encodable {
        let id: String
        let userId: String
        let serviceId: String
        let isDataSessionSupported: Bool

        init(id: String, userId: String, serviceId: String, isDataSessionSupported: Bool) {
            self.id = id
            self.userId = userId
            self.serviceId = serviceId
            self.isDataSessionSupported = isDataSessionSupported
        }
    }
    
    struct PeerListUpdateEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .peerListUpdate
        let added: [InitialPeerInfo]
        let removed: [String]
        let totalPeersCount: Int
        
        init(id: String, added: [InitialPeerInfo], removed: [String], totalPeersCount: Int) {
            self.id = id
            self.added = added
            self.removed = removed
            self.totalPeersCount = totalPeersCount
        }
    }
    
    struct NetworkDidUnavailableEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .networkUnavailable
        let willDisconnectSec: Int
        
        init(id: String, willDisconnectSec: Int) {
            self.id = id
            self.willDisconnectSec = willDisconnectSec
        }
    }
    
    struct NetworkDidReavailableEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .networkReavailable

        init(id: String) {
            self.id = id
        }
    }

    struct MyScreenShareStoppedByHoldEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .myScreenShareStoppedByHold

        init(id: String) {
            self.id = id
        }
    }
    
    struct PeerHoldEventData: Encodable {
        let peer: String
        let reason: String?
        
        init(peer: String, reason: String?) {
            self.peer = peer
            self.reason = reason
        }
    }
    
    struct PeersHoldEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .peersHold
        let peers: [PeerHoldEventData]
        
        init(id: String, peers: [PeerHoldEventData]) {
            self.id = id
            self.peers = peers
        }
    }
    
    struct PeersUnholdEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .peersUnhold
        let peers: [String]
        
        init(id: String, peers: [String]) {
            self.id = id
            self.peers = peers
        }
    }
    
    struct MyAudioMuteRequestedByPeerEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .myAudioMuteRequestedByPeer
        let peer: String
        let mute: Bool
        
        init(id: String, peer: String, mute: Bool) {
            self.id = id
            self.peer = peer
            self.mute = mute
        }
    }
    
    struct PeersMicMuteEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .peersMicMute
        let peers: [String]
        
        init(id: String, peers: [String]) {
            self.id = id
            self.peers = peers
        }
    }
    
    struct PeersMicUnmuteEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .peersMicUnmute
        let peers: [String]

        init(id: String, peers: [String]) {
            self.id = id
            self.peers = peers
        }
    }

    // MARK: contents sharing events
    struct PeerSharedContentsData: Encodable {
        let peer: String
        let data: String
        let elapsedMillis: Int

        init(peer: String, data: Data, elapsed: TimeInterval) {
            self.peer = peer
            self.data = data.base64EncodedString()
            self.elapsedMillis = Int((elapsed * 1000).rounded())
        }
    }

    struct PeersSharedContentsSetEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .peersSharedContentsSet
        let contents: [PeerSharedContentsData]

        init(id: String, contents: [PeerSharedContentsData]) {
            self.id = id
            self.contents = contents
        }
    }

    struct PeersSharedContentsUnsetEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .peersSharedContentsUnset
        let peers: [String]

        init(id: String, peers: [String]) {
            self.id = id
            self.peers = peers
        }
    }

    struct PeerExclusivelySharedContentsSetEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .peerExclusivelySharedContentsSet
        let peer: String
        let data: String
        let elapsedMillis: Int

        init(id: String, peer: String, data: Data, elapsed: TimeInterval) {
            self.id = id
            self.peer = peer
            self.data = data.base64EncodedString()
            self.elapsedMillis = Int((elapsed * 1000).rounded())
        }
    }

    struct PeerExclusivelySharedContentsUnsetEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .peerExclusivelySharedContentsUnset
        let peer: String

        init(id: String, peer: String) {
            self.id = id
            self.peer = peer
        }
    }

    struct PeerRoomSharedContentsSetEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .peerRoomSharedContentsSet
        let userId: String
        let serviceId: String
        let data: String
        let elapsedMillis: Int

        init(id: String, userId: String, serviceId: String, data: Data, elapsed: TimeInterval) {
            self.id = id
            self.userId = userId
            self.serviceId = serviceId
            self.data = data.base64EncodedString()
            self.elapsedMillis = Int((elapsed * 1000).rounded())
        }
    }

    struct PeerRoomSharedContentsUnsetEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .peerRoomSharedContentsUnset
        let userId: String
        let serviceId: String

        init(id: String, userId: String, serviceId: String) {
            self.id = id
            self.userId = userId
            self.serviceId = serviceId
        }
    }

    // MARK: short data events
    struct ShortDataReceivedEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .shortDataReceived
        let userId: String
        let serviceId: String
        let dataType: String
        let data: String

        init(id: String, userId: String, serviceId: String, dataType: String, data: Data) {
            self.id = id
            self.userId = userId
            self.serviceId = serviceId
            self.dataType = dataType
            self.data = data.base64EncodedString()
        }
    }

    // MARK: data session events
    struct DataSessionIncomingEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .dataSessionIncoming
        let streamId: Int
        let dataSessionType: Int

        init(id: String, streamId: UInt32, dataSessionType: Int) {
            self.id = id
            self.streamId = Int(streamId)
            self.dataSessionType = dataSessionType
        }
    }

    struct DataSessionInboundReceivedEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .dataSessionInboundReceived
        let streamId: Int
        let userId: String
        let serviceId: String
        let data: String
        let timestamp: Int
        let offset: Int

        init(id: String, streamId: UInt32, peerId: PlanetKitUserId, data: Data, timestamp: UInt64, offset: UInt64) {
            self.id = id
            self.streamId = Int(streamId)
            self.userId = peerId.id
            self.serviceId = peerId.serviceId
            self.data = data.base64EncodedString()
            // timestamp is an app-defined opaque value; the sender encodes it
            // with UInt64(bitPattern:), so reverse it the same way. Int(timestamp)
            // would trap for values above Int.max (e.g. a negative app timestamp).
            self.timestamp = Int(bitPattern: UInt(timestamp))
            self.offset = Int(offset)
        }
    }

    struct DataSessionInboundClosedEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .dataSessionInboundClosed
        let streamId: Int
        let closedReason: Int

        init(id: String, streamId: UInt32, closedReason: Int) {
            self.id = id
            self.streamId = Int(streamId)
            self.closedReason = closedReason
        }
    }

    struct DataSessionOutboundClosedEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .dataSessionOutboundClosed
        let streamId: Int
        let closedReason: Int

        init(id: String, streamId: UInt32, closedReason: Int) {
            self.id = id
            self.streamId = Int(streamId)
            self.closedReason = closedReason
        }
    }

    struct DataSessionOutboundTooLongQueuedDataEvent: ConferenceEvent {
        let type: EventType = .conference
        let id: String
        let subType: ConferenceEventType = .dataSessionOutboundTooLongQueuedData
        let streamId: Int
        let enabled: Bool

        init(id: String, streamId: UInt32, enabled: Bool) {
            self.id = id
            self.streamId = Int(streamId)
            self.enabled = enabled
        }
    }
}
