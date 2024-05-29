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

/// @nodoc
class PlanetKitAudioSampleTypeConverter
    implements JsonConverter<PlanetKitAudioSampleType, int> {
  const PlanetKitAudioSampleTypeConverter();

  @override
  PlanetKitAudioSampleType fromJson(int json) =>
      PlanetKitAudioSampleType.fromInt(json);

  @override
  int toJson(PlanetKitAudioSampleType object) => object.intValue;
}

/// Enumerates the types of audio sample formats supported by the PlanetKit system.
///
/// This enum provides identifiers for different audio sample types, which are used
/// to specify the format of audio data handled within the system.
enum PlanetKitAudioSampleType {
  /// Represents an error or an undefined sample type.
  error,

  /// Represents audio samples formatted as 32-bit signed floats.
  signedFloat32,

  /// Represents audio samples formatted as 16-bit signed shorts.
  signedShort16;

  /// @nodoc
  int get intValue {
    switch (this) {
      case PlanetKitAudioSampleType.signedFloat32:
        return 0;
      case PlanetKitAudioSampleType.signedShort16:
        return 1;
      case PlanetKitAudioSampleType.error:
        return -1;
    }
  }

  /// @nodoc
  static PlanetKitAudioSampleType fromInt(int value) {
    switch (value) {
      case 0:
        return PlanetKitAudioSampleType.signedFloat32;
      case 1:
        return PlanetKitAudioSampleType.signedShort16;
      default:
        return PlanetKitAudioSampleType.error;
    }
  }
}
