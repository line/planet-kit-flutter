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

// MARK: call params
struct MakeCallParam: Decodable {
    let myUserId: String
    let myServiceId: String
    let peerUserId: String
    let peerServiceId: String
    let accessToken: String
    let callKitType: PlanetKitCallKitType?
    let useResponderPreparation: Bool
    let holdTonePath: String?
    let ringbackTonePath: String?
    let endTonePath: String?
    
    let allowCallWithoutMic: Bool?
    let enableAudioDescription: Bool?
    let audioDescriptionUpdateIntervalMs: Int?
}

struct MakeCallResponse: Encodable {
    let callId: String?
    let failReason: PlanetKitStartFailReason
}

struct CcParam: Decodable {
    let id: String
}

struct VerifyCallParam: Decodable {
    let myUserId: String
    let myServiceId: String
    let ccParam: CcParam
    let callKitType: PlanetKitCallKitType?
    let holdTonePath: String?
    let ringtonePath: String?
    let endTonePath: String?
    
    let allowCallWithoutMic: Bool?
    let enableAudioDescription: Bool?
    let audioDescriptionUpdateIntervalMs: Int?
}


struct VerifyCallResponse: Encodable {
    let callId: String?
    let failReason: PlanetKitStartFailReason
}


struct SpeakerOutParam: Decodable {
    let callId: String
    let speakerOut: Bool
}

struct AcceptCallParam: Decodable {
    let callId: String
    let useResponderPreparation: Bool
}

struct HoldCallParam: Decodable {
    let callId: String
    let reason: String?
}

struct EndCallParam: Decodable {
    let callId: String
    let userReleasePhrase: String?
}

struct EndCallWithErrorParam: Decodable {
    let callId: String
    let userReleasePhrase: String
}

enum CallEventType: Int, Encodable {
    case connected = 0
    case disconnected = 1
    case verified = 2
    case waitConnect = 3
    case peerMicMuted = 4
    case peerMicUnmuted = 5
    case networkDidUnavailable = 6
    case networkDidReavailable = 7
    case finishPreparation = 8
    case peerHold = 9
    case peerUnhold = 10
    case myAudioMuteRequestByPeer = 11
}

protocol CallEvent: Event {
    var type: EventType { get }
    var id: String { get }
    var subType: CallEventType { get }
}

struct ConnectedCallEvent: CallEvent {
    let type: EventType
    let id: String
    let subType: CallEventType
    let isInResponderPreparation: Bool
    let shouldFinishPreparation: Bool
    
    init(id: String, isInResponderPreparation: Bool, shouldFinishPreparation: Bool) {
        type = .call
        subType = .connected

        self.id = id
        self.isInResponderPreparation = isInResponderPreparation
        self.shouldFinishPreparation = shouldFinishPreparation
    }
}

struct DisconnectedCallEvent: CallEvent {
    let type: EventType
    let id: String
    let disconnectReason: PlanetKitDisconnectReason
    let disconnectSource: PlanetKitDisconnectSource
    let byRemote: Bool
    
    let subType: CallEventType
    
    init(id: String, disconnectReason: PlanetKitDisconnectReason, disconnectSource: PlanetKitDisconnectSource, byRemote: Bool) {
        type = .call
        subType = .disconnected
        
        self.id = id
        self.disconnectReason = disconnectReason
        self.disconnectSource = disconnectSource
        self.byRemote = byRemote
    }
}

struct VerifiedCallEvent: CallEvent {
    let type: EventType
    let id: String
    let peerUseResponderPreparation: Bool
    let subType: CallEventType
    
    init(id: String, peerUseResponderPreparation: Bool) {
        type = .call
        subType = .verified
        
        self.id = id
        self.peerUseResponderPreparation = peerUseResponderPreparation
    }
}

struct WaitConnectCallEvent: CallEvent {
    let type: EventType
    let id: String
    let subType: CallEventType
    
    init(id: String) {
        type = .call
        subType = .waitConnect
        
        self.id = id
    }
}

struct FinishPreparationCallEvent: CallEvent {
    let type: EventType
    let id: String
    let subType: CallEventType
    
    init(id: String) {
        type = .call
        subType = .finishPreparation
        
        self.id = id
    }
}

struct PeerMicMutedCallEvent: CallEvent {
    let type: EventType
    let id: String
    let subType: CallEventType
    
    init(id: String) {
        type = .call
        subType = .peerMicMuted
        
        self.id = id
    }
}

struct PeerMicUnmutedCallEvent: CallEvent {
    let type: EventType
    let id: String
    let subType: CallEventType
    
    init(id: String) {
        type = .call
        subType = .peerMicUnmuted
        
        self.id = id
    }
}

struct NetworkUnavailableCallEvent: CallEvent {
    let type: EventType
    let id: String
    let subType: CallEventType
    let isPeer: Bool
    let willDisconnectSec: Int
    
    init(id: String, isPeer: Bool, willDisconnect: TimeInterval) {
        type = .call
        subType = .networkDidUnavailable
        
        self.id = id
        self.isPeer = isPeer
        willDisconnectSec = Int(willDisconnect)
    }
}

struct NetworkReavailableCallEvent: CallEvent {
    let type: EventType
    let id: String
    let subType: CallEventType
    let isPeer: Bool
    init(id: String, isPeer: Bool) {
        type = .call
        subType = .networkDidReavailable
        
        self.id = id
        self.isPeer = isPeer
    }
}

struct PeerHoldCallEvent: CallEvent {
    let type: EventType
    let id: String
    let subType: CallEventType
    let reason: String?
    init(id: String, reason: String?) {
        type = .call
        subType = .peerHold
        
        self.id = id
        self.reason = reason
    }
}

struct PeerUnholdCallEvent: CallEvent {
    let type: EventType
    let id: String
    let subType: CallEventType
    init(id: String) {
        type = .call
        subType = .peerUnhold
        
        self.id = id
    }
}

struct MyAudioMuteRequestByPeerEvent: CallEvent {
    let type: EventType
    let id: String
    let subType: CallEventType
    let mute: Bool
    init(id: String, mute: Bool) {
        type = .call
        subType = .myAudioMuteRequestByPeer
        
        self.id = id
        self.mute = mute
    }
}

// TODO: organize types by feature
struct PutHookedAudioBackParam: Codable {
    let callId: String
    let audioId: String
}


struct MuteMyAudioParam: Codable {
    let callId: String
    let mute: Bool
}

struct RequestPeerMuteParam: Codable {
    let callId: String
    let mute: Bool
}

struct SilencePeerAudioParam: Codable {
    let callId: String
    let silent: Bool
}