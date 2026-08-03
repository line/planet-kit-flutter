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
import com.linecorp.planetkit.session.data.PlanetKitDataSessionClosedReason
import com.linecorp.planetkit.session.data.PlanetKitDataSessionFailReason
import com.linecorp.planetkit.session.data.PlanetKitDataSessionType
import io.flutter.plugin.common.MethodChannel

/**
 * Guards a [MethodChannel.Result] so its `success` is delivered exactly once on the
 * main thread. The data session make APIs report their outcome asynchronously via a
 * listener (onSessionMade vs onError); both must resolve the same pending result.
 */
class SingleResult(private val result: MethodChannel.Result) {
    private var resolved = false

    @Synchronized
    fun success(value: Any?) {
        if (resolved) {
            return
        }
        resolved = true
        Handler(Looper.getMainLooper()).post {
            result.success(value)
        }
    }
}

/**
 * Maps PlanetKit data session SDK enums to/from the raw integers shared with the
 * Dart layer. Mirrors the explicit `when` mapping style used elsewhere in the plugin
 * (e.g. PlanetKitMediaTypeAdapter) instead of relying on internal `nRepresentation`.
 */
object PlanetKitFlutterDataSessionTypes {
    // Type: reliableMessage=1, reliableBytes=2, unreliableBytes=3, unreliableMessage=4 (unknown=0)
    fun typeToInt(type: PlanetKitDataSessionType?): Int = when (type) {
        PlanetKitDataSessionType.RELIABLE_MESSAGE -> 1
        PlanetKitDataSessionType.RELIABLE_BYTES -> 2
        PlanetKitDataSessionType.UNRELIABLE_BYTES -> 3
        PlanetKitDataSessionType.UNRELIABLE_MESSAGE -> 4
        else -> 0
    }

    fun typeFromInt(value: Int): PlanetKitDataSessionType = when (value) {
        1 -> PlanetKitDataSessionType.RELIABLE_MESSAGE
        2 -> PlanetKitDataSessionType.RELIABLE_BYTES
        3 -> PlanetKitDataSessionType.UNRELIABLE_BYTES
        4 -> PlanetKitDataSessionType.UNRELIABLE_MESSAGE
        else -> PlanetKitDataSessionType.UNKNOWN
    }

    // FailReason: none=0, internal=1, notIncoming=3, alreadyExist=4, invalidId=5, invalidType=6
    fun failReasonToInt(reason: PlanetKitDataSessionFailReason?): Int = when (reason) {
        PlanetKitDataSessionFailReason.NONE -> 0
        PlanetKitDataSessionFailReason.INTERNAL -> 1
        PlanetKitDataSessionFailReason.NOT_INCOMING -> 3
        PlanetKitDataSessionFailReason.ALREADY_EXIST -> 4
        PlanetKitDataSessionFailReason.INVALID_ID -> 5
        PlanetKitDataSessionFailReason.INVALID_TYPE -> 6
        else -> 1
    }

    // ClosedReason: sessionEnd=0, internal=1, unsupported=2
    fun closedReasonToInt(reason: PlanetKitDataSessionClosedReason?): Int = when (reason) {
        PlanetKitDataSessionClosedReason.SESSION_END -> 0
        PlanetKitDataSessionClosedReason.INTERNAL -> 1
        PlanetKitDataSessionClosedReason.UNSUPPORTED -> 2
        else -> 1
    }
}
