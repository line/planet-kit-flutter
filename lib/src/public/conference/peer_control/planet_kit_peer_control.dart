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
import '../../../internal/peer_control/planet_kit_platform_peer_control_event.dart';
import '../../../internal/peer_control/planet_kit_platform_peer_control_event_types.dart';
import '../../../internal/planet_kit_platform_interface.dart';
import '../../../internal/planet_kit_platform_resource_manager.dart';

/// Event handler to process peer events such as microphone mute/unmute and hold/unhold.
class PlanetKitPeerControlHandler {
  /// Called when the peer's microphone is muted.
  final void Function(PlanetKitPeerControl control)? onMicMute;

  /// Called when the peer's microphone is unmuted.
  final void Function(PlanetKitPeerControl control)? onMicUnmute;

  /// Called when the peer is put on hold with an optional reason.
  final void Function(PlanetKitPeerControl control, String? reason)? onHold;

  /// Called when the peer is taken off hold.
  final void Function(PlanetKitPeerControl control)? onUnhold;

  /// Called when the peer is disconnected.
  final void Function(PlanetKitPeerControl control)? onDisconnect;

  /// Called when there is an update on the peer's audio description, such as volume level changes.
  final void Function(PlanetKitPeerControl control, int averageVolumeLevel)?
      onAudioDescriptionUpdate;

  /// Constructor for [PlanetKitPeerControlHandler].
  PlanetKitPeerControlHandler(
      {required this.onMicMute,
      required this.onMicUnmute,
      required this.onHold,
      required this.onUnhold,
      required this.onDisconnect,
      required this.onAudioDescriptionUpdate});
}

/// Interface to manage a specific peer within a conference session.
class PlanetKitPeerControl {
  /// @nodoc
  final String id;
  PlanetKitPeerControlHandler? _handler;
  StreamSubscription<PeerControlEvent>? _subscription;

  /// @nodoc
  PlanetKitPeerControl({required this.id}) {
    NativeResourceManager.instance.add(this, id);
    _subscription = Platform.instance.eventManager.onPeerControlEvent
        .listen(_onPeerControlEvent);
  }

  /// Registers the handler for peer control event.
  Future<bool> register(PlanetKitPeerControlHandler handler) async {
    final result = await Platform.instance.peerControlInterface.register(id);
    if (result) {
      _handler = handler;
    }
    return result;
  }

  /// Unregisters the handler for peer control event.
  Future<bool> unregister() async {
    final result = await Platform.instance.peerControlInterface.unregister(id);
    if (result) {
      _handler = null;
    }

    return result;
  }

  /// @nodoc
  void _onPeerControlEvent(PeerControlEvent event) {
    if (event.id != this.id) {
      print("#flutter_kit_peer_control event not for current instance");
      return;
    }
    if (event.subType == PeerControlEventType.micMute) {
      _handler?.onMicMute?.call(this);
    } else if (event.subType == PeerControlEventType.micUnmute) {
      _handler?.onMicUnmute?.call(this);
    } else if (event.subType == PeerControlEventType.hold) {
      _handleHold(event);
    } else if (event.subType == PeerControlEventType.unhold) {
      _handler?.onUnhold?.call(this);
    } else if (event.subType == PeerControlEventType.disconnect) {
      _handler?.onDisconnect?.call(this);
    } else if (event.subType == PeerControlEventType.audioDescriptionUpdate) {
      _handleAudioDescriptionUpdate(event);
    }
  }

  /// @nodoc
  void _handleHold(PeerControlEvent peerControlEvent) {
    final event = peerControlEvent as HoldEvent;
    _handler?.onHold?.call(this, event.reason);
  }

  /// @nodoc
  void _handleAudioDescriptionUpdate(PeerControlEvent peerControlEvent) {
    final event = peerControlEvent as UpdateAudioDescriptionEvent;
    _handler?.onAudioDescriptionUpdate?.call(this, event.averageVolumeLevel);
  }
}