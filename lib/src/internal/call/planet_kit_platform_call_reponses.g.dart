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

part of 'planet_kit_platform_call_reponses.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MakeCallResponse _$MakeCallResponseFromJson(Map<String, dynamic> json) =>
    MakeCallResponse(
      callId: json['callId'] as String?,
      failReason: const PlanetKitStartFailReasonConverter()
          .fromJson((json['failReason'] as num).toInt()),
    );

VerifyCallResponse _$VerifyCallResponseFromJson(Map<String, dynamic> json) =>
    VerifyCallResponse(
      callId: json['callId'] as String?,
      failReason: const PlanetKitStartFailReasonConverter()
          .fromJson((json['failReason'] as num).toInt()),
    );

CreateCCParamResponse _$CreateCCParamResponseFromJson(
        Map<String, dynamic> json) =>
    CreateCCParamResponse(
      id: json['id'] as String,
      peerId: json['peerId'] as String?,
      peerServiceId: json['peerServiceId'] as String?,
      mediaType: const PlanetKitMediaTypeConverter()
          .fromJson((json['mediaType'] as num).toInt()),
    );
