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

CallEventData _$CallEventDataFromJson(Map<String, dynamic> json) =>
    CallEventData(
      const EventTypeConverter().fromJson(json['type'] as int),
      json['id'] as String,
      const CallEventTypeConverter().fromJson(json['callEventType'] as int),
    );

Map<String, dynamic> _$CallEventDataToJson(CallEventData instance) =>
    <String, dynamic>{
      'type': const EventTypeConverter().toJson(instance.type),
      'id': instance.id,
      'callEventType':
          const CallEventTypeConverter().toJson(instance.callEventType),
    };

DisconnectedEventData _$DisconnectedEventDataFromJson(
        Map<String, dynamic> json) =>
    DisconnectedEventData(
      const EventTypeConverter().fromJson(json['type'] as int),
      json['id'] as String,
      const CallEventTypeConverter().fromJson(json['callEventType'] as int),
      const PlanetKitDisconnectReasonConverter()
          .fromJson(json['disconnectReason'] as int),
      const PlanetKitDisconnectSourceConverter()
          .fromJson(json['disconnectSource'] as int),
      json['byRemote'] as bool,
    );

Map<String, dynamic> _$DisconnectedEventDataToJson(
        DisconnectedEventData instance) =>
    <String, dynamic>{
      'type': const EventTypeConverter().toJson(instance.type),
      'id': instance.id,
      'callEventType':
          const CallEventTypeConverter().toJson(instance.callEventType),
      'disconnectReason': const PlanetKitDisconnectReasonConverter()
          .toJson(instance.disconnectReason),
      'disconnectSource': const PlanetKitDisconnectSourceConverter()
          .toJson(instance.disconnectSource),
      'byRemote': instance.byRemote,
    };
