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
import '../../public/planet_kit_start_fail_reason.dart';
part 'planet_kit_platform_conference_responses.g.dart';

@JsonSerializable(createToJson: false)
class JoinConferenceResponse {
  final String? id;

  @PlanetKitStartFailReasonConverter()
  final PlanetKitStartFailReason failReason;

  JoinConferenceResponse({required this.id, required this.failReason});

  factory JoinConferenceResponse.fromJson(Map<String, dynamic> json) =>
      _$JoinConferenceResponseFromJson(json);
}
