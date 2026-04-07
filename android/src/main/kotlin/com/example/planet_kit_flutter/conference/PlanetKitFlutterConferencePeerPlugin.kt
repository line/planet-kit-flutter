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

package com.example.planet_kit_flutter.conference

import android.util.Log
import com.example.planet_kit_flutter.PlanetKitFlutterNativeInstances
import com.google.gson.Gson
import com.linecorp.planetkit.session.conference.subgroup.PlanetKitConferencePeer
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

data class HoldStatus(
    val isOnHold: Boolean,
    val reason: String?
)

class PlanetKitFlutterConferencePeerPlugin(
    private val nativeInstances: PlanetKitFlutterNativeInstances,
    private val gson: Gson
) {
    fun getHoldStatus(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "getHoldStatus ${call.method} called")
        val id = call.arguments as String
        val peer = nativeInstances.get(id) as? PlanetKitConferencePeer
        if (peer == null) {
            Log.d("FlutterPlugin", "${call.method} peer not found $id")
            result.success(null)
            return
        }

        val holdStatus =
            HoldStatus(isOnHold = peer.holdStatus.isOnHold, reason = peer.holdStatus.holdReason)
        val jsonString = gson.toJson(holdStatus)
        result.success(jsonString)
    }

    fun isMuted(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "isMuted ${call.method} called")
        val id = call.arguments as String
        val peer = nativeInstances.get(id) as? PlanetKitConferencePeer
        if (peer == null) {
            Log.d("FlutterPlugin", "${call.method} peer not found $id")
            result.success(false)
            return
        }

        result.success(peer.isAudioMuted)
    }

    fun getVideoStatus(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "getVideoStatus ${call.method} called")
        val id = call.arguments as String
        val peer = nativeInstances.get(id) as? PlanetKitConferencePeer
        if (peer == null) {
            Log.d("FlutterPlugin", "${call.method} peer not found $id")
            result.success(null)
            return
        }

        val videoStatus = peer.getVideoStatus(null)
        if (videoStatus.failReason != PlanetKitConferencePeer.PeerGetFailReason.NONE) {
            result.success(null)
            return
        }

        val jsonString = gson.toJson(videoStatus.videoStatus)
        result.success(jsonString)
    }

    fun getScreenShareState(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "getScreenShareState ${call.method} called")
        val id = call.arguments as String
        val peer = nativeInstances.get(id) as? PlanetKitConferencePeer
        if (peer == null) {
            Log.d("FlutterPlugin", "${call.method} peer not found $id")
            result.success(null)
            return
        }

        val screenShareStateResult = peer.getScreenShareState(null)
        if (screenShareStateResult.failReason != PlanetKitConferencePeer.PeerGetFailReason.NONE) {
            result.success(null)
            return
        }

        result.success(screenShareStateResult.screenShareState.ordinal)
    }
}