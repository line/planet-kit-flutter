package com.example.planet_kit_flutter.call

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.example.planet_kit_flutter.PlanetKitFlutterMyMediaStatusPlugin
import com.example.planet_kit_flutter.PlanetKitFlutterNativeInstances
import com.example.planet_kit_flutter.PlanetKitFlutterStreamHandler
import com.example.planet_kit_flutter.videoView.PlanetKitFlutterVideoViews
import com.google.gson.Gson
import com.linecorp.planetkit.PlanetKitVideoPauseReason
import com.linecorp.planetkit.audio.PlanetKitAudioDescription
import com.linecorp.planetkit.session.PlanetKitDisconnectedParam
import com.linecorp.planetkit.session.PlanetKitMediaDisableReason
import com.linecorp.planetkit.session.PlanetKitMyMediaStatusListener
import com.linecorp.planetkit.session.call.AcceptCallListener
import com.linecorp.planetkit.session.call.MakeCallListener
import com.linecorp.planetkit.session.call.PlanetKitCall
import com.linecorp.planetkit.session.call.PlanetKitCallConnectedParam
import com.linecorp.planetkit.session.call.PlanetKitCallStartMessage
import com.linecorp.planetkit.session.call.VerifyListener
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

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
    
    init {
        // Register this VerifyListener with broadcaster to receive events from background-verified calls
        // Regular calls (makeCall, verifyCall) bypass the broadcaster
        PlanetKitFlutterVerifyListenerBroadcaster.instance.registerListener(this)
        Log.d("FlutterPlugin", "PlanetKitFlutterCallPlugin registered with broadcaster: ${this.hashCode()}")
    }
    
    /**
     * Unregister from the broadcaster when this plugin is being cleaned up
     */
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
                param.shouldFinishPreparation
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

            val eventData = DisconnectedCallEvent(
                call.hashCode().toString(),
                param.reason,
                param.source,
                param.userCode,
                param.byRemote
            );

            val json = gson.toJson(eventData);
            val callId = call.hashCode().toString()
            if (PlanetKitFlutterBackgroundCalls.instance.contains(callId)) {
                backgroundEventStreamHandler.eventSink?.success(json)
                PlanetKitFlutterBackgroundCalls.instance.remove(callId)
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
}