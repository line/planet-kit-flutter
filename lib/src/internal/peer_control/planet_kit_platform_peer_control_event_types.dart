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

class PeerControlEventTypeConverter
    implements JsonConverter<PeerControlEventType, int> {
  const PeerControlEventTypeConverter();

  @override
  PeerControlEventType fromJson(int json) => PeerControlEventType.fromInt(json);

  @override
  int toJson(PeerControlEventType object) {
    throw UnimplementedError('Serialization is not supported.');
  }
}

enum PeerControlEventType {
  error,
  micMute,
  micUnmute,
  hold,
  unhold,
  disconnect,
  audioDescriptionUpdate,
  videoUpdate,
  screenShareUpdate;

  /// @nodoc
  static PeerControlEventType fromInt(int value) {
    switch (value) {
      case 0:
        return PeerControlEventType.micMute;
      case 1:
        return PeerControlEventType.micUnmute;
      case 2:
        return PeerControlEventType.hold;
      case 3:
        return PeerControlEventType.unhold;
      case 4:
        return PeerControlEventType.disconnect;
      case 5:
        return PeerControlEventType.audioDescriptionUpdate;
      case 6:
        return PeerControlEventType.videoUpdate;
      case 7:
        return PeerControlEventType.screenShareUpdate;
      default:
        return PeerControlEventType.error;
    }
  }
}
