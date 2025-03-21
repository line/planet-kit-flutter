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

part of 'planet_kit_join_conference_param.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$PlanetKitJoinConferenceParamToJson(
        PlanetKitJoinConferenceParam instance) =>
    <String, dynamic>{
      'myUserId': instance.myUserId,
      'myServiceId': instance.myServiceId,
      'roomId': instance.roomId,
      'roomServiceId': instance.roomServiceId,
      'accessToken': instance.accessToken,
      'endTonePath': instance.endTonePath,
      'allowConferenceWithoutMic': instance.allowConferenceWithoutMic,
      'allowConferenceWithoutMicPermission':
          instance.allowConferenceWithoutMicPermission,
      'enableAudioDescription': instance.enableAudioDescription,
      'audioDescriptionUpdateIntervalMs':
          instance.audioDescriptionUpdateIntervalMs,
      'mediaType':
          const PlanetKitMediaTypeConverter().toJson(instance.mediaType),
      'callKitType':
          const PlanetKitCallKitTypeConverter().toJson(instance.callKitType),
      'enableStatistics': instance.enableStatistics,
      'screenShareKey': instance.screenShareKey?.toJson(),
      'initialMyVideoState': const PlanetKitInitialMyVideoStateConverter()
          .toJson(instance.initialMyVideoState),
    };
