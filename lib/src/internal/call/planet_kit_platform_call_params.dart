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
part 'planet_kit_platform_call_params.g.dart';

@JsonSerializable(explicitToJson: true, createFactory: false)
class AcceptCallParam {
  final String callId;
  final bool useResponderPreparation;

  AcceptCallParam(
      {required this.callId, required this.useResponderPreparation});
  Map<String, dynamic> toJson() => _$AcceptCallParamToJson(this);
}

@JsonSerializable(explicitToJson: true, createFactory: false)
class HoldCallParam {
  final String callId;
  final String? reason;

  HoldCallParam({required this.callId, required this.reason});
  Map<String, dynamic> toJson() => _$HoldCallParamToJson(this);
}

@JsonSerializable(explicitToJson: true, createFactory: false)
class PutHookedAudioBackParam {
  final String callId;
  final String audioId;

  PutHookedAudioBackParam({required this.callId, required this.audioId});
  Map<String, dynamic> toJson() => _$PutHookedAudioBackParamToJson(this);
}

@JsonSerializable(explicitToJson: true, createFactory: false)
class MuteCallParam {
  final String callId;
  final bool mute;

  MuteCallParam({required this.callId, required this.mute});
  Map<String, dynamic> toJson() => _$MuteCallParamToJson(this);
}

@JsonSerializable(explicitToJson: true, createFactory: false)
class RequestPeerMuteParam {
  final String callId;
  final bool mute;

  RequestPeerMuteParam({required this.callId, required this.mute});
  Map<String, dynamic> toJson() => _$RequestPeerMuteParamToJson(this);
}

@JsonSerializable(explicitToJson: true, createFactory: false)
class SilencePeerAudioParam {
  final String callId;
  final bool silent;

  SilencePeerAudioParam({required this.callId, required this.silent});
  Map<String, dynamic> toJson() => _$SilencePeerAudioParamToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CallSpeakerOutParam {
  final String callId;
  final bool speakerOut;

  CallSpeakerOutParam({required this.callId, required this.speakerOut});
  Map<String, dynamic> toJson() => _$CallSpeakerOutParamToJson(this);
}

@JsonSerializable(explicitToJson: true)
class EndCallParam {
  final String callId;
  final String? userReleasePhrase;

  EndCallParam({required this.callId, required this.userReleasePhrase});
  Map<String, dynamic> toJson() => _$EndCallParamToJson(this);
}

@JsonSerializable(explicitToJson: true)
class EndCallWithErrorParam {
  final String callId;
  final String userReleasePhrase;

  EndCallWithErrorParam(
      {required this.callId, required this.userReleasePhrase});
  Map<String, dynamic> toJson() => _$EndCallWithErrorParamToJson(this);
}
