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
import 'planet_kit_platform_call_event_types.dart';
import '../planet_kit_platform_event.dart';
import '../planet_kit_platform_event_types.dart';
import '../../public/planet_kit_disconnect_reason.dart';
import '../../public/planet_kit_disconnect_source.dart';

part 'planet_kit_platform_call_event.g.dart';

@JsonSerializable(explicitToJson: true)
class CallEventData extends EventData {
  @CallEventTypeConverter()
  CallEventType callEventType;

  CallEventData(EventType type, String id, this.callEventType)
      : super(type: type, id: id);

  @override
  Map<String, dynamic> toJson() => _$CallEventDataToJson(this);
  factory CallEventData.fromJson(Map<String, dynamic> json) =>
      _$CallEventDataFromJson(json);
}

@JsonSerializable(explicitToJson: true)
class DisconnectedEventData extends CallEventData {
  @PlanetKitDisconnectReasonConverter()
  final PlanetKitDisconnectReason disconnectReason;

  @PlanetKitDisconnectSourceConverter()
  final PlanetKitDisconnectSource disconnectSource;

  final bool byRemote;

  DisconnectedEventData(super.type, super.id, super.callEventType,
      this.disconnectReason, this.disconnectSource, this.byRemote);

  @override
  Map<String, dynamic> toJson() => _$DisconnectedEventDataToJson(this);
  factory DisconnectedEventData.fromJson(Map<String, dynamic> json) =>
      _$DisconnectedEventDataFromJson(json);
}
