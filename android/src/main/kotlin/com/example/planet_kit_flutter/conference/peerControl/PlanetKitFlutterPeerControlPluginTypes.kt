package com.example.planet_kit_flutter.conference.peerControl

import com.example.planet_kit_flutter.Event
import com.example.planet_kit_flutter.EventType
import com.google.gson.JsonElement
import com.google.gson.JsonPrimitive
import com.google.gson.JsonSerializationContext
import com.google.gson.JsonSerializer
import com.linecorp.planetkit.PlanetKitVideoResolution
import com.linecorp.planetkit.video.PlanetKitScreenShareState
import com.linecorp.planetkit.video.PlanetKitVideoStatus
import java.lang.reflect.Type


enum class PeerControlEventType(val type: Int) {
    MIC_MUTE(0),
    MIC_UNMUTE(1),
    HOLD(2),
    UNHOLD(3),
    DISCONNECT(4),
    UPDATE_AUDIO_DESCRIPTION(5),
    UPDATE_VIDEO(6),
    UPDATE_SCREEN_SHARE(7);
}

class PeerControlEventTypeSerializer : JsonSerializer<PeerControlEventType> {
    override fun serialize(
        src: PeerControlEventType?,
        typeOfSrc: Type?,
        context: JsonSerializationContext?
    ): JsonElement {
        return JsonPrimitive(src?.type)
    }
}

interface PeerControlEvent : Event {
    val subType: PeerControlEventType
}

object PeerControlEvents {
    data class MicMuteEvent(
        override val id: String,

        override val type: EventType = EventType.PEER_CONTROL,
        override val subType: PeerControlEventType = PeerControlEventType.MIC_MUTE
    ) : PeerControlEvent

    data class MicUnmuteEvent(
        override val id: String,

        override val type: EventType = EventType.PEER_CONTROL,
        override val subType: PeerControlEventType = PeerControlEventType.MIC_UNMUTE
    ) : PeerControlEvent

    data class HoldEvent(
        override val id: String,
        val reason: String?,

        override val type: EventType = EventType.PEER_CONTROL,
        override val subType: PeerControlEventType = PeerControlEventType.HOLD,
    ) : PeerControlEvent

    data class UnholdEvent(
        override val id: String,

        override val type: EventType = EventType.PEER_CONTROL,
        override val subType: PeerControlEventType = PeerControlEventType.UNHOLD
    ) : PeerControlEvent

    data class DisconnectEvent(
        override val id: String,

        override val type: EventType = EventType.PEER_CONTROL,
        override val subType: PeerControlEventType = PeerControlEventType.DISCONNECT
    ) : PeerControlEvent

    data class UpdateAudioDescriptionEvent(
        override val id: String,
        val averageVolumeLevel: Int,

        override val type: EventType = EventType.PEER_CONTROL,
        override val subType: PeerControlEventType = PeerControlEventType.UPDATE_AUDIO_DESCRIPTION,
    ) : PeerControlEvent

    data class UpdateVideoEvent(
        override val id: String,
        val status: PlanetKitVideoStatus,

        override val type: EventType = EventType.PEER_CONTROL,
        override val subType: PeerControlEventType = PeerControlEventType.UPDATE_VIDEO,
    ) : PeerControlEvent

    data class UpdateScreenShareEvent(
        override val id: String,
        val state: PlanetKitScreenShareState,

        override val type: EventType = EventType.PEER_CONTROL,
        override val subType: PeerControlEventType = PeerControlEventType.UPDATE_SCREEN_SHARE,
    ) : PeerControlEvent
}

object PeerControlParams {
    data class StartVideoParam(
        val id: String,
        val viewId: String,
        val maxResolution: PlanetKitVideoResolution
    )

    data class StopVideoParam(
        val id: String,
        val viewId: String
    )

    data class StartScreenShareParam(
        val id: String,
        val viewId: String
    )

    data class StopScreenShareParam(
        val id: String,
        val viewId: String
    )
}
