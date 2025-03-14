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
import '../planet_kit_types.dart';
import '../screen_share/planet_kit_screen_share_key.dart';
import 'planet_kit_callkit_type.dart';
import 'planet_kit_cc_param.dart';
part 'planet_kit_verify_call_param.g.dart';

/// A data model representing the parameters required to verify a call with PlanetKit.
///
/// This class encapsulates details necessary for verifying a call, including user and
/// service identifiers, along with a configuration parameter object.
/// Use [PlanetKitVerifyCallParamBuilder] class to create [PlanetKitVerifyCallParam] instance.
@JsonSerializable(explicitToJson: true, createFactory: false)
class PlanetKitVerifyCallParam {
  /// The user ID of the individual initiating the verification.
  final String myUserId;

  /// The service ID associated with the user's service.
  final String myServiceId;

  /// A [PlanetKitCcParam] instance.
  final PlanetKitCcParam ccParam;

  /// CallKit type for iOS platform.
  @PlanetKitCallKitTypeConverter()
  final PlanetKitCallKitType callKitType;

  /// The asset path of the hold tone to be played when the peer holds this session.
  final String? holdTonePath;

  /// The asset path of the ringtone to be played when the call is in the verified state.
  final String? ringtonePath;

  /// The asset path of the end tone to be played when the call is disconnected.
  final String? endTonePath;

  /// Whether to allow the call without microphone permission.
  final bool? allowCallWithoutMic;

  /// Whether to allow the call without microphone permission. Android only.
  final bool? allowCallWithoutMicPermission;

  /// Whether to enable audio description updates during the call.
  final bool? enableAudioDescription;

  /// Interval in milliseconds for audio description updates.
  final int? audioDescriptionUpdateIntervalMs;

  /// The response on video enabled by peer.
  @PlanetKitResponseOnEnableVideoConverter()
  final PlanetKitResponseOnEnableVideo responseOnEnableVideo;

  /// Whether to enable statistics collection.
  final bool enableStatistics;

  /// The screen share key for the call. iOS only.
  final ScreenShareKey? screenShareKey;

  /// @nodoc
  PlanetKitVerifyCallParam._({
    required this.myUserId,
    required this.myServiceId,
    required this.ccParam,
    required this.callKitType,
    required this.holdTonePath,
    required this.ringtonePath,
    required this.endTonePath,
    required this.allowCallWithoutMic,
    required this.allowCallWithoutMicPermission,
    required this.enableAudioDescription,
    required this.audioDescriptionUpdateIntervalMs,
    required this.responseOnEnableVideo,
    required this.enableStatistics,
    required this.screenShareKey,
  });

  /// @nodoc
  Map<String, dynamic> toJson() => _$PlanetKitVerifyCallParamToJson(this);
}

/// Builder for creating an instance of `PlanetKitVerifyCallParam`.
class PlanetKitVerifyCallParamBuilder {
  String? _myUserId;
  String? _myServiceId;
  PlanetKitCcParam? _ccParam;
  PlanetKitCallKitType _callKitType = PlanetKitCallKitType.none;
  String? _holdTonePath;
  String? _ringtonePath;
  String? _endTonePath;
  bool? _allowCallWithoutMic;
  bool? _allowCallWithoutMicPermission;
  bool? _enableAudioDescription;
  int? _audioDescriptionUpdateIntervalMs;
  PlanetKitResponseOnEnableVideo _responseOnEnableVideo =
      PlanetKitResponseOnEnableVideo.pause;
  bool _enableStatistics = false;
  ScreenShareKey? _screenShareKey;

  /// Sets the user ID of the individual initiating the verification.
  PlanetKitVerifyCallParamBuilder setMyUserId(String myUserId) {
    _myUserId = myUserId;
    return this;
  }

  /// Sets the service ID associated with the user's service.
  PlanetKitVerifyCallParamBuilder setMyServiceId(String myServiceId) {
    _myServiceId = myServiceId;
    return this;
  }

  /// Sets the [PlanetKitCcParam] instance.
  PlanetKitVerifyCallParamBuilder setCcParam(PlanetKitCcParam ccParam) {
    _ccParam = ccParam;
    return this;
  }

  /// Sets CallKit type for iOS platform.
  PlanetKitVerifyCallParamBuilder setCallKitType(
      PlanetKitCallKitType callKitType) {
    _callKitType = callKitType;
    return this;
  }

  /// Sets the asset path of the tone to be played when the peer holds the call.
  PlanetKitVerifyCallParamBuilder setHoldTonePath(String holdTonePath) {
    _holdTonePath = holdTonePath;
    return this;
  }

  /// Sets the asset path of the tone to be played when the call is in the verified state.
  PlanetKitVerifyCallParamBuilder setRingtonePath(String ringtonePath) {
    _ringtonePath = ringtonePath;
    return this;
  }

  /// Sets the asset path of the tone to be played when the call is disconnected.
  PlanetKitVerifyCallParamBuilder setEndTonePath(String endTonePath) {
    _endTonePath = endTonePath;
    return this;
  }

  /// Sets whether to allow call without mic permission and returns the builder.
  PlanetKitVerifyCallParamBuilder setAllowCallWithoutMic(bool allow) {
    _allowCallWithoutMic = allow;
    return this;
  }

  /// Sets whether to allow call without mic permission. Android only.
  PlanetKitVerifyCallParamBuilder setAllowCallWithoutMicPermission(bool allow) {
    _allowCallWithoutMicPermission = allow;
    return this;
  }

  /// Sets whether to enable audio description and returns the builder.
  PlanetKitVerifyCallParamBuilder setEnableAudioDescription(bool enable) {
    _enableAudioDescription = enable;
    return this;
  }

  /// Sets the audio description update interval in milliseconds and returns the builder.
  PlanetKitVerifyCallParamBuilder setAudioDescriptionUpdateIntervalMs(
      int updateIntervalMs) {
    _audioDescriptionUpdateIntervalMs = updateIntervalMs;
    return this;
  }

  /// Sets the response on enabling video.
  PlanetKitVerifyCallParamBuilder setResponseOnEnableVideo(
      PlanetKitResponseOnEnableVideo response) {
    _responseOnEnableVideo = response;
    return this;
  }

  /// Sets whether to enable statistics collection and returns the builder.
  PlanetKitVerifyCallParamBuilder setEnableStatistics(bool enable) {
    _enableStatistics = enable;
    return this;
  }

  /// Sets the screen share key for the call and returns the builder.
  PlanetKitVerifyCallParamBuilder setScreenShareKey(
      ScreenShareKey screenShareKey) {
    _screenShareKey = screenShareKey;
    return this;
  }

  /// Constructs a [PlanetKitVerifyCallParam] with necessary details for call verification.
  /// Throws an exception if any required fields are missing.
  PlanetKitVerifyCallParam build() {
    if (_myUserId == null || _myServiceId == null || _ccParam == null) {
      throw Exception('Missing required fields for PlanetKitVerifyCallParam');
    }
    return PlanetKitVerifyCallParam._(
        myUserId: _myUserId!,
        myServiceId: _myServiceId!,
        ccParam: _ccParam!,
        callKitType: _callKitType,
        holdTonePath: _holdTonePath,
        ringtonePath: _ringtonePath,
        endTonePath: _endTonePath,
        allowCallWithoutMic: _allowCallWithoutMic,
        allowCallWithoutMicPermission: _allowCallWithoutMicPermission,
        enableAudioDescription: _enableAudioDescription,
        audioDescriptionUpdateIntervalMs: _audioDescriptionUpdateIntervalMs,
        responseOnEnableVideo: _responseOnEnableVideo,
        enableStatistics: _enableStatistics,
        screenShareKey: _screenShareKey);
  }
}
