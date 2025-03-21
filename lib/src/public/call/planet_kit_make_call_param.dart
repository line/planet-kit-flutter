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
import '../screen_share/planet_kit_screen_share_key.dart';
import 'planet_kit_callkit_type.dart';
part 'planet_kit_make_call_param.g.dart';

/// A data model representing the parameters required to initiate a call with PlanetKit.
///
/// This class encapsulates all necessary details needed to make a call, including user
/// and service identifiers for both the initiator and the receiver, as well as an access token.
@JsonSerializable(explicitToJson: true, createFactory: false)
class PlanetKitMakeCallParam {
  // TODO: add required marker for params

  /// The user ID of the caller.
  final String myUserId;

  /// The service ID of the caller's service.
  final String myServiceId;

  /// The country code of the caller in upper case as defined in ISO 3166-1 alpha-2.
  /// Set country code only if your service supports multi-zone.
  final String? myCountryCode;

  /// The user ID of the call receiver.
  final String peerUserId;

  /// The service ID of the call receiver's service.
  final String peerServiceId;

  /// The country code of the caller in upper case as defined in ISO 3166-1 alpha-2.
  /// Set country code only if your service supports multi-zone.
  final String? peerCountryCode;

  /// The access token to authenticate the call request.
  final String accessToken;

  /// The configuration to enable responder preparation feature.
  final bool useResponderPreparation;

  /// CallKit type for iOS platform.
  @PlanetKitCallKitTypeConverter()
  final PlanetKitCallKitType callKitType;

  /// The asset path of the hold tone to be played when the peer holds this session.
  final String? holdTonePath;

  /// The asset path of the ringback tone to be played when the call is in the wait answer state.
  final String? ringbackTonePath;

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

  /// The media type for the call.
  @PlanetKitMediaTypeConverter()
  final PlanetKitMediaType mediaType;

  /// The response on video enabled by peer.
  @PlanetKitResponseOnEnableVideoConverter()
  final PlanetKitResponseOnEnableVideo responseOnEnableVideo;

  /// Whether to enable statistics collection.
  final bool enableStatistics;

  /// The screen share key for the call. iOS only.
  final ScreenShareKey? screenShareKey;

  /// The initial state of the user's video.
  @PlanetKitInitialMyVideoStateConverter()
  final PlanetKitInitialMyVideoState initialMyVideoState;

  /// @nodoc
  PlanetKitMakeCallParam._(
      {required this.myUserId,
      required this.myServiceId,
      required this.myCountryCode,
      required this.peerUserId,
      required this.peerServiceId,
      required this.peerCountryCode,
      required this.accessToken,
      required this.useResponderPreparation,
      required this.callKitType,
      required this.holdTonePath,
      required this.ringbackTonePath,
      required this.endTonePath,
      required this.allowCallWithoutMic,
      required this.allowCallWithoutMicPermission,
      required this.enableAudioDescription,
      required this.audioDescriptionUpdateIntervalMs,
      required this.mediaType,
      required this.responseOnEnableVideo,
      required this.enableStatistics,
      required this.screenShareKey,
      required this.initialMyVideoState});

  /// @nodoc
  Map<String, dynamic> toJson() => _$PlanetKitMakeCallParamToJson(this);
}

/// Builder for creating an instance of `PlanetKitMakeCallParam`.
class PlanetKitMakeCallParamBuilder {
  String? _myUserId;
  String? _myServiceId;
  String? _myCountryCode;
  String? _peerUserId;
  String? _peerServiceId;
  String? _peerCountryCode;
  String? _accessToken;
  bool _useResponderPreparation = false;
  PlanetKitCallKitType _callKitType = PlanetKitCallKitType.none;
  String? _holdTonePath;
  String? _ringbackTonePath;
  String? _endTonePath;
  bool? _allowCallWithoutMic;
  bool? _allowCallWithoutMicPermission;
  bool? _enableAudioDescription;
  int? _audioDescriptionUpdateIntervalMs;
  PlanetKitMediaType _mediaType = PlanetKitMediaType.audio;
  PlanetKitResponseOnEnableVideo _responseOnEnableVideo =
      PlanetKitResponseOnEnableVideo.pause;
  bool _enableStatistics = false;
  ScreenShareKey? _screenShareKey;
  PlanetKitInitialMyVideoState _initialMyVideoState =
      PlanetKitInitialMyVideoState.resume;

  /// Sets the user ID of the caller and returns the builder.
  PlanetKitMakeCallParamBuilder setMyUserId(String myUserId) {
    _myUserId = myUserId;
    return this;
  }

  /// Sets the service ID of the caller and returns the builder.
  PlanetKitMakeCallParamBuilder setMyServiceId(String myServiceId) {
    _myServiceId = myServiceId;
    return this;
  }

  /// Sets the country code of the caller and returns the builder.
  PlanetKitMakeCallParamBuilder setMyCountryCode(String myCountryCode) {
    _myCountryCode = myCountryCode;
    return this;
  }

  /// Sets the user ID of the call receiver and returns the builder.
  PlanetKitMakeCallParamBuilder setPeerUserId(String peerUserId) {
    _peerUserId = peerUserId;
    return this;
  }

  /// Sets the service ID of the call receiver and returns the builder.
  PlanetKitMakeCallParamBuilder setPeerServiceId(String peerServiceId) {
    _peerServiceId = peerServiceId;
    return this;
  }

  /// Sets the country code of the call receiver and returns the builder.
  PlanetKitMakeCallParamBuilder setPeerCountryCode(String peerCountryCode) {
    _peerCountryCode = peerCountryCode;
    return this;
  }

  /// Sets the access token for the call and returns the builder.
  PlanetKitMakeCallParamBuilder setAccessToken(String accessToken) {
    _accessToken = accessToken;
    return this;
  }

  /// Set the configuration for responder preparation and returns the builder.
  /// Default value is false.
  PlanetKitMakeCallParamBuilder setUseResponderPreparation(
      bool useResponderPreparation) {
    _useResponderPreparation = useResponderPreparation;
    return this;
  }

  /// Set the asset path of the tone to be played when the peer holds the call.
  PlanetKitMakeCallParamBuilder setHoldTonePath(String holdTonePath) {
    _holdTonePath = holdTonePath;
    return this;
  }

  /// Set the asset path of the tone to be played when the call is in the wait answer state.
  PlanetKitMakeCallParamBuilder setRingbackTonePath(String ringbackTonePath) {
    _ringbackTonePath = ringbackTonePath;
    return this;
  }

  /// Set the asset path of the tone to be played when the call is disconnected.
  PlanetKitMakeCallParamBuilder setEndTonePath(String endTonePath) {
    _endTonePath = endTonePath;
    return this;
  }

  /// Sets whether to allow call without mic permission and returns the builder.
  PlanetKitMakeCallParamBuilder setAllowCallWithoutMic(bool allow) {
    _allowCallWithoutMic = allow;
    return this;
  }

  /// Sets whether to allow call without mic permission. Android only.
  PlanetKitMakeCallParamBuilder setAllowCallWithoutMicPermission(bool allow) {
    _allowCallWithoutMicPermission = allow;
    return this;
  }

  /// Sets whether to enable audio description and returns the builder.
  PlanetKitMakeCallParamBuilder setEnableAudioDescription(bool enable) {
    _enableAudioDescription = enable;
    return this;
  }

  /// Sets the audio description update interval in milliseconds and returns the builder.
  PlanetKitMakeCallParamBuilder setAudioDescriptionUpdateIntervalMs(
      int updateIntervalMs) {
    _audioDescriptionUpdateIntervalMs = updateIntervalMs;
    return this;
  }

  /// Sets CallKit type for iOS platform.
  PlanetKitMakeCallParamBuilder setCallKitType(
      PlanetKitCallKitType callKitType) {
    _callKitType = callKitType;
    return this;
  }

  /// Sets the media type for the call and returns the builder.
  PlanetKitMakeCallParamBuilder setMediaType(PlanetKitMediaType mediaType) {
    _mediaType = mediaType;
    return this;
  }

  /// Sets the response on enabling video and returns the builder.
  PlanetKitMakeCallParamBuilder setResponseOnEnableVideo(
      PlanetKitResponseOnEnableVideo response) {
    _responseOnEnableVideo = response;
    return this;
  }

  /// Sets whether to enable statistics collection and returns the builder.
  PlanetKitMakeCallParamBuilder setEnableStatistics(bool enable) {
    _enableStatistics = enable;
    return this;
  }

  /// Sets the screen share key for the call and returns the builder.
  PlanetKitMakeCallParamBuilder setScreenShareKey(
      ScreenShareKey screenShareKey) {
    _screenShareKey = screenShareKey;
    return this;
  }

  /// Sets the initial state of the user's video and returns the builder.
  PlanetKitMakeCallParamBuilder setInitialMyVideoState(
      PlanetKitInitialMyVideoState initialState) {
    _initialMyVideoState = initialState;
    return this;
  }

  /// Constructs a [PlanetKitMakeCallParam] with necessary details for making a call.
  /// Throws an exception if any required fields are missing.
  PlanetKitMakeCallParam build() {
    if (_myUserId == null ||
        _myServiceId == null ||
        _peerUserId == null ||
        _peerServiceId == null ||
        _accessToken == null) {
      throw Exception('Missing required fields for PlanetKitMakeCallParam');
      //TODO remove exception, return nil instead.
    }
    return PlanetKitMakeCallParam._(
        myUserId: _myUserId!,
        myServiceId: _myServiceId!,
        myCountryCode: _myCountryCode,
        peerUserId: _peerUserId!,
        peerServiceId: _peerServiceId!,
        peerCountryCode: _peerCountryCode,
        accessToken: _accessToken!,
        useResponderPreparation: _useResponderPreparation,
        callKitType: _callKitType,
        holdTonePath: _holdTonePath,
        ringbackTonePath: _ringbackTonePath,
        endTonePath: _endTonePath,
        allowCallWithoutMic: _allowCallWithoutMic,
        allowCallWithoutMicPermission: _allowCallWithoutMicPermission,
        enableAudioDescription: _enableAudioDescription,
        audioDescriptionUpdateIntervalMs: _audioDescriptionUpdateIntervalMs,
        mediaType: _mediaType,
        responseOnEnableVideo: _responseOnEnableVideo,
        enableStatistics: _enableStatistics,
        screenShareKey: _screenShareKey,
        initialMyVideoState: _initialMyVideoState);
  }
}
