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

extension PlanetKitPeerControl: PluginInstance {
    var instanceId: String {
        return "\(Unmanaged<AnyObject>.passUnretained(self).toOpaque())"
    }
}

enum PeerControlEventType: Int, Codable {
    case micMute = 0
    case micUnmute = 1
    case hold = 2
    case unhold = 3
    case disconnect = 4
    case updateAudioDescription = 5
}

protocol PeerControlEvent: Event {
    var type: EventType { get }
    var id: String { get }
    var subType: PeerControlEventType { get }
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
}

class PlanetKitFlutterPeerControlPlugin {
    let nativeInstances: PlanetKitFlutterNativeInstances
    let eventStreamHandler: PlanetKitFlutterStreamHandler
    
    init(nativeInstances: PlanetKitFlutterNativeInstances, eventStreamHandler: PlanetKitFlutterStreamHandler) {
        self.nativeInstances = nativeInstances
        self.eventStreamHandler = eventStreamHandler
    }
    
    func register(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        let id = call.arguments as! String
        
        guard let peerControl = nativeInstances.get(key: id) as? PlanetKitPeerControl else {
            PlanetKitLog.e("#flutter \(#function) call not found \(id)")
            result(false)
            return
        }
        
        peerControl.register(self) { success in
            PlanetKitLog.v("#flutter \(#function) peeer control register result: \(success)")
            result(success)
        }
    }
    
    func unregister(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        let id = call.arguments as! String
        
        guard let peerControl = nativeInstances.get(key: id) as? PlanetKitPeerControl else {
            PlanetKitLog.e("#flutter \(#function) call not found \(id)")
            result(false)
            return
        }
        
        peerControl.unregister() { success in
            PlanetKitLog.v("#flutter \(#function) peeer control unregister result: \(success)")
            result(success)
        }
    }
}

extension PlanetKitFlutterPeerControlPlugin: PlanetKitPeerControlDelegate {
    func didMuteMic(_ peerControl: PlanetKitPeerControl) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = PeerControlEvents.MicMuteEvent(id: peerControl.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    func didUnmuteMic(_ peerControl: PlanetKitPeerControl) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = PeerControlEvents.MicUnmuteEvent(id: peerControl.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    func didHold(_ peerControl: PlanetKitPeerControl, reason: String) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = PeerControlEvents.HoldEvent(id: peerControl.instanceId, reason: reason)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    func didUnhold(_ peerControl: PlanetKitPeerControl) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = PeerControlEvents.UnholdEvent(id: peerControl.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    func didDisconnect(_ peerControl: PlanetKitPeerControl) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = PeerControlEvents.DisconnectEvent(id: peerControl.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    func didUpdateAudioDescription(_ peerControl: PlanetKit.PlanetKitPeerControl, description: PlanetKit.PlanetKitPeerAudioDescription) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = PeerControlEvents.UpdateAudioDescriptionEvent(id: peerControl.instanceId, averageVolumeLevel: Int(description.averageVolumeLevel))
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
}
