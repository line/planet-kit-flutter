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
import 'package:planet_kit_flutter/src/public/video/planet_kit_video_resolution.dart';
part 'planet_kit_platform_peer_control_params.g.dart';

@JsonSerializable(explicitToJson: true, createFactory: false)
class StartVideoParam {
  final String id;
  final String viewId;

  @PlanetKitVideoResolutionConverter()
  final PlanetKitVideoResolution maxResolution;

  StartVideoParam(
      {required this.id, required this.viewId, required this.maxResolution});
  Map<String, dynamic> toJson() => _$StartVideoParamToJson(this);
}

@JsonSerializable(explicitToJson: true, createFactory: false)
class StopVideoParam {
  final String id;
  final String viewId;

  StopVideoParam({required this.id, required this.viewId});
  Map<String, dynamic> toJson() => _$StopVideoParamToJson(this);
}

@JsonSerializable(explicitToJson: true, createFactory: false)
class StartScreenShareParam {
  final String id;
  final String viewId;

  StartScreenShareParam({required this.id, required this.viewId});
  Map<String, dynamic> toJson() => _$StartScreenShareParamToJson(this);
}

@JsonSerializable(explicitToJson: true, createFactory: false)
class StopScreenShareParam {
  final String id;
  final String viewId;

  StopScreenShareParam({required this.id, required this.viewId});
  Map<String, dynamic> toJson() => _$StopScreenShareParamToJson(this);
}
