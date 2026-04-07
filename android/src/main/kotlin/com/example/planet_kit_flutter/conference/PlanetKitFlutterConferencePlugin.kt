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

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.example.planet_kit_flutter.PlanetKitFlutterMyMediaStatusPlugin
import com.example.planet_kit_flutter.PlanetKitFlutterNativeInstances
import com.example.planet_kit_flutter.PlanetKitFlutterStreamHandler
import com.example.planet_kit_flutter.videoView.PlanetKitFlutterVideoViews
import com.google.gson.Gson
import com.linecorp.planetkit.PlanetKit
import com.linecorp.planetkit.PlanetKitVideoPauseReason
import com.linecorp.planetkit.session.PlanetKitDisconnectedParam
import com.linecorp.planetkit.session.PlanetKitMyMediaStatusListener
import com.linecorp.planetkit.session.PlanetKitUser
import com.linecorp.planetkit.session.conference.ConferenceListener
import com.linecorp.planetkit.session.conference.PlanetKitConference
import com.linecorp.planetkit.session.conference.PlanetKitConferencePeerHoldReceivedParam
import com.linecorp.planetkit.session.conference.PlanetKitConferencePeerListUpdatedParam
import com.linecorp.planetkit.session.conference.subgroup.PlanetKitConferencePeer
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PlanetKitFlutterConferencePlugin(
    eventStreamHandler: PlanetKitFlutterStreamHandler,
    nativeInstances: PlanetKitFlutterNativeInstances,
    gson: Gson
) : ConferenceListener {
    private val eventStreamHandler = eventStreamHandler
    private val nativeInstances = nativeInstances
    private val gson = gson
    private val myMediaStatusListeners = HashMap<String, PlanetKitMyMediaStatusListener>()

    override fun onConnected(
        conference: PlanetKitConference,
        isVideoHwCodecEnabled: Boolean,
        isVideoShareModeSupported: Boolean
    ) {
        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onConnected")
            val eventData = ConferenceEvents.ConnectedEvent(
                conference.hashCode().toString()
            )
            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }

    override fun onDisconnected(
        conference: PlanetKitConference,
        param: PlanetKitDisconnectedParam
    ) {
        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onDisconnected")
            
            // Remove the my media status instance if it exists
            val myMediaStatus = conference.getMyMediaStatus()
            if (myMediaStatus != null) {
                nativeInstances.remove(myMediaStatus.hashCode().toString())
            }

            val eventData = ConferenceEvents.DisconnectedEvent(
                conference.hashCode().toString(),
                param.reason,
                param.source,
                param.userCode,
                param.byRemote
            )
            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }


    override fun onPeerListUpdated(param: PlanetKitConferencePeerListUpdatedParam) {
        // TODO: update after Android SDK's onPeerListUpdated updates
        val conference = PlanetKit.getConference()
        if (conference == null) {
            Log.d("FlutterPlugin", "conference is null")
            return
        }

        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onPeerListUpdated")

            var added: MutableList<ConferenceEvents.InitialPeerInfo> = mutableListOf()
            var removed: MutableList<String> = mutableListOf()

            for (addedPeer in param.addedPeers) {
                val info = ConferenceEvents.InitialPeerInfo(
                    addedPeer.hashCode().toString(),
                    addedPeer.userId,
                    addedPeer.serviceId
                )
                added.add(info)
                nativeInstances.add(addedPeer.hashCode().toString(), addedPeer)
            }

            for (removedPeer in param.removedPeers) {
                removed.add(removedPeer.hashCode().toString())
            }

            val eventData = ConferenceEvents.PeerListUpdateEvent(
                conference.hashCode().toString(),
                added,
                removed,
                param.totalPeerCnt
            )
            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }

    override fun onPeersMicMuted(
        conference: PlanetKitConference,
        peers: List<PlanetKitConferencePeer>
    ) {
        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onPeersMicMuted")
            var peerIds: MutableList<String> = mutableListOf()

            for (peer in peers) {
                peerIds.add(peer.hashCode().toString())
            }

            val eventData = ConferenceEvents.PeersMicMuteEvent(
                conference.hashCode().toString(),
                peerIds,
            )
            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }

    override fun onPeersMicUnmuted(
        conference: PlanetKitConference,
        peers: List<PlanetKitConferencePeer>
    ) {
        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onPeersMicUnmuted")
            var peerIds: MutableList<String> = mutableListOf()

            for (peer in peers) {
                peerIds.add(peer.hashCode().toString())
            }

            val eventData = ConferenceEvents.PeersMicUnmuteEvent(
                conference.hashCode().toString(),
                peerIds,
            )
            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }

    override fun onPeersOnHold(
        conference: PlanetKitConference,
        peerHoldReceivedList: List<PlanetKitConferencePeerHoldReceivedParam>
    ) {
        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onPeersOnHold")
            var holdDataList: MutableList<ConferenceEvents.PeerHoldEventData> = mutableListOf()

            for (holdReceived in peerHoldReceivedList) {
                val holdData = ConferenceEvents.PeerHoldEventData(
                    holdReceived.peer.hashCode().toString(),
                    holdReceived.reason
                )
                holdDataList.add(holdData)
            }

            val eventData = ConferenceEvents.PeersHoldEvent(
                conference.hashCode().toString(),
                holdDataList,
            )

            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }

    override fun onPeersUnhold(
        conference: PlanetKitConference,
        peers: List<PlanetKitConferencePeer>
    ) {
        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onPeersUnhold")
            var unholdPeers: MutableList<String> = mutableListOf()

            for (peer in peers) {
                unholdPeers.add(peer.hashCode().toString())
            }

            val eventData = ConferenceEvents.PeersUnholdEvent(
                conference.hashCode().toString(),
                unholdPeers,
            )

            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }

    override fun onMuteMyAudioRequestedByPeer(
        conference: PlanetKitConference,
        peer: PlanetKitConferencePeer,
        isMute: Boolean
    ) {
        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onMuteMyAudioRequestedByPeer")

            val eventData = ConferenceEvents.MyAudioMuteRequestedByPeerEvent(
                conference.hashCode().toString(),
                peer.hashCode().toString(),
                isMute
            )

            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }

    override fun onNetworkUnavailable(conference: PlanetKitConference, disconnectAfterSec: Int) {
        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onNetworkUnavailable")

            val eventData = ConferenceEvents.NetworkUnavailableEvent(
                conference.hashCode().toString(),
                disconnectAfterSec
            )

            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }

    override fun onNetworkReavailable(conference: PlanetKitConference) {
        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onNetworkReavailable")

            val eventData = ConferenceEvents.NetworkReavailableEvent(
                conference.hashCode().toString(),
            )

            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }


    fun leaveConference(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "leaveConference ${call.method} ${call.arguments}")
        val id = call.arguments as String
        val conference = nativeInstances.get(id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "leaveConference conference not found $id")
            result.success(false)
            return
        }

        conference.leaveConference()
        result.success(true)
    }

    fun muteMyAudio(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "muteMyAudio ${call.method} ${call.arguments}")
        val param =
            gson.fromJson(call.arguments.toString(), ConferenceParams.MuteMyAudioParam::class.java)

        val conference = nativeInstances.get(param.id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "muteMyAudio conference not found ${param.id}")
            result.success(false)
            return
        }

        val ret = conference.muteMyAudio(isMute = param.mute) { res ->
            if (!res.isSuccessful) {
                Log.e("FlutterPlugin", "muteMyAudio failed")
            }
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.e("FlutterPlugin", "muteMyAudio platform api returned $ret")
            result.success(false)
        }
    }

    fun speakerOut(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "speakerOut ${call.method} ${call.arguments}")
        val param =
            gson.fromJson(call.arguments.toString(), ConferenceParams.SpeakerOutParam::class.java)

        val conference = nativeInstances.get(param.id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "speakerOut conference not found ${param.id}")
            result.success(false)
            return
        }

        conference.setSpeakerOn(param.speakerOut)
        result.success(true)
    }

    fun isSpeakerOut(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "isSpeakerOut ${call.method} ${call.arguments}")
        val id = call.arguments as String
        val conference = nativeInstances.get(id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "isSpeakerOut conference not found $id")
            result.success(false)
            return
        }

        result.success(conference.isSpeakerOn)
    }

    fun isOnHold(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "isOnHold ${call.method} ${call.arguments}")
        val id = call.arguments as String
        val conference = nativeInstances.get(id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "isOnHold conference not found $id")
            result.success(false)
            return
        }

        result.success(conference.isOnHold)
    }

    fun silencePeersAudio(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "silencePeersAudio ${call.method} ${call.arguments}")
        val param = gson.fromJson(
            call.arguments.toString(),
            ConferenceParams.SilencePeersAudioParam::class.java
        )

        val conference = nativeInstances.get(param.id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "silencePeersAudio conference not found ${param.id}")
            result.success(false)
            return
        }

        val ret = conference.silencePeersAudio(param.silent) { res ->
            if (!res.isSuccessful) {
                Log.e("FlutterPlugin", "silencePeersAudio failed")
            }
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.e("FlutterPlugin", "silencePeersAudio platform api returned $ret")
            result.success(false)
        }
    }

    fun requestPeerMute(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "requestPeerMute ${call.method} ${call.arguments}")
        val param = gson.fromJson(
            call.arguments.toString(),
            ConferenceParams.RequestPeerMuteParam::class.java
        )

        val conference = nativeInstances.get(param.id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "requestPeerMute conference not found ${param.id}")
            result.success(false)
            return
        }

        val userId = PlanetKitUser(param.peerId.userId, param.peerId.serviceId)


        val ret = conference.requestPeerMute(userId, isMute = param.mute) { res ->
            if (!res.isSuccessful) {
                Log.e("FlutterPlugin", "requestPeerMute failed")
            }

            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.e("FlutterPlugin", "requestPeerMute platform api returned $ret")
            result.success(false)
        }
    }

    fun requestPeersMute(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "requestPeerMute ${call.method} ${call.arguments}")
        val param = gson.fromJson(
            call.arguments.toString(),
            ConferenceParams.RequestPeersMuteParam::class.java
        )

        val conference = nativeInstances.get(param.id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "requestPeerMute conference not found ${param.id}")
            result.success(false)
            return
        }


        val ret = conference.requestPeersMute(isMute = param.mute) { res ->
            if (!res.isSuccessful) {
                Log.e("FlutterPlugin", "requestPeerMute failed")
            }

            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.e("FlutterPlugin", "requestPeerMute platform api returned $ret")
            result.success(false)
        }
    }

    fun hold(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "hold ${call.method} ${call.arguments}")
        val param = gson.fromJson(
            call.arguments.toString(),
            ConferenceParams.HoldConferenceParam::class.java
        )

        val conference = nativeInstances.get(param.id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "hold conference not found ${param.id}")
            result.success(false)
            return
        }

        val ret = conference.hold(param.reason) { res ->
            if (!res.isSuccessful) {
                Log.e("FlutterPlugin", "hold failed")
            }

            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "hold platform api  returned false")
            result.success(false)
        }
    }

    fun unhold(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "unhold ${call.method} ${call.arguments}")
        val id = call.arguments as String

        val conference = nativeInstances.get(id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "unhold conference not found $id")
            result.success(false)
            return
        }

        val ret = conference.unhold() { res ->
            if (!res.isSuccessful) {
                Log.e("FlutterPlugin", "hold failed")
            }

            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "unhold platform api  returned false")
            result.success(false)
        }
    }

    fun getMyMediaStatus(
        call: MethodCall,
        myMediaStatusPlugin: PlanetKitFlutterMyMediaStatusPlugin,
        result: MethodChannel.Result
    ) {
        Log.d("FlutterPlugin", "addMyMediaStatusHandler ${call.arguments}")
        val id = call.arguments<String>() as String
        val conference = nativeInstances.get(id) as? PlanetKitConference

        if (conference == null) {
            Log.d("FlutterPlugin", "failed to find the conference for $id")
            result.success(null)
            return
        }

        val myMediaStatus = conference.getMyMediaStatus()

        if (myMediaStatus == null) {
            Log.d("FlutterPlugin", "failed to get my media status")
            result.success(null)
            return
        }

        val myMediaStatusHandler = myMediaStatusPlugin.getMyStatusHandler(myMediaStatus)

        if (myMediaStatusHandler == null) {
            Log.d("FlutterPlugin", "failed to get my media status handler")
            result.success(null)
            return
        }

        myMediaStatus.addHandler(myMediaStatusHandler, null) { addHandlerResult ->
            if (addHandlerResult.isSuccessful) {
                nativeInstances.add(myMediaStatus.hashCode().toString(), myMediaStatus)
                myMediaStatusListeners[id] = myMediaStatusHandler
                result.success(myMediaStatus.hashCode().toString())
            } else {
                result.success(null)
            }
        }
    }

    fun createPeerControl(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "createPeerControl ${call.method} ${call.arguments}")
        val param = gson.fromJson(
            call.arguments.toString(),
            ConferenceParams.CreatePeerControlParam::class.java
        )

        val conference = nativeInstances.get(param.conferenceId) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "createPeerControl conference not found ${param.conferenceId}")
            result.success(null)
            return
        }

        val peer = nativeInstances.get(param.peerId) as? PlanetKitConferencePeer
        if (peer == null) {
            Log.e("FlutterPlugin", "createPeerControl peer not found ${param.peerId}")
            result.success(null)
            return
        }

        val peerControl = peer.createPeerControl();

        if (peerControl == null) {
            Log.e("FlutterPlugin", "createPeerControl returned null")
            result.success(null);
            return
        }

        Log.d(
            "FlutterPlugin",
            "createPeerControl created with ${peerControl.hashCode().toString()}"
        )
        nativeInstances.add(peerControl.hashCode().toString(), peerControl)
        result.success(peerControl.hashCode().toString())
    }

    fun addMyVideoView(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        Log.d("FlutterPlugin", "addMyVideoView ${call.arguments}")
        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, ConferenceParams.AddVideoViewParam::class.java)
        val planetKitConference = nativeInstances.get(param.conferenceId) as? PlanetKitConference

        if (planetKitConference == null) {
            Log.d("FlutterPlugin", "failed to find the confernece for ${param.conferenceId}")
            result.success(false)
            return
        }

        val videoView = PlanetKitFlutterVideoViews.getView(param.viewId)
        if (videoView == null) {
            Log.d("FlutterPlugin", "failed to find the view for ${param.viewId}")
            result.success(false)
            return
        }

        planetKitConference.addMyVideoView(videoView.videoView)
        PlanetKitFlutterVideoViews.retain(param.viewId)
        result.success(true)
    }

    fun removeMyVideoView(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        Log.d("FlutterPlugin", "removeMyVideoView ${call.arguments}")
        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, ConferenceParams.RemoveVideoViewParam::class.java)
        val planetKitConference = nativeInstances.get(param.conferenceId) as? PlanetKitConference

        if (planetKitConference == null) {
            Log.d("FlutterPlugin", "failed to find the confernece for ${param.conferenceId}")
            result.success(false)
            return
        }

        val videoView = PlanetKitFlutterVideoViews.getView(param.viewId)

        if (videoView == null) {
            Log.d("FlutterPlugin", "failed to find the view for ${param.viewId}")
            result.success(false)
            return
        }

        planetKitConference.removeMyVideoView(videoView.videoView)
        PlanetKitFlutterVideoViews.release(param.viewId)
        result.success(true)
    }

    fun enableVideo(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        Log.d("FlutterPlugin", "enableVideo ${call.arguments}")

        val args = call.arguments<Map<String, Any>>()
        val jsonArgs = gson.toJson(args)
        val param = gson.fromJson(jsonArgs, ConferenceParams.EnableVideoParam::class.java)

        val id = param.conferenceId
        val conference = nativeInstances.get(id) as? PlanetKitConference

        if (conference == null) {
            Log.d("FlutterPlugin", "failed to find the conference for $id")
            result.success(false)
            return
        }

        val ret = conference.enableVideo(initialMyVideoState = param.initialMyVideoState) { res ->
            Log.d("FlutterPlugin", "conference.enableVideo() result ${res.isSuccessful}")
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "conference.enableVideo() returned false")
            result.success(false)
        }
    }

    fun disableVideo(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        Log.d("FlutterPlugin", "disableVideo ${call.arguments}")
        val id = call.arguments<String>() as String
        val conference = nativeInstances.get(id) as? PlanetKitConference

        if (conference == null) {
            Log.d("FlutterPlugin", "failed to find the conference for $id")
            result.success(false)
            return
        }

        val ret = conference.disableVideo() { res ->
            Log.d("FlutterPlugin", "conference.disableVideo() result ${res.isSuccessful}")
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "conference.disableVideo() returned false")
            result.success(false)
        }
    }

    fun pauseMyVideo(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        Log.d("FlutterPlugin", "pauseMyVideo ${call.arguments}")
        val id = call.arguments<String>() as String
        val conference = nativeInstances.get(id) as? PlanetKitConference

        if (conference == null) {
            Log.d("FlutterPlugin", "failed to find the conference for $id")
            result.success(false)
            return
        }

        val ret = conference.pauseMyVideo(PlanetKitVideoPauseReason.BY_USER) { res ->
            Log.d("FlutterPlugin", "conference.pauseMyVideo() result ${res.isSuccessful}")
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "conference.pauseMyVideo() returned false")
            result.success(false)
        }
    }

    fun resumeMyVideo(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        Log.d("FlutterPlugin", "resumeMyVideo ${call.arguments}")
        val id = call.arguments<String>() as String
        val conference = nativeInstances.get(id) as? PlanetKitConference

        if (conference == null) {
            Log.d("FlutterPlugin", "failed to find the conference for $id")
            result.success(false)
            return
        }

        val ret = conference.resumeMyVideo() { res ->
            Log.d("FlutterPlugin", "conference.resumeMyVideo() result ${res.isSuccessful}")
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.d("FlutterPlugin", "conference.resumeMyVideo() returned false")
            result.success(false)
        }
    }

    fun getStatistics(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        val id = call.arguments<String>() as String
        val conference = nativeInstances.get(id) as? PlanetKitConference

        if (conference == null) {
            Log.d("FlutterPlugin", "failed to find the call for $id")
            result.success(null)
            return
        }

        if (conference.statistics == null) {
            result.success(null)
            return
        }

        val json = gson.toJson(conference.statistics)

        result.success(json)
    }
}