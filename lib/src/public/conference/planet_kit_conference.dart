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

import 'dart:async';
import 'dart:typed_data';

import 'package:planet_kit_flutter/src/public/planet_kit_types.dart';

import '../../internal/conference/planet_kit_platform_conference_event.dart';
import '../../internal/conference/planet_kit_platform_conference_event_type.dart';
import '../../internal/data_session/planet_kit_data_session_container.dart';
import '../../internal/planet_kit_platform_interface.dart';
import '../../internal/planet_kit_platform_resource_manager.dart';
import '../data_session/planet_kit_data_session.dart';
import '../my_media_status/planet_kit_my_media_status.dart';
import '../planet_kit_disconnect_reason.dart';
import '../planet_kit_disconnect_source.dart';
import '../planet_kit_user_id.dart';
import '../statistics/planet_kit_statistics.dart';
import 'peer_control/planet_kit_peer_control.dart';
import 'planet_kit_conference_peer.dart';

/// Holds the details about the changes in the conference peer list, including added and removed peers.
class PlanetKitConferencePeerListUpdateParam {
  /// Peers that were added to the conference.
  final List<PlanetKitConferencePeer> addedPeers;

  /// Peers that were removed from the conference.
  final List<PlanetKitConferencePeer> removedPeers;

  /// Total number of peers currently in the conference.
  final int totalPeersCount;

  /// @nodoc
  PlanetKitConferencePeerListUpdateParam(
      {required this.addedPeers,
      required this.removedPeers,
      required this.totalPeersCount});
}

/// Represents shared contents set by a peer in a conference.
class PlanetKitConferenceSharedContents {
  /// The conference peer that set the shared contents.
  final PlanetKitConferencePeer peer;

  /// The shared contents data.
  final Uint8List data;

  /// The elapsed time since the shared contents were set.
  final Duration elapsed;

  /// @nodoc
  PlanetKitConferenceSharedContents(
      {required this.peer, required this.data, required this.elapsed});
}

/// Manages event callbacks for various conference-related events.
class PlanetKitConferenceEventHandler {
  /// Called when the conference is successfully connected.
  final void Function(PlanetKitConference conference) onConnected;

  /// Called when the conference is disconnected, providing the reason for the disconnection, the source of the disconnection, and whether the disconnection was initiated by the remote user.
  final void Function(
      PlanetKitConference conference,
      PlanetKitDisconnectReason reason,
      PlanetKitDisconnectSource source,
      String? userCode,
      bool byRemote) onDisconnected;

  /// Called when the peer list in the conference is updated.
  final void Function(PlanetKitConference conference,
      PlanetKitConferencePeerListUpdateParam updateParam) onPeerListUpdated;

  /// Optional callback for when peers in the conference mute their microphone.
  final void Function(
          PlanetKitConference conference, List<PlanetKitConferencePeer> peers)?
      onPeersMicMuted;

  /// Optional callback for when peers in the conference unmute their microphone.
  final void Function(
          PlanetKitConference conference, List<PlanetKitConferencePeer> peers)?
      onPeersMicUnmuted;

  /// Optional callback for when the local user's audio is requested to be muted by a peer.
  final void Function(PlanetKitConference conference,
      PlanetKitConferencePeer peer, bool mute)? onMyAudioMuteRequestedByPeer;

  /// Optional callback for when peers in the conference are put on hold.
  final void Function(PlanetKitConference conference, List<PeerHoldData> peers)?
      onPeersHold;

  /// Optional callback for when peers in the conference are taken off hold.
  final void Function(
          PlanetKitConference conference, List<PlanetKitConferencePeer> peers)?
      onPeersUnhold;

  /// Optional callback for when the network becomes unavailable during the conference.
  final void Function(PlanetKitConference conference, Duration willDisconnect)?
      onNetworkUnavailable;

  /// Optional callback for when the network becomes available again after being unavailable.
  final void Function(PlanetKitConference conference)? onNetworkReavailable;

  /// Optional callback for when peers in the conference set shared contents.
  final void Function(PlanetKitConference conference,
          List<PlanetKitConferenceSharedContents> sharedContents)?
      onPeersSharedContentsSet;

  /// Optional callback for when peers in the conference unset shared contents.
  final void Function(
          PlanetKitConference conference, List<PlanetKitConferencePeer> peers)?
      onPeersSharedContentsUnset;

  /// Optional callback for when a peer in the conference sets exclusively shared contents.
  final void Function(PlanetKitConference conference,
          PlanetKitConferencePeer peer, Uint8List data, Duration elapsed)?
      onPeerExclusivelySharedContentsSet;

  /// Optional callback for when a peer in the conference unsets exclusively shared contents.
  final void Function(
          PlanetKitConference conference, PlanetKitConferencePeer peer)?
      onPeerExclusivelySharedContentsUnset;

  /// Optional callback for when a peer sets room shared contents.
  final void Function(PlanetKitConference conference, PlanetKitUserId peerId,
      Uint8List data, Duration elapsed)? onPeerRoomSharedContentsSet;

  /// Optional callback for when a peer unsets room shared contents.
  final void Function(PlanetKitConference conference, PlanetKitUserId peerId)?
      onPeerRoomSharedContentsUnset;

  /// Optional callback triggered when short data is received from a peer.
  /// Provides the sender's [senderId], the data [type] string, and the binary [data].
  final void Function(PlanetKitConference conference, PlanetKitUserId senderId,
      String type, Uint8List data)? onShortDataReceived;

  /// Optional callback triggered when a peer starts a data session transfer
  /// on a given [streamId] with the given [type].
  ///
  /// In response, create an inbound data session with
  /// [PlanetKitConference.makeInboundDataSession], or ignore it with
  /// [PlanetKitConference.unsupportInboundDataSession].
  final void Function(PlanetKitConference conference,
      PlanetKitDataSessionStreamId streamId, PlanetKitDataSessionType type)?
      onDataSessionIncoming;

  /// Optional callback for when the local user's screen share is stopped because
  /// the conference was put on hold.
  final void Function(PlanetKitConference conference)?
      onMyScreenShareStoppedByHold;

  /// Constructs [PlanetKitConferenceEventHandler].
  PlanetKitConferenceEventHandler(
      {required this.onConnected,
      required this.onDisconnected,
      required this.onPeerListUpdated,
      this.onPeersMicMuted,
      this.onPeersMicUnmuted,
      this.onMyAudioMuteRequestedByPeer,
      this.onPeersHold,
      this.onPeersUnhold,
      this.onNetworkUnavailable,
      this.onNetworkReavailable,
      this.onPeersSharedContentsSet,
      this.onPeersSharedContentsUnset,
      this.onPeerExclusivelySharedContentsSet,
      this.onPeerExclusivelySharedContentsUnset,
      this.onPeerRoomSharedContentsSet,
      this.onPeerRoomSharedContentsUnset,
      this.onShortDataReceived,
      this.onDataSessionIncoming,
      this.onMyScreenShareStoppedByHold});
}

/// Represents a conference session within the PlanetKit system.
class PlanetKitConference {
  /// @nodoc
  final String id;

  /// Media status for the local user in the conference.
  PlanetKitMyMediaStatus myMediaStatus;

  /// List of current peers in the conference.
  List<PlanetKitConferencePeer> peers = [];

  PlanetKitConferenceEventHandler? _eventHandler;
  StreamSubscription<ConferenceEvent>? _subscription;
  final Map<String, PlanetKitConferencePeer> _peerMap = {};
  late final PlanetKitDataSessionContainer _dataSession;

  void _addPeer(PlanetKitConferencePeer peer) {
    peers.add(peer);
    _peerMap[peer.id] = peer;
  }

  PlanetKitConferencePeer? _removePeer(String id) {
    peers.removeWhere((item) => item.id == id);
    return _peerMap.remove(id);
  }

  PlanetKitConferencePeer? _getPeer(String id) {
    return _peerMap[id];
  }

  /// @nodoc
  PlanetKitConference(
      {required this.id,
      required PlanetKitConferenceEventHandler eventHandler,
      required this.myMediaStatus})
      : _eventHandler = eventHandler {
    NativeResourceManager.instance.add(this, id);
    _dataSession = PlanetKitDataSessionContainer(
      makeOutbound: (streamId, type) => Platform.instance.conferenceInterface
          .makeOutboundDataSession(id, streamId, type),
      makeInbound: (streamId) => Platform.instance.conferenceInterface
          .makeInboundDataSession(id, streamId),
      unsupport: (streamId) => Platform.instance.conferenceInterface
          .unsupportInboundDataSession(id, streamId),
      getOutboundType: (streamId) => Platform.instance.conferenceInterface
          .getOutboundDataSessionType(id, streamId),
      getInboundType: (streamId) => Platform.instance.conferenceInterface
          .getInboundDataSessionType(id, streamId),
      send: (streamId, data, timestamp) => Platform.instance.conferenceInterface
          .dataSessionSend(id, streamId, data, timestamp),
      changeDestination: (streamId, target) => Platform
          .instance.conferenceInterface
          .dataSessionChangeDestination(
              id, streamId, target?.userId, target?.serviceId),
    );
    _subscription =
        Platform.instance.eventManager.onConferenceEvent.listen(_onEvent);
  }

  /// Whether the speaker output is currently active.
  Future<bool> get isSpeakerOut async =>
      await Platform.instance.conferenceInterface.isSpeakerOut(id);

  /// Whether the conference is currently on hold.
  Future<bool> get isOnHold async =>
      await Platform.instance.conferenceInterface.isOnHold(id);

  /// Leaves the current conference session.
  Future<bool> leaveConference() async {
    return await Platform.instance.conferenceInterface.leaveConference(id);
  }

  /// Mutes or unmutes the local user's audio in the conference.
  Future<bool> muteMyAudio(bool mute) async {
    return await Platform.instance.conferenceInterface.muteMyAudio(id, mute);
  }

  /// Turns the speaker output on or off.
  Future<bool> speakerOut(bool speakerOut) async {
    return await Platform.instance.conferenceInterface
        .speakerOut(id, speakerOut);
  }

  /// Notifies the system that the local user's audio has been activated.
  Future<bool> notifyCallKitAudioActivation() async {
    return await Platform.instance.conferenceInterface
        .notifyCallKitAudioActivation(id);
  }

  /// Holds the conference with an optional reason.
  Future<bool> hold({String? reason}) async {
    return await Platform.instance.conferenceInterface.hold(id, reason);
  }

  /// Unholds the conference.
  Future<bool> unhold() async {
    return await Platform.instance.conferenceInterface.unhold(id);
  }

  /// Requests mute to a specific peer in the conference.
  Future<bool> requestPeerMute(bool mute, PlanetKitUserId peerId) async {
    return await Platform.instance.conferenceInterface
        .requestPeerMute(id, mute, peerId);
  }

  /// Requests mute to all peers in the conference.
  Future<bool> requestPeersMute(bool mute) async {
    return await Platform.instance.conferenceInterface
        .requestPeersMute(id, mute);
  }

  /// Silences all peers' audio for local playback.
  Future<bool> silencePeersAudio(bool silent) async {
    return await Platform.instance.conferenceInterface
        .silencePeersAudio(id, silent);
  }

  /// Adds the local user's video view.
  Future<bool> addMyVideoView(String viewId) async {
    return await Platform.instance.conferenceInterface
        .addMyVideoView(id, viewId);
  }

  /// Removes the local user's video view.
  Future<bool> removeMyVideoView(String viewId) async {
    return await Platform.instance.conferenceInterface
        .removeMyVideoView(id, viewId);
  }

  /// Enables video in conference.
  Future<bool> enableVideo(
      {PlanetKitInitialMyVideoState initialMyVideoState =
          PlanetKitInitialMyVideoState.resume}) async {
    return await Platform.instance.conferenceInterface
        .enableVideo(id, initialMyVideoState);
  }

  /// Disables video in conference.
  Future<bool> disableVideo() async {
    return await Platform.instance.conferenceInterface.disableVideo(id);
  }

  /// Pauses the local user's video.
  Future<bool> pauseMyVideo() async {
    return await Platform.instance.conferenceInterface.pauseMyVideo(id);
  }

  /// Resumes the local user's video.
  Future<bool> resumeMyVideo() async {
    return await Platform.instance.conferenceInterface.resumeMyVideo(id);
  }

  /// Starts sending the local screen to the conference. Android only — iOS uses
  /// the broadcast extension flow and always returns false from this method.
  Future<bool> startMyScreenShare() async {
    return await Platform.instance.conferenceInterface.startMyScreenShare(id);
  }

  /// Stops sending the local screen to the conference.
  Future<bool> stopMyScreenShare() async {
    return await Platform.instance.conferenceInterface.stopMyScreenShare(id);
  }

  /// Creates a [PlanetKitPeerControl] interface for a specific peer in the conference.
  Future<PlanetKitPeerControl?> createPeerControl(
      PlanetKitConferencePeer peer) async {
    final peerControlId = await Platform.instance.conferenceInterface
        .createPeerControl(id, peer.id);
    PlanetKitPeerControl? peerControl;
    if (peerControlId != null) {
      peerControl = PlanetKitPeerControl(id: peerControlId);
    }
    return peerControl;
  }

  /// Retrieves conference statistics.
  Future<PlanetKitStatistics?> getStatistics() async {
    return await Platform.instance.conferenceInterface.getStatistics(id);
  }

  /// Sets shared contents for the conference.
  Future<bool> setSharedContents(Uint8List data) async {
    return await Platform.instance.conferenceInterface
        .setSharedContents(id, data);
  }

  /// Unsets shared contents for the conference.
  Future<bool> unsetSharedContents() async {
    return await Platform.instance.conferenceInterface.unsetSharedContents(id);
  }

  /// Sets exclusively shared contents for the conference.
  Future<bool> setExclusivelySharedContents(Uint8List data) async {
    return await Platform.instance.conferenceInterface
        .setExclusivelySharedContents(id, data);
  }

  /// Unsets exclusively shared contents for the conference.
  Future<bool> unsetExclusivelySharedContents() async {
    return await Platform.instance.conferenceInterface
        .unsetExclusivelySharedContents(id);
  }

  /// Sets room shared contents for the conference.
  Future<bool> setRoomSharedContents(Uint8List data) async {
    return await Platform.instance.conferenceInterface
        .setRoomSharedContents(id, data);
  }

  /// Unsets room shared contents for the conference.
  Future<bool> unsetRoomSharedContents() async {
    return await Platform.instance.conferenceInterface
        .unsetRoomSharedContents(id);
  }

  /// Broadcasts short data to all peers in the conference with a [type] string
  /// and binary [data].
  ///
  /// Returns whether the send request was accepted. The [type] must be at most
  /// 100 bytes (including the null terminator) and [data] at most 800 bytes.
  /// These limits are enforced by the native SDK; a request that exceeds
  /// them (or is made before the session is connected) resolves to `false`.
  Future<bool> sendShortData(
      {required String type, required Uint8List data}) async {
    return await Platform.instance.conferenceInterface
        .sendShortData(id, type, data);
  }

  /// Sends short data to a single peer identified by [peerId] with a [type]
  /// string and binary [data].
  ///
  /// Returns whether the send request was accepted. The [type] must be at most
  /// 100 bytes (including the null terminator) and [data] at most 800 bytes.
  /// These limits are enforced by the native SDK; a request that exceeds
  /// them (or is made before the session is connected) resolves to `false`.
  Future<bool> sendShortDataToPeer(
      {required PlanetKitUserId peerId,
      required String type,
      required Uint8List data}) async {
    return await Platform.instance.conferenceInterface
        .sendShortDataToPeer(id, peerId, type, data);
  }

  /// Creates an outbound data session for [streamId] with the given [type].
  ///
  /// On success the result carries the created session and
  /// [PlanetKitDataSessionFailReason.none]; on failure it carries a null
  /// session and the fail reason.
  Future<PlanetKitMakeOutboundDataSessionResult> makeOutboundDataSession(
          PlanetKitDataSessionStreamId streamId,
          PlanetKitDataSessionType type,
          PlanetKitOutboundDataSessionHandler handler) =>
      _dataSession.makeOutbound(streamId, type, handler);

  /// Creates an inbound data session for [streamId] that received an
  /// [PlanetKitConferenceEventHandler.onDataSessionIncoming] notification.
  Future<PlanetKitMakeInboundDataSessionResult> makeInboundDataSession(
          PlanetKitDataSessionStreamId streamId,
          PlanetKitInboundDataSessionHandler handler) =>
      _dataSession.makeInbound(streamId, handler);

  /// Marks the inbound data session for [streamId] as unsupported, ignoring
  /// incoming data for that stream.
  ///
  /// The returned bool indicates that the unsupport request was accepted. It is
  /// always `true` on iOS (where the native call returns void) and reflects the
  /// native result on Android. Apps should not branch on this platform-specific
  /// semantic.
  Future<bool> unsupportInboundDataSession(
          PlanetKitDataSessionStreamId streamId) =>
      _dataSession.unsupportInbound(streamId);

  /// Returns the current outbound data session for [streamId], or null.
  Future<PlanetKitOutboundDataSession?> getOutboundDataSession(
          PlanetKitDataSessionStreamId streamId) =>
      _dataSession.getOutbound(streamId);

  /// Returns the current inbound data session for [streamId], or null.
  Future<PlanetKitInboundDataSession?> getInboundDataSession(
          PlanetKitDataSessionStreamId streamId) =>
      _dataSession.getInbound(streamId);

  void _onEvent(ConferenceEvent event) {
    if (event.id != this.id) {
      return;
    }

    print("#flutter_kit_conference event: $event");
    final type = event.subType;

    if (type == ConferenceEventType.connected) {
      _eventHandler?.onConnected(this);
    } else if (type == ConferenceEventType.disconnected) {
      _handleDisconnectedEvent(event);
    } else if (type == ConferenceEventType.peerListUpdate) {
      _handlePeerListUpdateEvent(event);
    } else if (type == ConferenceEventType.peersMicMute) {
      _handlePeersMicMuteEvent(event);
    } else if (type == ConferenceEventType.peersMicUnmute) {
      _handlePeersMicUnmuteEvent(event);
    } else if (type == ConferenceEventType.peersHold) {
      _handlePeersHoldEvent(event);
    } else if (type == ConferenceEventType.peersUnhold) {
      _handlePeersUnholdEvent(event);
    } else if (type == ConferenceEventType.networkUnavailable) {
      _handleNetworkUnavailableEvent(event);
    } else if (type == ConferenceEventType.networkReavailable) {
      _eventHandler?.onNetworkReavailable?.call(this);
    } else if (type == ConferenceEventType.myAudioMuteRequestedByPeer) {
      _handleMyAudioMuteRequestedByPeerEvent(event);
    } else if (type == ConferenceEventType.peersSharedContentsSet) {
      _handlePeersSharedContentsSetEvent(event);
    } else if (type == ConferenceEventType.peersSharedContentsUnset) {
      _handlePeersSharedContentsUnsetEvent(event);
    } else if (type == ConferenceEventType.peerExclusivelySharedContentsSet) {
      _handlePeerExclusivelySharedContentsSetEvent(event);
    } else if (type == ConferenceEventType.peerExclusivelySharedContentsUnset) {
      _handlePeerExclusivelySharedContentsUnsetEvent(event);
    } else if (type == ConferenceEventType.peerRoomSharedContentsSet) {
      _handlePeerRoomSharedContentsSetEvent(event);
    } else if (type == ConferenceEventType.peerRoomSharedContentsUnset) {
      _handlePeerRoomSharedContentsUnsetEvent(event);
    } else if (type == ConferenceEventType.shortDataReceived) {
      _handleShortDataReceivedEvent(event);
    } else if (type == ConferenceEventType.dataSessionIncoming) {
      _handleDataSessionIncomingEvent(event);
    } else if (type == ConferenceEventType.dataSessionInboundReceived) {
      _handleDataSessionInboundReceivedEvent(event);
    } else if (type == ConferenceEventType.dataSessionInboundClosed) {
      _handleDataSessionInboundClosedEvent(event);
    } else if (type == ConferenceEventType.dataSessionOutboundClosed) {
      _handleDataSessionOutboundClosedEvent(event);
    } else if (type ==
        ConferenceEventType.dataSessionOutboundTooLongQueuedData) {
      _handleDataSessionOutboundTooLongQueuedDataEvent(event);
    } else if (type == ConferenceEventType.myScreenShareStoppedByHold) {
      _eventHandler?.onMyScreenShareStoppedByHold?.call(this);
    } else {
      print("#planet_kit_conference event unknown");
    }
  }

  void _handleDataSessionIncomingEvent(ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as DataSessionIncomingEvent;
    final type = PlanetKitDataSessionType.fromInt(event.dataSessionType);
    if (type == null) {
      print("#planet_kit_conference dataSessionIncoming unknown type");
      return;
    }
    _dataSession.recordIncoming(event.streamId, type);
    _eventHandler?.onDataSessionIncoming?.call(this, event.streamId, type);
  }

  void _handleDataSessionInboundReceivedEvent(
      ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as DataSessionInboundReceivedEvent;
    final peerId =
        PlanetKitUserId(userId: event.userId, serviceId: event.serviceId);
    _dataSession.handleInboundReceived(
        event.streamId, peerId, event.data, event.timestamp, event.offset);
  }

  void _handleDataSessionInboundClosedEvent(ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as DataSessionInboundClosedEvent;
    _dataSession.handleInboundClosed(event.streamId,
        PlanetKitDataSessionClosedReason.fromInt(event.closedReason));
  }

  void _handleDataSessionOutboundClosedEvent(ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as DataSessionOutboundClosedEvent;
    _dataSession.handleOutboundClosed(event.streamId,
        PlanetKitDataSessionClosedReason.fromInt(event.closedReason));
  }

  void _handleDataSessionOutboundTooLongQueuedDataEvent(
      ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as DataSessionOutboundTooLongQueuedDataEvent;
    _dataSession.handleOutboundTooLongQueuedData(event.streamId, event.enabled);
  }

  void _handlePeersSharedContentsSetEvent(ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as PeersSharedContentsSetEvent;

    List<PlanetKitConferenceSharedContents> sharedContents = [];

    for (final content in event.contents) {
      final peer = _getPeer(content.peer);
      if (peer != null) {
        sharedContents.add(PlanetKitConferenceSharedContents(
            peer: peer,
            data: content.data,
            elapsed: Duration(milliseconds: content.elapsedMillis)));
      } else {
        print("planet_kit_conference failed to get peer ${content.peer}");
      }
    }

    _eventHandler?.onPeersSharedContentsSet?.call(this, sharedContents);
  }

  void _handlePeersSharedContentsUnsetEvent(ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as PeersSharedContentsUnsetEvent;

    List<PlanetKitConferencePeer> unsetPeers = [];

    for (final peerId in event.peers) {
      final peer = _getPeer(peerId);
      if (peer != null) {
        unsetPeers.add(peer);
      } else {
        print("planet_kit_conference failed to get peer $peerId");
      }
    }

    _eventHandler?.onPeersSharedContentsUnset?.call(this, unsetPeers);
  }

  void _handlePeerExclusivelySharedContentsSetEvent(
      ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as PeerExclusivelySharedContentsSetEvent;

    final peer = _getPeer(event.peer);
    if (peer != null) {
      _eventHandler?.onPeerExclusivelySharedContentsSet?.call(this, peer,
          event.data, Duration(milliseconds: event.elapsedMillis));
    } else {
      print("planet_kit_conference failed to get peer ${event.peer}");
    }
  }

  void _handlePeerExclusivelySharedContentsUnsetEvent(
      ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as PeerExclusivelySharedContentsUnsetEvent;

    final peer = _getPeer(event.peer);
    if (peer != null) {
      _eventHandler?.onPeerExclusivelySharedContentsUnset?.call(this, peer);
    } else {
      print("planet_kit_conference failed to get peer ${event.peer}");
    }
  }

  void _handlePeerRoomSharedContentsSetEvent(ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as PeerRoomSharedContentsSetEvent;

    final peerId =
        PlanetKitUserId(userId: event.userId, serviceId: event.serviceId);
    _eventHandler?.onPeerRoomSharedContentsSet?.call(this, peerId, event.data,
        Duration(milliseconds: event.elapsedMillis));
  }

  void _handlePeerRoomSharedContentsUnsetEvent(ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as PeerRoomSharedContentsUnsetEvent;

    final peerId =
        PlanetKitUserId(userId: event.userId, serviceId: event.serviceId);
    _eventHandler?.onPeerRoomSharedContentsUnset?.call(this, peerId);
  }

  void _handleShortDataReceivedEvent(ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as ShortDataReceivedEvent;
    final senderId =
        PlanetKitUserId(userId: event.userId, serviceId: event.serviceId);
    _eventHandler?.onShortDataReceived
        ?.call(this, senderId, event.dataType, event.data);
  }

  void _handlePeerListUpdateEvent(ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as PeerListUpdateEvent;

    List<PlanetKitConferencePeer> removedPeers = [];
    List<PlanetKitConferencePeer> addedPeers = [];

    for (final added in event.added) {
      final peerId =
          PlanetKitUserId(userId: added.userId, serviceId: added.serviceId);
      final peer = PlanetKitConferencePeer(
          id: added.id,
          userId: peerId,
          isDataSessionSupported: added.isDataSessionSupported);
      addedPeers.add(peer);
      _addPeer(peer);
    }

    for (final removed in event.removed) {
      final removedPeer = _removePeer(removed);
      if (removedPeer != null) {
        removedPeers.add(removedPeer);
      }
    }

    PlanetKitConferencePeerListUpdateParam param =
        PlanetKitConferencePeerListUpdateParam(
            addedPeers: addedPeers,
            removedPeers: removedPeers,
            totalPeersCount: peers.length);
    _eventHandler?.onPeerListUpdated(this, param);
  }

  void _handleDisconnectedEvent(ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as DisconnectedEvent;
    _subscription?.cancel();
    _eventHandler?.onDisconnected(this, event.disconnectReason,
        event.disconnectSource, event.userCode, event.byRemote);
    _eventHandler = null;
    myMediaStatus.dispose();
  }

  void _handlePeersMicMuteEvent(ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as PeersMicMuteEvent;

    List<PlanetKitConferencePeer> mutedPeers = [];

    for (final peerId in event.peers) {
      final peer = _getPeer(peerId);
      if (peer != null) {
        mutedPeers.add(peer);
      } else {
        print("planet_kit_conference failed to get peer $peerId");
      }
    }

    _eventHandler?.onPeersMicMuted?.call(this, mutedPeers);
  }

  void _handlePeersMicUnmuteEvent(ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as PeersMicUnmuteEvent;

    List<PlanetKitConferencePeer> unmutedPeers = [];

    for (final peerId in event.peers) {
      final peer = _getPeer(peerId);
      if (peer != null) {
        unmutedPeers.add(peer);
      } else {
        print("planet_kit_conference failed to get peer $peerId");
      }
    }

    _eventHandler?.onPeersMicUnmuted?.call(this, unmutedPeers);
  }

  void _handlePeersHoldEvent(ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as PeersHoldEvent;

    List<PeerHoldData> holdData = [];

    for (final holdEventData in event.peers) {
      final peer = _getPeer(holdEventData.peer);
      if (peer != null) {
        holdData
            .add(PeerHoldData(peer: peer, holdReason: holdEventData.reason));
      } else {
        print("planet_kit_conference failed to get peer ${holdEventData.peer}");
      }
    }

    _eventHandler?.onPeersHold?.call(this, holdData);
  }

  void _handlePeersUnholdEvent(ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as PeersUnholdEvent;

    List<PlanetKitConferencePeer> unholdPeers = [];

    for (final peerId in event.peers) {
      final peer = _getPeer(peerId);
      if (peer != null) {
        unholdPeers.add(peer);
      } else {
        print("planet_kit_conference failed to get peer $peerId");
      }
    }

    _eventHandler?.onPeersUnhold?.call(this, unholdPeers);
  }

  void _handleNetworkUnavailableEvent(ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as NetworkDidUnavailableEvent;

    _eventHandler?.onNetworkUnavailable
        ?.call(this, Duration(seconds: event.willDisconnectSec));
  }

  void _handleMyAudioMuteRequestedByPeerEvent(ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as MyAudioMuteRequestedByPeerEvent;

    final peer = _getPeer(event.peer);
    if (peer != null) {
      _eventHandler?.onMyAudioMuteRequestedByPeer?.call(this, peer, event.mute);
    } else {
      print("planet_kit_conference failed to get peer ${event.peer}");
    }
  }
}

/// Represents data about a peer being held in a conference.
class PeerHoldData {
  /// The conference peer that is currently on hold.
  final PlanetKitConferencePeer peer;

  /// Optional reason why the peer is on hold.
  final String? holdReason;

  /// @nodoc
  PeerHoldData({required this.peer, required this.holdReason});
}
