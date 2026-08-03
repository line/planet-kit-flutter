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
import '../../public/planet_kit_types.dart';
import 'planet_kit_platform_call_event_type.dart';
import '../planet_kit_platform_base64_converter.dart';
import '../planet_kit_platform_event.dart';
import '../planet_kit_platform_event_types.dart';
import '../planet_kit_platform_base64_converter.dart';
import '../../public/planet_kit_disconnect_reason.dart';
import '../../public/planet_kit_disconnect_source.dart';

part 'planet_kit_platform_call_event.g.dart';

class CallEventFactory {
  static CallEvent fromJson(Map<String, dynamic> data) {
    final event = CallEvent.fromJson(data);
    final type = event.subType;

    if (type == CallEventType.connected) {
      return ConnectedEvent.fromJson(data);
    } else if (type == CallEventType.disconnected) {
      return DisconnectedEvent.fromJson(data);
    } else if (type == CallEventType.verified) {
      return VerifiedEvent.fromJson(data);
    } else if (type == CallEventType.networkDidUnavailable) {
      return NetworkDidUnavailableEvent.fromJson(data);
    } else if (type == CallEventType.networkDidReavailable) {
      return NetworkDidReavailableEvent.fromJson(data);
    } else if (type == CallEventType.peerHold) {
      return PeerHoldEvent.fromJson(data);
    } else if (type == CallEventType.muteMyAudioRequestByPeer) {
      return MyAudioMuteRequestByPeerEvent.fromJson(data);
    } else if (type == CallEventType.peerVideoDidPause) {
      return PeerVideoDidPauseEvent.fromJson(data);
    } else if (type == CallEventType.videoDisabledByPeer) {
      return VideoDisabledByPeerEvent.fromJson(data);
    } else if (type == CallEventType.peerDidStartScreenShare) {
      return PeerDidStartScreenShareEvent.fromJson(data);
    } else if (type == CallEventType.peerDidStopScreenShare) {
      return PeerDidStopScreenShareEvent.fromJson(data);
    } else if (type == CallEventType.peerAudioDescriptionUpdate) {
      return PeerAudioDescriptionUpdateEvent.fromJson(data);
    } else if (type == CallEventType.peerSharedContentsSet) {
      return PeerSharedContentsSetEvent.fromJson(data);
    } else if (type == CallEventType.peerExclusivelySharedContentsSet) {
      return PeerExclusivelySharedContentsSetEvent.fromJson(data);
    } else if (type == CallEventType.adoptBackgroundCall) {
      return AdoptBackgroundCallEvent.fromJson(data);
    } else if (type == CallEventType.shortDataReceived) {
      return ShortDataReceivedEvent.fromJson(data);
    } else if (type == CallEventType.dataSessionIncoming) {
      return DataSessionIncomingEvent.fromJson(data);
    } else if (type == CallEventType.dataSessionInboundReceived) {
      return DataSessionInboundReceivedEvent.fromJson(data);
    } else if (type == CallEventType.dataSessionInboundClosed) {
      return DataSessionInboundClosedEvent.fromJson(data);
    } else if (type == CallEventType.dataSessionOutboundClosed) {
      return DataSessionOutboundClosedEvent.fromJson(data);
    } else if (type == CallEventType.dataSessionOutboundTooLongQueuedData) {
      return DataSessionOutboundTooLongQueuedDataEvent.fromJson(data);
    } else {
      return event;
    }
  }
}

@JsonSerializable(createToJson: false)
class CallEvent extends Event {
  @CallEventTypeConverter()
  CallEventType subType;

  CallEvent(EventType type, String id, this.subType)
      : super(type: type, id: id);

  factory CallEvent.fromJson(Map<String, dynamic> json) =>
      _$CallEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class DisconnectedEvent extends CallEvent {
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
class NetworkDidUnavailableEvent extends CallEvent {
  final bool isPeer;
  final int willDisconnectSec;

  NetworkDidUnavailableEvent(
      super.type, super.id, super.subType, this.isPeer, this.willDisconnectSec);

  factory NetworkDidUnavailableEvent.fromJson(Map<String, dynamic> json) =>
      _$NetworkDidUnavailableEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class NetworkDidReavailableEvent extends CallEvent {
  final bool isPeer;

  NetworkDidReavailableEvent(super.type, super.id, super.subType, this.isPeer);

  factory NetworkDidReavailableEvent.fromJson(Map<String, dynamic> json) =>
      _$NetworkDidReavailableEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class ConnectedEvent extends CallEvent {
  final bool isInResponderPreparation;
  final bool shouldFinishPreparation;

  /// Whether the data session feature is supported on this connected call.
  /// Defaults to false for compatibility with native builds that predate this
  /// field.
  @JsonKey(defaultValue: false)
  final bool isDataSessionSupported;

  ConnectedEvent(super.type, super.id, super.subType,
      this.isInResponderPreparation, this.shouldFinishPreparation,
      this.isDataSessionSupported);

  factory ConnectedEvent.fromJson(Map<String, dynamic> json) =>
      _$ConnectedEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class VerifiedEvent extends CallEvent {
  final bool peerUseResponderPreparation;
  VerifiedEvent(
      super.type, super.id, super.subType, this.peerUseResponderPreparation);

  factory VerifiedEvent.fromJson(Map<String, dynamic> json) =>
      _$VerifiedEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class PeerHoldEvent extends CallEvent {
  final String? reason;
  PeerHoldEvent(super.type, super.id, super.subType, this.reason);

  factory PeerHoldEvent.fromJson(Map<String, dynamic> json) =>
      _$PeerHoldEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class MyAudioMuteRequestByPeerEvent extends CallEvent {
  final bool mute;
  MyAudioMuteRequestByPeerEvent(super.type, super.id, super.subType, this.mute);

  factory MyAudioMuteRequestByPeerEvent.fromJson(Map<String, dynamic> json) =>
      _$MyAudioMuteRequestByPeerEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class PeerVideoDidPauseEvent extends CallEvent {
  @PlanetKitVideoPauseReasonConverter()
  final PlanetKitVideoPauseReason reason;

  PeerVideoDidPauseEvent(super.type, super.id, super.subType, this.reason);

  factory PeerVideoDidPauseEvent.fromJson(Map<String, dynamic> json) =>
      _$PeerVideoDidPauseEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class VideoDisabledByPeerEvent extends CallEvent {
  @PlanetKitMediaDisableReasonConverter()
  final PlanetKitMediaDisableReason reason;
  VideoDisabledByPeerEvent(super.type, super.id, super.subType, this.reason);

  factory VideoDisabledByPeerEvent.fromJson(Map<String, dynamic> json) =>
      _$VideoDisabledByPeerEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class PeerDidStartScreenShareEvent extends CallEvent {
  PeerDidStartScreenShareEvent(super.type, super.id, super.subType);

  factory PeerDidStartScreenShareEvent.fromJson(Map<String, dynamic> json) =>
      _$PeerDidStartScreenShareEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class PeerDidStopScreenShareEvent extends CallEvent {
  PeerDidStopScreenShareEvent(super.type, super.id, super.subType);

  factory PeerDidStopScreenShareEvent.fromJson(Map<String, dynamic> json) =>
      _$PeerDidStopScreenShareEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class PeerAudioDescriptionUpdateEvent extends CallEvent {
  final int averageVolumeLevel;
  PeerAudioDescriptionUpdateEvent(
      super.type, super.id, super.subType, this.averageVolumeLevel);

  factory PeerAudioDescriptionUpdateEvent.fromJson(Map<String, dynamic> json) =>
      _$PeerAudioDescriptionUpdateEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class AdoptBackgroundCallEvent extends CallEvent {
  AdoptBackgroundCallEvent(super.type, super.id, super.subType);

  factory AdoptBackgroundCallEvent.fromJson(Map<String, dynamic> json) =>
      _$AdoptBackgroundCallEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class PeerSharedContentsSetEvent extends CallEvent {
  @Base64DataConverter()
  final Uint8List data;
  final int elapsedMillis;

  PeerSharedContentsSetEvent(
      super.type, super.id, super.subType, this.data, this.elapsedMillis);

  factory PeerSharedContentsSetEvent.fromJson(Map<String, dynamic> json) =>
      _$PeerSharedContentsSetEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class PeerExclusivelySharedContentsSetEvent extends CallEvent {
  @Base64DataConverter()
  final Uint8List data;
  final int elapsedMillis;

  PeerExclusivelySharedContentsSetEvent(
      super.type, super.id, super.subType, this.data, this.elapsedMillis);

  factory PeerExclusivelySharedContentsSetEvent.fromJson(
          Map<String, dynamic> json) =>
      _$PeerExclusivelySharedContentsSetEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class ShortDataReceivedEvent extends CallEvent {
  final String dataType;

  @Base64DataConverter()
  final Uint8List data;

  ShortDataReceivedEvent(
      super.type, super.id, super.subType, this.dataType, this.data);

  factory ShortDataReceivedEvent.fromJson(Map<String, dynamic> json) =>
      _$ShortDataReceivedEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class DataSessionIncomingEvent extends CallEvent {
  final int streamId;
  final int dataSessionType;

  DataSessionIncomingEvent(
      super.type, super.id, super.subType, this.streamId, this.dataSessionType);

  factory DataSessionIncomingEvent.fromJson(Map<String, dynamic> json) =>
      _$DataSessionIncomingEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class DataSessionInboundReceivedEvent extends CallEvent {
  final int streamId;

  // Peer is serialized as flat userId/serviceId to match the existing inbound
  // event convention (e.g. conference shortDataReceived / shared-contents).
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
class DataSessionInboundClosedEvent extends CallEvent {
  final int streamId;
  final int closedReason;

  DataSessionInboundClosedEvent(
      super.type, super.id, super.subType, this.streamId, this.closedReason);

  factory DataSessionInboundClosedEvent.fromJson(Map<String, dynamic> json) =>
      _$DataSessionInboundClosedEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class DataSessionOutboundClosedEvent extends CallEvent {
  final int streamId;
  final int closedReason;

  DataSessionOutboundClosedEvent(
      super.type, super.id, super.subType, this.streamId, this.closedReason);

  factory DataSessionOutboundClosedEvent.fromJson(Map<String, dynamic> json) =>
      _$DataSessionOutboundClosedEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class DataSessionOutboundTooLongQueuedDataEvent extends CallEvent {
  final int streamId;
  final bool enabled;

  DataSessionOutboundTooLongQueuedDataEvent(
      super.type, super.id, super.subType, this.streamId, this.enabled);

  factory DataSessionOutboundTooLongQueuedDataEvent.fromJson(
          Map<String, dynamic> json) =>
      _$DataSessionOutboundTooLongQueuedDataEventFromJson(json);
}