// Copyright 2025 LINE Plus Corporation
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

/**
 * Per-stream outbound data session delegate for a conference.
 * Native sessions hold this delegate weakly, so the plugin must retain it.
 */
class PlanetKitFlutterConferenceOutboundDataSessionDelegate: PlanetKitOutboundDataSessionDelegate {
    let conferenceId: String
    let streamId: UInt32
    let eventStreamHandler: PlanetKitFlutterStreamHandler

    init(conferenceId: String, streamId: UInt32, eventStreamHandler: PlanetKitFlutterStreamHandler) {
        self.conferenceId = conferenceId
        self.streamId = streamId
        self.eventStreamHandler = eventStreamHandler
    }

    func didClose(_ session: PlanetKitOutboundDataSession, reason: PlanetKitDataSessionClosedReason) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            PlanetKitLog.v("#flutter \(#function)")
            let event = ConferenceEvents.DataSessionOutboundClosedEvent(id: conferenceId, streamId: streamId, closedReason: reason.rawValue)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            eventStreamHandler.eventSink?(encodedEvent)
        }
    }

    func didTooLongQueuedData(_ session: PlanetKitOutboundDataSession, enabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            PlanetKitLog.v("#flutter \(#function)")
            let event = ConferenceEvents.DataSessionOutboundTooLongQueuedDataEvent(id: conferenceId, streamId: streamId, enabled: enabled)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            eventStreamHandler.eventSink?(encodedEvent)
        }
    }
}

/**
 * Per-stream inbound data session delegate for a conference.
 * Native sessions hold this delegate weakly, so the plugin must retain it.
 */
class PlanetKitFlutterConferenceInboundDataSessionDelegate: PlanetKitInboundDataSessionDelegate {
    let conferenceId: String
    let streamId: UInt32
    let eventStreamHandler: PlanetKitFlutterStreamHandler

    init(conferenceId: String, streamId: UInt32, eventStreamHandler: PlanetKitFlutterStreamHandler) {
        self.conferenceId = conferenceId
        self.streamId = streamId
        self.eventStreamHandler = eventStreamHandler
    }

    func didClose(_ session: PlanetKitInboundDataSession, reason: PlanetKitDataSessionClosedReason) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            PlanetKitLog.v("#flutter \(#function)")
            let event = ConferenceEvents.DataSessionInboundClosedEvent(id: conferenceId, streamId: streamId, closedReason: reason.rawValue)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            eventStreamHandler.eventSink?(encodedEvent)
        }
    }

    func didReceive(_ session: PlanetKitInboundDataSession, peerId: PlanetKitUserId, data: Data, timestamp: UInt64, offset: UInt64) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            PlanetKitLog.v("#flutter \(#function)")
            let event = ConferenceEvents.DataSessionInboundReceivedEvent(id: conferenceId, streamId: streamId, peerId: peerId, data: data, timestamp: timestamp, offset: offset)
            let encodedEvent = PlanetKitFlutterPlugin.encode(data: event)
            eventStreamHandler.eventSink?(encodedEvent)
        }
    }
}
