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
import UIKit
import PlanetKit

class PlanetKitVideoViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        NSLog("#flutter \(#function) \(frame) \(viewId) \(args ?? "nil")")
        let view = PlanetKitFlutterVideoView(frame: frame, viewId: viewId, args: args, messenger: messenger)
        
        PlanetKitFlutterVideoViews.shared.register(id: String(viewId), view: view)
        return view
    }
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
          return FlutterStandardMessageCodec.sharedInstance()
    }
}

class PlanetKitFlutterVideoView: NSObject, FlutterPlatformView {
    
    var delegate: PlanetKitVideoOutputDelegate {
        return _view
    }
    private var _view: PlanetKitMTKView
    let id: String
    
    init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
        id = String(viewId)
        _view = PlanetKitMTKView(frame: frame, device: nil)
        _view.contentMode = .scaleAspectFit

        super.init()
        
        if let args = args as? [String: Any],
           let scaleType = args["scaleType"] as? String {
            applyScaleType(scaleType)
        }
    }
    
    deinit {
        NSLog("#flutter \(#function) video view deinit")
    }

    func view() -> UIView {
        return _view
    }
    
    private func applyScaleType(_ scaleType: String) {
        switch scaleType {
        case "centerCrop":
            _view.contentMode = .scaleAspectFill
        case "fitCenter":
            _view.contentMode = .scaleAspectFit
        default:
            _view.contentMode = .scaleAspectFit // Default to fitCenter if unknown
        }
    }
}
