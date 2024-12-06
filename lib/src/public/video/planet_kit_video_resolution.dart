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

/// A converter to handle JSON serialization for PlanetKitVideoResolution.
class PlanetKitVideoResolutionConverter
    implements JsonConverter<PlanetKitVideoResolution, int> {
  const PlanetKitVideoResolutionConverter();

  @override
  PlanetKitVideoResolution fromJson(int json) =>
      PlanetKitVideoResolution.fromInt(json);

  @override
  int toJson(PlanetKitVideoResolution object) => object.intValue;
}

/// An enumeration representing the video resolutions.
enum PlanetKitVideoResolution {
  /// The resolution is unknown.
  unknown,

  /// The recommended resolution.
  recommended,

  /// The resolution is thumbnails. The maximum resolution is 176x144.
  thumbnail,

  /// The resolution is QVGA. The maximum resolution is 320x240.
  qvga,

  /// The resolution is VGA. The maximum resolution is 640x480.
  vga,

  /// The resolution is HD. The maximum resolution is 1280x960.
  hd;

  /// @nodoc
  int get intValue {
    switch (this) {
      case PlanetKitVideoResolution.unknown:
        return 0;
      case PlanetKitVideoResolution.recommended:
        return 1;
      case PlanetKitVideoResolution.thumbnail:
        return 2;
      case PlanetKitVideoResolution.qvga:
        return 3;
      case PlanetKitVideoResolution.vga:
        return 4;
      case PlanetKitVideoResolution.hd:
        return 5;
    }
  }

  /// @nodoc
  static PlanetKitVideoResolution fromInt(int value) {
    switch (value) {
      case 0:
        return PlanetKitVideoResolution.unknown;
      case 1:
        return PlanetKitVideoResolution.recommended;
      case 2:
        return PlanetKitVideoResolution.thumbnail;
      case 3:
        return PlanetKitVideoResolution.qvga;
      case 4:
        return PlanetKitVideoResolution.vga;
      case 5:
        return PlanetKitVideoResolution.hd;
      default:
        return PlanetKitVideoResolution.unknown;
    }
  }
}
