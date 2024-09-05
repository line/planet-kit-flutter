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
  int toJson(CallEventType object) {
    throw UnimplementedError('Serialization is not supported.');
  }
}

enum CallEventType {
  connected, // 0
  disconnected, // 1
  verified, // 2
  waitConnect, // 3
  peerMicMuted, // 4
  peerMicUnmuted, // 5
  networkDidUnavailable, // 6
  networkDidReavailable, // 7
  finishPreparation, // 8
  peerHold, // 9
  peerUnhold, // 10
  muteMyAudioRequestByPeer, // 11
  peerVideoDidPause, // 12
  peerVideoDidResume, // 13
  videoEnabledByPeer, // 14
  videoDisabledByPeer, // 15
  detectedMyVideoNoSource, // 16
  peerDidStartScreenShare, // 17
  peerDidStopScreenShare, // 18
  error; // default case

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
        return CallEventType.networkDidUnavailable;
      case 7:
        return CallEventType.networkDidReavailable;
      case 8:
        return CallEventType.finishPreparation;
      case 9:
        return CallEventType.peerHold;
      case 10:
        return CallEventType.peerUnhold;
      case 11:
        return CallEventType.muteMyAudioRequestByPeer;
      case 12:
        return CallEventType.peerVideoDidPause;
      case 13:
        return CallEventType.peerVideoDidResume;
      case 14:
        return CallEventType.videoEnabledByPeer;
      case 15:
        return CallEventType.videoDisabledByPeer;
      case 16:
        return CallEventType.detectedMyVideoNoSource;
      case 17:
        return CallEventType.peerDidStartScreenShare;
      case 18:
        return CallEventType.peerDidStopScreenShare;
      default:
        return CallEventType.error;
    }
  }
}
