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
import 'package:planet_kit_flutter/src/public/planet_kit_types.dart';
import 'package:planet_kit_flutter/src/public/video/planet_kit_video_status.dart';
import '../planet_kit_platform_event.dart';
import '../planet_kit_platform_event_types.dart';
import 'planet_kit_platform_peer_control_event_types.dart';

part 'planet_kit_platform_peer_control_event.g.dart';

class PeerControlEventFactory {
  static PeerControlEvent fromJson(Map<String, dynamic> data) {
    final event = PeerControlEvent.fromJson(data);
    final type = event.subType;

    if (type == PeerControlEventType.hold) {
      return HoldEvent.fromJson(data);
    } else if (type == PeerControlEventType.audioDescriptionUpdate) {
      return UpdateAudioDescriptionEvent.fromJson(data);
    } else if (type == PeerControlEventType.videoUpdate) {
      return UpdateVideoEvent.fromJson(data);
    } else if (type == PeerControlEventType.screenShareUpdate) {
      return UpdateScreenShareEvent.fromJson(data);
    } else {
      return event;
    }
  }
}

@JsonSerializable(createToJson: false)
class PeerControlEvent extends Event {
  @PeerControlEventTypeConverter()
  PeerControlEventType subType;

  PeerControlEvent(EventType type, String id, this.subType)
      : super(type: type, id: id);

  factory PeerControlEvent.fromJson(Map<String, dynamic> json) =>
      _$PeerControlEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class HoldEvent extends PeerControlEvent {
  final String? reason;

  HoldEvent(super.type, super.id, super.subType, this.reason);

  factory HoldEvent.fromJson(Map<String, dynamic> json) =>
      _$HoldEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class UpdateAudioDescriptionEvent extends PeerControlEvent {
  final int averageVolumeLevel;

  UpdateAudioDescriptionEvent(
      super.type, super.id, super.subType, this.averageVolumeLevel);

  factory UpdateAudioDescriptionEvent.fromJson(Map<String, dynamic> json) =>
      _$UpdateAudioDescriptionEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class UpdateVideoEvent extends PeerControlEvent {
  final PlanetKitVideoStatus status;

  UpdateVideoEvent(super.type, super.id, super.subType, this.status);

  factory UpdateVideoEvent.fromJson(Map<String, dynamic> json) =>
      _$UpdateVideoEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class UpdateScreenShareEvent extends PeerControlEvent {
  @PlanetKitScreenShareStateConverter()
  final PlanetKitScreenShareState state;

  UpdateScreenShareEvent(super.type, super.id, super.subType, this.state);

  factory UpdateScreenShareEvent.fromJson(Map<String, dynamic> json) =>
      _$UpdateScreenShareEventFromJson(json);
}
