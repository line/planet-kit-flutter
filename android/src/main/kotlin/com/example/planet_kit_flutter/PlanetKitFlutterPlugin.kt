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

/** PlanetKitFlutterPlugin */
package com.example.planet_kit_flutter


import android.content.Context
import android.net.Uri
import android.util.Log
import com.example.planet_kit_flutter.call.CallEventType
import com.example.planet_kit_flutter.call.CallEventTypeSerializer
import com.example.planet_kit_flutter.call.NetworkReavailableCallEvent
import com.example.planet_kit_flutter.call.NetworkUnavailableCallEvent
import com.example.planet_kit_flutter.call.PlanetKitFlutterCallPlugin
import com.example.planet_kit_flutter.call.PlanetKitFlutterVerifyListenerBroadcaster
import com.example.planet_kit_flutter.camera.CameraEventType
import com.example.planet_kit_flutter.camera.CameraEventTypeSerializer
import com.example.planet_kit_flutter.camera.PlanetKitFlutterCameraPlugin
import com.example.planet_kit_flutter.conference.ConferenceEventType
import com.example.planet_kit_flutter.conference.ConferenceEventTypeSerializer
import com.example.planet_kit_flutter.conference.ConferenceParams
import com.example.planet_kit_flutter.conference.JoinConferenceResponse
import com.example.planet_kit_flutter.conference.PlanetKitFlutterConferencePeerPlugin
import com.example.planet_kit_flutter.conference.PlanetKitFlutterConferencePlugin
import com.example.planet_kit_flutter.conference.peerControl.PeerControlEventType
import com.example.planet_kit_flutter.conference.peerControl.PeerControlEventTypeSerializer
import com.example.planet_kit_flutter.conference.peerControl.PlanetKitFlutterPeerControlPlugin
import com.example.planet_kit_flutter.statistics.MyAudioSerializer
import com.example.planet_kit_flutter.statistics.MyScreenShareSerializer
import com.example.planet_kit_flutter.statistics.MyVideoSerializer
import com.example.planet_kit_flutter.statistics.NetworkSerializer
import com.example.planet_kit_flutter.statistics.PeerAudioSerializer
import com.example.planet_kit_flutter.statistics.PeerScreenShareSerializer
import com.example.planet_kit_flutter.statistics.PeerVideoSerializer
import com.example.planet_kit_flutter.statistics.PlanetKitStatisticsSerializer
import com.example.planet_kit_flutter.statistics.VideoSerializer
import com.example.planet_kit_flutter.videoView.PlanetKitFlutterVideoViewFactory
import com.example.planet_kit_flutter.videoView.PlanetKitFlutterVideoViews
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.linecorp.planetkit.PlanetKit
import com.linecorp.planetkit.PlanetKitInitialMyVideoState
import com.linecorp.planetkit.PlanetKitLogLevel
import com.linecorp.planetkit.PlanetKitLogSizeLimit
import com.linecorp.planetkit.PlanetKitMediaType
import com.linecorp.planetkit.PlanetKitResponseOnEnableVideo
import com.linecorp.planetkit.PlanetKitStartFailReason
import com.linecorp.planetkit.PlanetKitStatistics
import com.linecorp.planetkit.PlanetKitVideoPauseReason
import com.linecorp.planetkit.PlanetKitVideoResolution
import com.linecorp.planetkit.session.PlanetKitDisconnectReason
import com.linecorp.planetkit.session.PlanetKitDisconnectSource
import com.linecorp.planetkit.session.PlanetKitMediaDisableReason
import com.linecorp.planetkit.session.call.NetworkListener
import com.linecorp.planetkit.session.call.PlanetKitCCParam
import com.linecorp.planetkit.session.call.PlanetKitCall
import com.linecorp.planetkit.session.call.PlanetKitMakeCallParam
import com.linecorp.planetkit.session.call.PlanetKitVerifyCallParam
import com.linecorp.planetkit.session.call.VerifyListener
import com.linecorp.planetkit.session.conference.PlanetKitConference
import com.linecorp.planetkit.session.conference.PlanetKitConferenceParam
import com.linecorp.planetkit.video.PlanetKitScreenShareState
import com.linecorp.planetkit.video.PlanetKitVideoStatus
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.lang.ref.WeakReference


class PlanetKitFlutterPlugin : FlutterPlugin, MethodCallHandler {
    val planetKitFlutterVersion = "1.1.0"
    private lateinit var channel: MethodChannel
    private var flutterPluginBindingRef: WeakReference<FlutterPluginBinding>? = null
    private var gson: Gson
    private var flutterAssets: FlutterPlugin.FlutterAssets? = null

    private val nativeInstances = PlanetKitFlutterNativeInstances()
    private var callPlugin: PlanetKitFlutterCallPlugin
    private var hookedAudioPlugin: PlanetKitFlutterHookedAudioPlugin
    private var myMediaStatusPlugin: PlanetKitFlutterMyMediaStatusPlugin
    private var conferencePlugin: PlanetKitFlutterConferencePlugin
    private var conferencePeerPlugin: PlanetKitFlutterConferencePeerPlugin
    private var peerControlPlugin: PlanetKitFlutterPeerControlPlugin
    private lateinit var cameraPlugin: PlanetKitFlutterCameraPlugin
    private var videoViews = PlanetKitFlutterVideoViews
    val eventStreamHandler = PlanetKitFlutterStreamHandler()
    val hookedAudioStreamHandler = PlanetKitFlutterStreamHandler()
    val backgroundEventStreamHandler = PlanetKitFlutterStreamHandler()

    // TODO: remove after SDK update

    init {
        gson = GsonBuilder()
            .registerTypeAdapter(EventType::class.java, EventTypeSerializer())
            .registerTypeAdapter(CallEventType::class.java, CallEventTypeSerializer())
            .registerTypeAdapter(ConferenceEventType::class.java, ConferenceEventTypeSerializer())
            .registerTypeAdapter(PeerControlEventType::class.java, PeerControlEventTypeSerializer())
            .registerTypeAdapter(CameraEventType::class.java, CameraEventTypeSerializer())
            .registerTypeAdapter(
                MyMediaStatusEventType::class.java,
                MyMediaStatusEventTypeSerializer()
            )
            .registerTypeAdapter(PlanetKitLogLevel::class.java, PlanetKitLogLevelDeserializer())
            .registerTypeAdapter(
                PlanetKitLogSizeLimit::class.java,
                PlanetKitLogSizeLimitDeserializer()
            )
            .registerTypeAdapter(
                PlanetKitStartFailReason::class.java,
                PlanetKitStartFailReasonSerializer()
            )
            .registerTypeAdapter(
                PlanetKitDisconnectSource::class.java,
                PlanetKitDisconnectSourceSerializer()
            )
            .registerTypeAdapter(
                PlanetKitDisconnectReason::class.java,
                PlanetKitDisconnectReasonSerializer()
            )
            .registerTypeAdapter(
                PlanetKitMediaType.PLANET_MEDIA_TYPE_UNKNOWN::class.java,
                PlanetKitMediaTypeAdapter()
            )
            .registerTypeAdapter(
                PlanetKitMediaType.AUDIO::class.java,
                PlanetKitMediaTypeAdapter()
            )
            .registerTypeAdapter(
                PlanetKitMediaType.VIDEO::class.java,
                PlanetKitMediaTypeAdapter()
            )
            .registerTypeAdapter(
                PlanetKitMediaType.AUDIOVIDEO::class.java,
                PlanetKitMediaTypeAdapter()
            )
            .registerTypeAdapter(
                PlanetKitMediaType::class.java,
                PlanetKitMediaTypeAdapter()
            )
            .registerTypeAdapter(
                PlanetKitMediaDisableReason::class.java,
                PlanetKitMediaDisableReasonSerializer()
            )
            .registerTypeAdapter(
                PlanetKitVideoPauseReason::class.java,
                PlanetKitVideoPauseReasonSerializer()
            )
            .registerTypeAdapter(
                PlanetKitVideoStatus::class.java,
                PlanetKitVideoStatusSerializer()
            )
            .registerTypeAdapter(
                PlanetKitVideoStatus.VideoState::class.java,
                PlanetKitVideoStateSerializer()
            )
            .registerTypeAdapter(
                PlanetKitResponseOnEnableVideo::class.java,
                PlanetKitResponseOnEnableVideoDeserializer()
            )
            .registerTypeAdapter(
                PlanetKitVideoResolution::class.java,
                PlanetKitVideoResolutionDeserializer()
            )
            .registerTypeAdapter(PlanetKitStatistics::class.java, PlanetKitStatisticsSerializer())
            .registerTypeAdapter(PlanetKitStatistics.MyAudio::class.java, MyAudioSerializer())
            .registerTypeAdapter(PlanetKitStatistics.Network::class.java, NetworkSerializer())
            .registerTypeAdapter(PlanetKitStatistics.MyVideo::class.java, MyVideoSerializer())
            .registerTypeAdapter(PlanetKitStatistics.PeerAudio::class.java, PeerAudioSerializer())
            .registerTypeAdapter(PlanetKitStatistics.PeerVideo::class.java, PeerVideoSerializer())
            .registerTypeAdapter(PlanetKitStatistics.Video::class.java, VideoSerializer())
            .registerTypeAdapter(PlanetKitStatistics.MyScreenShare::class.java, MyScreenShareSerializer())
            .registerTypeAdapter(PlanetKitStatistics.PeerScreenShare::class.java, PeerScreenShareSerializer())
            .registerTypeAdapter(
                PlanetKitScreenShareState::class.java,
                PlanetKitScreenShareStateSerializer()
            )
            .registerTypeAdapter(PlanetKitInitialMyVideoState::class.java, PlanetKitInitialMyVideoStateAdapter())
            .create()
        callPlugin = PlanetKitFlutterCallPlugin(eventStreamHandler, backgroundEventStreamHandler, nativeInstances, gson)
        hookedAudioPlugin =
            PlanetKitFlutterHookedAudioPlugin(hookedAudioStreamHandler, nativeInstances, gson)
        myMediaStatusPlugin =
            PlanetKitFlutterMyMediaStatusPlugin(eventStreamHandler, nativeInstances, gson)
        conferencePlugin =
            PlanetKitFlutterConferencePlugin(eventStreamHandler, nativeInstances, gson)
        conferencePeerPlugin = PlanetKitFlutterConferencePeerPlugin(nativeInstances, gson)
        peerControlPlugin =
            PlanetKitFlutterPeerControlPlugin(eventStreamHandler, nativeInstances, gson)
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "planetkit_sdk")
        flutterAssets = flutterPluginBinding.flutterAssets
        channel.setMethodCallHandler(this)
        flutterPluginBindingRef = WeakReference(flutterPluginBinding)

        val context = flutterPluginBinding.applicationContext

        cameraPlugin = PlanetKitFlutterCameraPlugin(context, videoViews, eventStreamHandler, gson)

        flutterPluginBinding
            .platformViewRegistry
            .registerViewFactory("planet_kit_video_view", PlanetKitFlutterVideoViewFactory())

        EventChannel(flutterPluginBinding.binaryMessenger, "planetkit_event").setStreamHandler(
            eventStreamHandler
        )
        EventChannel(
            flutterPluginBinding.binaryMessenger,
            "planetkit_hooked_audio"
        ).setStreamHandler(hookedAudioStreamHandler)
        EventChannel(
            flutterPluginBinding.binaryMessenger,
            "planetkit_background_event"
        ).setStreamHandler(backgroundEventStreamHandler)
    }

    // Handle incoming method calls
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            "initializePlanetKit" -> initializePlanetKit(call, result)
            "makeCall" -> makeCall(call, result)
            "verifyCall" -> verifyCall(call, result)
            "verifyBackgroundCall" -> verifyBackgroundCall(call, result)
            "joinConference" -> joinConference(call, result)
            "releaseInstance" -> releaseInstance(call, result)
            "createCcParam" -> createCcParam(call, result)
            "setServerUrl" -> setServerUrl(call, result)
            "adoptBackgroundCall" -> adoptBackgroundCall(call, result)

            // HookedAudio
            "call_enableHookMyAudio" -> hookedAudioPlugin.enableHookMyAudio(call, result)
            "call_disableHookMyAudio" -> hookedAudioPlugin.disableHookMyAudio(call, result)
            "call_putHookedMyAudioBack" -> hookedAudioPlugin.putHookedMyAudioBack(call, result)
            "call_isHookMyAudioEnabled" -> hookedAudioPlugin.isHookMyAudioEnabled(call, result)
            "call_setHookedAudioData" -> hookedAudioPlugin.setHookedAudioData(call, result)

            // Call
            "call_acceptCall" -> callPlugin.acceptCall(call, result)
            "call_endCall" -> callPlugin.endCall(call, result)
            "call_endCallWithError" -> callPlugin.endCallWithError(call, result)
            "call_muteMyAudio" -> callPlugin.muteMyAudio(call, result)
            "call_requestPeerMute" -> callPlugin.requestPeerMute(call, result)
            "call_speakerOut" -> callPlugin.speakerOut(call, result)
            "call_isSpeakerOut" -> callPlugin.isSpeakerOut(call, result)
            "call_isMyAudioMuted" -> callPlugin.isMyAudioMuted(call, result)
            "call_isPeerAudioMuted" -> callPlugin.isPeerAudioMuted(call, result)
            "call_finishPreparation" -> callPlugin.finishPreparation(call, result)
            "call_isOnHold" -> callPlugin.isOnHold(call, result)
            "call_holdCall" -> callPlugin.holdCall(call, result)
            "call_unholdCall" -> callPlugin.unholdCall(call, result)
            "call_getMyMediaStatus" -> callPlugin.getMyMediaStatus(
                call,
                myMediaStatusPlugin,
                result
            )

            "call_silencePeerAudio" -> callPlugin.silencePeerAudio(call, result)

            "call_addMyVideoView" -> callPlugin.addMyVideoView(call, result)
            "call_removeMyVideoView" -> callPlugin.removeMyVideoView(call, result)
            "call_addPeerVideoView" -> callPlugin.addPeerVideoView(call, result)
            "call_removePeerVideoView" -> callPlugin.removePeerVideoView(call, result)
            "call_pauseMyVideo" -> callPlugin.pauseMyVideo(call, result)
            "call_resumeMyVideo" -> callPlugin.resumeMyVideo(call, result)
            "call_enableVideo" -> callPlugin.enableVideo(call, result)
            "call_disableVideo" -> callPlugin.disableVideo(call, result)
            "call_getStatistics" -> callPlugin.getStatistics(call, result)

            "call_addPeerScreenShareView" -> callPlugin.addPeerScreenShareView(call, result)
            "call_removePeerScreenShareView" -> callPlugin.removePeerScreenShareView(call, result)


            // My media status
            "myMediaStatus_isMyAudioMuted" -> myMediaStatusPlugin.isMyAudioMuted(call, result)
            "myMediaStatus_getMyVideoStatus" -> myMediaStatusPlugin.getMyVideoStatus(call, result)

            // Conference
            "conference_leaveConference" -> conferencePlugin.leaveConference(call, result)
            "conference_muteMyAudio" -> conferencePlugin.muteMyAudio(call, result)
            "conference_speakerOut" -> conferencePlugin.speakerOut(call, result)
            "conference_isSpeakerOut" -> conferencePlugin.isSpeakerOut(call, result)
            "conference_silencePeersAudio" -> conferencePlugin.silencePeersAudio(call, result)
            "conference_requestPeerMute" -> conferencePlugin.requestPeerMute(call, result)
            "conference_requestPeersMute" -> conferencePlugin.requestPeersMute(call, result)
            "conference_hold" -> conferencePlugin.hold(call, result)
            "conference_unhold" -> conferencePlugin.unhold(call, result)
            "conference_isOnHold" -> conferencePlugin.isOnHold(call, result)
            "conference_getMyMediaStatus" -> conferencePlugin.getMyMediaStatus(
                call,
                myMediaStatusPlugin,
                result
            )

            "conference_createPeerControl" -> conferencePlugin.createPeerControl(call, result)
            "conference_addMyVideoView" -> conferencePlugin.addMyVideoView(call, result)
            "conference_removeMyVideoView" -> conferencePlugin.removeMyVideoView(call, result)
            "conference_enableVideo" -> conferencePlugin.enableVideo(call, result)
            "conference_disableVideo" -> conferencePlugin.disableVideo(call, result)
            "conference_pauseMyVideo" -> conferencePlugin.pauseMyVideo(call, result)
            "conference_resumeMyVideo" -> conferencePlugin.resumeMyVideo(call, result)
            "conference_getStatistics" -> conferencePlugin.getStatistics(call, result)
            
            // Conference Peer
            "conferencePeer_getHoldStatus" -> conferencePeerPlugin.getHoldStatus(call, result)
            "conferencePeer_isMuted" -> conferencePeerPlugin.isMuted(call, result)
            "conferencePeer_getVideoStatus" -> conferencePeerPlugin.getVideoStatus(call, result)
            "conferencePeer_getScreenShareState" -> conferencePeerPlugin.getScreenShareState(call, result)

            // Peer control
            "peerControl_register" -> peerControlPlugin.register(call, result)
            "peerControl_unregister" -> peerControlPlugin.unregister(call, result)
            "peerControl_startVideo" -> peerControlPlugin.startVideo(call, result)
            "peerControl_stopVideo" -> peerControlPlugin.stopVideo(call, result)
            "peerControl_startScreenShare" -> peerControlPlugin.startScreenShare(call, result)
            "peerControl_stopScreenShare" -> peerControlPlugin.stopScreenShare(call, result)

            // Camera
            "camera_startPreview" -> cameraPlugin.startPreview(call, result)
            "camera_stopPreview" -> cameraPlugin.stopPreview(call, result)
            "camera_switchPosition" -> cameraPlugin.switchPosition(call, result)
            "camera_clearVirtualBackground" -> cameraPlugin.clearVirtualBackground(call, result)
            "camera_setVirtualBackgroundWithBlur" -> cameraPlugin.setVirtualBackgroundWithBlur(
                call,
                result
            )

            "camera_setVirtualBackgroundWithImage" -> cameraPlugin.setVirtualBackgroundWithImage(
                call,
                result
            )

            else -> result.notImplemented()
        }
    }


    private fun initializePlanetKit(call: MethodCall, result: Result) {
        Log.d("FlutterPlugin", "initializePlanetKit")

        val args = call.arguments<Map<String, Any>>()
        val applicationContext = flutterPluginBindingRef?.get()?.applicationContext

        if (applicationContext == null) {
            result.success(false);
            Log.e("FlutterPlugin", "applicationContext is null")
            return
        }

        val sharedPreferences = applicationContext?.getSharedPreferences("com.linecorp.planetkit.flutter", Context.MODE_PRIVATE)
        sharedPreferences?.edit()?.apply {
            putString("version", planetKitFlutterVersion)
            apply()
        }

        if (PlanetKit.isInitialize == true) {
            result.success(true)
            return
        }

        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, InitParam::class.java)

        val config = PlanetKit.PlanetKitConfiguration.Builder(applicationContext)
            .enableLog(param.logSetting.enabled)
            .setLogLevel(param.logSetting.logLevel)
            .setLogSizeLimit(param.logSetting.logSizeLimit)
            .setServerUrl(param.serverUrl)
            .build()
        PlanetKit.initialize(config) { isSuccessful, isVideoHwCodecSupport, userAgent ->
            Log.d(
                "FlutterPlugin", "PlanetKit initialization(isSuccessful=$isSuccessful, " +
                        "isVideoHwCodecSupport=$isVideoHwCodecSupport, userAgent=$userAgent)"
            )

            if (isSuccessful) {
                cameraPlugin.addCameraTypeChangedListener()
            }
            result.success(isSuccessful)
        }
    }

    private fun setNetworkListener(call: PlanetKitCall) {
        val networkListener = object : NetworkListener {
            override fun onNetworkReavailable(isPeer: Boolean) {
                Log.d("FlutterPlugin", "onNetworkReavailable")
                val eventData = NetworkReavailableCallEvent(
                    call.hashCode().toString(),
                    isPeer
                );
                val json = gson.toJson(eventData);
                eventStreamHandler.eventSink?.success(json);
            }

            override fun onNetworkUnavailable(isPeer: Boolean, disconnectAfterSec: Int) {
                Log.d("FlutterPlugin", "onNetworkUnavailable")
                val eventData = NetworkUnavailableCallEvent(
                    call.hashCode().toString(),
                    isPeer,
                    disconnectAfterSec,
                );
                val json = gson.toJson(eventData);
                eventStreamHandler.eventSink?.success(json);
            }
        }

        call.setNetworkListener(networkListener)
    }



    private fun makeCall(call: MethodCall, result: Result) {
        Log.d("FlutterPlugin", "makeCall")

        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, MakeCallParam::class.java)

        var makeCallParamBuilder = PlanetKitMakeCallParam.Builder()
            .myId(param.myUserId)
            .myServiceId(param.myServiceId)
            .peerId(param.peerUserId)
            .peerServiceId(param.peerServiceId)
            .accessToken(param.accessToken)
            .responderPreparation(param.useResponderPreparation)
            .setInitialMyVideoState(param.initialMyVideoState)

        param.myCountryCode?.let { myCountryCode ->
            makeCallParamBuilder = makeCallParamBuilder.myCountryCode(myCountryCode)
        }
        param.peerCountryCode?.let { peerCountryCode ->
            makeCallParamBuilder = makeCallParamBuilder.peerCountryCode(peerCountryCode)
        }

        param.holdTonePath?.let { holdTonePath ->
            flutterAssets?.getAssetFilePathByName(holdTonePath)?.let { key ->
                val uri = Uri.parse(key)
                makeCallParamBuilder = makeCallParamBuilder.holdTone(uri)
            }
        }

        param.endTonePath?.let { holdTonePath ->
            flutterAssets?.getAssetFilePathByName(holdTonePath)?.let { key ->
                val uri = Uri.parse(key)
                makeCallParamBuilder = makeCallParamBuilder.endTone(uri)
            }
        }

        param.ringbackTonePath?.let { ringbackTonePath ->
            flutterAssets?.getAssetFilePathByName(ringbackTonePath)?.let { key ->
                val uri = Uri.parse(key)
                makeCallParamBuilder = makeCallParamBuilder.ringbackTone(uri)
            }
        }

        param.allowCallWithoutMic?.let { allow ->
            makeCallParamBuilder = makeCallParamBuilder.allowCallWithoutMic(allow)
            Log.d("FlutterPlugin", "set allowCallWithoutMic $allow")
        }

        param.enableAudioDescription?.let { enable ->
            makeCallParamBuilder = makeCallParamBuilder.enableAudioDescription(enable)
            Log.d("FlutterPlugin", "set enableAudioDescription $enable")
        }

        param.audioDescriptionUpdateIntervalMs?.let { interval ->
            makeCallParamBuilder =
                makeCallParamBuilder.setAudioDescriptionInterval(interval.toLong())
            Log.d("FlutterPlugin", "set setAudioDescriptionInterval $interval")
        }

        param.allowCallWithoutMicPermission?.let { allow ->
            makeCallParamBuilder = makeCallParamBuilder.allowCallWithoutMicPermission(allow)
            Log.d("FlutterPlugin", "allowCallWithoutMicPermission $allow")
        }


        makeCallParamBuilder = makeCallParamBuilder.mediaType(param.mediaType)
        makeCallParamBuilder =
            makeCallParamBuilder.responseOnEnableVideo(param.responseOnEnableVideo)
        makeCallParamBuilder = makeCallParamBuilder.enableStatistics(param.enableStatistics)

        val makeCallParam = makeCallParamBuilder.build()

        // Regular makeCall uses the plugin instance directly (no broadcaster)
        val makeCallResult = PlanetKit.makeCall(makeCallParam, callPlugin)

        if (makeCallResult.reason == PlanetKitStartFailReason.NONE &&
            makeCallResult.call != null
        ) {
            val call = makeCallResult.call as PlanetKitCall
            nativeInstances.add(call.hashCode().toString(), call)
            setNetworkListener(call)
        }

        val response = MakeCallResponse(
            makeCallResult.call?.hashCode().toString(),
            makeCallResult.reason
        )
        val responseJson = gson.toJson(response)

        result.success(responseJson)
    }

    private fun verifyCall(call: MethodCall, result: Result) {
        Log.d("FlutterPlugin", "verifyCall ")

        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, VerifyCallParam::class.java)

        val ccParam = nativeInstances.get(param.ccParam.id) as? PlanetKitCCParam

        if (ccParam == null) {
            Log.d("FlutterPlugin", "failed to retrive ccParam instance")
            val response = VerifyCallResponse(null, PlanetKitStartFailReason.INVALID_PARAM)
            val responseJson = gson.toJson(response)
            result.success(responseJson)
            return
        }

        var verifyCallParamBuilder = PlanetKitVerifyCallParam.Builder()
            .myId(param.myUserId)
            .myServiceId(param.myServiceId)
            .cCParam(ccParam)

        param.holdTonePath?.let { holdTonePath ->
            flutterAssets?.getAssetFilePathByName(holdTonePath)?.let { key ->
                val uri = Uri.parse(key)
                verifyCallParamBuilder = verifyCallParamBuilder.holdTone(uri)
            }
        }

        param.endTonePath?.let { endTonePath ->
            flutterAssets?.getAssetFilePathByName(endTonePath)?.let { key ->
                val uri = Uri.parse(key)
                verifyCallParamBuilder = verifyCallParamBuilder.endTone(uri)
            }
        }

        param.ringtonePath?.let { ringtonePath ->
            flutterAssets?.getAssetFilePathByName(ringtonePath)?.let { key ->
                val uri = Uri.parse(key)
                verifyCallParamBuilder = verifyCallParamBuilder.ringTone(uri)
            }
        }

        param.allowCallWithoutMic?.let { allow ->
            verifyCallParamBuilder = verifyCallParamBuilder.allowCallWithoutMic(allow)
            Log.d("FlutterPlugin", "set allowCallWithoutMic $allow")
        }

        param.enableAudioDescription?.let { enable ->
            verifyCallParamBuilder = verifyCallParamBuilder.enableAudioDescription(enable)
            Log.d("FlutterPlugin", "set enableAudioDescription $enable")
        }

        param.audioDescriptionUpdateIntervalMs?.let { interval ->
            verifyCallParamBuilder =
                verifyCallParamBuilder.setAudioDescriptionInterval(interval.toLong())
            Log.d("FlutterPlugin", "set setAudioDescriptionInterval $interval")
        }

        param.allowCallWithoutMicPermission?.let { allow ->
            verifyCallParamBuilder = verifyCallParamBuilder.allowCallWithoutMicPermission(allow)
            Log.d("FlutterPlugin", "allowCallWithoutMicPermission $allow")
        }

        verifyCallParamBuilder =
            verifyCallParamBuilder.responseOnEnableVideo(param.responseOnEnableVideo)
        verifyCallParamBuilder = verifyCallParamBuilder.enableStatistics(param.enableStatistics)

        val verifyCallParam = verifyCallParamBuilder.build()

        // Regular verifyCall uses the plugin instance directly (no broadcaster)
        val verifyCallResult = PlanetKit.verifyCall(verifyCallParam, callPlugin as VerifyListener)

        if (verifyCallResult.reason == PlanetKitStartFailReason.NONE &&
            verifyCallResult.call != null
        ) {
            val call = verifyCallResult.call as PlanetKitCall
            nativeInstances.add(call.hashCode().toString(), call)
            setNetworkListener(call)
        }

        val response = VerifyCallResponse(
            verifyCallResult.call?.hashCode().toString(),
            verifyCallResult.reason
        )
        val responseJson = gson.toJson(response)

        result.success(responseJson)
    }

    private fun verifyBackgroundCall(call: MethodCall, result: Result) {
        Log.d("FlutterPlugin", "verifyBackgroundCall ")

        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, VerifyCallParam::class.java)

        val ccParam = nativeInstances.get(param.ccParam.id) as? PlanetKitCCParam

        if (ccParam == null) {
            Log.d("FlutterPlugin", "failed to retrive ccParam instance")
            val response = VerifyCallResponse(null, PlanetKitStartFailReason.INVALID_PARAM)
            val responseJson = gson.toJson(response)
            result.success(responseJson)
            return
        }

        var verifyCallParamBuilder = PlanetKitVerifyCallParam.Builder()
            .myId(param.myUserId)
            .myServiceId(param.myServiceId)
            .cCParam(ccParam)

        param.holdTonePath?.let { holdTonePath ->
            flutterAssets?.getAssetFilePathByName(holdTonePath)?.let { key ->
                val uri = Uri.parse(key)
                verifyCallParamBuilder = verifyCallParamBuilder.holdTone(uri)
            }
        }

        param.endTonePath?.let { endTonePath ->
            flutterAssets?.getAssetFilePathByName(endTonePath)?.let { key ->
                val uri = Uri.parse(key)
                verifyCallParamBuilder = verifyCallParamBuilder.endTone(uri)
            }
        }

        param.ringtonePath?.let { ringtonePath ->
            flutterAssets?.getAssetFilePathByName(ringtonePath)?.let { key ->
                val uri = Uri.parse(key)
                verifyCallParamBuilder = verifyCallParamBuilder.ringTone(uri)
            }
        }

        param.allowCallWithoutMic?.let { allow ->
            verifyCallParamBuilder = verifyCallParamBuilder.allowCallWithoutMic(allow)
            Log.d("FlutterPlugin", "set allowCallWithoutMic $allow")
        }

        param.enableAudioDescription?.let { enable ->
            verifyCallParamBuilder = verifyCallParamBuilder.enableAudioDescription(enable)
            Log.d("FlutterPlugin", "set enableAudioDescription $enable")
        }

        param.audioDescriptionUpdateIntervalMs?.let { interval ->
            verifyCallParamBuilder =
                verifyCallParamBuilder.setAudioDescriptionInterval(interval.toLong())
            Log.d("FlutterPlugin", "set setAudioDescriptionInterval $interval")
        }

        param.allowCallWithoutMicPermission?.let { allow ->
            verifyCallParamBuilder = verifyCallParamBuilder.allowCallWithoutMicPermission(allow)
            Log.d("FlutterPlugin", "allowCallWithoutMicPermission $allow")
        }

        verifyCallParamBuilder =
            verifyCallParamBuilder.responseOnEnableVideo(param.responseOnEnableVideo)
        verifyCallParamBuilder = verifyCallParamBuilder.enableStatistics(param.enableStatistics)

        val verifyCallParam = verifyCallParamBuilder.build()

        // IMPORTANT: Use the global broadcaster for background-verified calls
        // Flow: 1) Background engine: broadcaster → background plugin
        //       2) After adoptBackgroundCall(): broadcaster → foreground plugin  
        //       3) After acceptCall(): foreground plugin directly (no broadcaster)
        val verifyCallResult = PlanetKit.verifyCall(
            verifyCallParam,
            PlanetKitFlutterVerifyListenerBroadcaster.instance as VerifyListener
        )

        // Do not add to nativeInstances here; we keep it in the background pool
        verifyCallResult.call?.let { callObj ->
            callPlugin.addBackgroundCall(callObj)
        }

        val response = VerifyCallResponse(
            verifyCallResult.call?.hashCode().toString(),
            verifyCallResult.reason
        )
        val responseJson = gson.toJson(response)

        result.success(responseJson)
    }

    private fun adoptBackgroundCall(call: MethodCall, result: Result) {
        val callId = call.arguments<String>() as String
        val adopted = callPlugin.adoptBackgroundCall(callId, nativeInstances)
        result.success(adopted)
    }

    private fun joinConference(call: MethodCall, result: Result) {
        Log.d("FlutterPlugin", "joinConference ${call.arguments}")
        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, ConferenceParams.JoinConferenceParam::class.java)

        var conferenceParamBuilder = PlanetKitConferenceParam.Builder()
            .myId(param.myUserId)
            .myServiceId(param.myServiceId)
            .roomId(param.roomId)
            .roomServiceId(param.roomServiceId)
            .accessToken(param.accessToken)
            .enableStatistics(param.enableStatistics)
            .setInitialMyVideoState(param.initialMyVideoState)

        param.endTonePath?.let { endTonePath ->
            flutterAssets?.getAssetFilePathByName(endTonePath)?.let { key ->
                val uri = Uri.parse(key)
                conferenceParamBuilder = conferenceParamBuilder.endTone(uri)
            }
        }

        param.allowConferenceWithoutMic?.let { allow ->
            conferenceParamBuilder = conferenceParamBuilder.allowConferenceWithoutMic(allow)
            Log.d("FlutterPlugin", "set allowCallWithoutMic $allow")
        }

        param.enableAudioDescription?.let { enable ->
            conferenceParamBuilder = conferenceParamBuilder.enableAudioDescription(enable)
            Log.d("FlutterPlugin", "set enableAudioDescription $enable")
        }

        param.audioDescriptionUpdateIntervalMs?.let { interval ->
            conferenceParamBuilder =
                conferenceParamBuilder.setAudioDescriptionInterval(interval.toLong())
            Log.d("FlutterPlugin", "set setAudioDescriptionInterval $interval")
        }

        param.allowConferenceWithoutMicPermission?.let { allow ->
            conferenceParamBuilder = conferenceParamBuilder.allowConferenceWithoutMicPermission(allow)
            Log.d("FlutterPlugin", "allowConferenceWithoutMicPermission $allow")
        }

        conferenceParamBuilder = conferenceParamBuilder.mediaType(param.mediaType)

        val conferenceParam = conferenceParamBuilder.build()

        val joinConferenceResult = PlanetKit.joinConference(conferenceParam, conferencePlugin)

        if (joinConferenceResult.reason == PlanetKitStartFailReason.NONE &&
            joinConferenceResult.conference != null
        ) {
            val conference = joinConferenceResult.conference as PlanetKitConference
            nativeInstances.add(conference.hashCode().toString(), conference)
        }

        val response = JoinConferenceResponse(
            joinConferenceResult.conference?.hashCode().toString(),
            joinConferenceResult.reason
        )

        val responseJson = gson.toJson(response)
        result.success(responseJson)
    }


    private fun releaseInstance(call: MethodCall, result: Result) {
        Log.d("FlutterPlugin", "releaseInstance ${call.arguments}")
        val id = call.arguments<String>() as String
        nativeInstances.remove(id)
        result.success(true)
    }

    private fun createCcParam(call: MethodCall, result: Result) {
        Log.d("FlutterPlugin", "createCcParam")

        val ccParamString = call.arguments<String>() as String
        val ccParam = PlanetKitCCParam.create(ccParamString)

        if (ccParam == null) {
            result.success(null)
            return
        }

        val id = ccParam.hashCode().toString()
        nativeInstances.add(id, ccParam)

        val response = CreateCcParamResponse(
            id,
            ccParam.peerId,
            ccParam.peerServiceId,
            ccParam.mediaType
        )
        val responseJson = gson.toJson(response)

        Log.d("FlutterPlugin", "createCcParam ${responseJson}")

        result.success(responseJson)
    }

    private fun setServerUrl(call: MethodCall, result: Result) {
        Log.d("FlutterPlugin", "setServerUrl")
        val serverUrl = call.arguments<String>() as String

        PlanetKit.setServer(serverUrl)
        result.success(true)
    }


    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        flutterPluginBindingRef = null
        cameraPlugin.removeCameraTypeChangedListener()
    }
}


