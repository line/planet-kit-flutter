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

package com.example.planet_kit_flutter.conference.peerControl

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.example.planet_kit_flutter.PlanetKitFlutterNativeInstances
import com.example.planet_kit_flutter.PlanetKitFlutterStreamHandler
import com.example.planet_kit_flutter.videoView.PlanetKitFlutterVideoViews
import com.google.gson.Gson
import com.linecorp.planetkit.PlanetKit
import com.linecorp.planetkit.audio.PlanetKitAudioDescription
import com.linecorp.planetkit.session.conference.PlanetKitPeerControl
import com.linecorp.planetkit.session.conference.subgroup.PlanetKitConferencePeer
import com.linecorp.planetkit.video.PlanetKitScreenShareState
import com.linecorp.planetkit.video.PlanetKitVideoStatus
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel


class PlanetKitFlutterPeerControlPlugin(
    private val eventStreamHandler: PlanetKitFlutterStreamHandler,
    private val nativeInstances: PlanetKitFlutterNativeInstances,
    private val gson: Gson
) {
    fun register(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "register ${call.method} ${call.arguments}")
        val id = call.arguments as String

        val peerControl = nativeInstances.get(id) as? PlanetKitPeerControl
        if (peerControl == null) {
            Log.e("FlutterPlugin", "register peer control not found $id")
            result.success(false)
            return
        }

        val ret = peerControl.register(object : PlanetKitPeerControl.PeerControlListener {
            override fun onMicMuted(peer: PlanetKitConferencePeer) {
                Handler(Looper.getMainLooper()).post {
                    Log.d("FlutterPlugin", "onMicMute")
                    val event = PeerControlEvents.MicMuteEvent(peerControl.hashCode().toString())
                    val json = gson.toJson(event)
                    eventStreamHandler.eventSink?.success(json)
                }
            }

            override fun onMicUnmuted(peer: PlanetKitConferencePeer) {
                Handler(Looper.getMainLooper()).post {
                    Log.d("FlutterPlugin", "onMicUnmuted")
                    val event = PeerControlEvents.MicUnmuteEvent(peerControl.hashCode().toString())
                    val json = gson.toJson(event)
                    eventStreamHandler.eventSink?.success(json)
                }
            }

            override fun onHold(peer: PlanetKitConferencePeer, reason: String?) {
                Handler(Looper.getMainLooper()).post {
                    Log.d("FlutterPlugin", "onHold")
                    val event =
                        PeerControlEvents.HoldEvent(peerControl.hashCode().toString(), reason)
                    val json = gson.toJson(event)
                    eventStreamHandler.eventSink?.success(json)
                }
            }

            override fun onUnhold(peer: PlanetKitConferencePeer) {
                Handler(Looper.getMainLooper()).post {
                    Log.d("FlutterPlugin", "onUnhold")
                    val event = PeerControlEvents.UnholdEvent(peerControl.hashCode().toString())
                    val json = gson.toJson(event)
                    eventStreamHandler.eventSink?.success(json)
                }
            }

            override fun onDisconnected(peer: PlanetKitConferencePeer) {
                Handler(Looper.getMainLooper()).post {
                    Log.d("FlutterPlugin", "onDisconnected")
                    val event = PeerControlEvents.DisconnectEvent(peerControl.hashCode().toString())
                    val json = gson.toJson(event)
                    eventStreamHandler.eventSink?.success(json)
                }
            }

            override fun onAudioDescriptionUpdated(
                peer: PlanetKitConferencePeer,
                audioDescription: PlanetKitAudioDescription
            ) {
                Handler(Looper.getMainLooper()).post {
                    val event = PeerControlEvents.UpdateAudioDescriptionEvent(
                        peerControl.hashCode().toString(), audioDescription.averageVolumeLevel
                    )
                    val json = gson.toJson(event)
                    eventStreamHandler.eventSink?.success(json)
                }
            }

            override fun onVideoUpdated(
                peer: PlanetKitConferencePeer,
                videoStatus: PlanetKitVideoStatus,
                subgroupName: String?
            ) {
                Handler(Looper.getMainLooper()).post {
                    Log.d("FlutterPlugin", "onVideoUpdated")
                    val event = PeerControlEvents.UpdateVideoEvent(
                        peerControl.hashCode().toString(), videoStatus
                    )
                    val json = gson.toJson(event)
                    eventStreamHandler.eventSink?.success(json)
                }
            }

            override fun onScreenShareUpdated(
                peer: PlanetKitConferencePeer,
                state: PlanetKitScreenShareState,
                subgroupName: String?
            ) {
                Handler(Looper.getMainLooper()).post {
                    Log.d("FlutterPlugin", "onScreenShareUpdated")
                    val event = PeerControlEvents.UpdateScreenShareEvent(
                        peerControl.hashCode().toString(), state
                    )
                    val json = gson.toJson(event)
                    eventStreamHandler.eventSink?.success(json)
                }
            }

        }) { res ->
            Log.d("FlutterPlugin", "register peer control result: ${res.isSuccessful}")
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "register platform api  returned false")
            result.success(false)
        }
    }

    fun unregister(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "unregister ${call.method} ${call.arguments}")
        val id = call.arguments as String

        val peerControl = nativeInstances.get(id) as? PlanetKitPeerControl
        if (peerControl == null) {
            Log.e("FlutterPlugin", "unregister peer control not found $id")
            result.success(false)
            return
        }

        val ret = peerControl.unregister { res ->
            Log.d("FlutterPlugin", "unregister peer control result: ${res.isSuccessful}")
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "unregister platform api  returned false")
            result.success(false)
        }
    }

    fun startVideo(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "startVideo ${call.method} ${call.arguments}")
        val param =
            gson.fromJson(call.arguments.toString(), PeerControlParams.StartVideoParam::class.java)

        val peerControl = nativeInstances.get(param.id) as? PlanetKitPeerControl
        if (peerControl == null) {
            Log.e("FlutterPlugin", "startVideo peer control not found ${param.id}")
            result.success(false)
            return
        }

        val ret = peerControl.startVideo(param.maxResolution)

        if (!ret) {
            Log.d("FlutterPlugin", "startVideo platform api  returned false")
            result.success(false)
            return
        }

        val videoView = PlanetKitFlutterVideoViews.getView(param.viewId)

        if (videoView == null) {
            Log.d("FlutterPlugin", "failed to find the view for ${param.viewId}")
            result.success(false)
            return
        }

        val conference = PlanetKit.getConference()

        if (conference == null) {
            Log.d("FlutterPlugin", "conference is null")
            result.success(false)
            return
        }

        conference.addPeerVideoView(peerControl.peer.user, videoView.videoView)
        PlanetKitFlutterVideoViews.retain(param.viewId)
        result.success(true)
    }

    fun stopVideo(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "stopVideo ${call.method} ${call.arguments}")
        val param =
            gson.fromJson(call.arguments.toString(), PeerControlParams.StopVideoParam::class.java)

        val peerControl = nativeInstances.get(param.id) as? PlanetKitPeerControl
        if (peerControl == null) {
            Log.e("FlutterPlugin", "stopVideo peer control not found ${param.id}")
            result.success(false)
            return
        }

        val ret = peerControl.stopVideo()

        if (!ret) {
            Log.d("FlutterPlugin", "stopVideo platform api  returned false")
            result.success(false)
            PlanetKitFlutterVideoViews.release(param.viewId)
            return
        }

        val videoView = PlanetKitFlutterVideoViews.getView(param.viewId)

        if (videoView == null) {
            Log.d("FlutterPlugin", "failed to find the view for ${param.viewId}")
            result.success(false)
            return
        }

        val conference = PlanetKit.getConference()

        if (conference == null) {
            Log.d("FlutterPlugin", "conference is null")
            result.success(false)
            return
        }

        conference.removePeerVideoView(peerControl.peer.user, videoView.videoView)
        PlanetKitFlutterVideoViews.release(param.viewId)
        result.success(true)
    }

    fun startScreenShare(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "startScreenShare ${call.method} ${call.arguments}")
        val param =
            gson.fromJson(call.arguments.toString(), PeerControlParams.StartScreenShareParam::class.java)

        val peerControl = nativeInstances.get(param.id) as? PlanetKitPeerControl
        if (peerControl == null) {
            Log.e("FlutterPlugin", "startScreenShare peer control not found ${param.id}")
            result.success(false)
            return
        }

        val ret = peerControl.startScreenShare()

        if (!ret) {
            Log.d("FlutterPlugin", "startScreenShare platform api  returned false")
            result.success(false)
            return
        }

        val videoView = PlanetKitFlutterVideoViews.getView(param.viewId)

        if (videoView == null) {
            Log.d("FlutterPlugin", "failed to find the view for ${param.viewId}")
            result.success(false)
            return
        }

        val conference = PlanetKit.getConference()

        if (conference == null) {
            Log.d("FlutterPlugin", "conference is null")
            result.success(false)
            return
        }

        conference.addPeerScreenShareView(peerControl.peer.user, videoView.videoView)
        PlanetKitFlutterVideoViews.retain(param.viewId)
        result.success(true)
    }

    fun stopScreenShare(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "stopScreenShare ${call.method} ${call.arguments}")
        val param =
            gson.fromJson(call.arguments.toString(), PeerControlParams.StopScreenShareParam::class.java)

        val peerControl = nativeInstances.get(param.id) as? PlanetKitPeerControl
        if (peerControl == null) {
            Log.e("FlutterPlugin", "stopScreenShare peer control not found ${param.id}")
            result.success(false)
            return
        }

        val ret = peerControl.stopScreenShare()

        if (!ret) {
            Log.d("FlutterPlugin", "stopScreenShare platform api  returned false")
            result.success(false)
            return
        }

        val videoView = PlanetKitFlutterVideoViews.getView(param.viewId)

        if (videoView == null) {
            Log.d("FlutterPlugin", "failed to find the view for ${param.viewId}")
            result.success(false)
            return
        }

        val conference = PlanetKit.getConference()

        if (conference == null) {
            Log.d("FlutterPlugin", "conference is null")
            result.success(false)
            return
        }

        conference.removePeerScreenShareView(peerControl.peer.user, videoView.videoView)
        PlanetKitFlutterVideoViews.release(param.viewId)
        result.success(true)
    }
}


