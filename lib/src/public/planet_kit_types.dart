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

/// A converter for [PlanetKitScreenShareState] to and from JSON.
class PlanetKitScreenShareStateConverter
    implements JsonConverter<PlanetKitScreenShareState, int> {
  const PlanetKitScreenShareStateConverter();

  @override
  PlanetKitScreenShareState fromJson(int json) =>
      PlanetKitScreenShareState.fromInt(json);

  @override
  int toJson(PlanetKitScreenShareState object) => object.intValue;
}

/// Represents the state of screen share.
enum PlanetKitScreenShareState {
  /// Screen share is disabled.
  disabled,

  /// Screen share is enabled.
  enabled;

  /// @nodoc
  static PlanetKitScreenShareState fromInt(int value) {
    switch (value) {
      case 0:
        return PlanetKitScreenShareState.disabled;
      case 1:
        return PlanetKitScreenShareState.enabled;
      default:
        throw ArgumentError('Invalid PlanetKitScreenShareState value: $value');
    }
  }

  int get intValue {
    switch (this) {
      case PlanetKitScreenShareState.disabled:
        return 0;
      case PlanetKitScreenShareState.enabled:
        return 1;
    }
  }
}

/// Represents the type of media.
enum PlanetKitMediaType {
  /// Unknown media type.
  unknown,

  /// Audio media type.
  audio,

  /// Video media type.
  video,

  /// Audio and video media type.
  audiovideo;

  int get intValue {
    switch (this) {
      case PlanetKitMediaType.unknown:
        return 0;
      case PlanetKitMediaType.audio:
        return 1;
      case PlanetKitMediaType.video:
        return 2;
      case PlanetKitMediaType.audiovideo:
        return 3;
    }
  }

  static PlanetKitMediaType fromInt(int value) {
    switch (value) {
      case 0:
        return PlanetKitMediaType.unknown;
      case 1:
        return PlanetKitMediaType.audio;
      case 2:
        return PlanetKitMediaType.video;
      case 3:
        return PlanetKitMediaType.audiovideo;
      default:
        throw ArgumentError('Invalid enum value');
    }
  }
}

/// A converter for [PlanetKitMediaType] to and from JSON.
class PlanetKitMediaTypeConverter
    implements JsonConverter<PlanetKitMediaType, int> {
  const PlanetKitMediaTypeConverter();

  @override
  PlanetKitMediaType fromJson(int json) => PlanetKitMediaType.fromInt(json);

  @override
  int toJson(PlanetKitMediaType object) => object.intValue;
}

/// Represents the reason for video pause.
enum PlanetKitVideoPauseReason {
  /// Unknown reason for video pause.
  unknown,

  /// User-initiated video pause.
  user,

  /// Video pause due to an interrupt.
  interrupt,

  /// Undefined reason for video pause.
  undefined,

  /// Internal reason for video pause.
  internal,

  /// Video pause due to PlanetKitResponseOnEnableVideo configuration.
  enableVideoResponse,

  /// Video pause due to camera inactivity.
  cameraInactive,

  /// Video pause due to hold.
  hold
}

/// Represents the reason for media disable.
enum PlanetKitMediaDisableReason {
  /// Undefined reason for media disable.
  undefined,

  /// User-initiated media disable.
  user,

  /// Media disable due to decline.
  decline
}

/// A converter for [PlanetKitVideoPauseReason] to and from JSON.
class PlanetKitVideoPauseReasonConverter
    implements JsonConverter<PlanetKitVideoPauseReason, int> {
  const PlanetKitVideoPauseReasonConverter();

  @override
  PlanetKitVideoPauseReason fromJson(int json) {
    switch (json) {
      case 0:
        return PlanetKitVideoPauseReason.unknown;
      case 1:
        return PlanetKitVideoPauseReason.user;
      case 2:
        return PlanetKitVideoPauseReason.interrupt;
      case 3:
        return PlanetKitVideoPauseReason.undefined;
      case 4:
        return PlanetKitVideoPauseReason.internal;
      case 5:
        return PlanetKitVideoPauseReason.enableVideoResponse;
      case 6:
        return PlanetKitVideoPauseReason.cameraInactive;
      case 7:
        return PlanetKitVideoPauseReason.hold;
      default:
        throw ArgumentError('Unknown PlanetKitVideoPauseReason value: $json');
    }
  }

  @override
  int toJson(PlanetKitVideoPauseReason object) {
    switch (object) {
      case PlanetKitVideoPauseReason.unknown:
        return 0;
      case PlanetKitVideoPauseReason.user:
        return 1;
      case PlanetKitVideoPauseReason.interrupt:
        return 2;
      case PlanetKitVideoPauseReason.undefined:
        return 3;
      case PlanetKitVideoPauseReason.internal:
        return 4;
      case PlanetKitVideoPauseReason.enableVideoResponse:
        return 5;
      case PlanetKitVideoPauseReason.cameraInactive:
        return 6;
      case PlanetKitVideoPauseReason.hold:
        return 7;
    }
  }
}

/// A converter for [PlanetKitMediaDisableReason] to and from JSON.
class PlanetKitMediaDisableReasonConverter
    implements JsonConverter<PlanetKitMediaDisableReason, int> {
  const PlanetKitMediaDisableReasonConverter();

  @override
  PlanetKitMediaDisableReason fromJson(int json) {
    switch (json) {
      case 0:
        return PlanetKitMediaDisableReason.undefined;
      case 1:
        return PlanetKitMediaDisableReason.user;
      case 2:
        return PlanetKitMediaDisableReason.decline;
      default:
        throw ArgumentError('Unknown PlanetKitMediaDisableReason value: $json');
    }
  }

  @override
  int toJson(PlanetKitMediaDisableReason object) {
    switch (object) {
      case PlanetKitMediaDisableReason.undefined:
        return 0;
      case PlanetKitMediaDisableReason.user:
        return 1;
      case PlanetKitMediaDisableReason.decline:
        return 2;
    }
  }
}

/// Represents the response configuration on video enabled by peer.
enum PlanetKitResponseOnEnableVideo {
  /// Pause the video.
  pause,

  /// Send the video.
  send
}

/// A converter for [PlanetKitResponseOnEnableVideo] to and from JSON.
class PlanetKitResponseOnEnableVideoConverter
    implements JsonConverter<PlanetKitResponseOnEnableVideo, int> {
  const PlanetKitResponseOnEnableVideoConverter();

  @override
  PlanetKitResponseOnEnableVideo fromJson(int json) {
    switch (json) {
      case 0:
        return PlanetKitResponseOnEnableVideo.pause;
      case 1:
        return PlanetKitResponseOnEnableVideo.send;
      default:
        throw ArgumentError(
            'Unknown PlanetKitResponseOnEnableVideo value: $json');
    }
  }

  @override
  int toJson(PlanetKitResponseOnEnableVideo object) {
    switch (object) {
      case PlanetKitResponseOnEnableVideo.pause:
        return 0;
      case PlanetKitResponseOnEnableVideo.send:
        return 1;
    }
  }
}

/// Represents the initial state of the user's video.
enum PlanetKitInitialMyVideoState {
  /// Resume the video.
  resume,

  /// Pause the video.
  pause
}

/// A converter for [PlanetKitInitialMyVideoState] to and from JSON.
class PlanetKitInitialMyVideoStateConverter
    implements JsonConverter<PlanetKitInitialMyVideoState, int> {
  const PlanetKitInitialMyVideoStateConverter();

  /// Converts an integer from JSON to a [PlanetKitInitialMyVideoState] enum.
  ///
  /// Throws an [ArgumentError] if the integer does not match any known state.
  @override
  PlanetKitInitialMyVideoState fromJson(int json) {
    switch (json) {
      case 0:
        return PlanetKitInitialMyVideoState.resume;
      case 1:
        return PlanetKitInitialMyVideoState.pause;
      default:
        throw ArgumentError(
            'Unknown PlanetKitInitialMyVideoState value: $json');
    }
  }

  /// Converts a [PlanetKitInitialMyVideoState] enum to an integer for JSON.
  @override
  int toJson(PlanetKitInitialMyVideoState object) {
    switch (object) {
      case PlanetKitInitialMyVideoState.resume:
        return 0;
      case PlanetKitInitialMyVideoState.pause:
        return 1;
    }
  }
}
