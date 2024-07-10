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

import '../../public/planet_kit_user_id.dart';
part 'planet_kit_platform_conference_params.g.dart';

@JsonSerializable(explicitToJson: true, createFactory: false)
class HoldConferenceParam {
  final String id;
  final String? reason;

  HoldConferenceParam({required this.id, required this.reason});
  Map<String, dynamic> toJson() => _$HoldConferenceParamToJson(this);
}

@JsonSerializable(explicitToJson: true, createFactory: false)
class MuteMuAudioParam {
  final String id;
  final bool mute;

  MuteMuAudioParam({required this.id, required this.mute});
  Map<String, dynamic> toJson() => _$MuteMuAudioParamToJson(this);
}

@JsonSerializable(explicitToJson: true, createFactory: false)
class RequestPeerMuteParam {
  final String id;
  final bool mute;
  final PlanetKitUserId peerId;
  RequestPeerMuteParam(
      {required this.id, required this.mute, required this.peerId});
  Map<String, dynamic> toJson() => _$RequestPeerMuteParamToJson(this);
}

@JsonSerializable(explicitToJson: true, createFactory: false)
class RequestPeersMuteParam {
  final String id;
  final bool mute;
  RequestPeersMuteParam({required this.id, required this.mute});
  Map<String, dynamic> toJson() => _$RequestPeersMuteParamToJson(this);
}

@JsonSerializable(explicitToJson: true, createFactory: false)
class SilencePeersAudioParam {
  final String id;
  final bool silent;
  SilencePeersAudioParam({required this.id, required this.silent});
  Map<String, dynamic> toJson() => _$SilencePeersAudioParamToJson(this);
}

@JsonSerializable(explicitToJson: true, createFactory: false)
class SpeakerOutParam {
  final String id;
  final bool speakerOut;
  SpeakerOutParam({required this.id, required this.speakerOut});
  Map<String, dynamic> toJson() => _$SpeakerOutParamToJson(this);
}

@JsonSerializable(explicitToJson: true, createFactory: false)
class CreatePeerControlParam {
  final String conferenceId;
  final String peerId;
  CreatePeerControlParam({required this.conferenceId, required this.peerId});
  Map<String, dynamic> toJson() => _$CreatePeerControlParamToJson(this);
}
