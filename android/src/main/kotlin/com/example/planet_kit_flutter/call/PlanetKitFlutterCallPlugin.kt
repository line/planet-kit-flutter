package com.example.planet_kit_flutter.call

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.util.Log
import com.example.planet_kit_flutter.screenshare.PlanetKitScreenShareService
import com.example.planet_kit_flutter.PlanetKitFlutterDataSessionTypes
import com.example.planet_kit_flutter.PlanetKitFlutterMyMediaStatusPlugin
import com.example.planet_kit_flutter.SingleResult
import com.example.planet_kit_flutter.PlanetKitFlutterNativeInstances
import com.example.planet_kit_flutter.PlanetKitFlutterStreamHandler
import com.example.planet_kit_flutter.videoView.PlanetKitFlutterVideoViews
import com.google.gson.Gson
import com.linecorp.planetkit.PlanetKitVideoPauseReason
import com.linecorp.planetkit.audio.PlanetKitAudioDescription
import com.linecorp.planetkit.session.PlanetKitDisconnectedParam
import com.linecorp.planetkit.session.PlanetKitMediaDisableReason
import com.linecorp.planetkit.session.PlanetKitMyMediaStatusListener
import com.linecorp.planetkit.session.PlanetKitShortData
import com.linecorp.planetkit.session.PlanetKitUser
import com.linecorp.planetkit.session.call.AcceptCallListener
import com.linecorp.planetkit.session.call.MakeCallListener
import com.linecorp.planetkit.session.call.PlanetKitCall
import com.linecorp.planetkit.session.call.PlanetKitCallConnectedParam
import com.linecorp.planetkit.session.call.PlanetKitCallStartMessage
import com.linecorp.planetkit.session.call.VerifyListener
import com.linecorp.planetkit.session.data.InboundDataSessionListener
import com.linecorp.planetkit.session.data.OutboundDataSessionListener
import com.linecorp.planetkit.session.data.PlanetKitDataSessionClosedReason
import com.linecorp.planetkit.session.data.PlanetKitDataSessionFailReason
import com.linecorp.planetkit.session.data.PlanetKitDataSessionType
import com.linecorp.planetkit.session.data.PlanetKitInboundDataSession
import com.linecorp.planetkit.session.data.PlanetKitOutboundDataSession
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer
import java.util.concurrent.ConcurrentHashMap

/**
 * Handles call-related functionality.
 * 
 * For background-verified calls, this plugin instance is registered with the global
 * VerifyListener broadcaster to receive events until acceptCall() re-registers this
 * instance directly. Regular makeCall() and verifyCall() use this instance directly
 * without the broadcaster.
 */
class PlanetKitFlutterCallPlugin(
    eventStreamHandler: PlanetKitFlutterStreamHandler,
    backgroundEventStreamHandler: PlanetKitFlutterStreamHandler,
    nativeInstances: PlanetKitFlutterNativeInstances,
    gson: Gson
) : MakeCallListener, AcceptCallListener, VerifyListener {
    
    private val eventStreamHandler = eventStreamHandler
    private val backgroundEventStreamHandler = backgroundEventStreamHandler
    private val nativeInstances = nativeInstances
    private val gson = gson
    private val myMediaStatusListeners = HashMap<String, PlanetKitMyMediaStatusListener>()
    private var pendingScreenShareResult: MethodChannel.Result? = null
    private var pendingScreenShareInstanceId: String? = null

    // Retains data session listeners and native session objects per "callId:streamId" so
    // they stay referenced for the lifetime of the session (mirrors per-call state retention).
    private val outboundDataSessionListeners = ConcurrentHashMap<String, OutboundDataSessionListener>()
    private val inboundDataSessionListeners = ConcurrentHashMap<String, InboundDataSessionListener>()
    // The SDK's PlanetKitInboundDataSession does not expose its type, so we record the
    // type reported by onDataSessionIncoming to answer getInboundDataSession.
    private val inboundDataSessionTypes = ConcurrentHashMap<String, Int>()

    private fun dataSessionKey(callId: String, streamId: Int): String = "$callId:$streamId"

    companion object {
        val MEDIA_PROJECTION_REQUEST_CODE get() = com.example.planet_kit_flutter.screenshare.PlanetKitScreenShareService.MEDIA_PROJECTION_REQUEST_CODE
    }

    init {
        PlanetKitFlutterVerifyListenerBroadcaster.instance.registerListener(this)
        Log.d("FlutterPlugin", "PlanetKitFlutterCallPlugin registered with broadcaster: ${this.hashCode()}")
    }

    fun dispose() {
        PlanetKitFlutterVerifyListenerBroadcaster.instance.unregisterListener(this)
        Log.d("FlutterPlugin", "PlanetKitFlutterCallPlugin unregistered from broadcaster: ${this.hashCode()}")
    }

    override fun onConnected(call: PlanetKitCall, param: PlanetKitCallConnectedParam) {
        Log.d("FlutterPlugin", "onConnected")

        Handler(Looper.getMainLooper()).post {

            val eventData = ConnectedCallEvent(
                call.hashCode().toString(),
                param.isInResponderPreparation,
                param.shouldFinishPreparation,
                param.isDataSessionSupported
            );

            val json = gson.toJson(eventData);
            eventStreamHandler.eventSink?.success(json);
        }
    }

    override fun onVerified(
        call: PlanetKitCall,
        peerStartMessage: PlanetKitCallStartMessage?,
        peerUseResponderPreparation: Boolean
    ) {
        Log.d("FlutterPlugin", "onVerified")

        Handler(Looper.getMainLooper()).post {

            val eventData = VerifiedCallEvent(
                call.hashCode().toString(),
                peerUseResponderPreparation
            );

            val json = gson.toJson(eventData);
            val callId = call.hashCode().toString()
            if (PlanetKitFlutterBackgroundCalls.instance.contains(callId)) {
                backgroundEventStreamHandler.eventSink?.success(json)
            } else {
                eventStreamHandler.eventSink?.success(json)
            }
        }
    }

    override fun onWaitConnected(call: PlanetKitCall) {
        Log.d("FlutterPlugin", "onWaitConnected")

        Handler(Looper.getMainLooper()).post {

            val eventData = WaitConnectCallEvent(
                call.hashCode().toString()
            );

            val json = gson.toJson(eventData);
            eventStreamHandler.eventSink?.success(json);
        }
    }

    override fun onPeerMicMuted(call: PlanetKitCall) {
        Log.d("FlutterPlugin", "onPeerMicMuted ")

        Handler(Looper.getMainLooper()).post {

            val eventData = PeerMicMutedCallEvent(
                call.hashCode().toString()
            );

            val json = gson.toJson(eventData);
            eventStreamHandler.eventSink?.success(json);
        }
    }

    override fun onPeerMicUnmuted(call: PlanetKitCall) {
        Log.d("FlutterPlugin", "onPeerMicUnmuted ")

        Handler(Looper.getMainLooper()).post {

            val eventData = PeerMicUnmutedCallEvent(
                call.hashCode().toString()
            );

            val json = gson.toJson(eventData);
            eventStreamHandler.eventSink?.success(json);
        }
    }

    override fun onDisconnected(call: PlanetKitCall, param: PlanetKitDisconnectedParam) {
        Log.d("FlutterPlugin", "onDisconnected ")

        Handler(Looper.getMainLooper()).post {
            myMediaStatusListeners.remove(call.hashCode().toString())

            call.getMyMediaStatus()?.let { myMediaStatus ->
                nativeInstances.remove(myMediaStatus.hashCode().toString())
            }

            // Release any data session state for this call. The SDK fires
            // onClosed(sessionEnd) per session on teardown, but clear here too so
            // sessions still mid-make (or get-created with no listener) cannot
            // leak across successive calls in a long-lived app.
            val dataSessionPrefix = "${call.hashCode()}:"
            outboundDataSessionListeners.keys.removeAll { it.startsWith(dataSessionPrefix) }
            inboundDataSessionListeners.keys.removeAll { it.startsWith(dataSessionPrefix) }
            inboundDataSessionTypes.keys.removeAll { it.startsWith(dataSessionPrefix) }

            val eventData = DisconnectedCallEvent(
                call.hashCode().toString(),
                param.reason,
                param.source,
                param.userCode,
                param.byRemote
            );

            val json = gson.toJson(eventData);
            val callId = call.hashCode().toString()
            // route to the background sink while the call is still
            // registered, but do NOT remove it here. onDisconnected is broadcast
            // to every engine's plugin instance; removing mid-broadcast makes the
            // first listener evict the call so the remaining engine(s) — including
            // the background isolate that owns the handler — misroute and drop the
            // event. The broadcaster removes the entry once, after all listeners
            // have been notified.
            if (PlanetKitFlutterBackgroundCalls.instance.contains(callId)) {
                backgroundEventStreamHandler.eventSink?.success(json)
            } else {
                eventStreamHandler.eventSink?.success(json)
            }
        }
    }

    override fun onPreparationFinished(call: PlanetKitCall) {
        Log.d("FlutterPlugin", "onPreparationFinished ")
        Handler(Looper.getMainLooper()).post {
            val eventData = PreparationFinishedCallEvent(
                call.hashCode().toString()
            );

            val json = gson.toJson(eventData);
            eventStreamHandler.eventSink?.success(json);
        }
    }

    // Background call management
    fun addBackgroundCall(call: PlanetKitCall) {
        PlanetKitFlutterBackgroundCalls.instance.add(call)
    }

    fun adoptBackgroundCall(callId: String, nativeInstances: PlanetKitFlutterNativeInstances): Boolean {
        val call = PlanetKitFlutterBackgroundCalls.instance.remove(callId)
        return if (call != null) {
            nativeInstances.add(callId, call)
            Handler(Looper.getMainLooper()).post {
                val eventData = AdoptBackgroundCallEvent(callId)
                val json = gson.toJson(eventData)
                backgroundEventStreamHandler.eventSink?.success(json)
            }
            true
        } else {
            false
        }
    }

    override fun onPeerHold(call: PlanetKitCall, reason: String?) {
        Log.d("FlutterPlugin", "onPeerOnHold ")
        Handler(Looper.getMainLooper()).post {
            val eventData = PeerHoldCallEvent(
                call.hashCode().toString(),
                reason
            );

            val json = gson.toJson(eventData);
            eventStreamHandler.eventSink?.success(json);
        }
    }

    override fun onPeerUnhold(call: PlanetKitCall) {
        Log.d("FlutterPlugin", "onPeerUnhold ")
        Handler(Looper.getMainLooper()).post {
            val eventData = PeerUnholdCallEvent(
                call.hashCode().toString()
            );

            val json = gson.toJson(eventData);
            eventStreamHandler.eventSink?.success(json);
        }
    }

    override fun onMuteMyAudioRequestedByPeer(call: PlanetKitCall, isMute: Boolean) {
        Log.d("FlutterPlugin", "onMuteMyAudioRequestedByPeer ")
        Handler(Looper.getMainLooper()).post {
            val eventData = MuteMyAudioRequestedByPeerCallEvent(
                call.hashCode().toString(),
                isMute
            );

            val json = gson.toJson(eventData);
            eventStreamHandler.eventSink?.success(json);
        }
    }

    override fun onPeerVideoPaused(call: PlanetKitCall, reason: PlanetKitVideoPauseReason) {
        Log.d("FlutterPlugin", "onPeerVideoPaused ")
        Handler(Looper.getMainLooper()).post {
            val eventData = PeerVideoDidPauseCallEvent(
                call.hashCode().toString(),
                reason
            );

            val json = gson.toJson(eventData);
            eventStreamHandler.eventSink?.success(json);
        }
    }

    override fun onPeerVideoResumed(call: PlanetKitCall) {
        Log.d("FlutterPlugin", "onPeerVideoResumed ")
        Handler(Looper.getMainLooper()).post {
            val eventData = PeerVideoDidResumeCallEvent(
                call.hashCode().toString(),
            );

            val json = gson.toJson(eventData);
            eventStreamHandler.eventSink?.success(json);
        }
    }

    override fun onVideoEnabledByPeer(call: PlanetKitCall) {
        Log.d("FlutterPlugin", "onVideoEnabledByPeer ")
        Handler(Looper.getMainLooper()).post {
            val eventData = VideoEnabledByPeerCallEvent(
                call.hashCode().toString(),
            );

            val json = gson.toJson(eventData);
            eventStreamHandler.eventSink?.success(json);
        }
    }

    override fun onVideoDisabledByPeer(call: PlanetKitCall, reason: PlanetKitMediaDisableReason) {
        Log.d("FlutterPlugin", "onVideoDisabledByPeer ")
        Handler(Looper.getMainLooper()).post {
            val eventData = VideoDisabledByPeerCallEvent(
                call.hashCode().toString(),
                reason
            );

            val json = gson.toJson(eventData);
            eventStreamHandler.eventSink?.success(json);
        }
    }

    override fun onPeerScreenShareStarted(call: PlanetKitCall) {
        Log.d("FlutterPlugin", "onPeerScreenShareStarted ")
        Handler(Looper.getMainLooper()).post {
            val eventData = PeerDidStartScreenShareCallEvent(
                call.hashCode().toString(),
            );

            val json = gson.toJson(eventData);
            eventStreamHandler.eventSink?.success(json);
        }
    }

    override fun onPeerScreenShareStopped(call: PlanetKitCall, hasReason: Boolean, reason: Int) {
        Log.d("FlutterPlugin", "onPeerScreenShareStopped ")
        Handler(Looper.getMainLooper()).post {
            val eventData = PeerDidStopScreenShareCallEvent(
                call.hashCode().toString(),
            );

            val json = gson.toJson(eventData);
            eventStreamHandler.eventSink?.success(json);
        }
    }

    override fun onPeerAudioDescriptionUpdated(
        call: PlanetKitCall,
        audioDescription: PlanetKitAudioDescription
    ) {
        Handler(Looper.getMainLooper()).post {
            val eventData = PeerAudioDescriptionCallEvent(
                call.hashCode().toString(),
                audioDescription.averageVolumeLevel
            );

            val json = gson.toJson(eventData);
            eventStreamHandler.eventSink?.success(json);
        }
    }

    override fun onPeerSharedContentsSet(call: PlanetKitCall, data: ByteArray, elapsed: Long) {
        Log.d("FlutterPlugin", "onPeerSharedContentsSet ")
        Handler(Looper.getMainLooper()).post {
            // `elapsed` is milliseconds on PlanetKit Android; forwarded as-is to
            // the Dart `elapsedMillis` field (iOS converts its seconds value to ms).
            val eventData = PeerSharedContentsSetCallEvent(
                call.hashCode().toString(),
                Base64.encodeToString(data, Base64.NO_WRAP),
                elapsed
            );

            val json = gson.toJson(eventData);
            eventStreamHandler.eventSink?.success(json);
        }
    }

    override fun onPeerSharedContentsUnset(call: PlanetKitCall) {
        Log.d("FlutterPlugin", "onPeerSharedContentsUnset ")
        Handler(Looper.getMainLooper()).post {
            val eventData = PeerSharedContentsUnsetCallEvent(
                call.hashCode().toString()
            );

            val json = gson.toJson(eventData);
            eventStreamHandler.eventSink?.success(json);
        }
    }

    override fun onPeerExclusivelySharedContentsSet(call: PlanetKitCall, data: ByteArray, elapsed: Long) {
        Log.d("FlutterPlugin", "onPeerExclusivelySharedContentsSet ")
        Handler(Looper.getMainLooper()).post {
            // `elapsed` is milliseconds on PlanetKit Android; forwarded as-is to
            // the Dart `elapsedMillis` field (iOS converts its seconds value to ms).
            val eventData = PeerExclusivelySharedContentsSetCallEvent(
                call.hashCode().toString(),
                Base64.encodeToString(data, Base64.NO_WRAP),
                elapsed
            );

            val json = gson.toJson(eventData);
            eventStreamHandler.eventSink?.success(json);
        }
    }

    override fun onPeerExclusivelySharedContentsUnset(call: PlanetKitCall) {
        Log.d("FlutterPlugin", "onPeerExclusivelySharedContentsUnset ")
        Handler(Looper.getMainLooper()).post {
            val eventData = PeerExclusivelySharedContentsUnsetCallEvent(
                call.hashCode().toString()
            );

            val json = gson.toJson(eventData);
            eventStreamHandler.eventSink?.success(json);
        }
    }

    override fun onShortDataReceived(call: PlanetKitCall, shortData: PlanetKitShortData) {
        Log.d("FlutterPlugin", "onShortDataReceived ")
        Handler(Looper.getMainLooper()).post {
            val eventData = ShortDataReceivedCallEvent(
                call.hashCode().toString(),
                shortData.type ?: "",
                Base64.encodeToString(shortData.data, Base64.NO_WRAP)
            )

            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }

    override fun onDataSessionIncoming(
        call: PlanetKitCall,
        streamId: Int,
        type: PlanetKitDataSessionType
    ) {
        Log.d("FlutterPlugin", "onDataSessionIncoming $streamId")
        inboundDataSessionTypes[dataSessionKey(call.hashCode().toString(), streamId)] =
            PlanetKitFlutterDataSessionTypes.typeToInt(type)
        Handler(Looper.getMainLooper()).post {
            val eventData = DataSessionIncomingCallEvent(
                call.hashCode().toString(),
                streamId,
                PlanetKitFlutterDataSessionTypes.typeToInt(type)
            )
            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }

    fun makeOutboundDataSession(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "makeOutboundDataSession")
        val args = call.arguments<Map<String, Any?>>()
        val callId = args?.get("callId") as? String
        val streamId = (args?.get("streamId") as? Number)?.toInt()
        val typeInt = (args?.get("type") as? Number)?.toInt()

        if (callId == null || streamId == null || typeInt == null) {
            Log.d("FlutterPlugin", "makeOutboundDataSession invalid arguments")
            result.success(PlanetKitFlutterDataSessionTypes.failReasonToInt(PlanetKitDataSessionFailReason.INTERNAL))
            return
        }

        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall
        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(PlanetKitFlutterDataSessionTypes.failReasonToInt(PlanetKitDataSessionFailReason.INTERNAL))
            return
        }

        val key = dataSessionKey(callId, streamId)
        val resultHolder = SingleResult(result)
        val listener = object : OutboundDataSessionListener {
            override fun onSessionMade(session: PlanetKitOutboundDataSession) {
                Log.d("FlutterPlugin", "outbound onSessionMade $streamId")
                resultHolder.success(PlanetKitFlutterDataSessionTypes.failReasonToInt(PlanetKitDataSessionFailReason.NONE))
            }

            override fun onError(reason: PlanetKitDataSessionFailReason) {
                Log.d("FlutterPlugin", "outbound onError $streamId $reason")
                outboundDataSessionListeners.remove(key)
                resultHolder.success(PlanetKitFlutterDataSessionTypes.failReasonToInt(reason))
            }

            override fun onTooLongQueueData(
                session: PlanetKitOutboundDataSession,
                enabled: Boolean
            ) {
                Handler(Looper.getMainLooper()).post {
                    val eventData = DataSessionOutboundTooLongQueuedDataCallEvent(
                        callId,
                        session.streamId,
                        enabled
                    )
                    val json = gson.toJson(eventData)
                    eventStreamHandler.eventSink?.success(json)
                }
            }

            override fun onClosed(
                session: PlanetKitOutboundDataSession,
                reason: PlanetKitDataSessionClosedReason
            ) {
                Log.d("FlutterPlugin", "outbound onClosed ${session.streamId} $reason")
                outboundDataSessionListeners.remove(key)
                Handler(Looper.getMainLooper()).post {
                    val eventData = DataSessionOutboundClosedCallEvent(
                        callId,
                        session.streamId,
                        PlanetKitFlutterDataSessionTypes.closedReasonToInt(reason)
                    )
                    val json = gson.toJson(eventData)
                    eventStreamHandler.eventSink?.success(json)
                }
            }
        }

        outboundDataSessionListeners[key] = listener
        planetKitCall.makeOutboundDataSession(
            streamId,
            PlanetKitFlutterDataSessionTypes.typeFromInt(typeInt),
            listener
        )
    }

    fun makeInboundDataSession(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "makeInboundDataSession")
        val args = call.arguments<Map<String, Any?>>()
        val callId = args?.get("callId") as? String
        val streamId = (args?.get("streamId") as? Number)?.toInt()

        if (callId == null || streamId == null) {
            Log.d("FlutterPlugin", "makeInboundDataSession invalid arguments")
            result.success(PlanetKitFlutterDataSessionTypes.failReasonToInt(PlanetKitDataSessionFailReason.INTERNAL))
            return
        }

        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall
        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(PlanetKitFlutterDataSessionTypes.failReasonToInt(PlanetKitDataSessionFailReason.INTERNAL))
            return
        }

        val key = dataSessionKey(callId, streamId)
        val resultHolder = SingleResult(result)
        val listener = object : InboundDataSessionListener {
            override fun onSessionMade(session: PlanetKitInboundDataSession) {
                Log.d("FlutterPlugin", "inbound onSessionMade $streamId")
                resultHolder.success(PlanetKitFlutterDataSessionTypes.failReasonToInt(PlanetKitDataSessionFailReason.NONE))
            }

            override fun onError(reason: PlanetKitDataSessionFailReason) {
                Log.d("FlutterPlugin", "inbound onError $streamId $reason")
                inboundDataSessionListeners.remove(key)
                inboundDataSessionTypes.remove(key)
                resultHolder.success(PlanetKitFlutterDataSessionTypes.failReasonToInt(reason))
            }

            override fun onDataReceived(
                session: PlanetKitInboundDataSession,
                peer: PlanetKitUser,
                data: ByteBuffer,
                timestamp: Long,
                offset: Long
            ) {
                val bytes = ByteArray(data.remaining())
                data.get(bytes)
                Handler(Looper.getMainLooper()).post {
                    val eventData = DataSessionInboundReceivedCallEvent(
                        callId,
                        session.streamId,
                        peer.userId,
                        peer.serviceId,
                        Base64.encodeToString(bytes, Base64.NO_WRAP),
                        timestamp,
                        offset
                    )
                    val json = gson.toJson(eventData)
                    eventStreamHandler.eventSink?.success(json)
                }
            }

            override fun onClosed(
                session: PlanetKitInboundDataSession,
                reason: PlanetKitDataSessionClosedReason
            ) {
                Log.d("FlutterPlugin", "inbound onClosed ${session.streamId} $reason")
                inboundDataSessionListeners.remove(key)
                inboundDataSessionTypes.remove(key)
                Handler(Looper.getMainLooper()).post {
                    val eventData = DataSessionInboundClosedCallEvent(
                        callId,
                        session.streamId,
                        PlanetKitFlutterDataSessionTypes.closedReasonToInt(reason)
                    )
                    val json = gson.toJson(eventData)
                    eventStreamHandler.eventSink?.success(json)
                }
            }
        }

        inboundDataSessionListeners[key] = listener
        planetKitCall.makeInboundDataSession(streamId, listener)
    }

    fun unsupportInboundDataSession(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "unsupportInboundDataSession")
        val args = call.arguments<Map<String, Any?>>()
        val callId = args?.get("callId") as? String
        val streamId = (args?.get("streamId") as? Number)?.toInt()

        if (callId == null || streamId == null) {
            Log.d("FlutterPlugin", "unsupportInboundDataSession invalid arguments")
            result.success(false)
            return
        }

        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall
        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        val key = dataSessionKey(callId, streamId)
        inboundDataSessionListeners.remove(key)
        inboundDataSessionTypes.remove(key)
        result.success(planetKitCall.unsupportInboundDataSession(streamId))
    }

    fun getOutboundDataSession(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "getOutboundDataSession")
        val args = call.arguments<Map<String, Any?>>()
        val callId = args?.get("callId") as? String
        val streamId = (args?.get("streamId") as? Number)?.toInt()

        if (callId == null || streamId == null) {
            Log.d("FlutterPlugin", "getOutboundDataSession invalid arguments")
            result.success(null)
            return
        }

        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall
        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(null)
            return
        }

        val session = planetKitCall.getOutboundDataSession(streamId)
        if (session == null) {
            result.success(null)
            return
        }
        result.success(PlanetKitFlutterDataSessionTypes.typeToInt(session.type))
    }

    fun getInboundDataSession(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "getInboundDataSession")
        val args = call.arguments<Map<String, Any?>>()
        val callId = args?.get("callId") as? String
        val streamId = (args?.get("streamId") as? Number)?.toInt()

        if (callId == null || streamId == null) {
            Log.d("FlutterPlugin", "getInboundDataSession invalid arguments")
            result.success(null)
            return
        }

        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall
        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(null)
            return
        }

        val session = planetKitCall.getInboundDataSession(streamId)
        if (session == null) {
            result.success(null)
            return
        }
        // PlanetKitInboundDataSession does not expose its type; fall back to the type
        // recorded from onDataSessionIncoming for this stream.
        result.success(inboundDataSessionTypes[dataSessionKey(callId, streamId)])
    }

    fun dataSessionSend(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "dataSessionSend")
        val args = call.arguments<Map<String, Any?>>()
        val callId = args?.get("callId") as? String
        val streamId = (args?.get("streamId") as? Number)?.toInt()
        val data = args?.get("data") as? ByteArray
        val timestamp = (args?.get("timestamp") as? Number)?.toLong()

        if (callId == null || streamId == null || data == null || timestamp == null) {
            Log.d("FlutterPlugin", "dataSessionSend invalid arguments")
            result.success(false)
            return
        }

        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall
        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        val session = planetKitCall.getOutboundDataSession(streamId)
        if (session == null) {
            Log.d("FlutterPlugin", "failed to find the outbound data session for $streamId")
            result.success(false)
            return
        }

        result.success(session.send(ByteBuffer.wrap(data), timestamp))
    }

    fun dataSessionChangeDestination(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "dataSessionChangeDestination")
        val args = call.arguments<Map<String, Any?>>()
        val callId = args?.get("callId") as? String
        val streamId = (args?.get("streamId") as? Number)?.toInt()
        val peerUserId = args?.get("peerUserId") as? String
        val peerServiceId = args?.get("peerServiceId") as? String

        if (callId == null || streamId == null) {
            Log.d("FlutterPlugin", "dataSessionChangeDestination invalid arguments")
            result.success(false)
            return
        }

        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall
        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        val session = planetKitCall.getOutboundDataSession(streamId)
        if (session == null) {
            Log.d("FlutterPlugin", "failed to find the outbound data session for $streamId")
            result.success(false)
            return
        }

        val peer = if (peerUserId != null && peerServiceId != null) {
            PlanetKitUser(peerUserId, peerServiceId)
        } else {
            null
        }

        val ret = session.changeDestination(peer, null) { res ->
            if (!res.isSuccessful) {
                Log.d("FlutterPlugin", "dataSessionChangeDestination failed")
            }
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "dataSessionChangeDestination platform api returned $ret")
            result.success(false)
        }
    }

    fun sendShortData(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "sendShortData")

        val args = call.arguments<Map<String, Any?>>()
        if (args == null) {
            Log.d("FlutterPlugin", "sendShortData invalid arguments")
            result.success(false)
            return
        }

        val callId = args["callId"] as? String
        val type = args["type"] as? String
        val data = args["data"] as? ByteArray

        if (callId == null || type == null || data == null) {
            Log.d("FlutterPlugin", "sendShortData invalid arguments")
            result.success(false)
            return
        }

        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        val ret = planetKitCall.sendShortData(type, data, null) { res ->
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "sendShortData returned false")
            result.success(false)
        }
    }

    fun acceptCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "acceptCall ${call.arguments}")

        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, CallParams.AcceptCallParam::class.java)
        val planetKitCall = nativeInstances.get(param.callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for ${param.callId}")
            result.success(false)
            return
        }

        planetKitCall.acceptCall(
            this as AcceptCallListener,
            useResponderPreparation = param.useResponderPreparation,
            recordOnCloud = false,
            initialMyVideoState = param.initialMyVideoState
        )

        result.success(true)
    }

    fun endCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "endCall ${call.arguments}")

        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, CallParams.EndCallParam::class.java)
        val planetKitCall = nativeInstances.get(param.callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for ${param.callId}")
            result.success(false)
            return
        }

        if (param.userReleasePhrase != null) {
            planetKitCall.endCall(param.userReleasePhrase)
        } else {
            planetKitCall.endCall()
        }
        result.success(true)
    }

    fun endCallWithError(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "endCall ${call.arguments}")

        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, CallParams.EndCallWithErrorParam::class.java)
        val planetKitCall = nativeInstances.get(param.callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for ${param.callId}")
            result.success(false)
            return
        }

        planetKitCall.endCallWithError(param.userReleasePhrase)

        result.success(true)
    }

    fun muteMyAudio(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "muteMyAudio ${call.arguments}")

        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, CallParams.MuteMyAudioParam::class.java)

        val planetKitCall = nativeInstances.get(param.callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $param.callId")
            result.success(false)
            return
        }

        val ret = planetKitCall.muteMyAudio(isMute = param.mute) { res ->
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "muteMyAudio(true) returned false")
            result.success(false)
        }
    }

    fun requestPeerMute(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "requestPeerMute ${call.arguments}")
        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, CallParams.RequestPeerMuteParam::class.java)

        val planetKitCall = nativeInstances.get(param.callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $param.callId")
            result.success(false)
            return
        }

        val ret = planetKitCall.requestPeerMute(isMute = param.mute) { res ->
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "requestPeerMute returned false")
            result.success(false)
        }
    }

    fun speakerOut(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "speakerOut ${call.arguments}")

        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, CallParams.SpeakerOutParam::class.java)
        val planetKitCall = nativeInstances.get(param.callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for ${param.callId}")
            result.success(false)
            return
        }

        planetKitCall.setSpeakerOn(param.speakerOut)
        result.success(true)
    }

    fun isSpeakerOut(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "isSpeakerOut ${call.arguments}")

        val callId = call.arguments<String>() as String
        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        result.success(planetKitCall.isSpeakerOn)
    }

    fun isMyAudioMuted(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "isMyAudioMuted ${call.arguments}")

        val callId = call.arguments<String>() as String
        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        result.success(planetKitCall.isMyAudioMuted)
    }

    fun isPeerAudioMuted(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "isPeerAudioMuted ${call.arguments}")

        val callId = call.arguments<String>() as String
        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        result.success(planetKitCall.isPeerAudioMuted)
    }

    fun finishPreparation(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "finishPreparation")
        val callId = call.arguments<String>() as String
        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        val ret = planetKitCall.finishPreparation()

        if (!ret) {
            Log.d("FlutterPlugin", "enableInterceptMyAudio returned false")
        }
        result.success(ret)
    }

    fun isOnHold(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "isOnHold")
        val callId = call.arguments<String>() as String
        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        result.success(planetKitCall.isOnHold)
    }

    fun holdCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "holdCall ${call.arguments}")
        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, CallParams.HoldCallParam::class.java)
        val planetKitCall = nativeInstances.get(param.callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for ${param.callId}")
            result.success(false)
            return
        }

        val ret = planetKitCall.hold(param.reason) { res ->
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "planetKitCall.hold returned false")
            result.success(false)
        }
    }

    fun unholdCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "unholdCall")
        val callId = call.arguments<String>() as String
        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }


        val ret = planetKitCall.unhold() { res ->
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "planetKitCall.unhold() returned false")
            result.success(false)
        }
    }

    fun silencePeerAudio(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "silencePeerAudio ${call.arguments}")

        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, CallParams.SilencePeerAudioParam::class.java)
        val planetKitCall = nativeInstances.get(param.callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for ${param.callId}")
            result.success(false)
            return
        }

        val ret = planetKitCall.silencePeerAudio(param.silent) { res ->
            Log.d("FlutterPlugin", "planetKitCall.silencePeerAudio() result ${res.isSuccessful}")
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "planetKitCall.silencePeerAudio() returned false")
            result.success(false)
        }
    }

    fun getMyMediaStatus(
        call: MethodCall,
        myMediaStatusPlugin: PlanetKitFlutterMyMediaStatusPlugin,
        result: MethodChannel.Result
    ) {
        Log.d("FlutterPlugin", "addMyMediaStatusHandler ${call.arguments}")
        val callId = call.arguments<String>() as String
        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(null)
            return
        }

        val myMediaStatus = planetKitCall.getMyMediaStatus()

        if (myMediaStatus == null) {
            Log.d("FlutterPlugin", "failed to get my media status")
            result.success(null)
            return
        }

        val myMediaStatusHandler = myMediaStatusPlugin.getMyStatusHandler(myMediaStatus)

        if (myMediaStatusHandler == null) {
            Log.d("FlutterPlugin", "failed to get my media status handler")
            result.success(null)
            return
        }

        myMediaStatus.addHandler(myMediaStatusHandler, null) { addHandlerResult ->
            if (addHandlerResult.isSuccessful) {
                nativeInstances.add(myMediaStatus.hashCode().toString(), myMediaStatus)
                myMediaStatusListeners[callId] = myMediaStatusHandler
                result.success(myMediaStatus.hashCode().toString())
            } else {
                result.success(null)
            }
        }
    }

    fun pauseMyVideo(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "pauseMyVideo ${call.arguments}")
        val callId = call.arguments<String>() as String
        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        val ret = planetKitCall.pauseMyVideo(PlanetKitVideoPauseReason.BY_USER) { res ->
            Log.d("FlutterPlugin", "planetKitCall.pauseMyVideo() result ${res.isSuccessful}")
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "planetKitCall.pauseMyVideo() returned false")
            result.success(false)
        }
    }

    fun resumeMyVideo(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "resumeMyVideo ${call.arguments}")
        val callId = call.arguments<String>() as String
        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        val ret = planetKitCall.resumeMyVideo() { res ->
            Log.d("FlutterPlugin", "planetKitCall.resumeMyVideo() result ${res.isSuccessful}")
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "planetKitCall.resumeMyVideo() returned false")
            result.success(false)
        }
    }

    fun enableVideo(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "enableVideo ${call.arguments}")
        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, CallParams.EnableVideoParam::class.java)

        val callId = param.callId
        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        val ret = planetKitCall.enableVideo(initialMyVideoState = param.initialMyVideoState) { res ->
            Log.d("FlutterPlugin", "planetKitCall.enableVideo() result ${res.isSuccessful}")
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "planetKitCall.enableVideo() returned false")
            result.success(false)
        }
    }

    fun disableVideo(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "disableVideo ${call.arguments}")

        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, CallParams.DisableVideoParam::class.java)
        val planetKitCall = nativeInstances.get(param.callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for ${param.callId}")
            result.success(false)
            return
        }

        val ret = planetKitCall.disableVideo(param.reason) { res ->
            Log.d("FlutterPlugin", "planetKitCall.disableVideo() result ${res.isSuccessful}")
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "planetKitCall.disableVideo() returned false")
            result.success(false)
        }
    }


    fun addMyVideoView(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        Log.d("FlutterPlugin", "addMyVideoView ${call.arguments}")
        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, CallParams.AddVideoViewParam::class.java)
        val planetKitCall = nativeInstances.get(param.callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for ${param.callId}")
            result.success(false)
            return
        }

        val videoView = PlanetKitFlutterVideoViews.getView(param.viewId)
        if (videoView == null) {
            Log.d("FlutterPlugin", "failed to find the view for ${param.viewId}")
            result.success(false)
            return
        }

        planetKitCall.addMyVideoView(videoView.videoView)
        PlanetKitFlutterVideoViews.retain(param.viewId)
        result.success(true)
    }

    fun removeMyVideoView(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        Log.d("FlutterPlugin", "removeMyVideoView ${call.arguments}")
        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, CallParams.RemoveVideoViewParam::class.java)
        val planetKitCall = nativeInstances.get(param.callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for ${param.callId}")
            result.success(false)
            return
        }

        val videoView = PlanetKitFlutterVideoViews.getView(param.viewId)
        if (videoView == null) {
            Log.d("FlutterPlugin", "failed to find the view for ${param.viewId}")
            result.success(false)
            return
        }

        planetKitCall.removeMyVideoView(videoView.videoView);
        PlanetKitFlutterVideoViews.release(param.viewId)
        result.success(true)
    }


    fun addPeerVideoView(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        Log.d("FlutterPlugin", "addPeerVideoView ${call.arguments}")
        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, CallParams.AddVideoViewParam::class.java)
        val planetKitCall = nativeInstances.get(param.callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for ${param.callId}")
            result.success(false)
            return
        }

        val videoView = PlanetKitFlutterVideoViews.getView(param.viewId)
        if (videoView == null) {
            Log.d("FlutterPlugin", "failed to find the view for ${param.viewId}")
            result.success(false)
            return
        }

        planetKitCall.addPeerVideoView(videoView.videoView)
        PlanetKitFlutterVideoViews.retain(param.viewId)
        result.success(true)
    }

    fun removePeerVideoView(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        Log.d("FlutterPlugin", "removePeerVideoView ${call.arguments}")
        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, CallParams.RemoveVideoViewParam::class.java)
        val planetKitCall = nativeInstances.get(param.callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for ${param.callId}")
            result.success(false)
            return
        }

        val videoView = PlanetKitFlutterVideoViews.getView(param.viewId)
        if (videoView == null) {
            Log.d("FlutterPlugin", "failed to find the view for ${param.viewId}")
            result.success(false)
            return
        }

        planetKitCall.removePeerVideoView(videoView.videoView);
        PlanetKitFlutterVideoViews.release(param.viewId)
        result.success(true)
    }


    fun addPeerScreenShareView(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        Log.d("FlutterPlugin", "addPeerScreenShareView ${call.arguments}")
        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, CallParams.AddVideoViewParam::class.java)
        val planetKitCall = nativeInstances.get(param.callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for ${param.callId}")
            result.success(false)
            return
        }

        val videoView = PlanetKitFlutterVideoViews.getView(param.viewId)
        if (videoView == null) {
            Log.d("FlutterPlugin", "failed to find the view for ${param.viewId}")
            result.success(false)
            return
        }

        planetKitCall.addPeerScreenShareView(videoView.videoView);
        PlanetKitFlutterVideoViews.retain(param.viewId)
        result.success(true)
    }

    fun removePeerScreenShareView(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        Log.d("FlutterPlugin", "removePeerScreenShareView ${call.arguments}")
        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, CallParams.RemoveVideoViewParam::class.java)
        val planetKitCall = nativeInstances.get(param.callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for ${param.callId}")
            result.success(false)
            return
        }

        val videoView = PlanetKitFlutterVideoViews.getView(param.viewId)
        if (videoView == null) {
            Log.d("FlutterPlugin", "failed to find the view for ${param.viewId}")
            result.success(false)
            return
        }

        planetKitCall.removePeerScreenShareView(videoView.videoView);
        PlanetKitFlutterVideoViews.release(param.viewId)
        result.success(true)
    }

    fun getStatistics(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        val callId = call.arguments<String>() as String
        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(null)
            return
        }

        if (planetKitCall.statistics == null) {
            result.success(null)
            return
        }

        val json = gson.toJson(planetKitCall.statistics)

        result.success(json)
    }

    fun startMyScreenShare(
        call: MethodCall,
        result: MethodChannel.Result,
        activity: Activity?
    ) {
        Log.d("FlutterPlugin", "startMyScreenShare ${call.arguments}")
        val callId = call.arguments<String>() as String
        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        if (activity == null) {
            Log.e("FlutterPlugin", "startMyScreenShare: activity is null")
            result.success(false)
            return
        }

        if (pendingScreenShareResult != null) {
            Log.e("FlutterPlugin", "startMyScreenShare: another request is pending")
            result.success(false)
            return
        }

        pendingScreenShareResult = result
        pendingScreenShareInstanceId = callId

        val projectionManager = activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        activity.startActivityForResult(projectionManager.createScreenCaptureIntent(), MEDIA_PROJECTION_REQUEST_CODE)
    }

    fun onMediaProjectionResult(resultCode: Int, data: Intent?, context: Context) {
        val result = pendingScreenShareResult
        val instanceId = pendingScreenShareInstanceId
        pendingScreenShareResult = null
        pendingScreenShareInstanceId = null

        if (result == null) return

        if (resultCode != Activity.RESULT_OK || data == null || instanceId == null) {
            result.success(false)
            return
        }

        PlanetKitScreenShareService.onStartedCallbacks[instanceId] = { success ->
            Handler(Looper.getMainLooper()).post { result.success(success) }
        }

        val intent = Intent(context, PlanetKitScreenShareService::class.java).apply {
            putExtra(PlanetKitScreenShareService.EXTRA_RESULT_CODE, resultCode)
            putExtra(PlanetKitScreenShareService.EXTRA_RESULT_DATA, data)
            putExtra(PlanetKitScreenShareService.EXTRA_INSTANCE_ID, instanceId)
            putExtra(PlanetKitScreenShareService.EXTRA_IS_CONFERENCE, false)
        }
        try {
            context.startForegroundService(intent)
        } catch (e: Exception) {
            Log.e("FlutterPlugin", "startMyScreenShare: failed to start foreground service", e)
            PlanetKitScreenShareService.onStartedCallbacks.remove(instanceId)
            result.success(false)
        }
    }

    fun stopMyScreenShare(
        call: MethodCall,
        result: MethodChannel.Result,
        context: Context
    ) {
        Log.d("FlutterPlugin", "stopMyScreenShare ${call.arguments}")

        // Cancel any consent still in flight so an accept after stop cannot start capture.
        cancelPendingScreenShare()

        val callId = call.arguments<String>() as String
        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        planetKitCall.stopMyScreenShare()
        context.stopService(Intent(context, PlanetKitScreenShareService::class.java))
        result.success(true)
    }

    fun setSharedContents(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "setSharedContents")
        val args = call.arguments<Map<String, Any>>()
        val callId = args?.get("callId") as? String
        val data = args?.get("data") as? ByteArray

        if (callId == null || data == null) {
            Log.d("FlutterPlugin", "setSharedContents invalid arguments")
            result.success(false)
            return
        }

        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall
        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        val ret = planetKitCall.setSharedContents(data, null) { res ->
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "planetKitCall.setSharedContents() returned false")
            result.success(false)
        }
    }

    fun unsetSharedContents(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "unsetSharedContents")
        val callId = call.arguments<String>() as String
        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        val ret = planetKitCall.unsetSharedContents(null) { res ->
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "planetKitCall.unsetSharedContents() returned false")
            result.success(false)
        }
    }

    fun setExclusivelySharedContents(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "setExclusivelySharedContents")
        val args = call.arguments<Map<String, Any>>()
        val callId = args?.get("callId") as? String
        val data = args?.get("data") as? ByteArray

        if (callId == null || data == null) {
            Log.d("FlutterPlugin", "setExclusivelySharedContents invalid arguments")
            result.success(false)
            return
        }

        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall
        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        val ret = planetKitCall.setExclusivelySharedContents(data, null) { res ->
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "planetKitCall.setExclusivelySharedContents() returned false")
            result.success(false)
        }
    }

    fun unsetExclusivelySharedContents(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "unsetExclusivelySharedContents")
        val callId = call.arguments<String>() as String
        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        val ret = planetKitCall.unsetExclusivelySharedContents(null) { res ->
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "planetKitCall.unsetExclusivelySharedContents() returned false")
            result.success(false)
        }
    }

    fun cancelPendingScreenShare() {
        pendingScreenShareResult?.success(false)
        pendingScreenShareResult = null
        pendingScreenShareInstanceId = null
    }
}