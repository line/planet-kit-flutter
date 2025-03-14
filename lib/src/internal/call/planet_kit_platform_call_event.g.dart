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

part of 'planet_kit_platform_call_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CallEvent _$CallEventFromJson(Map<String, dynamic> json) => CallEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
    );

DisconnectedEvent _$DisconnectedEventFromJson(Map<String, dynamic> json) =>
    DisconnectedEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      const PlanetKitDisconnectReasonConverter()
          .fromJson((json['disconnectReason'] as num).toInt()),
      const PlanetKitDisconnectSourceConverter()
          .fromJson((json['disconnectSource'] as num).toInt()),
      json['userCode'] as String?,
      json['byRemote'] as bool,
    );

NetworkDidUnavailableEvent _$NetworkDidUnavailableEventFromJson(
        Map<String, dynamic> json) =>
    NetworkDidUnavailableEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      json['isPeer'] as bool,
      (json['willDisconnectSec'] as num).toInt(),
    );

NetworkDidReavailableEvent _$NetworkDidReavailableEventFromJson(
        Map<String, dynamic> json) =>
    NetworkDidReavailableEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      json['isPeer'] as bool,
    );

ConnectedEvent _$ConnectedEventFromJson(Map<String, dynamic> json) =>
    ConnectedEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      json['isInResponderPreparation'] as bool,
      json['shouldFinishPreparation'] as bool,
    );

VerifiedEvent _$VerifiedEventFromJson(Map<String, dynamic> json) =>
    VerifiedEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      json['peerUseResponderPreparation'] as bool,
    );

PeerHoldEvent _$PeerHoldEventFromJson(Map<String, dynamic> json) =>
    PeerHoldEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      json['reason'] as String?,
    );

MyAudioMuteRequestByPeerEvent _$MyAudioMuteRequestByPeerEventFromJson(
        Map<String, dynamic> json) =>
    MyAudioMuteRequestByPeerEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      json['mute'] as bool,
    );

PeerVideoDidPauseEvent _$PeerVideoDidPauseEventFromJson(
        Map<String, dynamic> json) =>
    PeerVideoDidPauseEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      const PlanetKitVideoPauseReasonConverter()
          .fromJson((json['reason'] as num).toInt()),
    );

VideoDisabledByPeerEvent _$VideoDisabledByPeerEventFromJson(
        Map<String, dynamic> json) =>
    VideoDisabledByPeerEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      const PlanetKitMediaDisableReasonConverter()
          .fromJson((json['reason'] as num).toInt()),
    );

PeerDidStartScreenShareEvent _$PeerDidStartScreenShareEventFromJson(
        Map<String, dynamic> json) =>
    PeerDidStartScreenShareEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
    );

PeerDidStopScreenShareEvent _$PeerDidStopScreenShareEventFromJson(
        Map<String, dynamic> json) =>
    PeerDidStopScreenShareEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
    );

PeerAudioDescriptionUpdateEvent _$PeerAudioDescriptionUpdateEventFromJson(
        Map<String, dynamic> json) =>
    PeerAudioDescriptionUpdateEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      (json['averageVolumeLevel'] as num).toInt(),
    );
