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
  myAudioMuteRequestedByPeer,
  shortDataReceived, // 10
  peersSharedContentsSet, // 11
  peersSharedContentsUnset, // 12
  peerExclusivelySharedContentsSet, // 13
  peerExclusivelySharedContentsUnset, // 14
  peerRoomSharedContentsSet, // 15
  peerRoomSharedContentsUnset, // 16
  dataSessionIncoming, // 17
  dataSessionInboundReceived, // 18
  dataSessionInboundClosed, // 19
  dataSessionOutboundClosed, // 20
  dataSessionOutboundTooLongQueuedData, // 21
  myScreenShareStoppedByHold; // 22

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
      case 10:
        return ConferenceEventType.shortDataReceived;
      case 11:
        return ConferenceEventType.peersSharedContentsSet;
      case 12:
        return ConferenceEventType.peersSharedContentsUnset;
      case 13:
        return ConferenceEventType.peerExclusivelySharedContentsSet;
      case 14:
        return ConferenceEventType.peerExclusivelySharedContentsUnset;
      case 15:
        return ConferenceEventType.peerRoomSharedContentsSet;
      case 16:
        return ConferenceEventType.peerRoomSharedContentsUnset;
      case 17:
        return ConferenceEventType.dataSessionIncoming;
      case 18:
        return ConferenceEventType.dataSessionInboundReceived;
      case 19:
        return ConferenceEventType.dataSessionInboundClosed;
      case 20:
        return ConferenceEventType.dataSessionOutboundClosed;
      case 21:
        return ConferenceEventType.dataSessionOutboundTooLongQueuedData;
      case 22:
        return ConferenceEventType.myScreenShareStoppedByHold;
      default:
        return ConferenceEventType.error;
    }
  }
}
