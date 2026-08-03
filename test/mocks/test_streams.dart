// Copyright 2026 LINE Plus Corporation
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

import 'package:planet_kit_flutter/src/internal/call/planet_kit_platform_background_call_event.dart';
import 'package:planet_kit_flutter/src/internal/call/planet_kit_platform_call_event.dart';
import 'package:planet_kit_flutter/src/internal/camera/planet_kit_platform_camera_event.dart';
import 'package:planet_kit_flutter/src/internal/conference/planet_kit_platform_conference_event.dart';
import 'package:planet_kit_flutter/src/internal/my_media_status/planet_kit_platform_my_media_status_event.dart';
import 'package:planet_kit_flutter/src/internal/peer_control/planet_kit_platform_peer_control_event.dart';

/// Holds broadcast [StreamController]s for each event type.
///
/// In setUp, stub each controller via mockito's thenAnswer on the mock event manager,
/// then inject events by calling [add] on the controllers in tests.
class TestStreams {
  final callEventController = StreamController<CallEvent>.broadcast();
  final conferenceEventController =
      StreamController<ConferenceEvent>.broadcast();
  final myMediaStatusEventController =
      StreamController<MyMediaStatusEvent>.broadcast();
  final peerControlEventController =
      StreamController<PeerControlEvent>.broadcast();
  final backgroundCallEventController =
      StreamController<BackgroundCallEvent>.broadcast();
  final cameraEventController = StreamController<CameraEvent>.broadcast();

  /// Close all controllers. Call this in [tearDown].
  void dispose() {
    callEventController.close();
    conferenceEventController.close();
    myMediaStatusEventController.close();
    peerControlEventController.close();
    backgroundCallEventController.close();
    cameraEventController.close();
  }
}
