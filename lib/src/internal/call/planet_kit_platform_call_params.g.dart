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

part of 'planet_kit_platform_call_params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$AcceptCallParamToJson(AcceptCallParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'useResponderPreparation': instance.useResponderPreparation,
    };

Map<String, dynamic> _$HoldCallParamToJson(HoldCallParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'reason': instance.reason,
    };

Map<String, dynamic> _$PutHookedAudioBackParamToJson(
        PutHookedAudioBackParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'audioId': instance.audioId,
    };

Map<String, dynamic> _$MuteCallParamToJson(MuteCallParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'mute': instance.mute,
    };

Map<String, dynamic> _$RequestPeerMuteParamToJson(
        RequestPeerMuteParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'mute': instance.mute,
    };

Map<String, dynamic> _$SilencePeerAudioParamToJson(
        SilencePeerAudioParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'silent': instance.silent,
    };

CallSpeakerOutParam _$CallSpeakerOutParamFromJson(Map<String, dynamic> json) =>
    CallSpeakerOutParam(
      callId: json['callId'] as String,
      speakerOut: json['speakerOut'] as bool,
    );

Map<String, dynamic> _$CallSpeakerOutParamToJson(
        CallSpeakerOutParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'speakerOut': instance.speakerOut,
    };

EndCallParam _$EndCallParamFromJson(Map<String, dynamic> json) => EndCallParam(
      callId: json['callId'] as String,
      userReleasePhrase: json['userReleasePhrase'] as String?,
    );

Map<String, dynamic> _$EndCallParamToJson(EndCallParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'userReleasePhrase': instance.userReleasePhrase,
    };

EndCallWithErrorParam _$EndCallWithErrorParamFromJson(
        Map<String, dynamic> json) =>
    EndCallWithErrorParam(
      callId: json['callId'] as String,
      userReleasePhrase: json['userReleasePhrase'] as String,
    );

Map<String, dynamic> _$EndCallWithErrorParamToJson(
        EndCallWithErrorParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'userReleasePhrase': instance.userReleasePhrase,
    };
