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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_platform_conference_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConferenceEvent _$ConferenceEventFromJson(Map<String, dynamic> json) =>
    ConferenceEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
    );

DisconnectedEvent _$DisconnectedEventFromJson(Map<String, dynamic> json) =>
    DisconnectedEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      const PlanetKitDisconnectReasonConverter()
          .fromJson((json['disconnectReason'] as num).toInt()),
      const PlanetKitDisconnectSourceConverter()
          .fromJson((json['disconnectSource'] as num).toInt()),
      json['byRemote'] as bool,
    );

InitialPeerInfo _$InitialPeerInfoFromJson(Map<String, dynamic> json) =>
    InitialPeerInfo(
      id: json['id'] as String,
      userId: json['userId'] as String,
      serviceId: json['serviceId'] as String,
    );

PeerListUpdateEvent _$PeerListUpdateEventFromJson(Map<String, dynamic> json) =>
    PeerListUpdateEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      (json['added'] as List<dynamic>)
          .map((e) => InitialPeerInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['removed'] as List<dynamic>).map((e) => e as String).toList(),
      (json['totalPeersCount'] as num).toInt(),
    );

NetworkDidUnavailableEvent _$NetworkDidUnavailableEventFromJson(
        Map<String, dynamic> json) =>
    NetworkDidUnavailableEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      (json['willDisconnectSec'] as num).toInt(),
    );

PeerHoldEventData _$PeerHoldEventDataFromJson(Map<String, dynamic> json) =>
    PeerHoldEventData(
      peer: json['peer'] as String,
      reason: json['reason'] as String?,
    );

PeersHoldEvent _$PeersHoldEventFromJson(Map<String, dynamic> json) =>
    PeersHoldEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      (json['peers'] as List<dynamic>)
          .map((e) => PeerHoldEventData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

PeersUnholdEvent _$PeersUnholdEventFromJson(Map<String, dynamic> json) =>
    PeersUnholdEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      (json['peers'] as List<dynamic>).map((e) => e as String).toList(),
    );

MyAudioMuteRequestedByPeerEvent _$MyAudioMuteRequestedByPeerEventFromJson(
        Map<String, dynamic> json) =>
    MyAudioMuteRequestedByPeerEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      json['peer'] as String,
      json['mute'] as bool,
    );

PeersMicMuteEvent _$PeersMicMuteEventFromJson(Map<String, dynamic> json) =>
    PeersMicMuteEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      (json['peers'] as List<dynamic>).map((e) => e as String).toList(),
    );

PeersMicUnmuteEvent _$PeersMicUnmuteEventFromJson(Map<String, dynamic> json) =>
    PeersMicUnmuteEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      (json['peers'] as List<dynamic>).map((e) => e as String).toList(),
    );
