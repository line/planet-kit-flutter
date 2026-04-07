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

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.gson.Gson
import com.linecorp.planetkit.audio.PlanetKitHookMyAudioListener
import com.linecorp.planetkit.audio.PlanetKitHookedAudio
import com.linecorp.planetkit.session.call.PlanetKitCall
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PlanetKitFlutterHookedAudioPlugin(
    hookedAudioStreamHandler: PlanetKitFlutterStreamHandler,
    nativeInstances: PlanetKitFlutterNativeInstances,
    gson: Gson
) {
    private val isInterceptedAudioEnabled = HashMap<String, Boolean>()
    private val nativeInstances = nativeInstances
    private val hookedAudioStreamHandler = hookedAudioStreamHandler
    private var gson = gson


    fun enableHookMyAudio(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "enableHookMyAudio")
        val callId = call.arguments<String>() as String
        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        val hookMyAudioListener = object : PlanetKitHookMyAudioListener {
            override fun onHooked(audioData: PlanetKitHookedAudio) {
                nativeInstances.add(audioData.hashCode().toString(), audioData)

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
                    hookedAudioStreamHandler.eventSink?.success(data)
                }
            }
        }

        val ret = planetKitCall.enableHookMyAudio(hookMyAudioListener) { res ->
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

    fun disableHookMyAudio(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "disableHookMyAudio")
        val callId = call.arguments<String>() as String
        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        val ret = planetKitCall.disableHookMyAudio() { res ->
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

    fun putHookedMyAudioBack(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "putHookedMyAudioBack")
        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, PutHookedAudioBackParam::class.java)

        val callId = param.callId
        val audioId = param.audioId
        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall
        val audio = nativeInstances.get(audioId) as? PlanetKitHookedAudio

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        if (audio == null) {
            Log.d("FlutterPlugin", "failed to find the call for $audioId")
            result.success(false)
            return
        }

        val ret = planetKitCall.putHookedMyAudioBack(audio)

        if (!ret) {
            Log.d("FlutterPlugin", "putInterceptedMyAudioBack returned false")
        }

        result.success(ret)
    }

    fun isHookMyAudioEnabled(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "isHookMyAudioEnabled")
        val callId = call.arguments<String>() as String
        val planetKitCall = nativeInstances.get(callId) as? PlanetKitCall

        if (planetKitCall == null) {
            Log.d("FlutterPlugin", "failed to find the call for $callId")
            result.success(false)
            return
        }

        if (!isInterceptedAudioEnabled.containsKey(planetKitCall.hashCode().toString())) {
            Log.d("FlutterPlugin", "failed to find the call in isInterceptedAudioEnabled")
            result.success(false)
            return
        }

        result.success(isInterceptedAudioEnabled[planetKitCall.hashCode().toString()])
    }

    fun setHookedAudioData(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "setHookedAudioData")
        val args = call.arguments as? Map<String, Any>

        val audioId = args?.get("audioId") as? String
        val dataBytes = args?.get("data") as? ByteArray

        if (audioId == null || dataBytes == null) {
            Log.d("FlutterPlugin", "failed to get parameters")
            result.success(false)
            return
        }

        val audio = nativeInstances.get(audioId) as? PlanetKitHookedAudio
        if (audio == null) {
            Log.d("FlutterPlugin", "failed to get PlanetKitInterceptedAudio instance")
            result.success(false)
            return
        }

        audio.setRawData(dataBytes)
        result.success(true)
    }
}