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

extension PlanetKitPeerControl: PluginInstance {
    var instanceId: String {
        return "\(Unmanaged<AnyObject>.passUnretained(self).toOpaque())"
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
            PlanetKitLog.e("#flutter \(#function) peer control not found \(id)")
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
            PlanetKitLog.e("#flutter \(#function) peer control not found \(id)")
            result(false)
            return
        }
        
        peerControl.unregister() { success in
            PlanetKitLog.v("#flutter \(#function) peeer control unregister result: \(success)")
            result(success)
        }
    }
    
    func startVideo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: PeerControlParams.StartVideo.self)
        
        guard let peerControl = nativeInstances.get(key: param.id) as? PlanetKitPeerControl else {
            PlanetKitLog.e("#flutter \(#function) peer control not found \(param.id)")
            result(false)
            return
        }
        
        guard let view = PlanetKitFlutterVideoViews.shared.getView(id: param.viewId) else {
            PlanetKitLog.e("#flutter \(#function) view not found \(param.viewId)")
            result(false)
            return
        }
                
        peerControl.startVideo(maxResolution: param.maxResolution, delegate: view.delegate) { success in
            PlanetKitLog.v("#flutter \(#function) startVideo result \(success)")
            result(success)
        }
    }
    
    func stopVideo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: PeerControlParams.StopVideo.self)
        
        guard let peerControl = nativeInstances.get(key: param.id) as? PlanetKitPeerControl else {
            PlanetKitLog.e("#flutter \(#function) peer control not found \(param.id)")
            result(false)
            return
        }
                
        peerControl.stopVideo() { success in
            PlanetKitLog.v("#flutter \(#function) stopVideo result \(success)")
            result(success)
        }
    }
    
    func startScreenShare(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: PeerControlParams.StartScreenShare.self)
        
        guard let peerControl = nativeInstances.get(key: param.id) as? PlanetKitPeerControl else {
            PlanetKitLog.e("#flutter \(#function) peer control not found \(param.id)")
            result(false)
            return
        }
        
        guard let view = PlanetKitFlutterVideoViews.shared.getView(id: param.viewId) else {
            PlanetKitLog.e("#flutter \(#function) view not found \(param.viewId)")
            result(false)
            return
        }
                
        peerControl.startScreenShare(delegate: view.delegate) { success in
            PlanetKitLog.v("#flutter \(#function) startVideo result \(success)")
            result(success)
        }
    }
    
    func stopScreenShare(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: PeerControlParams.StartScreenShare.self)
        
        guard let peerControl = nativeInstances.get(key: param.id) as? PlanetKitPeerControl else {
            PlanetKitLog.e("#flutter \(#function) peer control not found \(param.id)")
            result(false)
            return
        }
        
                
        peerControl.stopScreenShare() { success in
            PlanetKitLog.v("#flutter \(#function) stopScreenShare result \(success)")
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
            let event = PeerControlEvents.UpdateAudioDescriptionEvent(id: peerControl.instanceId, averageVolumeLevel: Int(description.averageVolumeLevel))
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    func didUpdateVideo(_ peerControl: PlanetKit.PlanetKitPeerControl, subgroup: PlanetKit.PlanetKitSubgroup, status: PlanetKit.PlanetKitVideoStatus) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = PeerControlEvents.UpdateVideoEvent(id: peerControl.instanceId, status: status)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    func didUpdateScreenShare(_ peerControl: PlanetKitPeerControl, subgroup: PlanetKitSubgroup, status: PlanetKitScreenShareStatus) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = PeerControlEvents.UpdateScreenShareEvent(id: peerControl.instanceId, state: status.state)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
}
