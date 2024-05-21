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

class CallEventTypeConverter implements JsonConverter<CallEventType, int> {
  const CallEventTypeConverter();

  @override
  CallEventType fromJson(int json) => CallEventType.fromInt(json);

  @override
  int toJson(CallEventType object) => object.intValue;
}

enum CallEventType {
  error,
  connected,
  disconnected,
  verified,
  waitConnect,
  peerMicMuted,
  peerMicUnmuted,
  interceptedAudio;

  int get intValue {
    switch (this) {
      case CallEventType.connected:
        return 0;
      case CallEventType.disconnected:
        return 1;
      case CallEventType.verified:
        return 2;
      case CallEventType.waitConnect:
        return 3;
      case CallEventType.peerMicMuted:
        return 4;
      case CallEventType.peerMicMuted:
        return 5;
      case CallEventType.interceptedAudio:
        return 6;
      default:
        return -1;
    }
  }

  static CallEventType fromInt(int value) {
    switch (value) {
      case 0:
        return CallEventType.connected;
      case 1:
        return CallEventType.disconnected;
      case 2:
        return CallEventType.verified;
      case 3:
        return CallEventType.waitConnect;
      case 4:
        return CallEventType.peerMicMuted;
      case 5:
        return CallEventType.peerMicUnmuted;
      case 6:
        return CallEventType.interceptedAudio;
      default:
        return CallEventType.error;
    }
  }
}
