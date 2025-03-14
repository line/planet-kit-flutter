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

extension PlanetKitCameraManager: PluginInstance {
    var instanceId: String {
        return "\(Unmanaged<AnyObject>.passUnretained(self).toOpaque())"
    }
}

class PlanetKitFlutterCameraPlugin {
    let eventStreamHandler: PlanetKitFlutterStreamHandler

    init(eventStreamHandler: PlanetKitFlutterStreamHandler) {
        self.eventStreamHandler = eventStreamHandler
    }
    
    func addCameraDelegate() {
        PlanetKitCameraManager.shared.delegate = self
    }
    
    func removeCameraDelegate() {
        PlanetKitCameraManager.shared.delegate = nil
    }
    
    func startPreview(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        let viewId = call.arguments as! String

        guard let view = PlanetKitFlutterVideoViews.shared.getView(id: viewId) else {
            PlanetKitLog.e("#flutter \(#function) failed to get view for id \(viewId)")
            result(false)
            return
        }
        
        PlanetKitCameraManager.shared.startPreview(delegate: view.delegate)
        PlanetKitFlutterVideoViews.shared.retain(id: viewId)
        result(true)
    }
    
    func stopPreview(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        let viewId = call.arguments as! String

        guard let view = PlanetKitFlutterVideoViews.shared.getView(id: viewId) else {
            PlanetKitLog.e("#flutter \(#function) failed to get view for id \(viewId)")
            result(false)
            return
        }
        

        PlanetKitCameraManager.shared.stopPreview(delegate: view.delegate)
        PlanetKitFlutterVideoViews.shared.release(id: viewId)
        result(true)
    }
    
    func switchPosition(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        PlanetKitCameraManager.shared.switchPosition()
    }
    
    func setVirtualBackgroundWithImage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        let urlString = call.arguments as! String
        
        guard let fileURL = URL(string: urlString) else {
            PlanetKitLog.e("#flutter \(#function) failed to create fileURL")
            result(false)
            return
        }
        
        guard #available(iOS 15.0, *) else {
            PlanetKitLog.e("#flutter \(#function) ios version not supported")
            result(false)
            return
        }
        
        guard let imageData = try? Data(contentsOf: fileURL) else {
            PlanetKitLog.e("#flutter \(#function) failed to load file from \(fileURL)")
            result(false)
            return
        }
        
        guard let image = CIImage(data: imageData) else {
            PlanetKitLog.e("#flutter \(#function) failed to create image from data")
            result(false)
            return
        }
        
        PlanetKitCameraManager.shared.virtualBackground = PlanetKitVirtualBackground(image: image)
        result(true)
    }
    
    func setVirtualBackgroundWithBlur(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        guard #available(iOS 15.0, *) else {
            PlanetKitLog.v("#flutter \(#function) ios version not supported")
            result(false)
            return
        }
        
        let blurRadius = call.arguments as! Int

        PlanetKitCameraManager.shared.virtualBackground = PlanetKitVirtualBackground(blurRadius: Float(blurRadius))
        result(true)
    }
    
    func clearVirtualBackground(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        guard #available(iOS 15.0, *) else {
            PlanetKitLog.v("#flutter \(#function) ios version not supported")
            result(false)
            return
        }
        PlanetKitCameraManager.shared.virtualBackground = nil
        result(true)
    }
}

extension PlanetKitFlutterCameraPlugin: PlanetKitCameraDelegate {
    func didStart() {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            let event = CameraEvents.StartEvent(id: PlanetKitCameraManager.shared.instanceId)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            
            eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    func didStop(_ error: NSError?) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            
            let encodedEvent = {
                if let error = error {
                    let event = CameraEvents.StartEvent(id: PlanetKitCameraManager.shared.instanceId)
                    return PlanetKitFlutterPlugin.encode(data: event)
                }
                else {
                    let event = CameraEvents.StopEvent(id: PlanetKitCameraManager.shared.instanceId)
                    return PlanetKitFlutterPlugin.encode(data: event)
                }
            }()
            
            eventStreamHandler.eventSink?(encodedEvent)
        }
    }
}

enum CameraEventType: Int, Encodable {
    case start = 0
    case stop = 1
    case error = 2
}

protocol CameraEvent: Event {
    var type: EventType { get }
    var id: String { get }
    var subType: CameraEventType { get }
}

struct CameraEvents {
    struct StartEvent: CameraEvent {
        let id: String
        let type: EventType = .camera
        let subType: CameraEventType = .start
    }
    
    struct StopEvent: CameraEvent {
        let id: String
        let type: EventType = .camera
        let subType: CameraEventType = .stop
    }
    
    struct ErrorEvent: CameraEvent {
        let id: String
        let type: EventType = .camera
        let subType: CameraEventType = .error
    }
}
