package com.example.planet_kit_flutter.call

import com.example.planet_kit_flutter.Event
import com.example.planet_kit_flutter.EventType
import com.google.gson.JsonElement
import com.google.gson.JsonPrimitive
import com.google.gson.JsonSerializationContext
import com.google.gson.JsonSerializer
import com.linecorp.planetkit.PlanetKitInitialMyVideoState
import com.linecorp.planetkit.PlanetKitVideoPauseReason
import com.linecorp.planetkit.session.PlanetKitDisconnectReason
import com.linecorp.planetkit.session.PlanetKitDisconnectSource
import com.linecorp.planetkit.session.PlanetKitMediaDisableReason
import java.lang.reflect.Type

object CallParams {
    data class SpeakerOutParam(
        val callId: String,
        val speakerOut: Boolean
    )

    data class AcceptCallParam(
        val callId: String,
        val useResponderPreparation: Boolean,
        val initialMyVideoState: PlanetKitInitialMyVideoState
    )


    data class HoldCallParam(
        val callId: String,
        val reason: String?
    )

    data class MuteMyAudioParam(
        val callId: String,
        val mute: Boolean
    )

    data class RequestPeerMuteParam(
        val callId: String,
        val mute: Boolean
    )

    data class SilencePeerAudioParam(
        val callId: String,
        val silent: Boolean
    )

    data class EndCallParam(
        val callId: String,
        val userReleasePhrase: String?
    )

    data class EndCallWithErrorParam(
        val callId: String,
        val userReleasePhrase: String
    )

    data class EnableVideoParam(
        val callId: String,
        val initialMyVideoState: PlanetKitInitialMyVideoState
    )

    data class DisableVideoParam(
        val callId: String,
        val reason: PlanetKitMediaDisableReason
    )

    data class AddVideoViewParam(
        val callId: String,
        val viewId: String
    )

    data class RemoveVideoViewParam(
        val callId: String,
        val viewId: String
    )

}

enum class CallEventType(val type: Int) {
    CONNECTED(0),
    DISCONNECTED(1),
    VERIFIED(2),
    WAIT_CONNECT(3),
    PEER_MIC_MUTED(4),
    PEER_MIC_UNMUTED(5),
    NETWORK_UNAVAILABLE(6),
    NETWORK_REAVAILABLE(7),
    PREPARATION_FINISHED(8),
    PEER_HOLD(9),
    PEER_UNHOLD(10),
    MY_AUDIO_MUTE_REQUEST_BY_PEER(11),
    PEER_VIDEO_DID_PAUSE(12),
    PEER_VIDEO_DID_RESUME(13),
    VIDEO_ENABLED_BY_PEER(14),
    VIDEO_DISABLED_BY_PEER(15),
    DETECTED_MY_VIDEO_NO_SOURCE(16),
    PEER_DID_START_SCREEN_SHARE(17),
    PEER_DID_STOP_SCREEN_SHARE(18),
    PEER_AUDIO_DESCRIPTION_UPDATE(19),
    SHORT_DATA_RECEIVED(20),
    PEER_SHARED_CONTENTS_SET(21),
    PEER_SHARED_CONTENTS_UNSET(22),
    PEER_EXCLUSIVELY_SHARED_CONTENTS_SET(23),
    PEER_EXCLUSIVELY_SHARED_CONTENTS_UNSET(24),
    DATA_SESSION_INCOMING(25),
    DATA_SESSION_INBOUND_RECEIVED(26),
    DATA_SESSION_INBOUND_CLOSED(27),
    DATA_SESSION_OUTBOUND_CLOSED(28),
    DATA_SESSION_OUTBOUND_TOO_LONG_QUEUED_DATA(29),
    ADOPT_BACKGROUND_CALL(100),


    ERROR(-1); // Assuming -1 is an appropriate representation for error
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

interface CallEvent : Event {
    val subType: CallEventType
}

data class ConnectedCallEvent(
    override val id: String,
    val isInResponderPreparation: Boolean,
    val shouldFinishPreparation: Boolean,
    val isDataSessionSupported: Boolean,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.CONNECTED
) : CallEvent

data class DisconnectedCallEvent(
    override val id: String,
    val disconnectReason: PlanetKitDisconnectReason,
    val disconnectSource: PlanetKitDisconnectSource,
    val userCode: String?,
    val byRemote: Boolean,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.DISCONNECTED
) : CallEvent

data class VerifiedCallEvent(
    override val id: String,
    val peerUseResponderPreparation: Boolean,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.VERIFIED
) : CallEvent

data class WaitConnectCallEvent(
    override val id: String,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.WAIT_CONNECT
) : CallEvent

data class PreparationFinishedCallEvent(
    override val id: String,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.PREPARATION_FINISHED
) : CallEvent

data class PeerMicMutedCallEvent(
    override val id: String,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.PEER_MIC_MUTED
) : CallEvent

data class PeerMicUnmutedCallEvent(
    override val id: String,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.PEER_MIC_UNMUTED
) : CallEvent

data class NetworkUnavailableCallEvent(
    override val id: String,
    val isPeer: Boolean,
    val willDisconnectSec: Int,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.NETWORK_UNAVAILABLE,
) : CallEvent

data class NetworkReavailableCallEvent(
    override val id: String,
    val isPeer: Boolean,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.NETWORK_REAVAILABLE,
) : CallEvent

data class PeerHoldCallEvent(
    override val id: String,
    val reason: String?,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.PEER_HOLD,
) : CallEvent

data class PeerUnholdCallEvent(
    override val id: String,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.PEER_UNHOLD,
) : CallEvent

data class MuteMyAudioRequestedByPeerCallEvent(
    override val id: String,
    val mute: Boolean,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.MY_AUDIO_MUTE_REQUEST_BY_PEER,
) : CallEvent

data class PeerVideoDidPauseCallEvent(
    override val id: String,
    val reason: PlanetKitVideoPauseReason,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.PEER_VIDEO_DID_PAUSE,
) : CallEvent

data class PeerVideoDidResumeCallEvent(
    override val id: String,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.PEER_VIDEO_DID_RESUME,
) : CallEvent

data class VideoEnabledByPeerCallEvent(
    override val id: String,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.VIDEO_ENABLED_BY_PEER,
) : CallEvent

data class VideoDisabledByPeerCallEvent(
    override val id: String,
    val reason: PlanetKitMediaDisableReason,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.VIDEO_DISABLED_BY_PEER,
) : CallEvent

data class PeerDidStartScreenShareCallEvent(
    override val id: String,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.PEER_DID_START_SCREEN_SHARE,
) : CallEvent

data class PeerDidStopScreenShareCallEvent(
    override val id: String,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.PEER_DID_STOP_SCREEN_SHARE,
) : CallEvent

data class PeerAudioDescriptionCallEvent(
    override val id: String,
    val averageVolumeLevel: Int,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.PEER_AUDIO_DESCRIPTION_UPDATE,
) : CallEvent


// TODO: check if this event exists for android.
data class DetectedMyVideoNoSourceCallEvent(
    override val id: String,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.DETECTED_MY_VIDEO_NO_SOURCE,
) : CallEvent


data class AdoptBackgroundCallEvent(
    override val id: String,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.ADOPT_BACKGROUND_CALL,
) : CallEvent

data class PeerSharedContentsSetCallEvent(
    override val id: String,
    val data: String,
    val elapsedMillis: Long,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.PEER_SHARED_CONTENTS_SET,
) : CallEvent

data class PeerSharedContentsUnsetCallEvent(
    override val id: String,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.PEER_SHARED_CONTENTS_UNSET,
) : CallEvent

data class PeerExclusivelySharedContentsSetCallEvent(
    override val id: String,
    val data: String,
    val elapsedMillis: Long,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.PEER_EXCLUSIVELY_SHARED_CONTENTS_SET,
) : CallEvent

data class PeerExclusivelySharedContentsUnsetCallEvent(
    override val id: String,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.PEER_EXCLUSIVELY_SHARED_CONTENTS_UNSET,
) : CallEvent

data class ShortDataReceivedCallEvent(
    override val id: String,
    val dataType: String,
    val data: String,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.SHORT_DATA_RECEIVED,
) : CallEvent

data class DataSessionIncomingCallEvent(
    override val id: String,
    val streamId: Int,
    val dataSessionType: Int,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.DATA_SESSION_INCOMING,
) : CallEvent

data class DataSessionInboundReceivedCallEvent(
    override val id: String,
    val streamId: Int,
    val userId: String,
    val serviceId: String,
    val data: String,
    val timestamp: Long,
    val offset: Long,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.DATA_SESSION_INBOUND_RECEIVED,
) : CallEvent

data class DataSessionInboundClosedCallEvent(
    override val id: String,
    val streamId: Int,
    val closedReason: Int,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.DATA_SESSION_INBOUND_CLOSED,
) : CallEvent

data class DataSessionOutboundClosedCallEvent(
    override val id: String,
    val streamId: Int,
    val closedReason: Int,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.DATA_SESSION_OUTBOUND_CLOSED,
) : CallEvent

data class DataSessionOutboundTooLongQueuedDataCallEvent(
    override val id: String,
    val streamId: Int,
    val enabled: Boolean,
    override val type: EventType = EventType.CALL,
    override val subType: CallEventType = CallEventType.DATA_SESSION_OUTBOUND_TOO_LONG_QUEUED_DATA,
) : CallEvent
