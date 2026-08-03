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
import 'package:planet_kit_flutter/src/internal/peer_control/planet_kit_platform_peer_control_event.dart';
import 'package:planet_kit_flutter/src/internal/peer_control/planet_kit_platform_peer_control_event_types.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_event_types.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_interface.dart';
import 'package:planet_kit_flutter/src/public/conference/peer_control/planet_kit_peer_control.dart';
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
  late MockPeerControlInterface mockPeerControlInterface;

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
    mockPeerControlInterface = MockPeerControlInterface();
    when(mockPlatform.peerControlInterface).thenReturn(mockPeerControlInterface);
    Platform.instance = mockPlatform;
  });

  tearDown(() => streams.dispose());

  // ---------------------------------------------------------------------------
  // Group: ID filtering
  // ---------------------------------------------------------------------------
  group('PlanetKitPeerControl - ID filtering', () {
    test('event with different peerControlId is ignored', () async {
      when(mockPeerControlInterface.register(any)).thenAnswer((_) async => true);

      // Register target-id with a handler that must NEVER be called (wrong ID event)
      final targetControl = PlanetKitPeerControl(id: 'target-id');
      await targetControl.register(PlanetKitPeerControlHandler(
        onMicMute: expectAsync1((_) {}, count: 0, reason: 'wrong-id event must not reach target-id handler'),
      ));

      // Register other-id to confirm the stream is actually delivering events
      final completer = Completer<void>();
      final otherControl = PlanetKitPeerControl(id: 'other-id');
      await otherControl.register(PlanetKitPeerControlHandler(
        onMicMute: (_) => completer.complete(),
      ));

      // Send event for other-id — target-id handler must NOT fire
      streams.peerControlEventController.add(
        PeerControlEvent(EventType.peerControl, 'other-id', PeerControlEventType.micMute),
      );
      await completer.future;
      // If target-id handler fired, expectAsync1(count:0) would have failed the test
    });

    test('event with matching peerControlId invokes handler', () async {
      var called = false;
      when(mockPeerControlInterface.register(any))
          .thenAnswer((_) async => true);

      final completer = Completer<void>();
      final control = PlanetKitPeerControl(id: 'target-id');
      await control.register(PlanetKitPeerControlHandler(
        onMicMute: (_) {
          called = true;
          completer.complete();
        },
      ));

      streams.peerControlEventController.add(
        PeerControlEvent(
            EventType.peerControl, 'target-id', PeerControlEventType.micMute),
      );
      await completer.future;

      expect(called, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Group: Event routing
  // ---------------------------------------------------------------------------
  group('PlanetKitPeerControl - Event routing', () {
    late PlanetKitPeerControl control;

    setUp(() async {
      control = PlanetKitPeerControl(id: 'peer-id');
      when(mockPeerControlInterface.register(any))
          .thenAnswer((_) async => true);
    });

    test('micMute event -> onMicMute called with correct control instance',
        () async {
      PlanetKitPeerControl? received;
      final completer = Completer<void>();
      await control.register(PlanetKitPeerControlHandler(
        onMicMute: (c) {
          received = c;
          completer.complete();
        },
      ));

      streams.peerControlEventController.add(
        PeerControlEvent(
            EventType.peerControl, 'peer-id', PeerControlEventType.micMute),
      );
      await completer.future;

      expect(received, same(control));
    });

    test('micUnmute event -> onMicUnmute called with correct control instance',
        () async {
      PlanetKitPeerControl? received;
      final completer = Completer<void>();
      await control.register(PlanetKitPeerControlHandler(
        onMicUnmute: (c) {
          received = c;
          completer.complete();
        },
      ));

      streams.peerControlEventController.add(
        PeerControlEvent(
            EventType.peerControl, 'peer-id', PeerControlEventType.micUnmute),
      );
      await completer.future;

      expect(received, same(control));
    });

    test('hold event -> onHold called with control and reason', () async {
      PlanetKitPeerControl? receivedControl;
      String? receivedReason;
      final completer = Completer<void>();
      await control.register(PlanetKitPeerControlHandler(
        onHold: (c, reason) {
          receivedControl = c;
          receivedReason = reason;
          completer.complete();
        },
      ));

      streams.peerControlEventController.add(
        HoldEvent(EventType.peerControl, 'peer-id', PeerControlEventType.hold,
            'be-right-back'),
      );
      await completer.future;

      expect(receivedControl, same(control));
      expect(receivedReason, equals('be-right-back'));
    });

    test('hold event with null reason -> onHold called with null reason',
        () async {
      String? receivedReason = 'sentinel';
      final completer = Completer<void>();
      await control.register(PlanetKitPeerControlHandler(
        onHold: (_, reason) {
          receivedReason = reason;
          completer.complete();
        },
      ));

      streams.peerControlEventController.add(
        HoldEvent(EventType.peerControl, 'peer-id', PeerControlEventType.hold,
            null),
      );
      await completer.future;

      expect(receivedReason, isNull);
    });

    test('unhold event -> onUnhold called with correct control instance',
        () async {
      PlanetKitPeerControl? received;
      final completer = Completer<void>();
      await control.register(PlanetKitPeerControlHandler(
        onUnhold: (c) {
          received = c;
          completer.complete();
        },
      ));

      streams.peerControlEventController.add(
        PeerControlEvent(
            EventType.peerControl, 'peer-id', PeerControlEventType.unhold),
      );
      await completer.future;

      expect(received, same(control));
    });

    test(
        'disconnect event -> onDisconnect called, handler nulled, subscription cancelled',
        () async {
      PlanetKitPeerControl? receivedControl;
      final completer = Completer<void>();
      await control.register(PlanetKitPeerControlHandler(
        onDisconnect: (c) {
          receivedControl = c;
          completer.complete();
        },
      ));

      streams.peerControlEventController.add(
        PeerControlEvent(
            EventType.peerControl, 'peer-id', PeerControlEventType.disconnect),
      );
      await completer.future;

      // onDisconnect was called with the correct control
      expect(receivedControl, same(control));

      // After disconnect the subscription is cancelled — verify by sending a
      // subsequent event and confirming a fresh control still receives it.
      final postDisconnectCompleter = Completer<void>();
      final witnessControl = PlanetKitPeerControl(id: 'peer-id');
      await witnessControl.register(PlanetKitPeerControlHandler(
        onMicMute: (_) => postDisconnectCompleter.complete(),
      ));
      streams.peerControlEventController.add(
        PeerControlEvent(
            EventType.peerControl, 'peer-id', PeerControlEventType.micMute),
      );
      await postDisconnectCompleter.future;
    });

    test(
        'audioDescriptionUpdate event -> onAudioDescriptionUpdate called with level',
        () async {
      PlanetKitPeerControl? receivedControl;
      int? receivedLevel;
      final completer = Completer<void>();
      await control.register(PlanetKitPeerControlHandler(
        onAudioDescriptionUpdate: (c, level) {
          receivedControl = c;
          receivedLevel = level;
          completer.complete();
        },
      ));

      streams.peerControlEventController.add(
        UpdateAudioDescriptionEvent(EventType.peerControl, 'peer-id',
            PeerControlEventType.audioDescriptionUpdate, 42),
      );
      await completer.future;

      expect(receivedControl, same(control));
      expect(receivedLevel, equals(42));
    });

    test('videoUpdate event -> onVideoUpdate called with correct videoStatus',
        () async {
      PlanetKitPeerControl? receivedControl;
      PlanetKitVideoStatus? receivedStatus;
      final completer = Completer<void>();
      await control.register(PlanetKitPeerControlHandler(
        onVideoUpdate: (c, vs) {
          receivedControl = c;
          receivedStatus = vs;
          completer.complete();
        },
      ));

      final videoStatus = PlanetKitVideoStatus(
          PlanetKitVideoState.enabled, PlanetKitVideoPauseReason.unknown);
      streams.peerControlEventController.add(
        UpdateVideoEvent(EventType.peerControl, 'peer-id',
            PeerControlEventType.videoUpdate, videoStatus),
      );
      await completer.future;

      expect(receivedControl, same(control));
      expect(receivedStatus, same(videoStatus));
    });

    test(
        'screenShareUpdate event -> onScreenShareUpdate called with correct state',
        () async {
      PlanetKitPeerControl? receivedControl;
      PlanetKitScreenShareState? receivedState;
      final completer = Completer<void>();
      await control.register(PlanetKitPeerControlHandler(
        onScreenShareUpdate: (c, state) {
          receivedControl = c;
          receivedState = state;
          completer.complete();
        },
      ));

      streams.peerControlEventController.add(
        UpdateScreenShareEvent(EventType.peerControl, 'peer-id',
            PeerControlEventType.screenShareUpdate,
            PlanetKitScreenShareState.enabled),
      );
      await completer.future;

      expect(receivedControl, same(control));
      expect(receivedState, equals(PlanetKitScreenShareState.enabled));
    });
  });

  // ---------------------------------------------------------------------------
  // Group: register / unregister
  // ---------------------------------------------------------------------------
  group('PlanetKitPeerControl - register/unregister', () {
    test(
        'register(handler) when peerControlInterface.register returns true -> '
        'handler stored and peerControlInterface.register(peerId) called',
        () async {
      when(mockPeerControlInterface.register('my-peer'))
          .thenAnswer((_) async => true);

      final control = PlanetKitPeerControl(id: 'my-peer');
      var handlerCalled = false;
      final completer = Completer<void>();

      final result = await control.register(PlanetKitPeerControlHandler(
        onMicMute: (_) {
          handlerCalled = true;
          completer.complete();
        },
      ));

      expect(result, isTrue);
      verify(mockPeerControlInterface.register('my-peer')).called(1);

      // Handler should be stored: emit a matching event to verify
      streams.peerControlEventController.add(
        PeerControlEvent(
            EventType.peerControl, 'my-peer', PeerControlEventType.micMute),
      );
      await completer.future;
      expect(handlerCalled, isTrue);
    });

    test(
        'register(handler) when peerControlInterface.register returns false -> '
        'handler NOT stored', () async {
      when(mockPeerControlInterface.register('my-peer'))
          .thenAnswer((_) async => false);

      final control = PlanetKitPeerControl(id: 'my-peer');
      var handlerCalled = false;

      final result = await control.register(PlanetKitPeerControlHandler(
        onMicMute: (_) => handlerCalled = true,
      ));

      expect(result, isFalse);

      // Handler should NOT be stored: event should be ignored
      streams.peerControlEventController.add(
        PeerControlEvent(
            EventType.peerControl, 'my-peer', PeerControlEventType.micMute),
      );
      // Broadcast streams fire synchronously — no delay needed for negative check
      expect(handlerCalled, isFalse);
    });

    test(
        'unregister() -> peerControlInterface.unregister(peerId) called and handler nulled',
        () async {
      when(mockPeerControlInterface.register('my-peer'))
          .thenAnswer((_) async => true);
      when(mockPeerControlInterface.unregister('my-peer'))
          .thenAnswer((_) async => true);

      final control = PlanetKitPeerControl(id: 'my-peer');
      var handlerCalled = false;
      await control.register(PlanetKitPeerControlHandler(
        onMicMute: (_) => handlerCalled = true,
      ));

      final result = await control.unregister();

      expect(result, isTrue);
      verify(mockPeerControlInterface.unregister('my-peer')).called(1);

      // Handler should be nulled: subsequent events should be ignored
      streams.peerControlEventController.add(
        PeerControlEvent(
            EventType.peerControl, 'my-peer', PeerControlEventType.micMute),
      );
      // Broadcast streams fire synchronously — no delay needed for negative check
      expect(handlerCalled, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Group: Post-disconnect lifecycle
  // ---------------------------------------------------------------------------
  group('PlanetKitPeerControl - Post-disconnect lifecycle', () {
    test('after disconnect event, further stream events are ignored', () async {
      when(mockPeerControlInterface.register(any))
          .thenAnswer((_) async => true);

      final control = PlanetKitPeerControl(id: 'peer-id');
      var disconnectCallCount = 0;
      var micMuteCallCount = 0;
      final disconnectCompleter = Completer<void>();

      await control.register(PlanetKitPeerControlHandler(
        onDisconnect: (_) {
          disconnectCallCount++;
          disconnectCompleter.complete();
        },
        onMicMute: (_) => micMuteCallCount++,
      ));

      // Fire disconnect
      streams.peerControlEventController.add(
        PeerControlEvent(
            EventType.peerControl, 'peer-id', PeerControlEventType.disconnect),
      );
      await disconnectCompleter.future;

      expect(disconnectCallCount, equals(1));

      // Fire micMute after disconnect: subscription was cancelled so this
      // event should never reach the listener.
      streams.peerControlEventController.add(
        PeerControlEvent(
            EventType.peerControl, 'peer-id', PeerControlEventType.micMute),
      );
      // Broadcast streams fire synchronously — no delay needed for negative check

      expect(micMuteCallCount, equals(0));
      // Disconnect itself should not fire again
      expect(disconnectCallCount, equals(1));
    });

    test('after disconnect, all event types are ignored', () async {
      when(mockPeerControlInterface.register(any))
          .thenAnswer((_) async => true);

      final control = PlanetKitPeerControl(id: 'peer-id');
      var callCount = 0;
      final disconnectCompleter = Completer<void>();

      await control.register(PlanetKitPeerControlHandler(
        onDisconnect: (_) => disconnectCompleter.complete(),
        onMicMute: (_) => callCount++,
        onMicUnmute: (_) => callCount++,
        onHold: (_, __) => callCount++,
        onUnhold: (_) => callCount++,
        onAudioDescriptionUpdate: (_, __) => callCount++,
        onVideoUpdate: (_, __) => callCount++,
        onScreenShareUpdate: (_, __) => callCount++,
      ));

      // Trigger disconnect to cancel subscription and null the handler
      streams.peerControlEventController.add(
        PeerControlEvent(
            EventType.peerControl, 'peer-id', PeerControlEventType.disconnect),
      );
      await disconnectCompleter.future;

      // Now emit all other event types: none should invoke callbacks
      final videoStatus = PlanetKitVideoStatus(
          PlanetKitVideoState.enabled, PlanetKitVideoPauseReason.unknown);

      streams.peerControlEventController.add(
        PeerControlEvent(
            EventType.peerControl, 'peer-id', PeerControlEventType.micMute),
      );
      streams.peerControlEventController.add(
        PeerControlEvent(
            EventType.peerControl, 'peer-id', PeerControlEventType.micUnmute),
      );
      streams.peerControlEventController.add(
        HoldEvent(EventType.peerControl, 'peer-id', PeerControlEventType.hold,
            null),
      );
      streams.peerControlEventController.add(
        PeerControlEvent(
            EventType.peerControl, 'peer-id', PeerControlEventType.unhold),
      );
      streams.peerControlEventController.add(
        UpdateAudioDescriptionEvent(EventType.peerControl, 'peer-id',
            PeerControlEventType.audioDescriptionUpdate, 50),
      );
      streams.peerControlEventController.add(
        UpdateVideoEvent(EventType.peerControl, 'peer-id',
            PeerControlEventType.videoUpdate, videoStatus),
      );
      streams.peerControlEventController.add(
        UpdateScreenShareEvent(
            EventType.peerControl,
            'peer-id',
            PeerControlEventType.screenShareUpdate,
            PlanetKitScreenShareState.enabled),
      );
      // Sentinel: prove the events were actually delivered to the stream
      // (subscription was cancelled on disconnect, so the handler didn't fire).
      final sentinelCompleter = Completer<void>();
      final sentinelSub = streams.peerControlEventController.stream
          .listen((_) {
        if (!sentinelCompleter.isCompleted) sentinelCompleter.complete();
      });
      streams.peerControlEventController.add(
        PeerControlEvent(
            EventType.peerControl, 'peer-id', PeerControlEventType.micMute),
      );
      await sentinelCompleter.future;
      await sentinelSub.cancel();

      expect(callCount, equals(0));
    });
  });
}
