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

package com.example.planet_kit_flutter

import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonDeserializer
import com.google.gson.JsonElement
import com.google.gson.JsonParseException
import com.google.gson.JsonPrimitive
import com.google.gson.JsonSerializationContext
import com.google.gson.JsonSerializer
import com.linecorp.planetkit.PlanetKitLogLevel
import com.linecorp.planetkit.PlanetKitLogSizeLimit
import com.linecorp.planetkit.PlanetKitStartFailReason
import com.linecorp.planetkit.session.PlanetKitDisconnectReason
import com.linecorp.planetkit.session.PlanetKitDisconnectSource

import java.lang.reflect.Type

data class LogSetting(
    var enabled: Boolean,
    var logLevel: PlanetKitLogLevel,
    var logSizeLimit: PlanetKitLogSizeLimit
)
data class InitParam(
    val logSetting: LogSetting,
    val serverUrl: String
)


class PlanetKitLogLevelDeserializer : JsonDeserializer<PlanetKitLogLevel> {
    override fun deserialize(json: JsonElement?, typeOfT: Type?, context: JsonDeserializationContext?): PlanetKitLogLevel {
        return when (json?.asInt) {
            0 -> PlanetKitLogLevel.SILENT
            4 -> PlanetKitLogLevel.SIMPLE
            5 -> PlanetKitLogLevel.DETAILED
            else -> throw JsonParseException("Unexpected value for PlanetKitLogLevel: ${json?.asInt}")
        }
    }
}

class PlanetKitLogSizeLimitDeserializer : JsonDeserializer<PlanetKitLogSizeLimit> {
    override fun deserialize(json: JsonElement?, typeOfT: Type?, context: JsonDeserializationContext?): PlanetKitLogSizeLimit {
        return when (json?.asInt) {
            0 -> PlanetKitLogSizeLimit.SMALL
            1 -> PlanetKitLogSizeLimit.MEDIUM
            2 -> PlanetKitLogSizeLimit.LARGE
            3 -> PlanetKitLogSizeLimit.UNLIMITED
            else -> throw JsonParseException("Unexpected value for PlanetKitLogSizeLimit: ${json?.asInt}")
        }
    }
}

data class PutHookedAudioBackParam(
    val callId: String,
    val audioId: String
)

data class MakeCallParam(
    val myUserId: String,
    val myServiceId: String,
    val peerUserId: String,
    val peerServiceId: String,
    val accessToken: String
)

data class CCParam(
    val id: String
)
data class VerifyCallParam(
    val myUserId: String,
    val myServiceId: String,
    val ccParam: CCParam
)

data class MakeCallResponse(
    val callId: String?,
    val failReason: PlanetKitStartFailReason
)


data class VerifyCallResponse(
    val callId: String?,
    val failReason: PlanetKitStartFailReason
)

data class SpeakerOutParam(
    val callId: String,
    val speakerOut: Boolean
)


// events

enum class EventType(val type: Int) {
    ERROR(-1),
    CALL(0);

    companion object {
        fun fromInt(value: Int) = values().firstOrNull { it.type == value } ?: ERROR
    }
}

class EventTypeSerializer : JsonSerializer<EventType> {
    override fun serialize(
        src: EventType?,
        typeOfSrc: Type?,
        context: JsonSerializationContext?
    ): JsonElement {
        return JsonPrimitive(src?.type)
    }
}

// call events
enum class CallEventType(val type: Int) {
    CONNECTED(0),
    DISCONNECTED(1),
    VERIFIED(2),
    WAIT_CONNECT(3),
    PEER_MIC_MUTED(4),
    PEER_MIC_UNMUTED(5),
    ERROR(-1); // Assuming -1 is an appropriate representation for error

    companion object {
        fun fromInt(value: Int) = values().firstOrNull { it.type == value } ?: ERROR
    }
}

class CallEventTypeSerializer : JsonSerializer<CallEventType> {
    override fun serialize(
        src: CallEventType?,
        typeOfSrc: Type?,
        context: JsonSerializationContext?
    ): JsonElement {
        return JsonPrimitive(src?.type)
    }
}

interface EventData {
    val type: EventType
    val id: String
}

interface CallEventData : EventData {
    val callEventType: CallEventType
}


data class CallConnectedEventData(
    override val id: String,
    override val type: EventType = EventType.CALL,
    override val callEventType: CallEventType = CallEventType.CONNECTED
) : CallEventData

data class CallDisconnectedEventData(
    override val id: String,
    val disconnectReason: PlanetKitDisconnectReason,
    val disconnectSource: PlanetKitDisconnectSource,
    val byRemote: Boolean,
    override val type: EventType = EventType.CALL,
    override val callEventType: CallEventType = CallEventType.DISCONNECTED
) : CallEventData

data class CallVerifiedEventData(
    override val id: String,
    override val type: EventType = EventType.CALL,
    override val callEventType: CallEventType = CallEventType.VERIFIED
) : CallEventData

data class CallWaitConnectEventData(
    override val id: String,
    override val type: EventType = EventType.CALL,
    override val callEventType: CallEventType = CallEventType.WAIT_CONNECT
) : CallEventData

data class CallPeerMicMutedEventData(
    override val id: String,
    override val type: EventType = EventType.CALL,
    override val callEventType: CallEventType = CallEventType.PEER_MIC_MUTED
) : CallEventData

data class CallPeerMicUnmutedEventData(
    override val id: String,
    override val type: EventType = EventType.CALL,
    override val callEventType: CallEventType = CallEventType.PEER_MIC_UNMUTED
) : CallEventData





// TODO: support int enum in planetkit anroid.
class PlanetKitStartFailReasonSerializer : JsonSerializer<PlanetKitStartFailReason> {
    override fun serialize(
        src: PlanetKitStartFailReason?,
        typeOfSrc: Type?,
        context: JsonSerializationContext?
    ): JsonElement {
        val code = when (src) {
            PlanetKitStartFailReason.NONE -> 0
            PlanetKitStartFailReason.INVALID_PARAM -> 1
            PlanetKitStartFailReason.ALREADY_EXIST -> 2
            PlanetKitStartFailReason.DECODE_CALL_PARAM -> 3
            PlanetKitStartFailReason.MEM_ERR -> 4
            PlanetKitStartFailReason.ID_CONFLICT -> 5
            PlanetKitStartFailReason.REUSE -> 6
            PlanetKitStartFailReason.INVALID_USER_ID -> 7
            PlanetKitStartFailReason.INVALID_SERVICE_ID -> 8
            PlanetKitStartFailReason.INVALID_API_KEY -> 9
            PlanetKitStartFailReason.INVALID_ROOM_ID -> 10
            PlanetKitStartFailReason.TOO_LONG_APP_SERVER_DATA -> 11
            PlanetKitStartFailReason.NOT_INITIALIZED -> 12
            PlanetKitStartFailReason.KIT_NO_PERMISSION_RECORD_AUDIO -> 3013
            PlanetKitStartFailReason.KIT_CALL_INIT_DATA_INVALID_SIZE -> 3014
            PlanetKitStartFailReason.KIT_MY_USER_ID_BLANK -> 3015
            PlanetKitStartFailReason.KIT_MY_SERVICE_ID_BLANK -> 3016
            PlanetKitStartFailReason.KIT_PEER_USER_ID_BLANK -> 3017
            PlanetKitStartFailReason.KIT_PEER_SERVICE_ID_BLANK -> 3018
            PlanetKitStartFailReason.KIT_INVALID_STATE_TO_MAKE_CALL -> 3019
            PlanetKitStartFailReason.KIT_CANNOT_CREATE_NEW_SESSION -> 3020
            PlanetKitStartFailReason.KIT_INVALID_STATE_TO_JOIN_CONFERENCE -> 3021
            PlanetKitStartFailReason.KIT_ROOM_ID_BLANK -> 3022
            PlanetKitStartFailReason.KIT_ROOM_SERVICE_ID_BLANK -> 3023
            PlanetKitStartFailReason.KIT_NO_PERMISSION_READ_PHONE_STATE -> 3024
            PlanetKitStartFailReason.KIT_INTERNAL_UNKNOWN_EXCEPTION_AT_VERIFY_CALL -> 3025
            PlanetKitStartFailReason.KIT_INTERNAL_JNI_ENV -> 3026
            PlanetKitStartFailReason.KIT_INTERNAL_JNI_HANDLE_NULLPTR -> 3027
            PlanetKitStartFailReason.KIT_INTERNAL_JNI_OBJ_NULLPTR -> 3028
            PlanetKitStartFailReason.KIT_INTERNAL_JNI_CLASS_NULLPTR -> 3029
            PlanetKitStartFailReason.KIT_INTERNAL_UNDEFINED -> 3030
            null -> 3030 // Handle null case if necessary
        }
        return JsonPrimitive(code)
    }
}

class PlanetKitDisconnectSourceSerializer : JsonSerializer<PlanetKitDisconnectSource> {
    override fun serialize(
        src: PlanetKitDisconnectSource?,
        typeOfSrc: Type?,
        context: JsonSerializationContext?
    ): JsonElement {
        val nSource = when (src) {
            PlanetKitDisconnectSource.UNDEFINED -> 0
            PlanetKitDisconnectSource.CALLEE -> 1
            PlanetKitDisconnectSource.CALLER -> 2
            PlanetKitDisconnectSource.PARTICIPANT -> 3
            PlanetKitDisconnectSource.CLOUD_SERVER -> 4
            PlanetKitDisconnectSource.APP_SERVER -> 5
            else -> -1 // or any default value for unknown cases
        }
        return JsonPrimitive(nSource)
    }
}


class PlanetKitDisconnectReasonSerializer : JsonSerializer<PlanetKitDisconnectReason> {
    override fun serialize(
        src: PlanetKitDisconnectReason?,
        typeOfSrc: Type?,
        context: JsonSerializationContext?
    ): JsonElement {
        val reasonCode = when (src) {
            PlanetKitDisconnectReason.NORMAL -> 1001
            PlanetKitDisconnectReason.DECLINE -> 1002
            PlanetKitDisconnectReason.CELL_CALL -> 1003
            PlanetKitDisconnectReason.INTERNAL_ERROR -> 1109
            PlanetKitDisconnectReason.USER_ERROR -> 1110
            PlanetKitDisconnectReason.INTERNAL_KIT_ERROR -> 1111
            PlanetKitDisconnectReason.AUDIO_TX_NO_SRC -> 1112 // Assuming AUDIO_TX_NO_SRC maps to micNoSource
            PlanetKitDisconnectReason.CANCEL -> 1201
            PlanetKitDisconnectReason.BUSY -> 1202
            PlanetKitDisconnectReason.NO_ANSWER -> 1203
            PlanetKitDisconnectReason.ALREADY_GOT_A_CALL -> 1204
            PlanetKitDisconnectReason.MULTIDEV_IN_USE -> 1205 // Assuming MULTIDEV_IN_USE maps to multiDeviceInUse
            PlanetKitDisconnectReason.MULTIDEV_ANSWER -> 1206 // Assuming MULTIDEV_ANSWER maps to multiDeviceAnswer
            PlanetKitDisconnectReason.MULTIDEV_DECLINE -> 1207 // Assuming MULTIDEV_DECLINE maps to multiDeviceDecline
            PlanetKitDisconnectReason.NETWORK_UNSTABLE -> 1301
            PlanetKitDisconnectReason.PUSH_ERROR -> 1302
            PlanetKitDisconnectReason.AUTH_ERROR -> 1303
            PlanetKitDisconnectReason.RELEASED_CALL -> 1304
            PlanetKitDisconnectReason.SERVER_INTERNAL_ERROR -> 1305
            PlanetKitDisconnectReason.UNAVAILABLE_NETWORK -> 1308
            PlanetKitDisconnectReason.APP_DESTROY -> 1309
            PlanetKitDisconnectReason.SYSTEM_SLEEP -> 1310
            PlanetKitDisconnectReason.SYSTEM_LOGOFF -> 1311
            PlanetKitDisconnectReason.MTU_EXCEEDED -> 1312
            PlanetKitDisconnectReason.APP_SERVER_DATA_ERROR -> 1313
            PlanetKitDisconnectReason.ROOM_IS_FULL -> 1401
            PlanetKitDisconnectReason.ALONE_KICK_OUT -> 1402
            PlanetKitDisconnectReason.REASON_ROOM_NOT_FOUND -> 1404 // Assuming REASON_ROOM_NOT_FOUND maps to roomNotFound
            PlanetKitDisconnectReason.ANOTHER_INSTANCE_TRY_TO_JOIN -> 1405
            PlanetKitDisconnectReason.SERVICE_ACCESS_TOKEN_ERROR -> 1501
            PlanetKitDisconnectReason.SERVICE_INVALID_ID -> 1502 // Assuming SERVICE_INVALID_ID maps to serviceInvalidID
            PlanetKitDisconnectReason.SERVICE_MAINTENANCE -> 1503
            PlanetKitDisconnectReason.SERVICE_BUSY -> 1504
            PlanetKitDisconnectReason.SERVICE_INTERNAL_ERROR -> 1505
            PlanetKitDisconnectReason.SERVICE_HTTP_ERROR -> 1506
            PlanetKitDisconnectReason.SERVICE_HTTP_CONNECTION_TIME_OUT -> 1507
            PlanetKitDisconnectReason.SERVICE_HTTP_INVALID_PEER_CERT -> 1508
            PlanetKitDisconnectReason.SERVICE_HTTP_CONNECT_FAIL -> 1509
            PlanetKitDisconnectReason.SERVICE_HTTP_INVALID_URL -> 1510
            PlanetKitDisconnectReason.SERVICE_INCOMPATIBLE_PLANETKIT_VER -> 1511
            else -> -1 // Handle null or unknown cases
        }
        return JsonPrimitive(reasonCode)
    }
}