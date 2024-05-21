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
//  PlanetKitFlutterPluginTypes.swift
//  planet_kit_flutter
//
//  Created by USER on 4/2/24.
//

import Foundation
import PlanetKit

// TODO: separate files by features
struct LogSetting: Codable {
    let enabled: Bool
    let logLevel: Int
    let logSizeLimit: Int
}
 
// NOTE: add optional param with optional variable
struct InitParam: Codable {
    let logSetting: LogSetting?
    let serverUrl: String?
}

extension PlanetKitStartFailReason: Codable {}


// MARK: call params
struct MakeCallParam: Codable {
    let myUserId: String
    let myServiceId: String
    let peerUserId: String
    let peerServiceId: String
    let accessToken: String
}

struct MakeCallResponse: Codable {
    let callId: String?
    let failReason: PlanetKitStartFailReason
}

struct CcParam: Codable {
    let id: String
}

struct VerifyCallParam: Codable {
    let myUserId: String
    let myServiceId: String
    let ccParam: CcParam
}


struct VerifyCallResponse: Codable {
    let callId: String?
    let failReason: PlanetKitStartFailReason
}


struct SpeakerOutParam: Codable {
    let callId: String
    let speakerOut: Bool
}

// MARK: events
// NOTE: enum value must be in-sync with android and flutter
extension PlanetKitDisconnectReason: Codable {}
extension PlanetKitDisconnectSource: Codable {}

enum EventType: Int, Codable {
    case call = 0
}

enum CallEventType: Int, Codable {
    case connected = 0
    case disconnected = 1
    case verified = 2
    case waitConnect = 3
    case peerMicMuted = 4
    case peerMicUnmuted = 5
}

protocol EventData: Codable {
    var type: EventType { get }
    var id: String { get }
}

protocol CallEventData: EventData {
    var type: EventType { get }
    var id: String { get }
    var callEventType: CallEventType { get }
}

struct CallConnectedEventData: CallEventData {
    var type: EventType
    var id: String
    var callEventType: CallEventType
    init(id: String) {
        type = .call
        self.id = id
        callEventType = .connected
    }
}

struct CallDisconnectedEventData: CallEventData {
    var type: EventType
    var id: String
    let disconnectReason: PlanetKitDisconnectReason
    let disconnectSource: PlanetKitDisconnectSource
    let byRemote: Bool
    
    var callEventType: CallEventType
    
    init(id: String, disconnectReason: PlanetKitDisconnectReason, disconnectSource: PlanetKitDisconnectSource, byRemote: Bool) {
        type = .call
        self.id = id
        self.disconnectReason = disconnectReason
        self.disconnectSource = disconnectSource
        self.byRemote = byRemote
        callEventType = .disconnected
    }
}

struct CallVerifiedEventData: CallEventData {
    var type: EventType
    var id: String
    var callEventType: CallEventType
    
    init(id: String) {
        type = .call
        self.id = id
        callEventType = .verified
    }
}

struct CallWaitConnectEventData: CallEventData {
    var type: EventType
    var id: String
    var callEventType: CallEventType
    
    init(id: String) {
        type = .call
        self.id = id
        callEventType = .waitConnect
    }
}

struct CallPeerMicMutedEventData: CallEventData {
    var type: EventType
    var id: String
    var callEventType: CallEventType
    
    init(id: String) {
        type = .call
        self.id = id
        callEventType = .peerMicMuted
    }
}

struct CallPeerMicUnmutedEventData: CallEventData {
    var type: EventType
    var id: String
    var callEventType: CallEventType
    
    init(id: String) {
        type = .call
        self.id = id
        callEventType = .peerMicUnmuted
    }
}

// TODO: organize types by feature
struct PutInterceptedAudioBackParam: Codable {
    let callId: String
    let audioId: String
}
