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
import 'dart:async';

import 'package:planet_kit_flutter/src/public/video/planet_kit_video_status.dart';

import '../../internal/my_media_status/planet_kit_platform_my_media_status_event.dart';
import '../../internal/my_media_status/planet_kit_platform_my_media_status_event_types.dart';
import '../../internal/planet_kit_platform_interface.dart';
import '../../internal/planet_kit_platform_resource_manager.dart';
import '../planet_kit_types.dart';

/// Event handler to process the media status update of the local user.
class PlanetKitMyMediaStatusHandler {
  /// Called when the microphone is muted.
  final void Function(PlanetKitMyMediaStatus status)? onMicMute;

  /// Called when the microphone is unmuted.
  final void Function(PlanetKitMyMediaStatus status)? onMicUnmute;

  /// Called when there is an update on audio description, such as volume level changes.
  final void Function(PlanetKitMyMediaStatus status, int averageVolumeLevel)?
      onAudioDescriptionUpdate;

  /// Called when there is an update on video status.
  final void Function(
          PlanetKitMyMediaStatus status, PlanetKitVideoStatus videoStatus)?
      onVideoStatusUpdate;

  /// Called when there is an update on screen share state.
  final void Function(PlanetKitMyMediaStatus status,
      PlanetKitScreenShareState screenShareState)? onScreenShareStateUpdate;

  /// Constructs a [PlanetKitMyMediaStatusHandler] with callbacks for various media status events.
  PlanetKitMyMediaStatusHandler(
      {required this.onMicMute,
      required this.onMicUnmute,
      required this.onAudioDescriptionUpdate,
      required this.onVideoStatusUpdate,
      required this.onScreenShareStateUpdate});
}

/// Provides information about the local user's media status and notifications for the media status change.
class PlanetKitMyMediaStatus {
  /// @nodoc
  final String myMediaStatusId;

  PlanetKitMyMediaStatusHandler? _handler;
  StreamSubscription<MyMediaStatusEvent>? _subscription;

  /// Checks if the user's audio is currently muted.
  Future<bool> get isMyAudioMuted async =>
      await Platform.instance.myMediaStatusInterface
          .isMyAudioMuted(myMediaStatusId);

  /// Retrieves the current video status for the user.
  ///
  /// Returns `null` if the video status cannot be retrieved.
  Future<PlanetKitVideoStatus?> get myVideoStatus async =>
      await Platform.instance.myMediaStatusInterface
          .getMyVideoStatus(myMediaStatusId);

  /// @nodoc
  PlanetKitMyMediaStatus({required this.myMediaStatusId}) {
    NativeResourceManager.instance.add(this, myMediaStatusId);
    _subscription = Platform.instance.eventManager.onMyMediaStatusEvent
        .listen(_onMyMediaStatusEvent);
  }

  /// Sets the event handler for this media status.
  ///
  /// The handler will receive updates about media status updates such as microphone mute status and audio description changes.
  void setHandler(PlanetKitMyMediaStatusHandler? handler) {
    _handler = handler;
  }

  void _onMyMediaStatusEvent(MyMediaStatusEvent event) {
    if (event.id != this.myMediaStatusId) {
      return;
    }
    final type = event.subType;
    if (type == MyMediaStatusEventType.mute) {
      print("#flutter_kit_my_media_status event mute");
      _handler?.onMicMute?.call(this);
    } else if (type == MyMediaStatusEventType.unmute) {
      print("#flutter_kit_my_media_status event unmute");
      _handler?.onMicUnmute?.call(this);
    } else if (type == MyMediaStatusEventType.audioDescriptionUpdate) {
      final updateAudioDescriptionEvent = event as UpdateAudioDescriptionEvent;
      _handler?.onAudioDescriptionUpdate
          ?.call(this, updateAudioDescriptionEvent.averageVolumeLevel);
    } else if (type == MyMediaStatusEventType.videoStatusUpdate) {
      print("#flutter_kit_my_media_status event videoStatusUpdate");
      final updateVideoStatusEvent = event as UpdateVideoStatusEvent;
      _handler?.onVideoStatusUpdate?.call(this, updateVideoStatusEvent.status);
    } else if (type == MyMediaStatusEventType.screenShareStateUpdate) {
      print("#flutter_kit_my_media_status event screenShareStateUpdate");
      final updateScreenShareStateEvent = event as UpdateScreenShareStateEvent;
      _handler?.onScreenShareStateUpdate
          ?.call(this, updateScreenShareStateEvent.state);
    }
  }
}
