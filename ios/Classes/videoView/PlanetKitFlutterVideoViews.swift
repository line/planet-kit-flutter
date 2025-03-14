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

class PlanetKitFlutterVideoViews {
    static let shared = PlanetKitFlutterVideoViews()
    private var videoViews: [String: (view: PlanetKitFlutterVideoView, count: Int)] = [:]
    private let lock = NSLock()
    
    func register(id: String, view: PlanetKitFlutterVideoView) {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        if let current = videoViews[id] {
            videoViews[id] = (current.view, current.count + 1)
        } else {
            videoViews[id] = (view, 1)
        }
    }
    
    func release(id: String) {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        if let current = videoViews[id] {
            if current.count > 1 {
                // Decrease the reference count
                videoViews[id] = (current.view, current.count - 1)
            } else {
                // Remove the view if the reference count reaches zero
                videoViews.removeValue(forKey: id)
            }
        }
    }
    
    func retain(id: String) {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        if let current = videoViews[id] {
            videoViews[id] = (current.view, current.count + 1)
        }
    }
    
    func getView(id: String) -> PlanetKitFlutterVideoView? {
        lock.lock()
        defer {
            lock.unlock()
        }
        return videoViews[id]?.view
    }
    
    var views: [PlanetKitFlutterVideoView] {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        return videoViews.values.map { $0.view }
    }
}
