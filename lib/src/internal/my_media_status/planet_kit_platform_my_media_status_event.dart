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
import 'package:planet_kit_flutter/src/public/video/planet_kit_video_status.dart';
import '../../public/planet_kit_types.dart';
import '../planet_kit_platform_event.dart';
import '../planet_kit_platform_event_types.dart';
import 'planet_kit_platform_my_media_status_event_types.dart';

part 'planet_kit_platform_my_media_status_event.g.dart';

class MyMediaStatusEventFactory {
  static MyMediaStatusEvent fromJson(Map<String, dynamic> data) {
    final event = MyMediaStatusEvent.fromJson(data);
    final type = event.subType;

    if (type == MyMediaStatusEventType.audioDescriptionUpdate) {
      return UpdateAudioDescriptionEvent.fromJson(data);
    } else if (type == MyMediaStatusEventType.videoStatusUpdate) {
      print("#UpdateVideoStatusEvent $data");
      return UpdateVideoStatusEvent.fromJson(data);
    } else if (type == MyMediaStatusEventType.screenShareStateUpdate) {
      return UpdateScreenShareStateEvent.fromJson(data);
    } else {
      return event;
    }
  }
}

@JsonSerializable(createToJson: false)
class MyMediaStatusEvent extends Event {
  @MyMediaStatusEventTypeConverter()
  MyMediaStatusEventType subType;

  MyMediaStatusEvent(EventType type, String id, this.subType)
      : super(type: type, id: id);

  factory MyMediaStatusEvent.fromJson(Map<String, dynamic> json) =>
      _$MyMediaStatusEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class UpdateAudioDescriptionEvent extends MyMediaStatusEvent {
  final int averageVolumeLevel;

  UpdateAudioDescriptionEvent(
      super.type, super.id, super.subType, this.averageVolumeLevel);

  factory UpdateAudioDescriptionEvent.fromJson(Map<String, dynamic> json) =>
      _$UpdateAudioDescriptionEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class UpdateVideoStatusEvent extends MyMediaStatusEvent {
  final PlanetKitVideoStatus status;

  UpdateVideoStatusEvent(super.type, super.id, super.subType, this.status);

  factory UpdateVideoStatusEvent.fromJson(Map<String, dynamic> json) =>
      _$UpdateVideoStatusEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class UpdateScreenShareStateEvent extends MyMediaStatusEvent {
  @PlanetKitScreenShareStateConverter()
  final PlanetKitScreenShareState state;

  UpdateScreenShareStateEvent(super.type, super.id, super.subType, this.state);

  factory UpdateScreenShareStateEvent.fromJson(Map<String, dynamic> json) =>
      _$UpdateScreenShareStateEventFromJson(json);
}
