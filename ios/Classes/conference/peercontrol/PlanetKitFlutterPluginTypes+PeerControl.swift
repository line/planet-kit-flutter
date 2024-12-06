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


enum PeerControlEventType: Int, Codable {
    case micMute = 0
    case micUnmute = 1
    case hold = 2
    case unhold = 3
    case disconnect = 4
    case updateAudioDescription = 5
    case updateVideo = 6
    case updateScreenShare = 7
}

protocol PeerControlEvent: Event {
    var type: EventType { get }
    var id: String { get }
    var subType: PeerControlEventType { get }
}

extension PlanetKitVideoResolution: Decodable { }

struct PeerControlParams {
    struct StartVideo: Decodable {
        let id: String
        let viewId: String
        let maxResolution: PlanetKitVideoResolution
    }
    
    struct StopVideo: Decodable {
        let id: String
        let viewId: String
    }
    
    struct StartScreenShare: Decodable {
        let id: String
        let viewId: String
    }
    
    struct StopScreenShare: Decodable {
        let id: String
        let viewId: String
    }
}

struct PeerControlEvents {
    struct MicMuteEvent: PeerControlEvent {
        let type: EventType
        let id: String
        let subType: PeerControlEventType
        
        init(id: String) {
            type = .peerControl
            subType = .micMute
            self.id = id
        }
    }
    
    struct MicUnmuteEvent: PeerControlEvent {
        let type: EventType
        let id: String
        let subType: PeerControlEventType
        
        init(id: String) {
            type = .peerControl
            subType = .micUnmute
            self.id = id
        }
    }
    
    struct HoldEvent: PeerControlEvent {
        let type: EventType
        let id: String
        let subType: PeerControlEventType
        let reason: String?
        init(id: String, reason: String?) {
            type = .peerControl
            subType = .hold
            self.id = id
            self.reason = reason
        }
    }
    
    struct UnholdEvent: PeerControlEvent {
        let type: EventType
        let id: String
        let subType: PeerControlEventType
        
        init(id: String) {
            type = .peerControl
            subType = .unhold
            self.id = id
        }
    }
    
    struct DisconnectEvent: PeerControlEvent {
        let type: EventType
        let id: String
        let subType: PeerControlEventType
        
        init(id: String) {
            type = .peerControl
            subType = .disconnect
            self.id = id
        }
    }
    
    struct UpdateAudioDescriptionEvent: PeerControlEvent {
        let type: EventType
        let id: String
        let subType: PeerControlEventType
        let averageVolumeLevel: Int
        
        init(id: String, averageVolumeLevel: Int) {
            type = .peerControl
            subType = .updateAudioDescription
            self.id = id
            self.averageVolumeLevel = averageVolumeLevel
        }
    }
    
    struct UpdateVideoEvent: PeerControlEvent {
        let type: EventType
        let id: String
        let subType: PeerControlEventType
        let status: PlanetKitVideoStatus
        
        init(id: String, status: PlanetKitVideoStatus) {
            type = .peerControl
            subType = .updateVideo
            self.id = id
            self.status = status
        }
    }
    
    struct UpdateScreenShareEvent: PeerControlEvent {
        let type: EventType
        let id: String
        let subType: PeerControlEventType
        let state: PlanetKitScreenShareState
        
        init(id: String, state: PlanetKitScreenShareState) {
            type = .peerControl
            subType = .updateScreenShare
            self.id = id
            self.state = state
        }
    }
}
