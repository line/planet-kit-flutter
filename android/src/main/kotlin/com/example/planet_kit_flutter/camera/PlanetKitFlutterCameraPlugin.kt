package com.example.planet_kit_flutter.camera

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.example.planet_kit_flutter.Event
import com.example.planet_kit_flutter.EventType
import com.example.planet_kit_flutter.PlanetKitFlutterStreamHandler
import com.example.planet_kit_flutter.videoView.PlanetKitFlutterVideoViews
import com.google.gson.Gson
import com.google.gson.JsonElement
import com.google.gson.JsonPrimitive
import com.google.gson.JsonSerializationContext
import com.google.gson.JsonSerializer
import com.linecorp.planetkit.PlanetKit
import com.linecorp.planetkit.plugin.virtualbackground.PlanetKitPluginProviderVirtualBackground
import com.linecorp.planetkit.video.PlanetKitCameraManager
import com.linecorp.planetkit.video.PlanetKitCameraType

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.reflect.Type

enum class CameraEventType(val type: Int) {
    START(0),
    STOP(1),
    ERROR(2)
}

class CameraEventTypeSerializer : JsonSerializer<CameraEventType> {
    override fun serialize(
        src: CameraEventType?,
        typeOfSrc: Type?,
        context: JsonSerializationContext?
    ): JsonElement {
        return JsonPrimitive(src?.type)
    }
}

interface CameraEvent : Event {
    val subType: CameraEventType
}

object CameraEvents {
    data class StartEvent(
        override val id: String,

        override val type: EventType = EventType.CAMERA,
        override val subType: CameraEventType = CameraEventType.START
    ) : CameraEvent

    data class StopEvent(
        override val id: String,

        override val type: EventType = EventType.CAMERA,
        override val subType: CameraEventType = CameraEventType.STOP
    ) : CameraEvent

    data class ErrorEvent(
        override val id: String,

        override val type: EventType = EventType.CAMERA,
        override val subType: CameraEventType = CameraEventType.ERROR
    ) : CameraEvent
}

class PlanetKitFlutterCameraPlugin (
    private val context: Context,
    private val videoViews: PlanetKitFlutterVideoViews,
    private val eventStreamHandler: PlanetKitFlutterStreamHandler,
    private val gson: Gson
    ) : PlanetKitCameraManager.StateListener {
    private val bmpHeight = 1886
    private val bmpWidth = 1928


    fun addCameraTypeChangedListener() {
        PlanetKit.getCameraManager().setStateListener(this)
    }

    fun removeCameraTypeChangedListener() {
        PlanetKit.getCameraManager().setStateListener(null)
    }
    fun startPreview(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "startPreview arg:  ${call.arguments}")
        val viewId = call.arguments as String

        val view = videoViews.getView(viewId)

        if (view == null) {
            Log.e("FlutterPlugin", "startPreview failed to get view for id $viewId")
            result.success(false)
            return
        }

        val res = PlanetKit.getCameraManager().startPreview(view.videoView)
        videoViews.retain(viewId)

        Log.v("FlutterPlugin", "startPreview() result $res")
        result.success(res)
    }

    fun stopPreview(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "stopPreview arg:  ${call.arguments}")
        val viewId = call.arguments as String

        val view = videoViews.getView(viewId)
        if (view == null) {
            Log.e("FlutterPlugin", "stopPreview failed to get view for id $viewId")
            result.success(false)
            return
        }

        PlanetKit.getCameraManager().stopPreview(view.videoView)
        videoViews.release(viewId)

        result.success(true)
    }

    fun switchPosition(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "switchPosition")

        if (PlanetKit.getCameraManager().cameraType == PlanetKitCameraType.FRONT) {
            PlanetKit.getCameraManager().cameraType = PlanetKitCameraType.BACK
        } else {
            PlanetKit.getCameraManager().cameraType = PlanetKitCameraType.FRONT
        }

        result.success(true)
    }


    fun setVirtualBackgroundWithImage(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "setVirtualBackgroundWithImage  ${call.arguments}")

        val uriString = call.arguments<String>() as String
        if (uriString == null) {
            Log.e("FlutterPlugin", "setVirtualBackgroundWithImage file uri is null")
            result.success(false)
            return
        }

        val uri = Uri.parse(uriString)

        val bmp = BitmapUtil.makeBitmap(uri, context.contentResolver, bmpWidth, bmpHeight)

        if (bmp == null) {
            Log.e("FlutterPlugin", "setVirtualBackgroundWithImage failed to makeBitmap")
            result.success(false)
            return
        }

        val res = PlanetKit.getCameraManager().setVirtualBackgroundPlugin(PlanetKitPluginProviderVirtualBackground.getPlugin())
        if (!res) {
            Log.e("FlutterPlugin", "setVirtualBackgroundWithImage failed to setVirtualBackgroundPlugin")
            result.success(false)
        }
        PlanetKitPluginProviderVirtualBackground.getPlugin().setVirtualBackgroundWithImage(bmp)
        result.success(true)
    }


    fun setVirtualBackgroundWithBlur(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "setVirtualBackgroundWithBlur  ${call.arguments}")

        val blurRadius = call.arguments<String>() as Int

        val res = PlanetKit.getCameraManager().setVirtualBackgroundPlugin(PlanetKitPluginProviderVirtualBackground.getPlugin())
        if (!res) {
            Log.e("FlutterPlugin", "setVirtualBackgroundWithImage failed to setVirtualBackgroundPlugin")
            result.success(false)
        }

        PlanetKitPluginProviderVirtualBackground.getPlugin().setVirtualBackgroundWithBlur(blurRadius)
        result.success(true)
    }

    fun clearVirtualBackground(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "clearVirtualBackground  ${call.arguments}")

        val res = PlanetKit.getCameraManager().setVirtualBackgroundPlugin(PlanetKitPluginProviderVirtualBackground.getPlugin())
        if (!res) {
            Log.e("FlutterPlugin", "clearVirtualBackground failed to setVirtualBackgroundPlugin")
            result.success(false)
        }

        PlanetKitPluginProviderVirtualBackground.getPlugin().clearVirtualBackground()
        result.success(true)
    }

    override fun onError(code: Int) {
        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onError")
            val event = CameraEvents.ErrorEvent(this.hashCode().toString())
            val json = gson.toJson(event)
            eventStreamHandler.eventSink?.success(json)
        }
    }

    override fun onStart() {
        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onStart")
            val event = CameraEvents.StartEvent(this.hashCode().toString())
            val json = gson.toJson(event)
            eventStreamHandler.eventSink?.success(json)
        }
    }

    override fun onStop() {
        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onStop")
            val event = CameraEvents.StopEvent(this.hashCode().toString())
            val json = gson.toJson(event)
            eventStreamHandler.eventSink?.success(json)
        }
    }
}