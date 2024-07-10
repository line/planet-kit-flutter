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

/// Parameter class for the PlanetKit initialization.
///
/// This class encapsulates initialization settings related to logging and server configuration.
@JsonSerializable(explicitToJson: true, createFactory: false)
class PlanetKitInitParam {
  /// Configuration settings for logging.
  final PlanetKitLogSetting logSetting;

  /// The server URL for PlanetKit.
  /// ref: https://docs.lineplanet.me/getting-started/essentials/development-environment
  final String serverUrl;

  /// Constructs a [PlanetKitInitParam] with specified log settings and server URL.
  PlanetKitInitParam({required this.logSetting, required this.serverUrl});

  /// @nodoc
  Map<String, dynamic> toJson() => _$PlanetKitInitParamToJson(this);
}

/// Defines the log level settings.
enum PlanetKitLogLevel {
  /// No logs are recorded.
  silent,

  /// Basic logs are recorded.
  simple,

  /// Detailed logs are recorded including debug information.
  detailed;

  /// @nodoc
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

  /// @nodoc
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

/// Defines the log size limits.
enum PlanetKitLogSizeLimit {
  /// The maximum log size is 16MB.
  small,

  /// The maximum log size is 64MB.
  medium,

  /// The maximum log size is 256MB.
  large,

  /// The maximum log size is unlimited.
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

/// Configuration settings for logging within PlanetKit.
@JsonSerializable(explicitToJson: true, createFactory: false)
class PlanetKitLogSetting {
  /// Indicates whether logging will be enabled.
  final bool enabled;

  /// The level of details for logs.
  @PlanetKitLogLevelConverter()
  final PlanetKitLogLevel logLevel;

  /// The size limit for log files.
  @PlanetKitLogSizeLimitConverter()
  final PlanetKitLogSizeLimit logSizeLimit;

  /// Constructs a [PlanetKitLogSetting].
  PlanetKitLogSetting({
    required this.enabled,
    required this.logLevel,
    required this.logSizeLimit,
  });

  /// @nodoc
  Map<String, dynamic> toJson() => _$PlanetKitLogSettingToJson(this);
}

/// @nodoc
class PlanetKitLogLevelConverter
    implements JsonConverter<PlanetKitLogLevel, int> {
  const PlanetKitLogLevelConverter();

  @override
  PlanetKitLogLevel fromJson(int json) => PlanetKitLogLevel.fromInt(json);

  @override
  int toJson(PlanetKitLogLevel object) => object.intValue;
}

/// @nodoc
class PlanetKitLogSizeLimitConverter
    implements JsonConverter<PlanetKitLogSizeLimit, int> {
  const PlanetKitLogSizeLimitConverter();

  @override
  PlanetKitLogSizeLimit fromJson(int json) =>
      PlanetKitLogSizeLimit.fromInt(json);

  @override
  int toJson(PlanetKitLogSizeLimit object) => object.intValue;
}
