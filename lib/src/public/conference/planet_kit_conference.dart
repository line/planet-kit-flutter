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

import '../../internal/conference/planet_kit_platform_conference_event.dart';
import '../../internal/conference/planet_kit_platform_conference_event_type.dart';
import '../../internal/planet_kit_platform_interface.dart';
import '../../internal/planet_kit_platform_resource_manager.dart';
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

/// Manages event callbacks for various conference-related events.
class PlanetKitConferenceEventHandler {
  /// Called when the conference is successfully connected.
  final void Function(PlanetKitConference conference) onConnected;

  /// Called when the conference is disconnected, providing the reason for the disconnection, the source of the disconnection, and whether the disconnection was initiated by the remote user.
  final void Function(
      PlanetKitConference conference,
      PlanetKitDisconnectReason reason,
      PlanetKitDisconnectSource source,
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
      this.onNetworkReavailable});
}

/// Represents a conference session within the PlanetKit system.
class PlanetKitConference {
  /// @nodoc
  final String id;

  /// Media status for the local user in the conference.
  PlanetKitMyMediaStatus myMediaStatus;

  /// List of current peers in the conference.
  List<PlanetKitConferencePeer> peers = [];

  final PlanetKitConferenceEventHandler? _eventHandler;
  StreamSubscription<ConferenceEvent>? _subscription;
  Map<String, PlanetKitConferencePeer> _peerMap = {};

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
  Future<bool> enableVideo() async {
    return await Platform.instance.conferenceInterface.enableVideo(id);
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
    } else {
      print("#planet_kit_conference event unknown");
    }
  }

  void _handlePeerListUpdateEvent(ConferenceEvent conferenceEvent) {
    final event = conferenceEvent as PeerListUpdateEvent;

    List<PlanetKitConferencePeer> removedPeers = [];
    List<PlanetKitConferencePeer> addedPeers = [];

    for (final added in event.added) {
      final peerId =
          PlanetKitUserId(userId: added.userId, serviceId: added.serviceId);
      final peer = PlanetKitConferencePeer(id: added.id, userId: peerId);
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
    _eventHandler?.onDisconnected(
        this, event.disconnectReason, event.disconnectSource, event.byRemote);
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

    _eventHandler?.onPeersMicMuted?.call(this, unmutedPeers);
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

    _eventHandler?.onPeersMicMuted?.call(this, unholdPeers);
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
