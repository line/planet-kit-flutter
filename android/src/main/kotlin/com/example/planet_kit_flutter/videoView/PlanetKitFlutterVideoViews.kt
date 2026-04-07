package com.example.planet_kit_flutter.videoView

import java.lang.ref.WeakReference

object PlanetKitFlutterVideoViews {
    private val videoViews: MutableMap<String, Pair<PlanetKitFlutterVideoView, Int>> = mutableMapOf()

    fun register(id: String, view: PlanetKitFlutterVideoView) {
        synchronized(this) {
            val current = videoViews[id]
            if (current != null) {
                // If the view is already registered, increase the reference count
                videoViews[id] = current.first to current.second + 1
            } else {
                // Register the view with an initial reference count of 1
                videoViews[id] = view to 1
            }
        }
    }

    fun release(id: String) {
        synchronized(this) {
            val current = videoViews[id]
            if (current != null) {
                val (view, count) = current
                if (count > 1) {
                    // Decrease the reference count
                    videoViews[id] = view to count - 1
                } else {
                    // Remove the view if the reference count reaches zero
                    videoViews.remove(id)
                }
            }
        }
    }

    fun retain(id: String) {
        synchronized(this) {
            val current = videoViews[id]
            if (current != null) {
                // Increase the reference count
                videoViews[id] = current.first to current.second + 1
            }
        }
    }

    fun getView(id: String): PlanetKitFlutterVideoView? {
        return synchronized(this) {
            videoViews[id]?.first
        }
    }

    val views: List<PlanetKitFlutterVideoView>
        get() = synchronized(this) {
            videoViews.values.map { it.first }
        }
}