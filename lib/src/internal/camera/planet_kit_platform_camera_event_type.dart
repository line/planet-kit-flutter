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

class CameraEventTypeConverter implements JsonConverter<CameraEventType, int> {
  const CameraEventTypeConverter();

  @override
  CameraEventType fromJson(int json) => CameraEventType.fromInt(json);

  @override
  int toJson(CameraEventType object) {
    throw UnimplementedError('Serialization is not supported.');
  }
}

enum CameraEventType {
  start,
  stop,
  error;

  static CameraEventType fromInt(int value) {
    switch (value) {
      case 0:
        return CameraEventType.start;
      case 1:
        return CameraEventType.stop;
      case 2:
        return CameraEventType.error;
      default:
        return CameraEventType.error;
    }
  }
}
