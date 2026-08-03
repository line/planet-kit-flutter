// Copyright 2025 LINE Plus Corporation
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

package com.example.planet_kit_flutter.call

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.linecorp.planetkit.session.PlanetKitDisconnectedParam
import com.linecorp.planetkit.session.call.PlanetKitCall
import com.linecorp.planetkit.session.call.PlanetKitCallStartMessage
import com.linecorp.planetkit.session.call.VerifyListener
import java.lang.ref.WeakReference

/**
 * Global singleton that implements VerifyListener for background-verified calls.
 * This solves the multi-engine problem where background and foreground Flutter engines
 * have different plugin instances.
 *
 * Usage:
 * - Only used for verifyBackgroundCall() - regular makeCall() and verifyCall() bypass this
 * - Routes events to background plugin while in background engine
 * - Routes events to foreground plugin after adoptBackgroundCall()
 * - After acceptCall() re-registers foreground plugin, this broadcaster is no longer used
 *
 * Events are routed based on whether the call is in the background registry or not.
 */
class PlanetKitFlutterVerifyListenerBroadcaster private constructor() : VerifyListener {
    
    // Use WeakReference to avoid memory leaks
    private val listeners = mutableListOf<WeakReference<VerifyListener>>()
    
    /**
     * Register a listener to receive events
     */
    fun registerListener(listener: VerifyListener) {
        synchronized(listeners) {
            // Clean up null references
            listeners.removeAll { it.get() == null }
            
            // Add if not already present
            if (listeners.none { it.get() === listener }) {
                listeners.add(WeakReference(listener))
                Log.d("VerifyListener", "Registered listener: ${listener.hashCode()}, total: ${listeners.size}")
            }
        }
    }
    
    /**
     * Unregister a listener
     */
    fun unregisterListener(listener: VerifyListener) {
        synchronized(listeners) {
            listeners.removeAll { it.get() === listener || it.get() == null }
            Log.d("VerifyListener", "Unregistered listener: ${listener.hashCode()}, remaining: ${listeners.size}")
        }
    }
    
    /**
     * Broadcast event to all registered listeners.
     * Each listener decides whether to handle the event based on call state.
     */
    private fun broadcast(action: (VerifyListener) -> Unit) {
        synchronized(listeners) {
            // Clean up null references
            listeners.removeAll { it.get() == null }
            
            // Notify all active listeners
            listeners.forEach { ref ->
                ref.get()?.let { listener ->
                    action(listener)
                }
            }
        }
    }

    // VerifyListener implementations - broadcast to all registered listeners
    
    override fun onVerified(call: PlanetKitCall, peerStartMessage: PlanetKitCallStartMessage?, peerUseResponderPreparation: Boolean) {
        Log.d("VerifyListener", "onVerified ${call.hashCode()}, broadcasting to listeners")
        Handler(Looper.getMainLooper()).post {
            broadcast { listener ->
                listener.onVerified(call, peerStartMessage, peerUseResponderPreparation)
            }
        }
    }
    
    override fun onDisconnected(call: PlanetKitCall, disconnected: PlanetKitDisconnectedParam) {
        Log.d("VerifyListener", "onDisconnected ${call.hashCode()}, broadcasting to listeners")
        Handler(Looper.getMainLooper()).post {
            broadcast { listener ->
                listener.onDisconnected(call, disconnected)
            }
            // remove the background-call registry entry exactly once,
            // AFTER every listener has been notified. Each engine's plugin routes
            // this disconnect based on registry membership; evicting it inside a
            // listener let the first engine starve the others (notably the FCM
            // background isolate that owns the verify handler). Each listener's
            // emit is itself posted to the main looper, so this follow-up post is
            // ordered (FIFO) after all of them, keeping routing correct before the
            // entry is cleaned up.
            Handler(Looper.getMainLooper()).post {
                PlanetKitFlutterBackgroundCalls.instance.remove(call.hashCode().toString())
            }
        }
    }

    companion object {
        @Volatile
        private var INSTANCE: PlanetKitFlutterVerifyListenerBroadcaster? = null
        
        val instance: PlanetKitFlutterVerifyListenerBroadcaster
            get() {
                return INSTANCE ?: synchronized(this) {
                    INSTANCE ?: PlanetKitFlutterVerifyListenerBroadcaster().also { INSTANCE = it }
                }
            }
    }
}
