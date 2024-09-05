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
import '../planet_kit_types.dart';

part 'planet_kit_video_status.g.dart';

/// @nodoc
class PlanetKitVideoStateConverter
    implements JsonConverter<PlanetKitVideoState, int> {
  const PlanetKitVideoStateConverter();

  @override
  PlanetKitVideoState fromJson(int json) => PlanetKitVideoState.fromInt(json);

  @override
  int toJson(PlanetKitVideoState object) => object.intValue;
}

/// Represents the state of the video in PlanetKit.
enum PlanetKitVideoState {
  /// Video is disabled.
  disabled,

  /// Video is enabled.
  enabled,

  /// Video is paused.
  paused;

  /// @nodoc
  int get intValue {
    switch (this) {
      case PlanetKitVideoState.disabled:
        return 0;
      case PlanetKitVideoState.enabled:
        return 1;
      case PlanetKitVideoState.paused:
        return 2;
    }
  }

  /// @nodoc
  static PlanetKitVideoState fromInt(int rawValue) {
    switch (rawValue) {
      case 0:
        return PlanetKitVideoState.disabled;
      case 1:
        return PlanetKitVideoState.enabled;
      case 2:
        return PlanetKitVideoState.paused;
      default:
        throw ArgumentError('Invalid raw value: $rawValue');
    }
  }
}

/// Represents the video status in PlanetKit.
@JsonSerializable(createToJson: false)
class PlanetKitVideoStatus {
  /// The current state of the video.
  @PlanetKitVideoStateConverter()
  PlanetKitVideoState state;

  /// The reason for the video pause, if applicable.
  @PlanetKitVideoPauseReasonConverter()
  PlanetKitVideoPauseReason pauseReason;

  /// Constructs a [PlanetKitVideoStatus] instance.
  PlanetKitVideoStatus(this.state, this.pauseReason);

  /// @nodoc
  factory PlanetKitVideoStatus.fromJson(Map<String, dynamic> json) =>
      _$PlanetKitVideoStatusFromJson(json);
}
