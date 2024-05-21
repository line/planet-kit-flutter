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

class PlanetKitAudioSampleTypeConverter
    implements JsonConverter<PlanetKitAudioSampleType, int> {
  const PlanetKitAudioSampleTypeConverter();

  @override
  PlanetKitAudioSampleType fromJson(int json) =>
      PlanetKitAudioSampleType.fromInt(json);

  @override
  int toJson(PlanetKitAudioSampleType object) => object.intValue;
}

enum PlanetKitAudioSampleType {
  error,
  signedFloat32,
  signedShort16;

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
