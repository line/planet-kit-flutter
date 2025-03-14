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

part of 'planet_kit_platform_conference_params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$HoldConferenceParamToJson(
        HoldConferenceParam instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reason': instance.reason,
    };

Map<String, dynamic> _$MuteMuAudioParamToJson(MuteMuAudioParam instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mute': instance.mute,
    };

Map<String, dynamic> _$RequestPeerMuteParamToJson(
        RequestPeerMuteParam instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mute': instance.mute,
      'peerId': instance.peerId.toJson(),
    };

Map<String, dynamic> _$RequestPeersMuteParamToJson(
        RequestPeersMuteParam instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mute': instance.mute,
    };

Map<String, dynamic> _$SilencePeersAudioParamToJson(
        SilencePeersAudioParam instance) =>
    <String, dynamic>{
      'id': instance.id,
      'silent': instance.silent,
    };

Map<String, dynamic> _$SpeakerOutParamToJson(SpeakerOutParam instance) =>
    <String, dynamic>{
      'id': instance.id,
      'speakerOut': instance.speakerOut,
    };

Map<String, dynamic> _$CreatePeerControlParamToJson(
        CreatePeerControlParam instance) =>
    <String, dynamic>{
      'conferenceId': instance.conferenceId,
      'peerId': instance.peerId,
    };

Map<String, dynamic> _$AddMyVideoViewParamToJson(
        AddMyVideoViewParam instance) =>
    <String, dynamic>{
      'conferenceId': instance.conferenceId,
      'viewId': instance.viewId,
    };

Map<String, dynamic> _$RemoveMyVideoViewParamToJson(
        RemoveMyVideoViewParam instance) =>
    <String, dynamic>{
      'conferenceId': instance.conferenceId,
      'viewId': instance.viewId,
    };

Map<String, dynamic> _$EnableVideoParamToJson(EnableVideoParam instance) =>
    <String, dynamic>{
      'conferenceId': instance.conferenceId,
      'initialMyVideoState': const PlanetKitInitialMyVideoStateConverter()
          .toJson(instance.initialMyVideoState),
    };
