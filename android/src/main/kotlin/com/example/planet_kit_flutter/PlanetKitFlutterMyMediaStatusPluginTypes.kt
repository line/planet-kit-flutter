package com.example.planet_kit_flutter

import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.JsonPrimitive
import com.google.gson.JsonSerializationContext
import com.google.gson.JsonSerializer
import com.linecorp.planetkit.video.PlanetKitScreenShareState
import com.linecorp.planetkit.video.PlanetKitVideoStatus
import java.lang.reflect.Type

enum class MyMediaStatusEventType(val type: Int) {
    MIC_MUTE(0),
    MIC_UNMUTE(1),
    UPDATE_AUDIO_DESCRIPTION(2),
    UPDATE_VIDEO_STATUS(3),
    UPDATE_SCREEN_SHARE_STATE(4)
}

interface MyMediaStatusEvent : Event {
    val subType: MyMediaStatusEventType
}

data class MicMuteEvent(
    override val id: String,
    override val type: EventType = EventType.MY_MEDIA_STATUS,
    override val subType: MyMediaStatusEventType = MyMediaStatusEventType.MIC_MUTE
) : MyMediaStatusEvent

data class MicUnmuteEvent(
    override val id: String,
    override val type: EventType = EventType.MY_MEDIA_STATUS,
    override val subType: MyMediaStatusEventType = MyMediaStatusEventType.MIC_UNMUTE
) : MyMediaStatusEvent

data class UpdateAudioDescriptionEvent(
    override val id: String,
    val averageVolumeLevel: Int,
    override val type: EventType = EventType.MY_MEDIA_STATUS,
    override val subType: MyMediaStatusEventType = MyMediaStatusEventType.UPDATE_AUDIO_DESCRIPTION
) : MyMediaStatusEvent

data class UpdateVideoStatusEvent(
    override val id: String,
    val status: PlanetKitVideoStatus,
    override val type: EventType = EventType.MY_MEDIA_STATUS,
    override val subType: MyMediaStatusEventType = MyMediaStatusEventType.UPDATE_VIDEO_STATUS
) : MyMediaStatusEvent

data class UpdateScreenShareStateEvent(
    override val id: String,
    val state: PlanetKitScreenShareState,
    override val type: EventType = EventType.MY_MEDIA_STATUS,
    override val subType: MyMediaStatusEventType = MyMediaStatusEventType.UPDATE_SCREEN_SHARE_STATE
) : MyMediaStatusEvent

class MyMediaStatusEventTypeSerializer : JsonSerializer<MyMediaStatusEventType> {
    override fun serialize(
        src: MyMediaStatusEventType?,
        typeOfSrc: Type?,
        context: JsonSerializationContext?
    ): JsonElement {
        return JsonPrimitive(src?.type)
    }
}

class PlanetKitVideoStatusSerializer : JsonSerializer<PlanetKitVideoStatus> {
    override fun serialize(
        src: PlanetKitVideoStatus?,
        typeOfSrc: Type?,
        context: JsonSerializationContext?
    ): JsonElement {
        val jsonObject = JsonObject()
        if (src != null && context != null) {
            // TODO: change property "videoState" to match the iOS platform.
            jsonObject.add("state", context.serialize(src.videoState))
            jsonObject.add("pauseReason", context.serialize(src.pauseReason))
        }
        return jsonObject
    }
}

class PlanetKitVideoStateSerializer : JsonSerializer<PlanetKitVideoStatus.VideoState> {
    override fun serialize(
        src: PlanetKitVideoStatus.VideoState?,
        typeOfSrc: Type?,
        context: JsonSerializationContext?
    ): JsonElement {
        val code = when (src) {
            PlanetKitVideoStatus.VideoState.DISABLED -> 0
            PlanetKitVideoStatus.VideoState.ENABLED -> 1
            PlanetKitVideoStatus.VideoState.PAUSED -> 2
            null -> -1 // Default case for null values
        }
        return JsonPrimitive(code)
    }
}

class PlanetKitScreenShareStateSerializer : JsonSerializer<PlanetKitScreenShareState> {
    override fun serialize(
        src: PlanetKitScreenShareState?,
        typeOfSrc: Type?,
        context: JsonSerializationContext?
    ): JsonElement {
        val code = when (src) {
            PlanetKitScreenShareState.DISABLED -> 0
            PlanetKitScreenShareState.ENABLED -> 1
            null -> -1 // Default case for null values
        }
        return JsonPrimitive(code)
    }
}