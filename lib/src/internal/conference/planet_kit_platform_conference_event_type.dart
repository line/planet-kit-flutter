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

class ConferenceEventTypeConverter
    implements JsonConverter<ConferenceEventType, int> {
  const ConferenceEventTypeConverter();

  @override
  ConferenceEventType fromJson(int json) => ConferenceEventType.fromInt(json);

  @override
  int toJson(ConferenceEventType object) {
    throw UnimplementedError('Serialization is not supported.');
  }
}

enum ConferenceEventType {
  error,
  connected,
  disconnected,
  peerListUpdate,
  peersMicMute,
  peersMicUnmute,
  peersHold,
  peersUnhold,
  networkUnavailable,
  networkReavailable,
  myAudioMuteRequestedByPeer;

  static ConferenceEventType fromInt(int value) {
    switch (value) {
      case 0:
        return ConferenceEventType.connected;
      case 1:
        return ConferenceEventType.disconnected;
      case 2:
        return ConferenceEventType.peerListUpdate;
      case 3:
        return ConferenceEventType.peersMicMute;
      case 4:
        return ConferenceEventType.peersMicUnmute;
      case 5:
        return ConferenceEventType.peersHold;
      case 6:
        return ConferenceEventType.peersUnhold;
      case 7:
        return ConferenceEventType.networkUnavailable;
      case 8:
        return ConferenceEventType.networkReavailable;
      case 9:
        return ConferenceEventType.myAudioMuteRequestedByPeer;
      default:
        return ConferenceEventType.error;
    }
  }
}
