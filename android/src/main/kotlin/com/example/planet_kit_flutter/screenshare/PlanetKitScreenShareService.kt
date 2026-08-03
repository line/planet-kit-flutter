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

package com.example.planet_kit_flutter.screenshare

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.IBinder
import android.util.Log
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import com.example.planet_kit_flutter.PlanetKitFlutterNativeInstances
import com.linecorp.planetkit.session.call.PlanetKitCall
import com.linecorp.planetkit.session.conference.PlanetKitConference
import com.linecorp.planetkit.video.ScreenCapturerVideoSource

class PlanetKitScreenShareService : Service() {

    companion object {
        const val EXTRA_RESULT_CODE = "resultCode"
        const val EXTRA_RESULT_DATA = "resultData"
        const val EXTRA_INSTANCE_ID = "instanceId"
        const val EXTRA_IS_CONFERENCE = "isConference"
        const val NOTIFICATION_ID = 2001
        const val CHANNEL_ID = "planetkit_screen_share"
        const val CHANNEL_NAME = "Screen Share"

        // Keyed by session instanceId (call id / conference id) so that concurrent
        // requests from different sessions each keep their own callback and never
        // overwrite one another. The service removes a key once it notifies it.
        val onStartedCallbacks = ConcurrentHashMap<String, (Boolean) -> Unit>()

        const val MEDIA_PROJECTION_REQUEST_CODE = 1001

        lateinit var nativeInstances: PlanetKitFlutterNativeInstances
    }

    private var screenSource: ScreenCapturerVideoSource? = null
    private var currentInstanceId: String? = null
    private var isConferenceSession: Boolean = false
    private val isStopping = AtomicBoolean(false)
    private var screenOffReceiver: BroadcastReceiver? = null

    override fun onBind(intent: Intent?): IBinder? = null

    /**
     * Stops the active screen share on the SDK (so peers receive
     * onPeerScreenShareStopped and remove the shared view) and then stops this
     * service. Guarded so the capturer-error and screen-off paths can't both run.
     */
    private fun stopScreenShareAndSelf(reason: String) {
        // compareAndSet guarantees single-stop even if the screen-off (main thread)
        // and capturer-error (SDK thread) triggers race.
        if (!isStopping.compareAndSet(false, true)) return
        Log.d("PlanetKitScreenShareService", "Stopping screen share ($reason)")
        currentInstanceId?.let { id ->
            // If we stop while a startMyScreenShare response is still pending, the
            // SDK may never deliver that callback. Consume it here with false so the
            // caller's awaiting Dart Future resolves instead of hanging forever.
            onStartedCallbacks.remove(id)?.invoke(false)
            if (isConferenceSession) {
                (nativeInstances.get(id) as? PlanetKitConference)?.stopMyScreenShare()
            } else {
                (nativeInstances.get(id) as? PlanetKitCall)?.stopMyScreenShare()
            }
        }
        stopSelf()
    }

    /**
     * Detect device lock / screen-off. The MEDIA_PROJECTION foreground service
     * keeps capturing across a lock on many devices, so the capturer never errors
     * and the peer would keep seeing the (locked) screen. ACTION_SCREEN_OFF fires
     * on lock/screen-off but NOT on app-switch, so stopping here matches iOS
     * (screen share ends on lock) while leaving "share another app" intact.
     */
    private fun registerScreenOffReceiver() {
        if (screenOffReceiver != null) return
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == Intent.ACTION_SCREEN_OFF) {
                    Log.d("PlanetKitScreenShareService", "ACTION_SCREEN_OFF received")
                    stopScreenShareAndSelf("device lock / screen off")
                }
            }
        }
        ContextCompat.registerReceiver(
            this,
            receiver,
            IntentFilter(Intent.ACTION_SCREEN_OFF),
            ContextCompat.RECEIVER_NOT_EXPORTED
        )
        screenOffReceiver = receiver
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createNotificationChannel()
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Screen sharing")
            .setContentText("Your screen is being shared")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                notification,
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        val resultCode = intent?.getIntExtra(EXTRA_RESULT_CODE, -1) ?: -1
        val resultData = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent?.getParcelableExtra(EXTRA_RESULT_DATA, Intent::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent?.getParcelableExtra(EXTRA_RESULT_DATA)
        }
        val instanceId = intent?.getStringExtra(EXTRA_INSTANCE_ID)
        val isConference = intent?.getBooleanExtra(EXTRA_IS_CONFERENCE, false) ?: false

        // Notify (and consume) the callback registered for this specific session.
        fun notifyStarted(success: Boolean) {
            instanceId?.let { onStartedCallbacks.remove(it)?.invoke(success) }
        }

        if (resultData == null || instanceId == null) {
            Log.e("PlanetKitScreenShareService", "Missing required extras")
            notifyStarted(false)
            stopSelf()
            return START_NOT_STICKY
        }

        val src = ScreenCapturerVideoSource.getInstance(resultCode, resultData)
        if (src == null) {
            Log.e("PlanetKitScreenShareService", "Failed to create ScreenCapturerVideoSource")
            notifyStarted(false)
            stopSelf()
            return START_NOT_STICKY
        }
        screenSource = src
        currentInstanceId = instanceId
        isConferenceSession = isConference
        isStopping.set(false)

        // Secondary trigger: some devices DO stop the MediaProjection on lock,
        // and genuine capture errors can occur. Stop the share so peers are
        // notified instead of being left with a frozen last frame.
        src.setOnErrorListener {
            Log.e("PlanetKitScreenShareService", "ScreenCapturerVideoSource error")
            stopScreenShareAndSelf("capturer error")
        }

        // Primary trigger for device lock (see registerScreenOffReceiver).
        registerScreenOffReceiver()

        if (isConference) {
            val conference = nativeInstances.get(instanceId) as? PlanetKitConference
            if (conference == null) {
                Log.e("PlanetKitScreenShareService", "Conference not found: $instanceId")
                notifyStarted(false)
                stopSelf()
                return START_NOT_STICKY
            }
            conference.startMyScreenShare(src) { response ->
                notifyStarted(response.isSuccessful)
                if (!response.isSuccessful) {
                    stopSelf()
                }
            }
        } else {
            val call = nativeInstances.get(instanceId) as? PlanetKitCall
            if (call == null) {
                Log.e("PlanetKitScreenShareService", "Call not found: $instanceId")
                notifyStarted(false)
                stopSelf()
                return START_NOT_STICKY
            }
            call.startMyScreenShare(src) { response ->
                notifyStarted(response.isSuccessful)
                if (!response.isSuccessful) {
                    stopSelf()
                }
            }
        }

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        screenOffReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: IllegalArgumentException) {
                // Receiver was not registered; ignore.
            }
        }
        screenOffReceiver = null
        screenSource = null
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}
