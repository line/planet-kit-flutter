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

import '../call/planet_kit_callkit_type.dart';
import '../planet_kit_types.dart';
import '../screen_share/planet_kit_screen_share_key.dart';
part 'planet_kit_join_conference_param.g.dart';

/// Configuration parameters for joining a group call with PlanetKit.
@JsonSerializable(explicitToJson: true, createFactory: false)
class PlanetKitJoinConferenceParam {
  /// User ID of the participant joining the conference.
  final String myUserId;

  /// Service ID associated with the user.
  final String myServiceId;

  /// Room ID of the conference to join.
  final String roomId;

  /// Service ID associated with the room.
  final String roomServiceId;

  /// Access token for authentication.
  final String accessToken;

  /// Optional path to a tone file to play at the end of the conference.
  final String? endTonePath;

  /// Whether to allow joining the conference without microphone permission.
  final bool? allowConferenceWithoutMic;

  /// Whether to enable audio description updates during the conference.
  final bool? enableAudioDescription;

  /// Interval in milliseconds for audio description updates.
  final int? audioDescriptionUpdateIntervalMs;

  /// The media type for the conference.
  @PlanetKitMediaTypeConverter()
  final PlanetKitMediaType mediaType;

  /// CallKit type for iOS platform.
  @PlanetKitCallKitTypeConverter()
  final PlanetKitCallKitType callKitType;

  /// Whether to enable statistics collection.
  final bool enableStatistics;

  /// The screen share key for the call. iOS only.
  final ScreenShareKey? screenShareKey;

  /// @nodoc
  PlanetKitJoinConferenceParam._(
      {required this.myUserId,
      required this.myServiceId,
      required this.roomId,
      required this.roomServiceId,
      required this.accessToken,
      required this.endTonePath,
      required this.allowConferenceWithoutMic,
      required this.enableAudioDescription,
      required this.audioDescriptionUpdateIntervalMs,
      required this.mediaType,
      required this.callKitType,
      required this.enableStatistics,
      required this.screenShareKey});

  /// @nodoc
  Map<String, dynamic> toJson() => _$PlanetKitJoinConferenceParamToJson(this);
}

/// Builder class for creating [PlanetKitJoinConferenceParam] instances.
class PlanetKitJoinConferenceParamBuilder {
  String? _myUserId;
  String? _myServiceId;
  String? _roomId;
  String? _roomServiceId;
  String? _accessToken;
  String? _endTonePath;
  bool? _allowConferenceWithoutMic;
  bool? _enableAudioDescription;
  int? _audioDescriptionUpdateIntervalMs;
  PlanetKitMediaType _mediaType = PlanetKitMediaType.audio;
  PlanetKitCallKitType _callKitType = PlanetKitCallKitType.none;
  bool _enableStatistics = false;
  ScreenShareKey? _screenShareKey;

  /// Sets the user ID and returns the builder.
  PlanetKitJoinConferenceParamBuilder setMyUserId(String myUserId) {
    _myUserId = myUserId;
    return this;
  }

  /// Sets the service ID and returns the builder.
  PlanetKitJoinConferenceParamBuilder setMyServiceId(String myServiceId) {
    _myServiceId = myServiceId;
    return this;
  }

  /// Sets the room ID and returns the builder.
  PlanetKitJoinConferenceParamBuilder setRoomId(String roomId) {
    _roomId = roomId;
    return this;
  }

  /// Sets the room service ID and returns the builder.
  PlanetKitJoinConferenceParamBuilder setRoomServiceId(String roomServiceId) {
    _roomServiceId = roomServiceId;
    return this;
  }

  /// Sets the access token and returns the builder.
  PlanetKitJoinConferenceParamBuilder setAccessToken(String accessToken) {
    _accessToken = accessToken;
    return this;
  }

  /// Sets the end tone path and returns the builder.
  PlanetKitJoinConferenceParamBuilder setEndTonePath(String endTonePath) {
    _endTonePath = endTonePath;
    return this;
  }

  /// Sets whether to allow conference without mic permission and returns the builder.
  PlanetKitJoinConferenceParamBuilder setAllowConferenceWithoutMic(bool allow) {
    _allowConferenceWithoutMic = allow;
    return this;
  }

  /// Sets whether to enable audio description and returns the builder.
  PlanetKitJoinConferenceParamBuilder setEnableAudioDescription(bool enable) {
    _enableAudioDescription = enable;
    return this;
  }

  /// Sets the audio description update interval in milliseconds and returns the builder.
  PlanetKitJoinConferenceParamBuilder setAudioDescriptionUpdateIntervalMs(
      int updateIntervalMs) {
    _audioDescriptionUpdateIntervalMs = updateIntervalMs;
    return this;
  }

  /// Sets CallKit type for iOS platform.
  PlanetKitJoinConferenceParamBuilder setCallKitType(
      PlanetKitCallKitType callKitType) {
    _callKitType = callKitType;
    return this;
  }

  /// Sets the media type for the conference and returns the builder.
  PlanetKitJoinConferenceParamBuilder setMediaType(
      PlanetKitMediaType mediaType) {
    _mediaType = mediaType;
    return this;
  }

  /// Sets whether to enable statistics collection and returns the builder.
  PlanetKitJoinConferenceParamBuilder setEnableStatistics(bool enable) {
    _enableStatistics = enable;
    return this;
  }

  /// Sets the screen share key for the conference and returns the builder.
  PlanetKitJoinConferenceParamBuilder setScreenShareKey(
      ScreenShareKey screenShareKey) {
    _screenShareKey = screenShareKey;
    return this;
  }

  /// Builds and returns a [PlanetKitJoinConferenceParam] instance.
  ///
  /// Throws an exception if any required fields are not set.
  PlanetKitJoinConferenceParam build() {
    if (_myUserId == null ||
        _myServiceId == null ||
        _roomId == null ||
        _roomServiceId == null ||
        _accessToken == null) {
      throw Exception(
          'Missing required fields for PlanetKitJoinConferenceParam');
      //TODO remove exception, return nil instead.s
    }
    return PlanetKitJoinConferenceParam._(
        myUserId: _myUserId!,
        myServiceId: _myServiceId!,
        roomId: _roomId!,
        roomServiceId: _roomServiceId!,
        accessToken: _accessToken!,
        endTonePath: _endTonePath,
        allowConferenceWithoutMic: _allowConferenceWithoutMic,
        enableAudioDescription: _enableAudioDescription,
        audioDescriptionUpdateIntervalMs: _audioDescriptionUpdateIntervalMs,
        mediaType: _mediaType,
        callKitType: _callKitType,
        enableStatistics: _enableStatistics,
        screenShareKey: _screenShareKey);
  }
}
