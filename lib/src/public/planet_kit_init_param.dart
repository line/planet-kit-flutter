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

import 'package:json_annotation/json_annotation.dart';
part 'planet_kit_init_param.g.dart';

@JsonSerializable(explicitToJson: true)
class PlanetKitInitParam {
  final PlanetKitLogSetting logSetting;
  final String serverUrl;
  PlanetKitInitParam({required this.logSetting, required this.serverUrl});

  Map<String, dynamic> toJson() => _$PlanetKitInitParamToJson(this);
}

enum PlanetKitLogLevel {
  silent,
  simple,
  detailed;

  int get intValue {
    switch (this) {
      case PlanetKitLogLevel.silent:
        return 0;
      case PlanetKitLogLevel.simple:
        return 4;
      case PlanetKitLogLevel.detailed:
        return 5;
    }
  }

  static PlanetKitLogLevel fromInt(int value) {
    switch (value) {
      case 0:
        return PlanetKitLogLevel.silent;
      case 4:
        return PlanetKitLogLevel.simple;
      case 5:
        return PlanetKitLogLevel.detailed;
      default:
        throw ArgumentError('Invalid enum value');
    }
  }
}

enum PlanetKitLogSizeLimit {
  small,
  medium,
  large,
  unlimited;

  int get intValue {
    switch (this) {
      case PlanetKitLogSizeLimit.small:
        return 0;
      case PlanetKitLogSizeLimit.medium:
        return 1;
      case PlanetKitLogSizeLimit.large:
        return 2;
      case PlanetKitLogSizeLimit.unlimited:
        return 3;
    }
  }

  static PlanetKitLogSizeLimit fromInt(int value) {
    switch (value) {
      case 0:
        return PlanetKitLogSizeLimit.small;
      case 1:
        return PlanetKitLogSizeLimit.medium;
      case 2:
        return PlanetKitLogSizeLimit.large;
      case 3:
        return PlanetKitLogSizeLimit.unlimited;
      default:
        throw ArgumentError('Invalid enum value');
    }
  }
}

@JsonSerializable()
class PlanetKitLogSetting {
  final bool enabled;

  @PlanetKitLogLevelConverter()
  final PlanetKitLogLevel logLevel;

  @PlanetKitLogSizeLimitConverter()
  final PlanetKitLogSizeLimit logSizeLimit;

  PlanetKitLogSetting({
    required this.enabled,
    required this.logLevel,
    required this.logSizeLimit,
  });

  factory PlanetKitLogSetting.fromJson(Map<String, dynamic> json) =>
      _$PlanetKitLogSettingFromJson(json);

  Map<String, dynamic> toJson() => _$PlanetKitLogSettingToJson(this);
}

// Custom converter for PlanetKitLogLevel
class PlanetKitLogLevelConverter
    implements JsonConverter<PlanetKitLogLevel, int> {
  const PlanetKitLogLevelConverter();

  @override
  PlanetKitLogLevel fromJson(int json) => PlanetKitLogLevel.fromInt(json);

  @override
  int toJson(PlanetKitLogLevel object) => object.intValue;
}

// Custom converter for PlanetKitLogSizeLimit
class PlanetKitLogSizeLimitConverter
    implements JsonConverter<PlanetKitLogSizeLimit, int> {
  const PlanetKitLogSizeLimitConverter();

  @override
  PlanetKitLogSizeLimit fromJson(int json) =>
      PlanetKitLogSizeLimit.fromInt(json);

  @override
  int toJson(PlanetKitLogSizeLimit object) => object.intValue;
}
