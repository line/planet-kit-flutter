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

part of 'planet_kit_init_param.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanetKitInitParam _$PlanetKitInitParamFromJson(Map<String, dynamic> json) =>
    PlanetKitInitParam(
      logSetting: PlanetKitLogSetting.fromJson(
          json['logSetting'] as Map<String, dynamic>),
      serverUrl: json['serverUrl'] as String,
    );

Map<String, dynamic> _$PlanetKitInitParamToJson(PlanetKitInitParam instance) =>
    <String, dynamic>{
      'logSetting': instance.logSetting.toJson(),
      'serverUrl': instance.serverUrl,
    };

PlanetKitLogSetting _$PlanetKitLogSettingFromJson(Map<String, dynamic> json) =>
    PlanetKitLogSetting(
      enabled: json['enabled'] as bool,
      logLevel:
          const PlanetKitLogLevelConverter().fromJson(json['logLevel'] as int),
      logSizeLimit: const PlanetKitLogSizeLimitConverter()
          .fromJson(json['logSizeLimit'] as int),
    );

Map<String, dynamic> _$PlanetKitLogSettingToJson(
        PlanetKitLogSetting instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'logLevel': const PlanetKitLogLevelConverter().toJson(instance.logLevel),
      'logSizeLimit':
          const PlanetKitLogSizeLimitConverter().toJson(instance.logSizeLimit),
    };
