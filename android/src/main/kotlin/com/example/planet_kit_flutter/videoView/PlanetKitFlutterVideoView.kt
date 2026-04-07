package com.example.planet_kit_flutter.videoView

import android.content.Context
import android.util.Log
import android.view.View
import com.linecorp.planetkit.ui.PlanetKitVideoView
import com.linecorp.planetkit.ui.PlanetKitViewScaleType
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class PlanetKitFlutterVideoViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        Log.d("FlutterPlugin", "create: $viewId $args")
        val creationParams = args as? Map<String, Any>
        val scaleType = creationParams?.get("scaleType") as? String
        val view = PlanetKitFlutterVideoView(context, viewId, scaleType)
        PlanetKitFlutterVideoViews.register(viewId.toString(), view)
        return view
    }
}

class PlanetKitFlutterVideoView(context: Context, viewId: Int, scaleType: String?) : PlatformView {
    private val id: String = viewId.toString()
    val videoView: PlanetKitVideoView = PlanetKitVideoView(context)

    init {
        applyScaleType(scaleType)
    }

    override fun getView(): View {
        return videoView
    }

    override fun dispose() {
        Log.d("FlutterPlugin", "dispose video view")
        PlanetKitFlutterVideoViews.release(id)
    }

    private fun applyScaleType(scaleType: String?) {
        when (scaleType) {
            "centerCrop" -> videoView.scaleType = PlanetKitViewScaleType.CenterCrop
            "fitCenter" -> videoView.scaleType = PlanetKitViewScaleType.FitCenter
            else -> videoView.scaleType =
                PlanetKitViewScaleType.FitCenter // Default to fitCenter if unknown
        }
    }
}