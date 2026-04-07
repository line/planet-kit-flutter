package com.example.planet_kit_flutter

import android.util.Log
import com.google.gson.Gson
import com.linecorp.planetkit.audio.PlanetKitAudioDescription
import com.linecorp.planetkit.session.PlanetKitMyMediaStatus
import com.linecorp.planetkit.session.PlanetKitMyMediaStatusListener
import com.linecorp.planetkit.video.PlanetKitScreenShareState
import com.linecorp.planetkit.video.PlanetKitVideoStatus
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel


class PlanetKitFlutterMyMediaStatusPlugin(
    eventStreamHandler: PlanetKitFlutterStreamHandler,
    nativeInstances: PlanetKitFlutterNativeInstances,
    gson: Gson
) {
    private val eventStreamHandler = eventStreamHandler
    private val nativeInstances = nativeInstances
    private val gson = gson

    fun isMyAudioMuted(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "isMyAudioMuted ${call.arguments}")

        val id = call.arguments<String>() as String
        val myMediaStatus = nativeInstances.get(id) as? PlanetKitMyMediaStatus

        if (myMediaStatus == null) {
            Log.d("FlutterPlugin", "failed to find the myMediaStatus for $id")
            result.success(false)
            return
        }

        result.success(myMediaStatus.isMyAudioMuted)
    }

    fun getMyVideoStatus(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "getMyVideoStatus ${call.arguments}")

        val id = call.arguments<String>() as String
        val myMediaStatus = nativeInstances.get(id) as? PlanetKitMyMediaStatus

        if (myMediaStatus == null) {
            Log.d("FlutterPlugin", "failed to find the myMediaStatus for $id")
            result.success(null)
            return
        }
        val jsonString = gson.toJson(myMediaStatus.myVideoStatus)

        result.success(jsonString)
    }

    fun getMyStatusHandler(myMediaStatus: PlanetKitMyMediaStatus): PlanetKitMyMediaStatusListener {
        val statusListener = object : PlanetKitMyMediaStatusListener {
            override fun onMyAudioDescriptionUpdated(audioDescription: PlanetKitAudioDescription) {
                val eventData = UpdateAudioDescriptionEvent(
                    myMediaStatus.hashCode().toString(),
                    audioDescription.averageVolumeLevel
                );

                val json = gson.toJson(eventData);
                eventStreamHandler.eventSink?.success(json);
            }

            override fun onMyAudioMuted() {
                val eventData = MicMuteEvent(
                    myMediaStatus.hashCode().toString()
                );

                val json = gson.toJson(eventData);
                eventStreamHandler.eventSink?.success(json);
            }

            override fun onMyAudioUnmuted() {
                val eventData = MicUnmuteEvent(
                    myMediaStatus.hashCode().toString()
                );

                val json = gson.toJson(eventData);
                eventStreamHandler.eventSink?.success(json);
            }

            override fun onScreenShareStateUpdated(state: PlanetKitScreenShareState) {
                val eventData = UpdateScreenShareStateEvent(
                    myMediaStatus.hashCode().toString(),
                    state
                )

                val json = gson.toJson(eventData)
                eventStreamHandler.eventSink?.success(json)
            }

            override fun onVideoStatusUpdated(videoStatus: PlanetKitVideoStatus) {
                val eventData = UpdateVideoStatusEvent(
                    myMediaStatus.hashCode().toString(),
                    videoStatus
                );

                val json = gson.toJson(eventData);
                eventStreamHandler.eventSink?.success(json);
            }
        }

        return statusListener
    }
}