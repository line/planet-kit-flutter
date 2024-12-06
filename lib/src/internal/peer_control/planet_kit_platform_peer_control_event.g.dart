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

part of 'planet_kit_platform_peer_control_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PeerControlEvent _$PeerControlEventFromJson(Map<String, dynamic> json) =>
    PeerControlEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const PeerControlEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
    );

HoldEvent _$HoldEventFromJson(Map<String, dynamic> json) => HoldEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const PeerControlEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      json['reason'] as String?,
    );

UpdateAudioDescriptionEvent _$UpdateAudioDescriptionEventFromJson(
        Map<String, dynamic> json) =>
    UpdateAudioDescriptionEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const PeerControlEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      (json['averageVolumeLevel'] as num).toInt(),
    );

UpdateVideoEvent _$UpdateVideoEventFromJson(Map<String, dynamic> json) =>
    UpdateVideoEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const PeerControlEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      PlanetKitVideoStatus.fromJson(json['status'] as Map<String, dynamic>),
    );

UpdateScreenShareEvent _$UpdateScreenShareEventFromJson(
        Map<String, dynamic> json) =>
    UpdateScreenShareEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const PeerControlEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      const PlanetKitScreenShareStateConverter()
          .fromJson((json['state'] as num).toInt()),
    );
