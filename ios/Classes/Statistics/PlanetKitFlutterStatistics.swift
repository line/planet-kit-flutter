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

// Extension to make PlanetKitStatistics encodable
extension PlanetKitStatistics: Encodable {
    enum CodingKeys: String, CodingKey {
        case myAudio
        case peersAudio
        case myVideo
        case peerVideos
        case myScreenShare
        case peerScreenShares
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(myAudio, forKey: .myAudio)
        try container.encode(peersAudio, forKey: .peersAudio)
        try container.encode(myVideo, forKey: .myVideo)
        try container.encode(peerVideos, forKey: .peerVideos)
        try container.encode(myScreenShare, forKey: .myScreenShare)
        try container.encode(peerScreenShares, forKey: .peerScreenShares)
    }
}

extension PlanetKitStatistics.MyAudio: Encodable {
    enum CodingKeys: String, CodingKey {
        case network
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(network, forKey: .network)
    }
}

extension PlanetKitStatistics.PeersAudio: Encodable {
    enum CodingKeys: String, CodingKey {
        case network
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(network, forKey: .network)
    }
}

extension PlanetKitStatistics.MyVideo: Encodable {
    enum CodingKeys: String, CodingKey {
        case network
        case video
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(network, forKey: .network)
        try container.encode(video, forKey: .video)
    }
}

extension PlanetKitStatistics.PeerVideo: Encodable {
    enum CodingKeys: String, CodingKey {
        case peerId
        case subGroupName
        case network
        case video
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(peerId, forKey: .peerId)
        try container.encode(subGroupName, forKey: .subGroupName)
        try container.encode(network, forKey: .network)
        try container.encode(video, forKey: .video)
    }
}

extension PlanetKitStatistics.MyScreenShare: Encodable {
    enum CodingKeys: String, CodingKey {
        case network
        case video
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(network, forKey: .network)
        try container.encode(video, forKey: .video)
    }
}

extension PlanetKitStatistics.PeerScreenShare: Encodable {
    enum CodingKeys: String, CodingKey {
        case peerId
        case subGroupName
        case network
        case video
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(peerId, forKey: .peerId)
        try container.encode(subGroupName, forKey: .subGroupName)
        try container.encode(network, forKey: .network)
        try container.encode(video, forKey: .video)
    }
}

extension PlanetKitStatistics.Network: Encodable {
    enum CodingKeys: String, CodingKey {
        case lossRate
        case jitterMs
        case latencyMs
        case bps
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lossRate, forKey: .lossRate)
        try container.encode(jitterMs, forKey: .jitterMs)
        try container.encode(latencyMs, forKey: .latencyMs)
        try container.encode(bps, forKey: .bps)
    }
}

extension PlanetKitStatistics.Video: Encodable {
    enum CodingKeys: String, CodingKey {
        case width
        case height
        case fps
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(witdh, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(fps, forKey: .fps)
    }
}

extension PlanetKitUserId: Encodable {
    enum CodingKeys: String, CodingKey {
        case id
        case serviceId
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(serviceId, forKey: .serviceId)
    }
}
