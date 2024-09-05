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
    static public let shared = PlanetKitFlutterVideoViews()
    private var videoViews: [String : Weak<PlanetKitFlutterVideoView>] = [:]
    private let lock = NSLock()
    
    func addView(id: String, view: PlanetKitFlutterVideoView) {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        videoViews[id] = Weak<PlanetKitFlutterVideoView>(value: view)
    }
    
    func removeView(id: String) {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        videoViews.removeValue(forKey: id)
    }
    
    func getView(id: String) -> PlanetKitFlutterVideoView? {
        lock.lock()
        defer {
            lock.unlock()
        }
        return videoViews[id]?.value
    }
    
    var views: [PlanetKitFlutterVideoView] {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        return videoViews.filter { $1.value != nil }.map { $1.value! }
    }
}
