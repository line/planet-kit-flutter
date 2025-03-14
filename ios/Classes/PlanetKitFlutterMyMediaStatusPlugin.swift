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

extension PlanetKitMyMediaStatus: PluginInstance {
    var instanceId: String {
        return "\(Unmanaged<AnyObject>.passUnretained(self).toOpaque())"
    }
}

enum MyMediaStatusEventType: Int, Codable {
    case micMute = 0
    case micUnmute = 1
    case updateAudioDescription = 2
    case updateVideoStatus = 3
    case updateScreenShareState = 4
}

protocol MyMediaStatusEvent: Event {
    var type: EventType { get }
    var id: String { get }
    var subType: MyMediaStatusEventType { get }
}

struct MicMuteMyMediaStatusEvent: MyMediaStatusEvent {
    let type: EventType
    let id: String
    let subType: MyMediaStatusEventType
    
    init(id: String) {
        type = .myMediaStatus
        subType = .micMute

        self.id = id
    }
}

struct MicUnmuteMyMediaStatusEventData: MyMediaStatusEvent {
    let type: EventType
    let id: String
    let subType: MyMediaStatusEventType
    
    init(id: String) {
        type = .myMediaStatus
        subType = .micUnmute

        self.id = id
    }
}

struct UpdateAudioDescriptionEvent: MyMediaStatusEvent {
    let type: EventType
    let id: String
    let subType: MyMediaStatusEventType
    
    let averageVolumeLevel: Int
    init(id: String, averageVolumeLevel: Int) {
        type = .myMediaStatus
        subType = .updateAudioDescription

        self.id = id
        self.averageVolumeLevel = averageVolumeLevel
    }
}

struct UpdateScreenShareStateEvent: MyMediaStatusEvent {
    let type: EventType
    let id: String
    let subType: MyMediaStatusEventType
    
    let state: PlanetKitScreenShareState
    init(id: String, state: PlanetKitScreenShareState) {
        type = .myMediaStatus
        subType = .updateScreenShareState

        self.id = id
        self.state = state
    }
}

extension PlanetKitVideoState: Encodable {}
extension PlanetKitVideoPauseReason: Encodable {}

extension PlanetKitVideoStatus: Encodable {
    enum CodingKeys: String, CodingKey {
        case state
        case pauseReason
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(state, forKey: .state)
        try container.encode(pauseReason, forKey: .pauseReason)
    }
}

struct UpdateVideoStatus: MyMediaStatusEvent {
    let type: EventType
    let id: String
    let subType: MyMediaStatusEventType
    
    let status: PlanetKitVideoStatus
    init(id: String, status: PlanetKitVideoStatus) {
        type = .myMediaStatus
        subType = .updateVideoStatus

        self.id = id
        self.status = status
    }
}

class PlanetKitFlutterMyMediaStatusPlugin {
    let nativeInstances: PlanetKitFlutterNativeInstances
    let eventStreamHandler: PlanetKitFlutterStreamHandler
    
    init(nativeInstances: PlanetKitFlutterNativeInstances, eventStreamHandler: PlanetKitFlutterStreamHandler) {
        self.nativeInstances = nativeInstances
        self.eventStreamHandler = eventStreamHandler
    }
    
    func isMyAudioMutedMyMediaStatus(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let myMediaStatusId = call.arguments as! String
        guard let myMediaStatus = nativeInstances.get(key: myMediaStatusId) as? PlanetKitMyMediaStatus else {
            PlanetKitLog.e("#flutter \(#function) call not found \(myMediaStatusId)")
            result(false)
            return
        }
        
        result(myMediaStatus.isMyAudioMuted)
    }
    
    func getMyVideoStatus(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let myMediaStatusId = call.arguments as! String
        guard let myMediaStatus = nativeInstances.get(key: myMediaStatusId) as? PlanetKitMyMediaStatus else {
            PlanetKitLog.e("#flutter \(#function) call not found \(myMediaStatusId)")
            result(nil)
            return
        }
        
        let myVideoStatus = myMediaStatus.videoStatus
        let encodedData = PlanetKitFlutterPlugin.encode(data: myVideoStatus)
        
        result(encodedData)
    }
}

extension PlanetKitFlutterMyMediaStatusPlugin: PlanetKitMyMediaStatusDelegate {
    public func didMuteMic(_ myMediaStatus: PlanetKitMyMediaStatus) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = MicMuteMyMediaStatusEvent(id: myMediaStatus.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func didUnmuteMic(_ myMediaStatus: PlanetKitMyMediaStatus) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = MicUnmuteMyMediaStatusEventData(id: myMediaStatus.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }

    public func didUpdateAudioDescription(_ myMediaStatus: PlanetKitMyMediaStatus, description: PlanetKitMyAudioDescription) {
        DispatchQueue.main.async {
            let event = UpdateAudioDescriptionEvent(id: myMediaStatus.instanceId, averageVolumeLevel: Int(description.averageVolumeLevel))
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func didUpdateVideoStatus(_ myMediaStatus: PlanetKitMyMediaStatus, status: PlanetKitVideoStatus) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = UpdateVideoStatus(id: myMediaStatus.instanceId, status: status)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func didUpdateScreenShareState(_ myMediaStatus: PlanetKit.PlanetKitMyMediaStatus, state: PlanetKit.PlanetKitScreenShareState) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = UpdateScreenShareStateEvent(id: myMediaStatus.instanceId, state: state)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
}
