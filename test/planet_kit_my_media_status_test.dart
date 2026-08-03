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

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:planet_kit_flutter/src/internal/my_media_status/planet_kit_platform_my_media_status_event.dart';
import 'package:planet_kit_flutter/src/internal/my_media_status/planet_kit_platform_my_media_status_event_types.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_event_types.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_interface.dart';
import 'package:planet_kit_flutter/src/public/my_media_status/planet_kit_my_media_status.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_types.dart';
import 'package:planet_kit_flutter/src/public/video/planet_kit_video_status.dart';

import 'mocks/mock_platform.dart';
import 'mocks/mock_platform.mocks.dart';
import 'mocks/test_streams.dart';

void main() {
  late TestStreams streams;
  late MockEventManagerInterface mockEventManager;
  late MockBackgroundEventManagerInterface mockBackgroundEventManager;
  late MockPlatform mockPlatform;

  setUp(() {
    streams = TestStreams();
    mockEventManager = MockEventManagerInterface();
    when(mockEventManager.onCallEvent)
        .thenAnswer((_) => streams.callEventController.stream);
    when(mockEventManager.onMyMediaStatusEvent)
        .thenAnswer((_) => streams.myMediaStatusEventController.stream);
    when(mockEventManager.onConferenceEvent)
        .thenAnswer((_) => streams.conferenceEventController.stream);
    when(mockEventManager.onPeerControlEvent)
        .thenAnswer((_) => streams.peerControlEventController.stream);
    when(mockEventManager.onCameraEvent)
        .thenAnswer((_) => streams.cameraEventController.stream);
    mockBackgroundEventManager = MockBackgroundEventManagerInterface();
    when(mockBackgroundEventManager.onCallEvent)
        .thenAnswer((_) => streams.backgroundCallEventController.stream);
    mockPlatform = MockPlatform();
    when(mockPlatform.eventManager).thenReturn(mockEventManager);
    when(mockPlatform.backgroundEventManager)
        .thenReturn(mockBackgroundEventManager);
    Platform.instance = mockPlatform;
  });

  tearDown(() {
    streams.dispose();
  });

  group('PlanetKitMyMediaStatus - ID filtering', () {
    test('event with different id is ignored — callbacks not invoked',
        () async {
      var called = false;
      final status = PlanetKitMyMediaStatus(myMediaStatusId: 'target-id');
      status.setHandler(PlanetKitMyMediaStatusHandler(
        onMicMute: (_) => called = true,
        onMicUnmute: (_) => called = true,
        onAudioDescriptionUpdate: (_, __) => called = true,
        onVideoStatusUpdate: (_, __) => called = true,
        onScreenShareStateUpdate: (_, __) => called = true,
      ));

      streams.myMediaStatusEventController.add(
        MyMediaStatusEvent(
            EventType.myMediaStatus, 'other-id', MyMediaStatusEventType.mute),
      );

      expect(called, isFalse);
      status.dispose();
    });

    test('event with matching id invokes handler', () async {
      var called = false;
      final completer = Completer<void>();
      final status = PlanetKitMyMediaStatus(myMediaStatusId: 'target-id');
      status.setHandler(PlanetKitMyMediaStatusHandler(
        onMicMute: (_) {
          called = true;
          completer.complete();
        },
        onMicUnmute: null,
        onAudioDescriptionUpdate: null,
        onVideoStatusUpdate: null,
        onScreenShareStateUpdate: null,
      ));

      streams.myMediaStatusEventController.add(
        MyMediaStatusEvent(
            EventType.myMediaStatus, 'target-id', MyMediaStatusEventType.mute),
      );
      await completer.future;

      expect(called, isTrue);
      status.dispose();
    });
  });

  group('PlanetKitMyMediaStatus - Event routing', () {
    test('mute event → onMicMute called with correct status instance',
        () async {
      PlanetKitMyMediaStatus? receivedStatus;
      final completer = Completer<void>();
      final status = PlanetKitMyMediaStatus(myMediaStatusId: 'id-1');
      status.setHandler(PlanetKitMyMediaStatusHandler(
        onMicMute: (s) {
          receivedStatus = s;
          completer.complete();
        },
        onMicUnmute: null,
        onAudioDescriptionUpdate: null,
        onVideoStatusUpdate: null,
        onScreenShareStateUpdate: null,
      ));

      streams.myMediaStatusEventController.add(
        MyMediaStatusEvent(
            EventType.myMediaStatus, 'id-1', MyMediaStatusEventType.mute),
      );
      await completer.future;

      expect(receivedStatus, same(status));
      status.dispose();
    });

    test('unmute event → onMicUnmute called with correct status instance',
        () async {
      PlanetKitMyMediaStatus? receivedStatus;
      final completer = Completer<void>();
      final status = PlanetKitMyMediaStatus(myMediaStatusId: 'id-1');
      status.setHandler(PlanetKitMyMediaStatusHandler(
        onMicMute: null,
        onMicUnmute: (s) {
          receivedStatus = s;
          completer.complete();
        },
        onAudioDescriptionUpdate: null,
        onVideoStatusUpdate: null,
        onScreenShareStateUpdate: null,
      ));

      streams.myMediaStatusEventController.add(
        MyMediaStatusEvent(
            EventType.myMediaStatus, 'id-1', MyMediaStatusEventType.unmute),
      );
      await completer.future;

      expect(receivedStatus, same(status));
      status.dispose();
    });

    test(
        'audioDescriptionUpdate event → onAudioDescriptionUpdate called with correct level',
        () async {
      PlanetKitMyMediaStatus? receivedStatus;
      int? receivedLevel;
      final completer = Completer<void>();
      final status = PlanetKitMyMediaStatus(myMediaStatusId: 'id-1');
      status.setHandler(PlanetKitMyMediaStatusHandler(
        onMicMute: null,
        onMicUnmute: null,
        onAudioDescriptionUpdate: (s, level) {
          receivedStatus = s;
          receivedLevel = level;
          completer.complete();
        },
        onVideoStatusUpdate: null,
        onScreenShareStateUpdate: null,
      ));

      streams.myMediaStatusEventController.add(
        UpdateAudioDescriptionEvent(EventType.myMediaStatus, 'id-1',
            MyMediaStatusEventType.audioDescriptionUpdate, 75),
      );
      await completer.future;

      expect(receivedStatus, same(status));
      expect(receivedLevel, equals(75));
      status.dispose();
    });

    test(
        'videoStatusUpdate event → onVideoStatusUpdate called with correct video status',
        () async {
      PlanetKitMyMediaStatus? receivedStatus;
      PlanetKitVideoStatus? receivedVideoStatus;
      final completer = Completer<void>();
      final status = PlanetKitMyMediaStatus(myMediaStatusId: 'id-1');
      status.setHandler(PlanetKitMyMediaStatusHandler(
        onMicMute: null,
        onMicUnmute: null,
        onAudioDescriptionUpdate: null,
        onVideoStatusUpdate: (s, vs) {
          receivedStatus = s;
          receivedVideoStatus = vs;
          completer.complete();
        },
        onScreenShareStateUpdate: null,
      ));

      final videoStatus =
          PlanetKitVideoStatus(PlanetKitVideoState.enabled, PlanetKitVideoPauseReason.unknown);
      streams.myMediaStatusEventController.add(
        UpdateVideoStatusEvent(EventType.myMediaStatus, 'id-1',
            MyMediaStatusEventType.videoStatusUpdate, videoStatus),
      );
      await completer.future;

      expect(receivedStatus, same(status));
      expect(receivedVideoStatus, same(videoStatus));
      status.dispose();
    });

    test(
        'screenShareStateUpdate event → onScreenShareStateUpdate called with correct state',
        () async {
      PlanetKitMyMediaStatus? receivedStatus;
      PlanetKitScreenShareState? receivedState;
      final completer = Completer<void>();
      final status = PlanetKitMyMediaStatus(myMediaStatusId: 'id-1');
      status.setHandler(PlanetKitMyMediaStatusHandler(
        onMicMute: null,
        onMicUnmute: null,
        onAudioDescriptionUpdate: null,
        onVideoStatusUpdate: null,
        onScreenShareStateUpdate: (s, state) {
          receivedStatus = s;
          receivedState = state;
          completer.complete();
        },
      ));

      streams.myMediaStatusEventController.add(
        UpdateScreenShareStateEvent(EventType.myMediaStatus, 'id-1',
            MyMediaStatusEventType.screenShareStateUpdate,
            PlanetKitScreenShareState.enabled),
      );
      await completer.future;

      expect(receivedStatus, same(status));
      expect(receivedState, equals(PlanetKitScreenShareState.enabled));
      status.dispose();
    });

    test(
        'audioDescriptionUpdate transmits correct level value when level is zero',
        () async {
      int? receivedLevel;
      final completer = Completer<void>();
      final status = PlanetKitMyMediaStatus(myMediaStatusId: 'id-1');
      status.setHandler(PlanetKitMyMediaStatusHandler(
        onMicMute: null,
        onMicUnmute: null,
        onAudioDescriptionUpdate: (_, level) {
          receivedLevel = level;
          completer.complete();
        },
        onVideoStatusUpdate: null,
        onScreenShareStateUpdate: null,
      ));

      streams.myMediaStatusEventController.add(
        UpdateAudioDescriptionEvent(EventType.myMediaStatus, 'id-1',
            MyMediaStatusEventType.audioDescriptionUpdate, 0),
      );
      await completer.future;

      expect(receivedLevel, equals(0));
      status.dispose();
    });
  });

  group('PlanetKitMyMediaStatus - Handler management', () {
    test('no handler set → events received without crash', () async {
      final status = PlanetKitMyMediaStatus(myMediaStatusId: 'id-1');
      // No handler set — fire an event; should not throw
      streams.myMediaStatusEventController.add(
        MyMediaStatusEvent(
            EventType.myMediaStatus, 'id-1', MyMediaStatusEventType.mute),
      );
      // Set a handler and fire a sentinel event to confirm the event loop ran
      // (proving the no-handler event was processed without crashing).
      final sentinel = Completer<void>();
      status.setHandler(PlanetKitMyMediaStatusHandler(
        onMicMute: (_) => sentinel.complete(),
        onMicUnmute: null,
        onAudioDescriptionUpdate: null,
        onVideoStatusUpdate: null,
        onScreenShareStateUpdate: null,
      ));
      streams.myMediaStatusEventController.add(
        MyMediaStatusEvent(
            EventType.myMediaStatus, 'id-1', MyMediaStatusEventType.mute),
      );
      await sentinel.future;
      status.dispose();
    });

    test('setHandler(null) → subsequent events do nothing', () async {
      var called = false;
      final status = PlanetKitMyMediaStatus(myMediaStatusId: 'id-1');
      status.setHandler(PlanetKitMyMediaStatusHandler(
        onMicMute: (_) => called = true,
        onMicUnmute: null,
        onAudioDescriptionUpdate: null,
        onVideoStatusUpdate: null,
        onScreenShareStateUpdate: null,
      ));
      status.setHandler(null);

      streams.myMediaStatusEventController.add(
        MyMediaStatusEvent(
            EventType.myMediaStatus, 'id-1', MyMediaStatusEventType.mute),
      );

      expect(called, isFalse);
      status.dispose();
    });

    test('setHandler(newHandler) → new handler receives events, old does not',
        () async {
      var oldHandlerCalled = false;
      var newHandlerCalled = false;
      final completer = Completer<void>();
      final status = PlanetKitMyMediaStatus(myMediaStatusId: 'id-1');

      status.setHandler(PlanetKitMyMediaStatusHandler(
        onMicMute: (_) => oldHandlerCalled = true,
        onMicUnmute: null,
        onAudioDescriptionUpdate: null,
        onVideoStatusUpdate: null,
        onScreenShareStateUpdate: null,
      ));
      status.setHandler(PlanetKitMyMediaStatusHandler(
        onMicMute: (_) {
          newHandlerCalled = true;
          completer.complete();
        },
        onMicUnmute: null,
        onAudioDescriptionUpdate: null,
        onVideoStatusUpdate: null,
        onScreenShareStateUpdate: null,
      ));

      streams.myMediaStatusEventController.add(
        MyMediaStatusEvent(
            EventType.myMediaStatus, 'id-1', MyMediaStatusEventType.mute),
      );
      await completer.future;

      expect(oldHandlerCalled, isFalse);
      expect(newHandlerCalled, isTrue);
      status.dispose();
    });

    test('individual callbacks can be null without affecting other callbacks',
        () async {
      var unmuteCalled = false;
      final completer = Completer<void>();
      final status = PlanetKitMyMediaStatus(myMediaStatusId: 'id-1');
      status.setHandler(PlanetKitMyMediaStatusHandler(
        onMicMute: null, // null callback
        onMicUnmute: (_) {
          unmuteCalled = true;
          completer.complete();
        },
        onAudioDescriptionUpdate: null,
        onVideoStatusUpdate: null,
        onScreenShareStateUpdate: null,
      ));

      // Fire mute (null callback) — should not crash
      streams.myMediaStatusEventController.add(
        MyMediaStatusEvent(
            EventType.myMediaStatus, 'id-1', MyMediaStatusEventType.mute),
      );

      // Fire unmute (non-null callback) — should be called
      streams.myMediaStatusEventController.add(
        MyMediaStatusEvent(
            EventType.myMediaStatus, 'id-1', MyMediaStatusEventType.unmute),
      );
      await completer.future;

      expect(unmuteCalled, isTrue);
      status.dispose();
    });
  });

  group('PlanetKitMyMediaStatus - Lifecycle', () {
    test('dispose() cancels subscription — subsequent events do nothing',
        () async {
      var callCount = 0;
      final completer = Completer<void>();
      final status = PlanetKitMyMediaStatus(myMediaStatusId: 'id-1');
      status.setHandler(PlanetKitMyMediaStatusHandler(
        onMicMute: (_) {
          callCount++;
          if (!completer.isCompleted) completer.complete();
        },
        onMicUnmute: null,
        onAudioDescriptionUpdate: null,
        onVideoStatusUpdate: null,
        onScreenShareStateUpdate: null,
      ));

      // First event fires before dispose
      streams.myMediaStatusEventController.add(
        MyMediaStatusEvent(
            EventType.myMediaStatus, 'id-1', MyMediaStatusEventType.mute),
      );
      await completer.future;
      expect(callCount, equals(1));

      status.dispose();

      // Events after dispose are ignored
      streams.myMediaStatusEventController.add(
        MyMediaStatusEvent(
            EventType.myMediaStatus, 'id-1', MyMediaStatusEventType.mute),
      );

      expect(callCount, equals(1));
    });

    test('dispose() nulls handler — no callbacks after dispose', () async {
      var called = false;
      final status = PlanetKitMyMediaStatus(myMediaStatusId: 'id-1');
      status.setHandler(PlanetKitMyMediaStatusHandler(
        onMicMute: (_) => called = true,
        onMicUnmute: null,
        onAudioDescriptionUpdate: null,
        onVideoStatusUpdate: null,
        onScreenShareStateUpdate: null,
      ));

      status.dispose();

      streams.myMediaStatusEventController.add(
        MyMediaStatusEvent(
            EventType.myMediaStatus, 'id-1', MyMediaStatusEventType.mute),
      );

      expect(called, isFalse);
    });

    test('multiple PlanetKitMyMediaStatus instances with same id both receive events',
        () async {
      var count1 = 0;
      var count2 = 0;
      final completer1 = Completer<void>();
      final completer2 = Completer<void>();
      final status1 = PlanetKitMyMediaStatus(myMediaStatusId: 'shared-id');
      final status2 = PlanetKitMyMediaStatus(myMediaStatusId: 'shared-id');

      status1.setHandler(PlanetKitMyMediaStatusHandler(
        onMicMute: (_) {
          count1++;
          completer1.complete();
        },
        onMicUnmute: null,
        onAudioDescriptionUpdate: null,
        onVideoStatusUpdate: null,
        onScreenShareStateUpdate: null,
      ));
      status2.setHandler(PlanetKitMyMediaStatusHandler(
        onMicMute: (_) {
          count2++;
          completer2.complete();
        },
        onMicUnmute: null,
        onAudioDescriptionUpdate: null,
        onVideoStatusUpdate: null,
        onScreenShareStateUpdate: null,
      ));

      streams.myMediaStatusEventController.add(
        MyMediaStatusEvent(EventType.myMediaStatus, 'shared-id',
            MyMediaStatusEventType.mute),
      );
      await Future.wait([completer1.future, completer2.future]);

      expect(count1, equals(1));
      expect(count2, equals(1));
      status1.dispose();
      status2.dispose();
    });
  });
}
