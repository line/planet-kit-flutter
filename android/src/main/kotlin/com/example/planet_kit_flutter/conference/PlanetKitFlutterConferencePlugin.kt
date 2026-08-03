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

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.util.Log
import com.example.planet_kit_flutter.screenshare.PlanetKitScreenShareService
import com.example.planet_kit_flutter.PlanetKitFlutterDataSessionTypes
import com.example.planet_kit_flutter.PlanetKitFlutterMyMediaStatusPlugin
import com.example.planet_kit_flutter.SingleResult
import com.example.planet_kit_flutter.PlanetKitFlutterNativeInstances
import com.example.planet_kit_flutter.PlanetKitFlutterStreamHandler
import com.example.planet_kit_flutter.videoView.PlanetKitFlutterVideoViews
import com.google.gson.Gson
import com.linecorp.planetkit.PlanetKit
import com.linecorp.planetkit.PlanetKitVideoPauseReason
import com.linecorp.planetkit.session.PlanetKitDisconnectedParam
import com.linecorp.planetkit.session.PlanetKitMyMediaStatusListener
import com.linecorp.planetkit.session.PlanetKitShortData
import com.linecorp.planetkit.session.PlanetKitUser
import com.linecorp.planetkit.session.conference.ConferenceListener
import com.linecorp.planetkit.session.conference.PlanetKitConference
import com.linecorp.planetkit.session.conference.PlanetKitConferencePeerHoldReceivedParam
import com.linecorp.planetkit.session.conference.PlanetKitConferencePeerListUpdatedParam
import com.linecorp.planetkit.session.conference.PlanetKitConferencePeerSetSharedContentsParam
import com.linecorp.planetkit.session.conference.subgroup.PlanetKitConferencePeer
import com.linecorp.planetkit.session.data.InboundDataSessionListener
import com.linecorp.planetkit.session.data.OutboundDataSessionListener
import com.linecorp.planetkit.session.data.PlanetKitDataSessionClosedReason
import com.linecorp.planetkit.session.data.PlanetKitDataSessionFailReason
import com.linecorp.planetkit.session.data.PlanetKitDataSessionType
import com.linecorp.planetkit.session.data.PlanetKitInboundDataSession
import com.linecorp.planetkit.session.data.PlanetKitOutboundDataSession
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer
import java.util.concurrent.ConcurrentHashMap

class PlanetKitFlutterConferencePlugin(
    eventStreamHandler: PlanetKitFlutterStreamHandler,
    nativeInstances: PlanetKitFlutterNativeInstances,
    gson: Gson
) : ConferenceListener {
    private val eventStreamHandler = eventStreamHandler
    private val nativeInstances = nativeInstances
    private val gson = gson
    private val myMediaStatusListeners = HashMap<String, PlanetKitMyMediaStatusListener>()
    private var pendingScreenShareResult: MethodChannel.Result? = null
    private var pendingScreenShareInstanceId: String? = null

    // Retains data session listeners per "conferenceId:streamId" so they stay referenced
    // for the lifetime of the session (mirrors per-conference state retention).
    private val outboundDataSessionListeners = ConcurrentHashMap<String, OutboundDataSessionListener>()
    private val inboundDataSessionListeners = ConcurrentHashMap<String, InboundDataSessionListener>()
    // The SDK's PlanetKitInboundDataSession does not expose its type, so we record the
    // type reported by onDataSessionIncoming to answer getInboundDataSession.
    private val inboundDataSessionTypes = ConcurrentHashMap<String, Int>()

    private fun dataSessionKey(conferenceId: String, streamId: Int): String = "$conferenceId:$streamId"

    companion object {
        val MEDIA_PROJECTION_REQUEST_CODE get() = com.example.planet_kit_flutter.screenshare.PlanetKitScreenShareService.MEDIA_PROJECTION_REQUEST_CODE
    }

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

            // Release any data session state for this conference so sessions
            // still mid-make (or get-created with no listener) cannot leak
            // across successive conferences in a long-lived app.
            val dataSessionPrefix = "${conference.hashCode()}:"
            outboundDataSessionListeners.keys.removeAll { it.startsWith(dataSessionPrefix) }
            inboundDataSessionListeners.keys.removeAll { it.startsWith(dataSessionPrefix) }
            inboundDataSessionTypes.keys.removeAll { it.startsWith(dataSessionPrefix) }

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
                    addedPeer.serviceId,
                    addedPeer.isDataSessionSupported
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

    override fun onMyScreenShareStoppedByHold(conference: PlanetKitConference) {
        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onMyScreenShareStoppedByHold")

            val eventData = ConferenceEvents.MyScreenShareStoppedByHoldEvent(
                conference.hashCode().toString(),
            )

            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }


    override fun onPeersSharedContentsSet(
        conference: PlanetKitConference,
        params: List<PlanetKitConferencePeerSetSharedContentsParam>
    ) {
        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onPeersSharedContentsSet")
            var contents: MutableList<ConferenceEvents.SharedContentsEventData> = mutableListOf()

            for (param in params) {
                val content = ConferenceEvents.SharedContentsEventData(
                    param.peer.hashCode().toString(),
                    Base64.encodeToString(param.data, Base64.NO_WRAP),
                    param.elapsedAfterSetMs
                )
                contents.add(content)
            }

            val eventData = ConferenceEvents.PeersSharedContentsSetEvent(
                conference.hashCode().toString(),
                contents
            )
            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }

    override fun onPeersSharedContentsUnset(
        conference: PlanetKitConference,
        peers: List<PlanetKitConferencePeer>
    ) {
        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onPeersSharedContentsUnset")
            var peerIds: MutableList<String> = mutableListOf()

            for (peer in peers) {
                peerIds.add(peer.hashCode().toString())
            }

            val eventData = ConferenceEvents.PeersSharedContentsUnsetEvent(
                conference.hashCode().toString(),
                peerIds
            )
            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }

    override fun onPeerExclusivelySharedContentsSet(
        conference: PlanetKitConference,
        peer: PlanetKitConferencePeer,
        data: ByteArray,
        elapsed: Long
    ) {
        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onPeerExclusivelySharedContentsSet")
            // `elapsed` is milliseconds on PlanetKit Android; forwarded as-is to
            // the Dart `elapsedMillis` field (iOS converts its seconds value to ms).
            val eventData = ConferenceEvents.PeerExclusivelySharedContentsSetEvent(
                conference.hashCode().toString(),
                peer.hashCode().toString(),
                Base64.encodeToString(data, Base64.NO_WRAP),
                elapsed
            )
            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }

    override fun onPeerExclusivelySharedContentsUnset(
        conference: PlanetKitConference,
        peer: PlanetKitConferencePeer
    ) {
        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onPeerExclusivelySharedContentsUnset")
            val eventData = ConferenceEvents.PeerExclusivelySharedContentsUnsetEvent(
                conference.hashCode().toString(),
                peer.hashCode().toString()
            )
            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }

    override fun onPeerRoomSharedContentsSet(
        conference: PlanetKitConference,
        peer: PlanetKitUser,
        data: ByteArray,
        elapsed: Long
    ) {
        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onPeerRoomSharedContentsSet")
            // `elapsed` is milliseconds on PlanetKit Android; forwarded as-is to
            // the Dart `elapsedMillis` field (iOS converts its seconds value to ms).
            val eventData = ConferenceEvents.PeerRoomSharedContentsSetEvent(
                conference.hashCode().toString(),
                peer.userId,
                peer.serviceId,
                Base64.encodeToString(data, Base64.NO_WRAP),
                elapsed
            )
            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }

    override fun onPeerRoomSharedContentsUnset(
        conference: PlanetKitConference,
        peer: PlanetKitUser
    ) {
        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onPeerRoomSharedContentsUnset")
            val eventData = ConferenceEvents.PeerRoomSharedContentsUnsetEvent(
                conference.hashCode().toString(),
                peer.userId,
                peer.serviceId
            )
            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }

    override fun onShortDataReceived(
        conference: PlanetKitConference,
        sender: PlanetKitUser,
        shortData: PlanetKitShortData
    ) {
        Handler(Looper.getMainLooper()).post {
            Log.d("FlutterPlugin", "onShortDataReceived")

            val eventData = ConferenceEvents.ShortDataReceivedEvent(
                conference.hashCode().toString(),
                sender.userId,
                sender.serviceId,
                shortData.type ?: "",
                Base64.encodeToString(shortData.data, Base64.NO_WRAP)
            )

            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }

    override fun onDataSessionIncoming(
        conference: PlanetKitConference,
        subgroupName: String?,
        streamId: Int,
        type: PlanetKitDataSessionType
    ) {
        Log.d("FlutterPlugin", "onDataSessionIncoming $streamId subgroup=$subgroupName")
        // Flutter does not expose subgroups; ignore subgroup data sessions (out of scope).
        if (!subgroupName.isNullOrEmpty()) {
            Log.d("FlutterPlugin", "ignoring subgroup data session incoming")
            return
        }
        inboundDataSessionTypes[dataSessionKey(conference.hashCode().toString(), streamId)] =
            PlanetKitFlutterDataSessionTypes.typeToInt(type)
        Handler(Looper.getMainLooper()).post {
            val eventData = ConferenceEvents.DataSessionIncomingEvent(
                conference.hashCode().toString(),
                streamId,
                PlanetKitFlutterDataSessionTypes.typeToInt(type)
            )
            val json = gson.toJson(eventData)
            eventStreamHandler.eventSink?.success(json)
        }
    }

    fun makeOutboundDataSession(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "makeOutboundDataSession")
        val args = call.arguments<Map<String, Any?>>()
        val id = args?.get("id") as? String
        val streamId = (args?.get("streamId") as? Number)?.toInt()
        val typeInt = (args?.get("type") as? Number)?.toInt()

        if (id == null || streamId == null || typeInt == null) {
            Log.e("FlutterPlugin", "makeOutboundDataSession invalid arguments")
            result.success(PlanetKitFlutterDataSessionTypes.failReasonToInt(PlanetKitDataSessionFailReason.INTERNAL))
            return
        }

        val conference = nativeInstances.get(id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "makeOutboundDataSession conference not found $id")
            result.success(PlanetKitFlutterDataSessionTypes.failReasonToInt(PlanetKitDataSessionFailReason.INTERNAL))
            return
        }

        val key = dataSessionKey(id, streamId)
        val resultHolder = SingleResult(result)
        val listener = object : OutboundDataSessionListener {
            override fun onSessionMade(session: PlanetKitOutboundDataSession) {
                Log.d("FlutterPlugin", "outbound onSessionMade $streamId")
                resultHolder.success(PlanetKitFlutterDataSessionTypes.failReasonToInt(PlanetKitDataSessionFailReason.NONE))
            }

            override fun onError(reason: PlanetKitDataSessionFailReason) {
                Log.d("FlutterPlugin", "outbound onError $streamId $reason")
                outboundDataSessionListeners.remove(key)
                resultHolder.success(PlanetKitFlutterDataSessionTypes.failReasonToInt(reason))
            }

            override fun onTooLongQueueData(
                session: PlanetKitOutboundDataSession,
                enabled: Boolean
            ) {
                Handler(Looper.getMainLooper()).post {
                    val eventData = ConferenceEvents.DataSessionOutboundTooLongQueuedDataEvent(
                        id,
                        session.streamId,
                        enabled
                    )
                    val json = gson.toJson(eventData)
                    eventStreamHandler.eventSink?.success(json)
                }
            }

            override fun onClosed(
                session: PlanetKitOutboundDataSession,
                reason: PlanetKitDataSessionClosedReason
            ) {
                Log.d("FlutterPlugin", "outbound onClosed ${session.streamId} $reason")
                outboundDataSessionListeners.remove(key)
                Handler(Looper.getMainLooper()).post {
                    val eventData = ConferenceEvents.DataSessionOutboundClosedEvent(
                        id,
                        session.streamId,
                        PlanetKitFlutterDataSessionTypes.closedReasonToInt(reason)
                    )
                    val json = gson.toJson(eventData)
                    eventStreamHandler.eventSink?.success(json)
                }
            }
        }

        outboundDataSessionListeners[key] = listener
        conference.makeOutboundDataSession(
            streamId,
            PlanetKitFlutterDataSessionTypes.typeFromInt(typeInt),
            listener
        )
    }

    fun makeInboundDataSession(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "makeInboundDataSession")
        val args = call.arguments<Map<String, Any?>>()
        val id = args?.get("id") as? String
        val streamId = (args?.get("streamId") as? Number)?.toInt()

        if (id == null || streamId == null) {
            Log.e("FlutterPlugin", "makeInboundDataSession invalid arguments")
            result.success(PlanetKitFlutterDataSessionTypes.failReasonToInt(PlanetKitDataSessionFailReason.INTERNAL))
            return
        }

        val conference = nativeInstances.get(id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "makeInboundDataSession conference not found $id")
            result.success(PlanetKitFlutterDataSessionTypes.failReasonToInt(PlanetKitDataSessionFailReason.INTERNAL))
            return
        }

        val key = dataSessionKey(id, streamId)
        val resultHolder = SingleResult(result)
        val listener = object : InboundDataSessionListener {
            override fun onSessionMade(session: PlanetKitInboundDataSession) {
                Log.d("FlutterPlugin", "inbound onSessionMade $streamId")
                resultHolder.success(PlanetKitFlutterDataSessionTypes.failReasonToInt(PlanetKitDataSessionFailReason.NONE))
            }

            override fun onError(reason: PlanetKitDataSessionFailReason) {
                Log.d("FlutterPlugin", "inbound onError $streamId $reason")
                inboundDataSessionListeners.remove(key)
                inboundDataSessionTypes.remove(key)
                resultHolder.success(PlanetKitFlutterDataSessionTypes.failReasonToInt(reason))
            }

            override fun onDataReceived(
                session: PlanetKitInboundDataSession,
                peer: PlanetKitUser,
                data: ByteBuffer,
                timestamp: Long,
                offset: Long
            ) {
                val bytes = ByteArray(data.remaining())
                data.get(bytes)
                Handler(Looper.getMainLooper()).post {
                    val eventData = ConferenceEvents.DataSessionInboundReceivedEvent(
                        id,
                        session.streamId,
                        peer.userId,
                        peer.serviceId,
                        Base64.encodeToString(bytes, Base64.NO_WRAP),
                        timestamp,
                        offset
                    )
                    val json = gson.toJson(eventData)
                    eventStreamHandler.eventSink?.success(json)
                }
            }

            override fun onClosed(
                session: PlanetKitInboundDataSession,
                reason: PlanetKitDataSessionClosedReason
            ) {
                Log.d("FlutterPlugin", "inbound onClosed ${session.streamId} $reason")
                inboundDataSessionListeners.remove(key)
                inboundDataSessionTypes.remove(key)
                Handler(Looper.getMainLooper()).post {
                    val eventData = ConferenceEvents.DataSessionInboundClosedEvent(
                        id,
                        session.streamId,
                        PlanetKitFlutterDataSessionTypes.closedReasonToInt(reason)
                    )
                    val json = gson.toJson(eventData)
                    eventStreamHandler.eventSink?.success(json)
                }
            }
        }

        inboundDataSessionListeners[key] = listener
        conference.makeInboundDataSession(streamId, listener)
    }

    fun unsupportInboundDataSession(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "unsupportInboundDataSession")
        val args = call.arguments<Map<String, Any?>>()
        val id = args?.get("id") as? String
        val streamId = (args?.get("streamId") as? Number)?.toInt()

        if (id == null || streamId == null) {
            Log.e("FlutterPlugin", "unsupportInboundDataSession invalid arguments")
            result.success(false)
            return
        }

        val conference = nativeInstances.get(id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "unsupportInboundDataSession conference not found $id")
            result.success(false)
            return
        }

        val key = dataSessionKey(id, streamId)
        inboundDataSessionListeners.remove(key)
        inboundDataSessionTypes.remove(key)
        result.success(conference.unsupportInboundDataSession(streamId))
    }

    fun getOutboundDataSession(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "getOutboundDataSession")
        val args = call.arguments<Map<String, Any?>>()
        val id = args?.get("id") as? String
        val streamId = (args?.get("streamId") as? Number)?.toInt()

        if (id == null || streamId == null) {
            Log.e("FlutterPlugin", "getOutboundDataSession invalid arguments")
            result.success(null)
            return
        }

        val conference = nativeInstances.get(id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "getOutboundDataSession conference not found $id")
            result.success(null)
            return
        }

        val session = conference.getOutboundDataSession(streamId)
        if (session == null) {
            result.success(null)
            return
        }
        result.success(PlanetKitFlutterDataSessionTypes.typeToInt(session.type))
    }

    fun getInboundDataSession(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "getInboundDataSession")
        val args = call.arguments<Map<String, Any?>>()
        val id = args?.get("id") as? String
        val streamId = (args?.get("streamId") as? Number)?.toInt()

        if (id == null || streamId == null) {
            Log.e("FlutterPlugin", "getInboundDataSession invalid arguments")
            result.success(null)
            return
        }

        val conference = nativeInstances.get(id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "getInboundDataSession conference not found $id")
            result.success(null)
            return
        }

        val session = conference.getInboundDataSession(streamId)
        if (session == null) {
            result.success(null)
            return
        }
        // PlanetKitInboundDataSession does not expose its type; fall back to the type
        // recorded from onDataSessionIncoming for this stream.
        result.success(inboundDataSessionTypes[dataSessionKey(id, streamId)])
    }

    fun dataSessionSend(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "dataSessionSend")
        val args = call.arguments<Map<String, Any?>>()
        val id = args?.get("id") as? String
        val streamId = (args?.get("streamId") as? Number)?.toInt()
        val data = args?.get("data") as? ByteArray
        val timestamp = (args?.get("timestamp") as? Number)?.toLong()

        if (id == null || streamId == null || data == null || timestamp == null) {
            Log.e("FlutterPlugin", "dataSessionSend invalid arguments")
            result.success(false)
            return
        }

        val conference = nativeInstances.get(id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "dataSessionSend conference not found $id")
            result.success(false)
            return
        }

        val session = conference.getOutboundDataSession(streamId)
        if (session == null) {
            Log.e("FlutterPlugin", "dataSessionSend outbound data session not found $streamId")
            result.success(false)
            return
        }

        result.success(session.send(ByteBuffer.wrap(data), timestamp))
    }

    fun dataSessionChangeDestination(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "dataSessionChangeDestination")
        val args = call.arguments<Map<String, Any?>>()
        val id = args?.get("id") as? String
        val streamId = (args?.get("streamId") as? Number)?.toInt()
        val peerUserId = args?.get("peerUserId") as? String
        val peerServiceId = args?.get("peerServiceId") as? String

        if (id == null || streamId == null) {
            Log.e("FlutterPlugin", "dataSessionChangeDestination invalid arguments")
            result.success(false)
            return
        }

        val conference = nativeInstances.get(id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "dataSessionChangeDestination conference not found $id")
            result.success(false)
            return
        }

        val session = conference.getOutboundDataSession(streamId)
        if (session == null) {
            Log.e("FlutterPlugin", "dataSessionChangeDestination outbound data session not found $streamId")
            result.success(false)
            return
        }

        val peer = if (peerUserId != null && peerServiceId != null) {
            PlanetKitUser(peerUserId, peerServiceId)
        } else {
            null
        }

        val ret = session.changeDestination(peer, null) { res ->
            if (!res.isSuccessful) {
                Log.e("FlutterPlugin", "dataSessionChangeDestination failed")
            }
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.e("FlutterPlugin", "dataSessionChangeDestination platform api returned $ret")
            result.success(false)
        }
    }

    fun sendShortData(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "sendShortData ${call.method}")

        val args = call.arguments<Map<String, Any?>>()
        if (args == null) {
            Log.e("FlutterPlugin", "sendShortData invalid arguments")
            result.success(false)
            return
        }

        val id = args["id"] as? String
        val type = args["type"] as? String
        val data = args["data"] as? ByteArray

        if (id == null || type == null || data == null) {
            Log.e("FlutterPlugin", "sendShortData invalid arguments")
            result.success(false)
            return
        }

        val conference = nativeInstances.get(id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "sendShortData conference not found $id")
            result.success(false)
            return
        }

        val ret = conference.sendShortData(type, data, null) { res ->
            if (!res.isSuccessful) {
                Log.e("FlutterPlugin", "sendShortData failed")
            }
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.e("FlutterPlugin", "sendShortData platform api returned $ret")
            result.success(false)
        }
    }

    fun sendShortDataToPeer(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "sendShortDataToPeer ${call.method}")

        val args = call.arguments<Map<String, Any?>>()
        if (args == null) {
            Log.e("FlutterPlugin", "sendShortDataToPeer invalid arguments")
            result.success(false)
            return
        }

        val id = args["id"] as? String
        val type = args["type"] as? String
        val data = args["data"] as? ByteArray

        @Suppress("UNCHECKED_CAST")
        val peerId = args["peerId"] as? Map<String, Any?>
        val peerUserId = peerId?.get("userId") as? String
        val peerServiceId = peerId?.get("serviceId") as? String

        if (id == null || type == null || data == null ||
            peerUserId == null || peerServiceId == null
        ) {
            Log.e("FlutterPlugin", "sendShortDataToPeer invalid arguments")
            result.success(false)
            return
        }

        val conference = nativeInstances.get(id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "sendShortDataToPeer conference not found $id")
            result.success(false)
            return
        }

        val target = PlanetKitUser(peerUserId, peerServiceId)

        val ret = conference.sendShortData(target, type, data, null) { res ->
            if (!res.isSuccessful) {
                Log.e("FlutterPlugin", "sendShortDataToPeer failed")
            }
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.e("FlutterPlugin", "sendShortDataToPeer platform api returned $ret")
            result.success(false)
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

    fun startMyScreenShare(
        call: MethodCall,
        result: MethodChannel.Result,
        activity: Activity?
    ) {
        Log.d("FlutterPlugin", "startMyScreenShare conference ${call.arguments}")
        val conferenceId = call.arguments<String>() as String
        val conference = nativeInstances.get(conferenceId) as? PlanetKitConference

        if (conference == null) {
            Log.d("FlutterPlugin", "failed to find the conference for $conferenceId")
            result.success(false)
            return
        }

        if (activity == null) {
            Log.e("FlutterPlugin", "startMyScreenShare: activity is null")
            result.success(false)
            return
        }

        if (pendingScreenShareResult != null) {
            Log.e("FlutterPlugin", "startMyScreenShare: another request is pending")
            result.success(false)
            return
        }

        pendingScreenShareResult = result
        pendingScreenShareInstanceId = conferenceId

        val projectionManager = activity.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        activity.startActivityForResult(projectionManager.createScreenCaptureIntent(), MEDIA_PROJECTION_REQUEST_CODE)
    }

    fun onMediaProjectionResult(resultCode: Int, data: Intent?, context: Context) {
        val result = pendingScreenShareResult
        val instanceId = pendingScreenShareInstanceId
        pendingScreenShareResult = null
        pendingScreenShareInstanceId = null

        if (result == null) return

        if (resultCode != Activity.RESULT_OK || data == null || instanceId == null) {
            result.success(false)
            return
        }

        PlanetKitScreenShareService.onStartedCallbacks[instanceId] = { success ->
            Handler(Looper.getMainLooper()).post { result.success(success) }
        }

        val intent = Intent(context, PlanetKitScreenShareService::class.java).apply {
            putExtra(PlanetKitScreenShareService.EXTRA_RESULT_CODE, resultCode)
            putExtra(PlanetKitScreenShareService.EXTRA_RESULT_DATA, data)
            putExtra(PlanetKitScreenShareService.EXTRA_INSTANCE_ID, instanceId)
            putExtra(PlanetKitScreenShareService.EXTRA_IS_CONFERENCE, true)
        }
        try {
            context.startForegroundService(intent)
        } catch (e: Exception) {
            Log.e("FlutterPlugin", "startMyScreenShare: failed to start foreground service", e)
            PlanetKitScreenShareService.onStartedCallbacks.remove(instanceId)
            result.success(false)
        }
    }

    fun stopMyScreenShare(
        call: MethodCall,
        result: MethodChannel.Result,
        context: Context
    ) {
        Log.d("FlutterPlugin", "stopMyScreenShare conference ${call.arguments}")

        // Cancel any consent still in flight so an accept after stop cannot start capture.
        cancelPendingScreenShare()

        val conferenceId = call.arguments<String>() as String
        val conference = nativeInstances.get(conferenceId) as? PlanetKitConference

        if (conference == null) {
            Log.d("FlutterPlugin", "failed to find the conference for $conferenceId")
            result.success(false)
            return
        }

        conference.stopMyScreenShare()
        context.stopService(Intent(context, PlanetKitScreenShareService::class.java))
        result.success(true)
    }

    fun setSharedContents(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "setSharedContents")
        val args = call.arguments<Map<String, Any>>()
        val id = args?.get("id") as? String
        val data = args?.get("data") as? ByteArray

        if (id == null || data == null) {
            Log.e("FlutterPlugin", "setSharedContents invalid arguments")
            result.success(false)
            return
        }

        val conference = nativeInstances.get(id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "setSharedContents conference not found $id")
            result.success(false)
            return
        }

        val ret = conference.setSharedContents(data, null) { res ->
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.e("FlutterPlugin", "setSharedContents platform api returned $ret")
            result.success(false)
        }
    }

    fun unsetSharedContents(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "unsetSharedContents")
        val id = call.arguments as String
        val conference = nativeInstances.get(id) as? PlanetKitConference

        if (conference == null) {
            Log.e("FlutterPlugin", "unsetSharedContents conference not found $id")
            result.success(false)
            return
        }

        val ret = conference.unsetSharedContents(null) { res ->
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.e("FlutterPlugin", "unsetSharedContents platform api returned $ret")
            result.success(false)
        }
    }

    fun setExclusivelySharedContents(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "setExclusivelySharedContents")
        val args = call.arguments<Map<String, Any>>()
        val id = args?.get("id") as? String
        val data = args?.get("data") as? ByteArray

        if (id == null || data == null) {
            Log.e("FlutterPlugin", "setExclusivelySharedContents invalid arguments")
            result.success(false)
            return
        }

        val conference = nativeInstances.get(id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "setExclusivelySharedContents conference not found $id")
            result.success(false)
            return
        }

        val ret = conference.setExclusivelySharedContents(data, null) { res ->
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.e("FlutterPlugin", "setExclusivelySharedContents platform api returned $ret")
            result.success(false)
        }
    }

    fun unsetExclusivelySharedContents(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "unsetExclusivelySharedContents")
        val id = call.arguments as String
        val conference = nativeInstances.get(id) as? PlanetKitConference

        if (conference == null) {
            Log.e("FlutterPlugin", "unsetExclusivelySharedContents conference not found $id")
            result.success(false)
            return
        }

        val ret = conference.unsetExclusivelySharedContents(null) { res ->
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.e("FlutterPlugin", "unsetExclusivelySharedContents platform api returned $ret")
            result.success(false)
        }
    }

    fun setRoomSharedContents(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "setRoomSharedContents")
        val args = call.arguments<Map<String, Any>>()
        val id = args?.get("id") as? String
        val data = args?.get("data") as? ByteArray

        if (id == null || data == null) {
            Log.e("FlutterPlugin", "setRoomSharedContents invalid arguments")
            result.success(false)
            return
        }

        val conference = nativeInstances.get(id) as? PlanetKitConference
        if (conference == null) {
            Log.e("FlutterPlugin", "setRoomSharedContents conference not found $id")
            result.success(false)
            return
        }

        val ret = conference.setRoomSharedContents(data, null) { res ->
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.e("FlutterPlugin", "setRoomSharedContents platform api returned $ret")
            result.success(false)
        }
    }

    fun unsetRoomSharedContents(call: MethodCall, result: MethodChannel.Result) {
        Log.d("FlutterPlugin", "unsetRoomSharedContents")
        val id = call.arguments as String
        val conference = nativeInstances.get(id) as? PlanetKitConference

        if (conference == null) {
            Log.e("FlutterPlugin", "unsetRoomSharedContents conference not found $id")
            result.success(false)
            return
        }

        val ret = conference.unsetRoomSharedContents(null) { res ->
            result.success(res.isSuccessful)
        }

        if (!ret) {
            Log.e("FlutterPlugin", "unsetRoomSharedContents platform api returned $ret")
            result.success(false)
        }
    }

    fun cancelPendingScreenShare() {
        pendingScreenShareResult?.success(false)
        pendingScreenShareResult = null
        pendingScreenShareInstanceId = null
    }
}