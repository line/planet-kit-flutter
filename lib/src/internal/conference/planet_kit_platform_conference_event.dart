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

import 'package:json_annotation/json_annotation.dart';
import '../planet_kit_platform_event.dart';
import '../planet_kit_platform_event_types.dart';
import '../../public/planet_kit_disconnect_reason.dart';
import '../../public/planet_kit_disconnect_source.dart';
import 'planet_kit_platform_conference_event_type.dart';

part 'planet_kit_platform_conference_event.g.dart';

class ConferenceEventFactory {
  static ConferenceEvent fromJson(Map<String, dynamic> data) {
    final event = ConferenceEvent.fromJson(data);
    final type = event.subType;

    if (type == ConferenceEventType.disconnected) {
      return DisconnectedEvent.fromJson(data);
    } else if (type == ConferenceEventType.peerListUpdate) {
      return PeerListUpdateEvent.fromJson(data);
    } else if (type == ConferenceEventType.peersMicMute) {
      return PeersMicMuteEvent.fromJson(data);
    } else if (type == ConferenceEventType.peersMicUnmute) {
      return PeersMicUnmuteEvent.fromJson(data);
    } else if (type == ConferenceEventType.peersHold) {
      return PeersHoldEvent.fromJson(data);
    } else if (type == ConferenceEventType.peersUnhold) {
      return PeersUnholdEvent.fromJson(data);
    } else if (type == ConferenceEventType.networkUnavailable) {
      return NetworkDidUnavailableEvent.fromJson(data);
    } else if (type == ConferenceEventType.myAudioMuteRequestedByPeer) {
      return MyAudioMuteRequestedByPeerEvent.fromJson(data);
    } else {
      return event;
    }
  }
}

@JsonSerializable(createToJson: false)
class ConferenceEvent extends Event {
  @ConferenceEventTypeConverter()
  ConferenceEventType subType;

  ConferenceEvent(EventType type, String id, this.subType)
      : super(type: type, id: id);

  factory ConferenceEvent.fromJson(Map<String, dynamic> json) =>
      _$ConferenceEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class DisconnectedEvent extends ConferenceEvent {
  @PlanetKitDisconnectReasonConverter()
  final PlanetKitDisconnectReason disconnectReason;

  @PlanetKitDisconnectSourceConverter()
  final PlanetKitDisconnectSource disconnectSource;

  final bool byRemote;

  DisconnectedEvent(super.type, super.id, super.subType, this.disconnectReason,
      this.disconnectSource, this.byRemote);

  factory DisconnectedEvent.fromJson(Map<String, dynamic> json) =>
      _$DisconnectedEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class InitialPeerInfo {
  final String id;
  final String userId;
  final String serviceId;

  InitialPeerInfo(
      {required this.id, required this.userId, required this.serviceId});
  factory InitialPeerInfo.fromJson(Map<String, dynamic> json) =>
      _$InitialPeerInfoFromJson(json);
}

@JsonSerializable(createToJson: false)
class PeerListUpdateEvent extends ConferenceEvent {
  final List<InitialPeerInfo> added;
  final List<String> removed;
  final int totalPeersCount;

  PeerListUpdateEvent(super.type, super.id, super.subType, this.added,
      this.removed, this.totalPeersCount);

  factory PeerListUpdateEvent.fromJson(Map<String, dynamic> json) =>
      _$PeerListUpdateEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class NetworkDidUnavailableEvent extends ConferenceEvent {
  final int willDisconnectSec;

  NetworkDidUnavailableEvent(
      super.type, super.id, super.subType, this.willDisconnectSec);

  factory NetworkDidUnavailableEvent.fromJson(Map<String, dynamic> json) =>
      _$NetworkDidUnavailableEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class PeerHoldEventData {
  String peer;
  String? reason;
  PeerHoldEventData({required this.peer, required this.reason});

  factory PeerHoldEventData.fromJson(Map<String, dynamic> json) =>
      _$PeerHoldEventDataFromJson(json);
}

@JsonSerializable(createToJson: false)
class PeersHoldEvent extends ConferenceEvent {
  final List<PeerHoldEventData> peers;
  PeersHoldEvent(super.type, super.id, super.subType, this.peers);

  factory PeersHoldEvent.fromJson(Map<String, dynamic> json) =>
      _$PeersHoldEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class PeersUnholdEvent extends ConferenceEvent {
  final List<String> peers;
  PeersUnholdEvent(super.type, super.id, super.subType, this.peers);

  factory PeersUnholdEvent.fromJson(Map<String, dynamic> json) =>
      _$PeersUnholdEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class MyAudioMuteRequestedByPeerEvent extends ConferenceEvent {
  final String peer;
  final bool mute;
  MyAudioMuteRequestedByPeerEvent(
      super.type, super.id, super.subType, this.peer, this.mute);

  factory MyAudioMuteRequestedByPeerEvent.fromJson(Map<String, dynamic> json) =>
      _$MyAudioMuteRequestedByPeerEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class PeersMicMuteEvent extends ConferenceEvent {
  final List<String> peers;
  PeersMicMuteEvent(super.type, super.id, super.subType, this.peers);

  factory PeersMicMuteEvent.fromJson(Map<String, dynamic> json) =>
      _$PeersMicMuteEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class PeersMicUnmuteEvent extends ConferenceEvent {
  final List<String> peers;
  PeersMicUnmuteEvent(super.type, super.id, super.subType, this.peers);

  factory PeersMicUnmuteEvent.fromJson(Map<String, dynamic> json) =>
      _$PeersMicUnmuteEventFromJson(json);
}
