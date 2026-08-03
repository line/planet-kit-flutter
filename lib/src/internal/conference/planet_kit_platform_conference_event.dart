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

import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import '../planet_kit_platform_base64_converter.dart';
import '../planet_kit_platform_event.dart';
import '../planet_kit_platform_event_types.dart';
import '../planet_kit_platform_base64_converter.dart';
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
    } else if (type == ConferenceEventType.peersSharedContentsSet) {
      return PeersSharedContentsSetEvent.fromJson(data);
    } else if (type == ConferenceEventType.peersSharedContentsUnset) {
      return PeersSharedContentsUnsetEvent.fromJson(data);
    } else if (type == ConferenceEventType.peerExclusivelySharedContentsSet) {
      return PeerExclusivelySharedContentsSetEvent.fromJson(data);
    } else if (type == ConferenceEventType.peerExclusivelySharedContentsUnset) {
      return PeerExclusivelySharedContentsUnsetEvent.fromJson(data);
    } else if (type == ConferenceEventType.peerRoomSharedContentsSet) {
      return PeerRoomSharedContentsSetEvent.fromJson(data);
    } else if (type == ConferenceEventType.peerRoomSharedContentsUnset) {
      return PeerRoomSharedContentsUnsetEvent.fromJson(data);
    } else if (type == ConferenceEventType.shortDataReceived) {
      return ShortDataReceivedEvent.fromJson(data);
    } else if (type == ConferenceEventType.dataSessionIncoming) {
      return DataSessionIncomingEvent.fromJson(data);
    } else if (type == ConferenceEventType.dataSessionInboundReceived) {
      return DataSessionInboundReceivedEvent.fromJson(data);
    } else if (type == ConferenceEventType.dataSessionInboundClosed) {
      return DataSessionInboundClosedEvent.fromJson(data);
    } else if (type == ConferenceEventType.dataSessionOutboundClosed) {
      return DataSessionOutboundClosedEvent.fromJson(data);
    } else if (type ==
        ConferenceEventType.dataSessionOutboundTooLongQueuedData) {
      return DataSessionOutboundTooLongQueuedDataEvent.fromJson(data);
    } else {
      // No-payload events (e.g. connected, networkReavailable,
      // myScreenShareStoppedByHold) fall through as the base ConferenceEvent;
      // the public layer dispatches on subType alone.
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

  final String? userCode;
  final bool byRemote;

  DisconnectedEvent(super.type, super.id, super.subType, this.disconnectReason,
      this.disconnectSource, this.userCode, this.byRemote);

  factory DisconnectedEvent.fromJson(Map<String, dynamic> json) =>
      _$DisconnectedEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class InitialPeerInfo {
  final String id;
  final String userId;
  final String serviceId;

  /// Whether the peer supports the data session feature. Defaults to false for
  /// compatibility with native builds that predate this field.
  @JsonKey(defaultValue: false)
  final bool isDataSessionSupported;

  InitialPeerInfo(
      {required this.id,
      required this.userId,
      required this.serviceId,
      this.isDataSessionSupported = false});
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

@JsonSerializable(createToJson: false)
class PeerSharedContentsEventData {
  final String peer;

  @Base64DataConverter()
  final Uint8List data;

  final int elapsedMillis;

  PeerSharedContentsEventData(
      {required this.peer, required this.data, required this.elapsedMillis});

  factory PeerSharedContentsEventData.fromJson(Map<String, dynamic> json) =>
      _$PeerSharedContentsEventDataFromJson(json);
}

@JsonSerializable(createToJson: false)
class PeersSharedContentsSetEvent extends ConferenceEvent {
  final List<PeerSharedContentsEventData> contents;
  PeersSharedContentsSetEvent(
      super.type, super.id, super.subType, this.contents);

  factory PeersSharedContentsSetEvent.fromJson(Map<String, dynamic> json) =>
      _$PeersSharedContentsSetEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class PeersSharedContentsUnsetEvent extends ConferenceEvent {
  final List<String> peers;
  PeersSharedContentsUnsetEvent(
      super.type, super.id, super.subType, this.peers);

  factory PeersSharedContentsUnsetEvent.fromJson(Map<String, dynamic> json) =>
      _$PeersSharedContentsUnsetEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class PeerExclusivelySharedContentsSetEvent extends ConferenceEvent {
  final String peer;

  @Base64DataConverter()
  final Uint8List data;

  final int elapsedMillis;

  PeerExclusivelySharedContentsSetEvent(super.type, super.id, super.subType,
      this.peer, this.data, this.elapsedMillis);

  factory PeerExclusivelySharedContentsSetEvent.fromJson(
          Map<String, dynamic> json) =>
      _$PeerExclusivelySharedContentsSetEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class PeerExclusivelySharedContentsUnsetEvent extends ConferenceEvent {
  final String peer;
  PeerExclusivelySharedContentsUnsetEvent(
      super.type, super.id, super.subType, this.peer);

  factory PeerExclusivelySharedContentsUnsetEvent.fromJson(
          Map<String, dynamic> json) =>
      _$PeerExclusivelySharedContentsUnsetEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class PeerRoomSharedContentsSetEvent extends ConferenceEvent {
  final String userId;
  final String serviceId;

  @Base64DataConverter()
  final Uint8List data;

  final int elapsedMillis;

  PeerRoomSharedContentsSetEvent(super.type, super.id, super.subType,
      this.userId, this.serviceId, this.data, this.elapsedMillis);

  factory PeerRoomSharedContentsSetEvent.fromJson(Map<String, dynamic> json) =>
      _$PeerRoomSharedContentsSetEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class PeerRoomSharedContentsUnsetEvent extends ConferenceEvent {
  final String userId;
  final String serviceId;

  PeerRoomSharedContentsUnsetEvent(
      super.type, super.id, super.subType, this.userId, this.serviceId);

  factory PeerRoomSharedContentsUnsetEvent.fromJson(
          Map<String, dynamic> json) =>
      _$PeerRoomSharedContentsUnsetEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class ShortDataReceivedEvent extends ConferenceEvent {
  final String userId;
  final String serviceId;
  final String dataType;

  @Base64DataConverter()
  final Uint8List data;

  ShortDataReceivedEvent(super.type, super.id, super.subType, this.userId,
      this.serviceId, this.dataType, this.data);

  factory ShortDataReceivedEvent.fromJson(Map<String, dynamic> json) =>
      _$ShortDataReceivedEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class DataSessionIncomingEvent extends ConferenceEvent {
  final int streamId;
  final int dataSessionType;

  DataSessionIncomingEvent(
      super.type, super.id, super.subType, this.streamId, this.dataSessionType);

  factory DataSessionIncomingEvent.fromJson(Map<String, dynamic> json) =>
      _$DataSessionIncomingEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class DataSessionInboundReceivedEvent extends ConferenceEvent {
  final int streamId;
  final String userId;
  final String serviceId;

  @Base64DataConverter()
  final Uint8List data;

  final int timestamp;
  final int offset;

  DataSessionInboundReceivedEvent(super.type, super.id, super.subType,
      this.streamId, this.userId, this.serviceId, this.data, this.timestamp,
      this.offset);

  factory DataSessionInboundReceivedEvent.fromJson(Map<String, dynamic> json) =>
      _$DataSessionInboundReceivedEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class DataSessionInboundClosedEvent extends ConferenceEvent {
  final int streamId;
  final int closedReason;

  DataSessionInboundClosedEvent(
      super.type, super.id, super.subType, this.streamId, this.closedReason);

  factory DataSessionInboundClosedEvent.fromJson(Map<String, dynamic> json) =>
      _$DataSessionInboundClosedEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class DataSessionOutboundClosedEvent extends ConferenceEvent {
  final int streamId;
  final int closedReason;

  DataSessionOutboundClosedEvent(
      super.type, super.id, super.subType, this.streamId, this.closedReason);

  factory DataSessionOutboundClosedEvent.fromJson(Map<String, dynamic> json) =>
      _$DataSessionOutboundClosedEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class DataSessionOutboundTooLongQueuedDataEvent extends ConferenceEvent {
  final int streamId;
  final bool enabled;

  DataSessionOutboundTooLongQueuedDataEvent(
      super.type, super.id, super.subType, this.streamId, this.enabled);

  factory DataSessionOutboundTooLongQueuedDataEvent.fromJson(
          Map<String, dynamic> json) =>
      _$DataSessionOutboundTooLongQueuedDataEventFromJson(json);
}
