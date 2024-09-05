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

class PlanetKitFlutterCameraPlugin {
    init() {
        PlanetKitCamera.shared.addReceiver(self)
    }
    
    deinit {
        PlanetKitCamera.shared.removeReceiver(self)
    }
    
    // TODO: remove preview counts in PlanetKit 5.5
    private var previews: [PlanetKitFlutterVideoView] = []
    private let previewLock = NSLock()
    
    private func addPreview(view: PlanetKitFlutterVideoView) {
        previewLock.lock()
        defer {
            previewLock.unlock()
        }
        
        previews.append(view)
    }
    
    private func removePreview(view: PlanetKitFlutterVideoView) {
        previewLock.lock()
        defer {
            previewLock.unlock()
        }
        
        previews.removeAll{ $0 == view }
    }
    
    
    func startPreview(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        let viewId = call.arguments as! String

        guard let view = PlanetKitFlutterVideoViews.shared.getView(id: viewId) else {
            PlanetKitLog.e("#flutter \(#function) failed to get view for id \(viewId)")
            result(false)
            return
        }
        
        // TODO: remove preview counts in PlanetKit 5.5
        if previews.count == 0 {
            PlanetKitCamera.shared.open()
            PlanetKitCamera.shared.start()
        }
        
        previews.append(view)
        
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
        
        // TODO: remove preview counts in PlanetKit 5.5
        removePreview(view: view)
        if previews.count == 0 {
            PlanetKitCamera.shared.stop()
            PlanetKitCamera.shared.close()
        }
        
        result(true)
    }
    
    func switchPosition(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        PlanetKitCamera.shared.switchPosition()
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
        
        PlanetKitCamera.shared.virtualBackground = PlanetKitVirtualBackground(image: image)
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

        PlanetKitCamera.shared.virtualBackground = PlanetKitVirtualBackground(blurRadius: Float(blurRadius))
        result(true)
    }
    
    func clearVirtualBackground(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        guard #available(iOS 15.0, *) else {
            PlanetKitLog.v("#flutter \(#function) ios version not supported")
            result(false)
            return
        }
        PlanetKitCamera.shared.virtualBackground = nil
        result(true)
    }
}

extension PlanetKitFlutterCameraPlugin: PlanetKitVideoStreamDelegate {
    public func videoOutput(_ videoBuffer: PlanetKit.PlanetKitVideoBuffer) {
        previewLock.lock()
        defer {
            previewLock.unlock()
        }
        
        for preview in previews {
            preview.delegate.videoOutput(videoBuffer)
        }
    }
}
