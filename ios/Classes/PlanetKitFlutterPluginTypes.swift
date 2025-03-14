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

extension PlanetKitCallKitType: Codable {}

extension PlanetKitScreenShareState: Encodable {}

// MARK: events
// NOTE: enum value must be in-sync with android and flutter
extension PlanetKitDisconnectReason: Codable {}
extension PlanetKitDisconnectSource: Codable {}
extension PlanetKitInitialMyVideoState: Decodable { }

enum EventType: Int, Encodable {
    case call = 0
    case myMediaStatus = 1
    case conference = 2
    case peerControl = 3
    case camera = 4
}


protocol Event: Encodable {
    var type: EventType { get }
    var id: String { get }
}

class Weak<T: AnyObject> {
  weak var value : T?
  init (value: T) {
    self.value = value
  }
}
