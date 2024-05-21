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

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.linecorp.planetkit.PlanetKit
import com.linecorp.planetkit.PlanetKitLogLevel
import com.linecorp.planetkit.PlanetKitLogSizeLimit
import com.linecorp.planetkit.PlanetKitStartFailReason
import com.linecorp.planetkit.audio.PlanetKitInterceptMyAudioListener
import com.linecorp.planetkit.audio.PlanetKitInterceptedAudio
import com.linecorp.planetkit.session.PlanetKitDisconnectReason
import com.linecorp.planetkit.session.PlanetKitDisconnectSource
import com.linecorp.planetkit.session.PlanetKitDisconnectedParam
import com.linecorp.planetkit.session.call.AcceptCallListener
import com.linecorp.planetkit.session.call.MakeCallListener
import com.linecorp.planetkit.session.call.PlanetKitCCParam
import com.linecorp.planetkit.session.call.PlanetKitCall
import com.linecorp.planetkit.session.call.PlanetKitCallConnectedParam
import com.linecorp.planetkit.session.call.PlanetKitCallStartMessage
import com.linecorp.planetkit.session.call.PlanetKitMakeCallParam
import com.linecorp.planetkit.session.call.PlanetKitVerifyCallParam
import com.linecorp.planetkit.session.call.VerifyListener
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.lang.ref.WeakReference

class PlanetKitFlutterPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private var flutterPluginBindingRef: WeakReference<FlutterPluginBinding>? = null
  private lateinit var gson: Gson

  private val _nativeInstances = HashMap<String, Any>()

  @Synchronized
  fun addNativeInstance(key: String, instance: Any) {
    _nativeInstances[key] = instance
  }

  @Synchronized
  fun removeNativeInstance(key: String) {
    _nativeInstances.remove(key)
  }

  @Synchronized
  fun getNativeInstance(key: String): Any? {
    return _nativeInstances[key]
  }

  val eventStreamHandler = PlanetKitFlutterStreamHandler()
  val interceptedAudioStreamHandler = PlanetKitFlutterStreamHandler()

  // TODO: remove after SDK update
  val isInterceptedAudioEnabled = HashMap<String, Boolean>()

  private val listener = object : MakeCallListener, AcceptCallListener, VerifyListener {
    override fun onConnected(call: PlanetKitCall, param: PlanetKitCallConnectedParam) {
      Log.d("FlutterPlugin", "onConnected")

      Handler(Looper.getMainLooper()).post {

        val eventData = CallConnectedEventData(
          call.hashCode().toString()
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

        val eventData = CallVerifiedEventData(
          call.hashCode().toString()
        );

        val json = gson.toJson(eventData);
        eventStreamHandler.eventSink?.success(json);
      }
    }

    override fun onWaitConnected(call: PlanetKitCall) {
      Log.d("FlutterPlugin", "onWaitConnected")

      Handler(Looper.getMainLooper()).post {

        val eventData = CallWaitConnectEventData(
          call.hashCode().toString()
        );

        val json = gson.toJson(eventData);
        eventStreamHandler.eventSink?.success(json);
      }
    }

    override fun onPeerMicMuted(call: PlanetKitCall) {
      Log.d("FlutterPlugin", "onPeerMicMuted ")

      Handler(Looper.getMainLooper()).post {

        val eventData = CallPeerMicMutedEventData(
          call.hashCode().toString()
        );

        val json = gson.toJson(eventData);
        eventStreamHandler.eventSink?.success(json);
      }
    }

    override fun onPeerMicUnmuted(call: PlanetKitCall) {
      Log.d("FlutterPlugin", "onPeerMicUnmuted ")

      Handler(Looper.getMainLooper()).post {

        val eventData = CallPeerMicUnmutedEventData(
          call.hashCode().toString()
        );

        val json = gson.toJson(eventData);
        eventStreamHandler.eventSink?.success(json);
      }
    }

    override fun onDisconnected(call: PlanetKitCall, param: PlanetKitDisconnectedParam) {
      Log.d("FlutterPlugin", "onDisconnected ")

      Handler(Looper.getMainLooper()).post {

        val eventData = CallDisconnectedEventData(
          call.hashCode().toString(),
          param.reason,
          param.source,
          param.byRemote
        );

        val json = gson.toJson(eventData);
        eventStreamHandler.eventSink?.success(json);
      }
    }
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "planetkit_sdk")
    channel.setMethodCallHandler(this)
    flutterPluginBindingRef = WeakReference(flutterPluginBinding);
    gson = GsonBuilder()
      .registerTypeAdapter(EventType::class.java, EventTypeSerializer())
      .registerTypeAdapter(CallEventType::class.java, CallEventTypeSerializer())
      .registerTypeAdapter(PlanetKitLogLevel::class.java, PlanetKitLogLevelDeserializer())
      .registerTypeAdapter(PlanetKitLogSizeLimit::class.java, PlanetKitLogSizeLimitDeserializer())
      .registerTypeAdapter(PlanetKitStartFailReason::class.java, PlanetKitStartFailReasonSerializer())
      .registerTypeAdapter(PlanetKitDisconnectSource::class.java, PlanetKitDisconnectSourceSerializer())
      .registerTypeAdapter(PlanetKitDisconnectReason::class.java, PlanetKitDisconnectReasonSerializer())
      .create()

    EventChannel(flutterPluginBinding.binaryMessenger, "planetkit_event").setStreamHandler(eventStreamHandler)
    EventChannel(flutterPluginBinding.binaryMessenger, "planetkit_intercepted_audio").setStreamHandler(interceptedAudioStreamHandler)
  }

  // Handle incoming method calls
  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
      "initializePlanetKit" -> initializePlanetKit(call, result)
      "makeCall" -> makeCall(call, result)
      "verifyCall" -> verifyCall(call, result)
      "acceptCall" -> acceptCall(call, result)
      "endCall" -> endCall(call, result)
      "muteMyAudio" -> muteMyAudio(call, result)
      "unmuteMyAudio" -> unmuteMyAudio(call, result)
      "speakerOut" -> speakerOut(call, result)
      "isSpeakerOut" -> isSpeakerOut(call, result)
      "isMyAudioMuted" -> isMyAudioMuted(call, result)
      "isPeerAudioMuted" -> isPeerAudioMuted(call, result)
      "releaseInstance" -> releaseInstance(call, result)
      "createCcParam" -> createCcParam(call, result)
      "enableInterceptMyAudio" -> enableInterceptMyAudio(call, result)
      "disableInterceptMyAudio" -> disableInterceptMyAudio(call, result)
      "putInterceptedMyAudioBack" -> putInterceptedMyAudioBack(call, result)
      "isInterceptMyAudioEnabled" -> isInterceptMyAudioEnabled(call, result)
      "setInterceptedAudioData" -> setInterceptedAudioData(call, result)

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
      result.success(isSuccessful)
    }
  }


  private fun makeCall(call: MethodCall, result: Result) {
    Log.d("FlutterPlugin", "makeCall")

    val args = call.arguments<Map<String, Any>>()
    val jsonArgs = gson.toJson(args)
    val param = gson.fromJson(jsonArgs, MakeCallParam::class.java)

    val makeCallParam = PlanetKitMakeCallParam.Builder()
      .myId(param.myUserId)
      .myServiceId(param.myServiceId)
      .peerId(param.peerUserId)
      .peerServiceId(param.peerServiceId)
      .accessToken(param.accessToken)
      .build()

    val makeCallResult = PlanetKit.makeCall(makeCallParam, listener)

    if (makeCallResult.reason == PlanetKitStartFailReason.NONE &&
      makeCallResult.call != null) {
      val call = makeCallResult.call as PlanetKitCall
      addNativeInstance(call.hashCode().toString(), call)
    }

    val response = MakeCallResponse(makeCallResult.call?.hashCode().toString(),
      makeCallResult.reason)
    val responseJson = gson.toJson(response)

    result.success(responseJson)
  }

  private fun verifyCall(call: MethodCall, result: Result) {
    Log.d("FlutterPlugin", "verifyCall ")

    val args = call.arguments<Map<String, Any>>()
    val jsonArgs = gson.toJson(args)
    val param = gson.fromJson(jsonArgs, VerifyCallParam::class.java)

    val ccParam = getNativeInstance(param.ccParam.id) as? PlanetKitCCParam

    if (ccParam == null) {
      Log.d("FlutterPlugin", "failed to retrive ccParam instance")
      val response = VerifyCallResponse(null, PlanetKitStartFailReason.INVALID_PARAM)
      val responseJson = gson.toJson(response)
      result.success(responseJson)
      return
    }

    val verifyCallParam = PlanetKitVerifyCallParam.Builder()
      .myId(param.myUserId)
      .myServiceId(param.myServiceId)
      .cCParam(ccParam)
      .build()

    val verifyCallResult = PlanetKit.verifyCall(verifyCallParam, listener as VerifyListener)

    if (verifyCallResult.reason == PlanetKitStartFailReason.NONE &&
      verifyCallResult.call != null) {
      val call = verifyCallResult.call as PlanetKitCall
      addNativeInstance(call.hashCode().toString(), call)
    }

    val response = VerifyCallResponse(verifyCallResult.call?.hashCode().toString(),
      verifyCallResult.reason)
    val responseJson = gson.toJson(response)

    result.success(responseJson)
  }

  private fun acceptCall(call: MethodCall, result: Result) {
    Log.d("FlutterPlugin", "acceptCall ${call.arguments}")

    val callId = call.arguments<String>() as String
    val planetKitCall = getNativeInstance(callId) as? PlanetKitCall

    if (planetKitCall == null) {
      Log.d("FlutterPlugin", "failed to find the call for $callId")
      result.success(false)
      return
    }

    planetKitCall.acceptCall(listener as AcceptCallListener, useResponderPreparation = false, recordOnCloud = false)

    result.success(true)
  }

  private fun endCall(call: MethodCall, result: Result) {
    Log.d("FlutterPlugin", "endCall ${call.arguments}")

    val callId = call.arguments<String>() as String
    val planetKitCall = getNativeInstance(callId) as? PlanetKitCall

    if (planetKitCall == null) {
      Log.d("FlutterPlugin", "failed to find the call for $callId")
      result.success(false)
      return
    }

    planetKitCall.endCall()
    result.success(true)
  }

  private fun muteMyAudio(call: MethodCall, result: Result) {
    Log.d("FlutterPlugin", "muteMyAudio ${call.arguments}")

    val callId = call.arguments<String>() as String
    val planetKitCall = getNativeInstance(callId) as? PlanetKitCall

    if (planetKitCall == null) {
      Log.d("FlutterPlugin", "failed to find the call for $callId")
      result.success( false)
      return
    }

    val ret = planetKitCall.muteMyAudio(isMute = true) { res ->
      result.success( res.isSuccessful)
    }

    if (!ret) {
      Log.d("FlutterPlugin", "muteMyAudio(true) returned false")
      result.success(false)
    }
  }

  private fun unmuteMyAudio(call: MethodCall, result: Result) {
    Log.d("FlutterPlugin", "unmuteMyAudio ${call.arguments}")

    val callId = call.arguments<String>() as String
    val planetKitCall = getNativeInstance(callId) as? PlanetKitCall

    if (planetKitCall == null) {
      Log.d("FlutterPlugin", "failed to find the call for $callId")
      result.success( false)
      return
    }

    val ret = planetKitCall.muteMyAudio(isMute = false) { res ->
      result.success( res.isSuccessful)
    }

    if (!ret) {
      Log.d("FlutterPlugin", "muteMyAudio(false) returned false")
      result.success(false)
    }
  }

  private fun speakerOut(call: MethodCall, result: Result) {
    Log.d("FlutterPlugin", "speakerOut ${call.arguments}")

    val args = call.arguments<Map<String, Any>>()
    val jsonArgs = gson.toJson(args)
    val param = gson.fromJson(jsonArgs, SpeakerOutParam::class.java)
    val planetKitCall = getNativeInstance(param.callId) as? PlanetKitCall

    if (planetKitCall == null) {
      Log.d("FlutterPlugin", "failed to find the call for ${param.callId}")
      result.success( false)
      return
    }

    planetKitCall.setSpeakerOn(param.speakerOut)
    result.success(true)
  }

  private fun isSpeakerOut(call: MethodCall, result: Result) {
    Log.d("FlutterPlugin", "isSpeakerOut ${call.arguments}")

    val callId = call.arguments<String>() as String
    val planetKitCall = getNativeInstance(callId) as? PlanetKitCall

    if (planetKitCall == null) {
      Log.d("FlutterPlugin", "failed to find the call for $callId")
      result.success( false)
      return
    }

    result.success(planetKitCall.isSpeakerOn)
  }

  private fun isMyAudioMuted(call: MethodCall, result: Result) {
    Log.d("FlutterPlugin", "isMyAudioMuted ${call.arguments}")

    val callId = call.arguments<String>() as String
    val planetKitCall = getNativeInstance(callId) as? PlanetKitCall

    if (planetKitCall == null) {
      Log.d("FlutterPlugin", "failed to find the call for $callId")
      result.success( false)
      return
    }

    result.success(planetKitCall.isMyAudioMuted)
  }

  private fun isPeerAudioMuted(call: MethodCall, result: Result) {
    Log.d("FlutterPlugin", "isPeerAudioMuted ${call.arguments}")

    val callId = call.arguments<String>() as String
    val planetKitCall = getNativeInstance(callId) as? PlanetKitCall

    if (planetKitCall == null) {
      Log.d("FlutterPlugin", "failed to find the call for $callId")
      result.success( false)
      return
    }

    result.success(planetKitCall.isPeerAudioMuted)
  }


  private fun releaseInstance(call: MethodCall, result: Result) {
    Log.d("FlutterPlugin", "releaseInstance ${call.arguments}")
    val id = call.arguments<String>() as String
    removeNativeInstance(id)
    result.success(true)
  }

  private fun createCcParam(call: MethodCall, result: Result) {
    Log.d("FlutterPlugin", "createCcParam")

    val ccParamString = call.arguments<String>() as String
    val ccParam = PlanetKitCCParam(ccParamString)
    val id = ccParam.hashCode().toString()
    addNativeInstance(id, ccParam)

    result.success(id)
  }

  private fun enableInterceptMyAudio(call: MethodCall, result: Result) {
    Log.d("FlutterPlugin", "enableInterceptMyAudio")
    val callId = call.arguments<String>() as String
    val planetKitCall = getNativeInstance(callId) as? PlanetKitCall

    if (planetKitCall == null) {
      Log.d("FlutterPlugin", "failed to find the call for $callId")
      result.success( false)
      return
    }

    val interceptMyAudioListener = object : PlanetKitInterceptMyAudioListener {
      override fun onIntercept(audioData: PlanetKitInterceptedAudio) {
        addNativeInstance(audioData.hashCode().toString(), audioData)

        val data = mapOf(
          "callId" to planetKitCall.hashCode().toString(),
          "audioId" to audioData.hashCode().toString(),
          "sampleRate" to audioData.sampleRate,
          "channel" to audioData.channel,
          "sampleType" to audioData.sampleType.ordinal,
          "sampleCount" to audioData.sampleCount,
          "seq" to audioData.sequenceNumber,
          "data" to audioData.getRawData()  // Assuming this is a ByteArray or similar
        )

        Handler(Looper.getMainLooper()).post {
          interceptedAudioStreamHandler.eventSink?.success(data)
        }
      }
    }

    val ret = planetKitCall.enableInterceptMyAudio(interceptMyAudioListener) { res ->
      if (res.isSuccessful) {
        // TODO: remove after SDK update
        isInterceptedAudioEnabled[planetKitCall.hashCode().toString()] = true
      }
      result.success(res.isSuccessful)
    }

    if (!ret) {
      Log.d("FlutterPlugin", "enableInterceptMyAudio returned false")
      result.success(false)
    }
  }

  private fun disableInterceptMyAudio(call: MethodCall, result: Result) {
    Log.d("FlutterPlugin", "disableInterceptMyAudio")
    val callId = call.arguments<String>() as String
    val planetKitCall = getNativeInstance(callId) as? PlanetKitCall

    if (planetKitCall == null) {
      Log.d("FlutterPlugin", "failed to find the call for $callId")
      result.success( false)
      return
    }

    val ret = planetKitCall.disableInterceptMyAudio() { res ->
      if (res.isSuccessful) {
        // TODO: remove after SDK update
        isInterceptedAudioEnabled[planetKitCall.hashCode().toString()] = false
      }
      result.success(res.isSuccessful)
    }

    if (!ret) {
      Log.d("FlutterPlugin", "enableInterceptMyAudio returned false")
      result.success(false)
    }
  }

  private fun putInterceptedMyAudioBack(call: MethodCall, result: Result) {
    Log.d("FlutterPlugin", "putInterceptedMyAudioBack")
    val args = call.arguments<Map<String, Any>>()
    val jsonArgs = gson.toJson(args)
    val param = gson.fromJson(jsonArgs, PutInterceptedAudioBackParam::class.java)

    val callId = param.callId
    val audioId = param.audioId
    val planetKitCall = getNativeInstance(callId) as? PlanetKitCall
    val audio = getNativeInstance(audioId) as? PlanetKitInterceptedAudio

    if (planetKitCall == null) {
      Log.d("FlutterPlugin", "failed to find the call for $callId")
      result.success( false)
      return
    }

    if (audio == null) {
      Log.d("FlutterPlugin", "failed to find the call for $audioId")
      result.success( false)
      return
    }

    val ret = planetKitCall.putInterceptedMyAudioBack(audio)

    if (!ret) {
      Log.d("FlutterPlugin", "putInterceptedMyAudioBack returned false")
    }

    result.success(ret)
  }

  private fun isInterceptMyAudioEnabled(call: MethodCall, result: Result) {
    Log.d("FlutterPlugin", "isInterceptMyAudioEnabled")
    val callId = call.arguments<String>() as String
    val planetKitCall = getNativeInstance(callId) as? PlanetKitCall

    if (planetKitCall == null) {
      Log.d("FlutterPlugin", "failed to find the call for $callId")
      result.success( false)
      return
    }

    if (isInterceptedAudioEnabled.containsKey(planetKitCall.hashCode().toString())) {
      Log.d("FlutterPlugin", "failed to find the call in isInterceptedAudioEnabled")
      result.success( false)
      return
    }

    result.success(isInterceptedAudioEnabled[planetKitCall.hashCode().toString()])
  }

  private fun setInterceptedAudioData(call: MethodCall, result: Result) {
    Log.d("FlutterPlugin", "setInterceptedAudioData")
    val args = call.arguments as? Map<String, Any>

    val audioId = args?.get("audioId") as? String
    val dataBytes = args?.get("data") as? ByteArray

    if (audioId == null || dataBytes == null) {
      Log.d("FlutterPlugin", "failed to get parameters")
      result.success(false)
      return
    }

    val audio = getNativeInstance(audioId) as? PlanetKitInterceptedAudio
    if (audio == null) {
      Log.d("FlutterPlugin", "failed to get PlanetKitInterceptedAudio instance")
      result.success(false)
      return
    }

    audio.setRawData(dataBytes)
    result.success(true)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    flutterPluginBindingRef = null
  }
}



