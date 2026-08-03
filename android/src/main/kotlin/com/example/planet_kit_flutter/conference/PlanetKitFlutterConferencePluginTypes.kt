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

package com.example.planet_kit_flutter.conference

import com.example.planet_kit_flutter.Event
import com.example.planet_kit_flutter.EventType
import com.google.gson.JsonElement
import com.google.gson.JsonPrimitive
import com.google.gson.JsonSerializationContext
import com.google.gson.JsonSerializer
import com.linecorp.planetkit.PlanetKitInitialMyVideoState
import com.linecorp.planetkit.PlanetKitMediaType
import com.linecorp.planetkit.PlanetKitStartFailReason
import com.linecorp.planetkit.session.PlanetKitDisconnectReason
import com.linecorp.planetkit.session.PlanetKitDisconnectSource
import java.lang.reflect.Type

object ConferenceParams {
    data class UserId(
        val userId: String,
        val serviceId: String
    )

    data class HoldConferenceParam(
        val id: String,
        val reason: String?
    )

    data class MuteMyAudioParam(
        val id: String,
        val mute: Boolean
    )

    data class RequestPeerMuteParam(
        val id: String,
        val mute: Boolean,
        val peerId: UserId
    )

    data class RequestPeersMuteParam(
        val id: String,
        val mute: Boolean,
    )

    data class SilencePeersAudioParam(
        val id: String,
        val silent: Boolean
    )

    data class SpeakerOutParam(
        val id: String,
        val speakerOut: Boolean
    )

    data class JoinConferenceParam(
        val myUserId: String,
        val myServiceId: String,
        val roomId: String,
        val roomServiceId: String,
        val accessToken: String,
        val endTonePath: String?,

        val allowConferenceWithoutMic: Boolean?,
        val allowConferenceWithoutMicPermission: Boolean?,
        val enableAudioDescription: Boolean?,
        val audioDescriptionUpdateIntervalMs: Int?,

        val mediaType: PlanetKitMediaType,
        val enableStatistics: Boolean,

        val initialMyVideoState: PlanetKitInitialMyVideoState,

        val appServerData: String?
    )

    data class CreatePeerControlParam(
        val conferenceId: String,
        val peerId: String
    )

    data class AddVideoViewParam(
        val conferenceId: String,
        val viewId: String
    )

    data class RemoveVideoViewParam(
        val conferenceId: String,
        val viewId: String
    )

    data class EnableVideoParam(
        val conferenceId: String,
        val initialMyVideoState: PlanetKitInitialMyVideoState
    )

}

data class JoinConferenceResponse(
    val id: String?,
    val failReason: PlanetKitStartFailReason
)

enum class ConferenceEventType(val type: Int) {
    CONNECTED(0),
    DISCONNECTED(1),
    PEER_LIST_UPDATE(2),
    PEERS_MIC_MUTE(3),
    PEERS_MIC_UNMUTE(4),
    PEERS_HOLD(5),
    PEERS_UNHOLD(6),
    NETWORK_UNAVAILABLE(7),
    NETWORK_REAVAILABLE(8),
    MY_AUDIO_MUTE_REQUESTED_BY_PEER(9),
    SHORT_DATA_RECEIVED(10),
    PEERS_SHARED_CONTENTS_SET(11),
    PEERS_SHARED_CONTENTS_UNSET(12),
    PEER_EXCLUSIVELY_SHARED_CONTENTS_SET(13),
    PEER_EXCLUSIVELY_SHARED_CONTENTS_UNSET(14),
    PEER_ROOM_SHARED_CONTENTS_SET(15),
    PEER_ROOM_SHARED_CONTENTS_UNSET(16),
    DATA_SESSION_INCOMING(17),
    DATA_SESSION_INBOUND_RECEIVED(18),
    DATA_SESSION_INBOUND_CLOSED(19),
    DATA_SESSION_OUTBOUND_CLOSED(20),
    DATA_SESSION_OUTBOUND_TOO_LONG_QUEUED_DATA(21),
    MY_SCREEN_SHARE_STOPPED_BY_HOLD(22),
    ERROR(-1); // Assuming -1 is an appropriate representation for error
}

class ConferenceEventTypeSerializer : JsonSerializer<ConferenceEventType> {
    override fun serialize(
        src: ConferenceEventType?,
        typeOfSrc: Type?,
        context: JsonSerializationContext?
    ): JsonElement {
        return JsonPrimitive(src?.type)
    }
}


interface ConferenceEvent : Event {
    val subType: ConferenceEventType
}

object ConferenceEvents {
    data class ConnectedEvent(
        override val id: String,
        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.CONNECTED
    ) : ConferenceEvent

    data class MyScreenShareStoppedByHoldEvent(
        override val id: String,
        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.MY_SCREEN_SHARE_STOPPED_BY_HOLD
    ) : ConferenceEvent

    data class DisconnectedEvent(
        override val id: String,
        val disconnectReason: PlanetKitDisconnectReason,
        val disconnectSource: PlanetKitDisconnectSource,
        val userCode: String?,
        val byRemote: Boolean,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.DISCONNECTED
    ) : ConferenceEvent

    data class InitialPeerInfo(
        val id: String,
        val userId: String,
        val serviceId: String,
        val isDataSessionSupported: Boolean
    )

    data class PeerListUpdateEvent(
        override val id: String,
        val added: List<InitialPeerInfo>,
        val removed: List<String>,
        val totalPeersCount: Int,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.PEER_LIST_UPDATE
    ) : ConferenceEvent

    data class NetworkUnavailableEvent(
        override val id: String,
        val willDisconnectSec: Int,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.NETWORK_UNAVAILABLE,
    ) : ConferenceEvent

    data class NetworkReavailableEvent(
        override val id: String,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.NETWORK_REAVAILABLE,
    ) : ConferenceEvent

    data class PeerHoldEventData(
        val peer: String,
        val reason: String?
    )

    data class PeersHoldEvent(
        override val id: String,
        val peers: List<PeerHoldEventData>,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.PEERS_HOLD,
    ) : ConferenceEvent

    data class PeersUnholdEvent(
        override val id: String,
        val peers: List<String>,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.PEERS_UNHOLD,
    ) : ConferenceEvent

    data class MyAudioMuteRequestedByPeerEvent(
        override val id: String,
        val peer: String,
        val mute: Boolean,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.MY_AUDIO_MUTE_REQUESTED_BY_PEER,
    ) : ConferenceEvent

    data class PeersMicMuteEvent(
        override val id: String,
        val peers: List<String>,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.PEERS_MIC_MUTE,
    ) : ConferenceEvent

    data class PeersMicUnmuteEvent(
        override val id: String,
        val peers: List<String>,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.PEERS_MIC_UNMUTE,
    ) : ConferenceEvent

    data class SharedContentsEventData(
        val peer: String,
        val data: String,
        val elapsedMillis: Long
    )

    data class PeersSharedContentsSetEvent(
        override val id: String,
        val contents: List<SharedContentsEventData>,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.PEERS_SHARED_CONTENTS_SET,
    ) : ConferenceEvent

    data class PeersSharedContentsUnsetEvent(
        override val id: String,
        val peers: List<String>,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.PEERS_SHARED_CONTENTS_UNSET,
    ) : ConferenceEvent

    data class PeerExclusivelySharedContentsSetEvent(
        override val id: String,
        val peer: String,
        val data: String,
        val elapsedMillis: Long,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.PEER_EXCLUSIVELY_SHARED_CONTENTS_SET,
    ) : ConferenceEvent

    data class PeerExclusivelySharedContentsUnsetEvent(
        override val id: String,
        val peer: String,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.PEER_EXCLUSIVELY_SHARED_CONTENTS_UNSET,
    ) : ConferenceEvent

    data class PeerRoomSharedContentsSetEvent(
        override val id: String,
        val userId: String,
        val serviceId: String,
        val data: String,
        val elapsedMillis: Long,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.PEER_ROOM_SHARED_CONTENTS_SET,
    ) : ConferenceEvent

    data class PeerRoomSharedContentsUnsetEvent(
        override val id: String,
        val userId: String,
        val serviceId: String,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.PEER_ROOM_SHARED_CONTENTS_UNSET,
    ) : ConferenceEvent

    data class ShortDataReceivedEvent(
        override val id: String,
        val userId: String,
        val serviceId: String,
        val dataType: String,
        val data: String,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.SHORT_DATA_RECEIVED,
    ) : ConferenceEvent

    data class DataSessionIncomingEvent(
        override val id: String,
        val streamId: Int,
        val dataSessionType: Int,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.DATA_SESSION_INCOMING,
    ) : ConferenceEvent

    data class DataSessionInboundReceivedEvent(
        override val id: String,
        val streamId: Int,
        val userId: String,
        val serviceId: String,
        val data: String,
        val timestamp: Long,
        val offset: Long,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.DATA_SESSION_INBOUND_RECEIVED,
    ) : ConferenceEvent

    data class DataSessionInboundClosedEvent(
        override val id: String,
        val streamId: Int,
        val closedReason: Int,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.DATA_SESSION_INBOUND_CLOSED,
    ) : ConferenceEvent

    data class DataSessionOutboundClosedEvent(
        override val id: String,
        val streamId: Int,
        val closedReason: Int,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.DATA_SESSION_OUTBOUND_CLOSED,
    ) : ConferenceEvent

    data class DataSessionOutboundTooLongQueuedDataEvent(
        override val id: String,
        val streamId: Int,
        val enabled: Boolean,

        override val type: EventType = EventType.CONFERENCE,
        override val subType: ConferenceEventType = ConferenceEventType.DATA_SESSION_OUTBOUND_TOO_LONG_QUEUED_DATA,
    ) : ConferenceEvent
}