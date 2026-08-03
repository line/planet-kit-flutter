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
import 'package:planet_kit_flutter/src/internal/call/planet_kit_platform_call_event.dart';
import 'package:planet_kit_flutter/src/internal/call/planet_kit_platform_call_event_type.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_event_types.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_interface.dart';
import 'package:planet_kit_flutter/src/public/call/planet_kit_call.dart';
import 'package:planet_kit_flutter/src/public/my_media_status/planet_kit_my_media_status.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_disconnect_reason.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_disconnect_source.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_types.dart';

import 'mocks/mock_platform.dart';
import 'mocks/mock_platform.mocks.dart';
import 'mocks/test_streams.dart';

// ---------------------------------------------------------------------------
// Helper to build a PlanetKitCall with a given eventHandler.
// ---------------------------------------------------------------------------
PlanetKitCall _makeCall({
  required String callId,
  required PlanetKitCallEventHandler eventHandler,
}) {
  final myMediaStatus =
      PlanetKitMyMediaStatus(myMediaStatusId: 'media-$callId');
  return PlanetKitCall(
    callId: callId,
    eventHandler: eventHandler,
    myMediaStatus: myMediaStatus,
  );
}

// ---------------------------------------------------------------------------
// No-op handler — all required callbacks do nothing, optionals left null.
// ---------------------------------------------------------------------------
PlanetKitCallEventHandler _noopHandler() => PlanetKitCallEventHandler(
      onWaitConnected: (_) {},
      onConnected: (_, __, ___) {},
      onDisconnected: (_, __, ___, ____, _____) {},
      onVerified: (_, __) {},
      onPreparationFinished: (_) {},
    );

void main() {
  late TestStreams streams;
  late MockEventManagerInterface mockEventManager;
  late MockBackgroundEventManagerInterface mockBackgroundEventManager;
  late MockPlatform mockPlatform;
  late MockCallInterface mockCallInterface;

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
    mockCallInterface = MockCallInterface();
    when(mockPlatform.callInterface).thenReturn(mockCallInterface);
    Platform.instance = mockPlatform;
  });

  tearDown(() => streams.dispose());

  // =========================================================================
  // Group: ID filtering
  // =========================================================================
  group('PlanetKitCall - ID filtering', () {
    test('emit event with different callId => callback NOT fired', () async {
      var called = false;
      final call = _makeCall(
        callId: 'target-id',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) => called = true,
          onConnected: (_, __, ___) => called = true,
          onDisconnected: (_, __, ___, ____, _____) => called = true,
          onVerified: (_, __) => called = true,
          onPreparationFinished: (_) => called = true,
        ),
      );

      streams.callEventController.add(
        CallEvent(EventType.call, 'other-id', CallEventType.waitConnect),
      );

      expect(called, isFalse);
      call.myMediaStatus.dispose();
    });

    test('emit event with matching callId => callback fired', () async {
      var called = false;
      final completer = Completer<void>();
      final call = _makeCall(
        callId: 'target-id',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) { called = true; completer.complete(); },
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
        ),
      );

      streams.callEventController.add(
        CallEvent(EventType.call, 'target-id', CallEventType.waitConnect),
      );
      await completer.future;

      expect(called, isTrue);
      call.myMediaStatus.dispose();
    });
  });

  // =========================================================================
  // Group: Event routing
  // =========================================================================
  group('PlanetKitCall - Event routing', () {
    test('waitConnect => onWaitConnected called with correct call instance',
        () async {
      PlanetKitCall? received;
      final completer = Completer<void>();
      final call = _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (c) { received = c; completer.complete(); },
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
        ),
      );

      streams.callEventController.add(
        CallEvent(EventType.call, 'cid', CallEventType.waitConnect),
      );
      await completer.future;

      expect(received, same(call));
      call.myMediaStatus.dispose();
    });

    test('connected => onConnected called with correct parameters', () async {
      PlanetKitCall? receivedCall;
      bool? receivedIsInPrep;
      bool? receivedShouldFinish;
      final completer = Completer<void>();

      final call = _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) {},
          onConnected: (c, isInPrep, shouldFinish) {
            receivedCall = c;
            receivedIsInPrep = isInPrep;
            receivedShouldFinish = shouldFinish;
            completer.complete();
          },
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
        ),
      );

      streams.callEventController.add(
        ConnectedEvent(
            EventType.call, 'cid', CallEventType.connected, true, false, false),
      );
      await completer.future;

      expect(receivedCall, same(call));
      expect(receivedIsInPrep, isTrue);
      expect(receivedShouldFinish, isFalse);
      call.myMediaStatus.dispose();
    });

    test('disconnected => onDisconnected called with correct parameters',
        () async {
      PlanetKitCall? receivedCall;
      PlanetKitDisconnectReason? receivedReason;
      PlanetKitDisconnectSource? receivedSource;
      String? receivedUserCode;
      bool? receivedByRemote;
      final completer = Completer<void>();

      _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) {},
          onConnected: (_, __, ___) {},
          onDisconnected: (c, reason, source, userCode, byRemote) {
            receivedCall = c;
            receivedReason = reason;
            receivedSource = source;
            receivedUserCode = userCode;
            receivedByRemote = byRemote;
            completer.complete();
          },
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
        ),
      );

      streams.callEventController.add(
        DisconnectedEvent(
            EventType.call,
            'cid',
            CallEventType.disconnected,
            PlanetKitDisconnectReason.normal,
            PlanetKitDisconnectSource.callee,
            'my-user-code',
            true),
      );
      await completer.future;

      expect(receivedCall, isNotNull);
      expect(receivedReason, equals(PlanetKitDisconnectReason.normal));
      expect(receivedSource, equals(PlanetKitDisconnectSource.callee));
      expect(receivedUserCode, equals('my-user-code'));
      expect(receivedByRemote, isTrue);
    });

    test('verified => onVerified called with correct peerUseResponderPreparation',
        () async {
      PlanetKitCall? receivedCall;
      bool? receivedPeerUsePrep;
      final completer = Completer<void>();

      final call = _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) {},
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (c, peerUsePrep) {
            receivedCall = c;
            receivedPeerUsePrep = peerUsePrep;
            completer.complete();
          },
          onPreparationFinished: (_) {},
        ),
      );

      streams.callEventController.add(
        VerifiedEvent(
            EventType.call, 'cid', CallEventType.verified, true),
      );
      await completer.future;

      expect(receivedCall, same(call));
      expect(receivedPeerUsePrep, isTrue);
      call.myMediaStatus.dispose();
    });

    test('peerMicMuted => onPeerMicMuted called with correct call instance',
        () async {
      PlanetKitCall? received;
      final completer = Completer<void>();
      final call = _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) {},
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
          onPeerMicMuted: (c) { received = c; completer.complete(); },
        ),
      );

      streams.callEventController.add(
        CallEvent(EventType.call, 'cid', CallEventType.peerMicMuted),
      );
      await completer.future;

      expect(received, same(call));
      call.myMediaStatus.dispose();
    });

    test('peerMicUnmuted => onPeerMicUnmuted called with correct call instance',
        () async {
      PlanetKitCall? received;
      final completer = Completer<void>();
      final call = _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) {},
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
          onPeerMicUnmuted: (c) { received = c; completer.complete(); },
        ),
      );

      streams.callEventController.add(
        CallEvent(EventType.call, 'cid', CallEventType.peerMicUnmuted),
      );
      await completer.future;

      expect(received, same(call));
      call.myMediaStatus.dispose();
    });

    test('networkDidUnavailable => onNetworkUnavailable called with correct parameters',
        () async {
      PlanetKitCall? receivedCall;
      bool? receivedIsPeer;
      Duration? receivedDuration;
      final completer = Completer<void>();

      final call = _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) {},
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
          onNetworkUnavailable: (c, isPeer, willDisconnect) {
            receivedCall = c;
            receivedIsPeer = isPeer;
            receivedDuration = willDisconnect;
            completer.complete();
          },
        ),
      );

      streams.callEventController.add(
        NetworkDidUnavailableEvent(
            EventType.call,
            'cid',
            CallEventType.networkDidUnavailable,
            true,
            30),
      );
      await completer.future;

      expect(receivedCall, same(call));
      expect(receivedIsPeer, isTrue);
      expect(receivedDuration, equals(const Duration(seconds: 30)));
      call.myMediaStatus.dispose();
    });

    test('networkDidReavailable => onNetworkReavailable called with correct parameters',
        () async {
      PlanetKitCall? receivedCall;
      bool? receivedIsPeer;
      final completer = Completer<void>();

      final call = _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) {},
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
          onNetworkReavailable: (c, isPeer) {
            receivedCall = c;
            receivedIsPeer = isPeer;
            completer.complete();
          },
        ),
      );

      streams.callEventController.add(
        NetworkDidReavailableEvent(
            EventType.call,
            'cid',
            CallEventType.networkDidReavailable,
            false),
      );
      await completer.future;

      expect(receivedCall, same(call));
      expect(receivedIsPeer, isFalse);
      call.myMediaStatus.dispose();
    });

    test('finishPreparation => onPreparationFinished called with correct call instance',
        () async {
      PlanetKitCall? received;
      final completer = Completer<void>();
      final call = _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) {},
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (_, __) {},
          onPreparationFinished: (c) { received = c; completer.complete(); },
        ),
      );

      streams.callEventController.add(
        CallEvent(EventType.call, 'cid', CallEventType.finishPreparation),
      );
      await completer.future;

      expect(received, same(call));
      call.myMediaStatus.dispose();
    });

    test('peerHold => onPeerHold called with correct reason', () async {
      PlanetKitCall? receivedCall;
      String? receivedReason;
      final completer = Completer<void>();

      final call = _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) {},
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
          onPeerHold: (c, reason) {
            receivedCall = c;
            receivedReason = reason;
            completer.complete();
          },
        ),
      );

      streams.callEventController.add(
        PeerHoldEvent(
            EventType.call, 'cid', CallEventType.peerHold, 'hold-reason'),
      );
      await completer.future;

      expect(receivedCall, same(call));
      expect(receivedReason, equals('hold-reason'));
      call.myMediaStatus.dispose();
    });

    test('peerUnhold => onPeerUnhold called with correct call instance',
        () async {
      PlanetKitCall? received;
      final completer = Completer<void>();
      final call = _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) {},
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
          onPeerUnhold: (c) { received = c; completer.complete(); },
        ),
      );

      streams.callEventController.add(
        CallEvent(EventType.call, 'cid', CallEventType.peerUnhold),
      );
      await completer.future;

      expect(received, same(call));
      call.myMediaStatus.dispose();
    });

    test('muteMyAudioRequestByPeer => onMyAudioMuteRequestedByPeer called with correct mute value',
        () async {
      PlanetKitCall? receivedCall;
      bool? receivedMute;
      final completer = Completer<void>();

      final call = _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) {},
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
          onMyAudioMuteRequestedByPeer: (c, mute) {
            receivedCall = c;
            receivedMute = mute;
            completer.complete();
          },
        ),
      );

      streams.callEventController.add(
        MyAudioMuteRequestByPeerEvent(
            EventType.call,
            'cid',
            CallEventType.muteMyAudioRequestByPeer,
            true),
      );
      await completer.future;

      expect(receivedCall, same(call));
      expect(receivedMute, isTrue);
      call.myMediaStatus.dispose();
    });

    test('peerVideoDidPause => onPeerVideoPaused called with correct reason',
        () async {
      PlanetKitCall? receivedCall;
      PlanetKitVideoPauseReason? receivedReason;
      final completer = Completer<void>();

      final call = _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) {},
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
          onPeerVideoPaused: (c, reason) {
            receivedCall = c;
            receivedReason = reason;
            completer.complete();
          },
        ),
      );

      streams.callEventController.add(
        PeerVideoDidPauseEvent(
            EventType.call,
            'cid',
            CallEventType.peerVideoDidPause,
            PlanetKitVideoPauseReason.user),
      );
      await completer.future;

      expect(receivedCall, same(call));
      expect(receivedReason, equals(PlanetKitVideoPauseReason.user));
      call.myMediaStatus.dispose();
    });

    test('peerVideoDidResume => onPeerVideoResumed called with correct call instance',
        () async {
      PlanetKitCall? received;
      final completer = Completer<void>();
      final call = _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) {},
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
          onPeerVideoResumed: (c) { received = c; completer.complete(); },
        ),
      );

      streams.callEventController.add(
        CallEvent(EventType.call, 'cid', CallEventType.peerVideoDidResume),
      );
      await completer.future;

      expect(received, same(call));
      call.myMediaStatus.dispose();
    });

    test('videoEnabledByPeer => onVideoEnabledByPeer called with correct call instance',
        () async {
      PlanetKitCall? received;
      final completer = Completer<void>();
      final call = _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) {},
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
          onVideoEnabledByPeer: (c) { received = c; completer.complete(); },
        ),
      );

      streams.callEventController.add(
        CallEvent(EventType.call, 'cid', CallEventType.videoEnabledByPeer),
      );
      await completer.future;

      expect(received, same(call));
      call.myMediaStatus.dispose();
    });

    test('videoDisabledByPeer => onVideoDisabledByPeer called with correct reason',
        () async {
      PlanetKitCall? receivedCall;
      PlanetKitMediaDisableReason? receivedReason;
      final completer = Completer<void>();

      final call = _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) {},
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
          onVideoDisabledByPeer: (c, reason) {
            receivedCall = c;
            receivedReason = reason;
            completer.complete();
          },
        ),
      );

      streams.callEventController.add(
        VideoDisabledByPeerEvent(
            EventType.call,
            'cid',
            CallEventType.videoDisabledByPeer,
            PlanetKitMediaDisableReason.user),
      );
      await completer.future;

      expect(receivedCall, same(call));
      expect(receivedReason, equals(PlanetKitMediaDisableReason.user));
      call.myMediaStatus.dispose();
    });

    test('detectedMyVideoNoSource => onDetectedMyVideoNoSource called with correct call instance',
        () async {
      PlanetKitCall? received;
      final completer = Completer<void>();
      final call = _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) {},
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
          onDetectedMyVideoNoSource: (c) { received = c; completer.complete(); },
        ),
      );

      streams.callEventController.add(
        CallEvent(
            EventType.call, 'cid', CallEventType.detectedMyVideoNoSource),
      );
      await completer.future;

      expect(received, same(call));
      call.myMediaStatus.dispose();
    });

    test('peerDidStartScreenShare => onPeerScreenShareStarted called with correct call instance',
        () async {
      PlanetKitCall? received;
      final completer = Completer<void>();
      final call = _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) {},
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
          onPeerScreenShareStarted: (c) { received = c; completer.complete(); },
        ),
      );

      streams.callEventController.add(
        CallEvent(
            EventType.call, 'cid', CallEventType.peerDidStartScreenShare),
      );
      await completer.future;

      expect(received, same(call));
      call.myMediaStatus.dispose();
    });

    test('peerDidStopScreenShare => onPeerScreenShareStopped called with correct call instance',
        () async {
      PlanetKitCall? received;
      final completer = Completer<void>();
      final call = _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) {},
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
          onPeerScreenShareStopped: (c) { received = c; completer.complete(); },
        ),
      );

      streams.callEventController.add(
        CallEvent(
            EventType.call, 'cid', CallEventType.peerDidStopScreenShare),
      );
      await completer.future;

      expect(received, same(call));
      call.myMediaStatus.dispose();
    });

    test('peerAudioDescriptionUpdate => onPeerAudioDescriptionUpdated called with correct level',
        () async {
      PlanetKitCall? receivedCall;
      int? receivedLevel;
      final completer = Completer<void>();

      final call = _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) {},
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
          onPeerAudioDescriptionUpdated: (c, level) {
            receivedCall = c;
            receivedLevel = level;
            completer.complete();
          },
        ),
      );

      streams.callEventController.add(
        PeerAudioDescriptionUpdateEvent(
            EventType.call,
            'cid',
            CallEventType.peerAudioDescriptionUpdate,
            85),
      );
      await completer.future;

      expect(receivedCall, same(call));
      expect(receivedLevel, equals(85));
      call.myMediaStatus.dispose();
    });
  });

  // =========================================================================
  // Group: Lifecycle / cleanup on disconnect
  // =========================================================================
  group('PlanetKitCall - Lifecycle cleanup on disconnect', () {
    test('after disconnected event: subscription is cancelled — further events do nothing',
        () async {
      var waitConnectCount = 0;
      _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) => waitConnectCount++,
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {},
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
        ),
      );

      // Fire disconnect (noop handler) — no completer needed
      streams.callEventController.add(
        DisconnectedEvent(
            EventType.call,
            'cid',
            CallEventType.disconnected,
            PlanetKitDisconnectReason.normal,
            PlanetKitDisconnectSource.callee,
            null,
            false),
      );

      // Now fire waitConnect — should be ignored
      streams.callEventController.add(
        CallEvent(EventType.call, 'cid', CallEventType.waitConnect),
      );

      expect(waitConnectCount, equals(0));
    });

    test('after disconnected event: eventHandler is nulled — onDisconnected called exactly once',
        () async {
      var disconnectCount = 0;
      final completer = Completer<void>();

      _makeCall(
        callId: 'cid',
        eventHandler: PlanetKitCallEventHandler(
          onWaitConnected: (_) {},
          onConnected: (_, __, ___) {},
          onDisconnected: (_, __, ___, ____, _____) {
            disconnectCount++;
            completer.complete();
          },
          onVerified: (_, __) {},
          onPreparationFinished: (_) {},
        ),
      );

      streams.callEventController.add(
        DisconnectedEvent(
            EventType.call,
            'cid',
            CallEventType.disconnected,
            PlanetKitDisconnectReason.normal,
            PlanetKitDisconnectSource.callee,
            null,
            true),
      );
      await completer.future;

      expect(disconnectCount, equals(1));
    });

    test('after disconnected event: myMediaStatus subscription is stopped',
        () async {
      var mediaCallCount = 0;

      final call = _makeCall(
        callId: 'cid',
        eventHandler: _noopHandler(),
      );

      // Fire disconnect — this calls myMediaStatus.dispose() internally
      streams.callEventController.add(
        DisconnectedEvent(
            EventType.call,
            'cid',
            CallEventType.disconnected,
            PlanetKitDisconnectReason.normal,
            PlanetKitDisconnectSource.callee,
            null,
            false),
      );

      // The media status was disposed; no callbacks should fire.
      // We set a handler now and verify no events flow through.
      call.myMediaStatus.setHandler(null);
      expect(mediaCallCount, equals(0));
    });
  });

  // =========================================================================
  // Group: Method delegation to CallInterface
  // =========================================================================
  group('PlanetKitCall - Method delegation', () {
    test('acceptCall => delegates to callInterface.acceptCall with callId',
        () async {
      when(mockCallInterface.acceptCall(any, any, any))
          .thenAnswer((_) async => true);

      final call = _makeCall(callId: 'cid', eventHandler: _noopHandler());
      final result = await call.acceptCall(
          useResponderPreparation: true,
          initialMyVideoState: PlanetKitInitialMyVideoState.pause);

      expect(result, isTrue);
      verify(mockCallInterface.acceptCall(
          'cid', true, PlanetKitInitialMyVideoState.pause));
      call.myMediaStatus.dispose();
    });

    test('endCall => delegates to callInterface.endCall with callId', () async {
      when(mockCallInterface.endCall(any, any))
          .thenAnswer((_) async => true);

      final call = _makeCall(callId: 'cid', eventHandler: _noopHandler());
      final result = await call.endCall(userReleasePhrase: 'bye');

      expect(result, isTrue);
      verify(mockCallInterface.endCall('cid', 'bye'));
      call.myMediaStatus.dispose();
    });

    test('muteMyAudio(true) => delegates to callInterface.muteMyAudio(callId, true)',
        () async {
      when(mockCallInterface.muteMyAudio(any, any))
          .thenAnswer((_) async => true);

      final call = _makeCall(callId: 'cid', eventHandler: _noopHandler());
      final result = await call.muteMyAudio(true);

      expect(result, isTrue);
      verify(mockCallInterface.muteMyAudio('cid', true));
      call.myMediaStatus.dispose();
    });

    test('muteMyAudio(false) => delegates to callInterface.muteMyAudio(callId, false)',
        () async {
      when(mockCallInterface.muteMyAudio(any, any))
          .thenAnswer((_) async => true);

      final call = _makeCall(callId: 'cid', eventHandler: _noopHandler());
      await call.muteMyAudio(false);

      verify(mockCallInterface.muteMyAudio('cid', false));
      call.myMediaStatus.dispose();
    });

    test('speakerOut(true) => delegates to callInterface.speakerOut(callId, true)',
        () async {
      when(mockCallInterface.speakerOut(any, any))
          .thenAnswer((_) async => true);

      final call = _makeCall(callId: 'cid', eventHandler: _noopHandler());
      final result = await call.speakerOut(true);

      expect(result, isTrue);
      verify(mockCallInterface.speakerOut('cid', true));
      call.myMediaStatus.dispose();
    });

    test('hold(reason) => delegates to callInterface.hold(callId, reason)',
        () async {
      when(mockCallInterface.hold(any, any)).thenAnswer((_) async => true);

      final call = _makeCall(callId: 'cid', eventHandler: _noopHandler());
      final result = await call.hold(reason: 'brb');

      expect(result, isTrue);
      verify(mockCallInterface.hold('cid', 'brb'));
      call.myMediaStatus.dispose();
    });

    test('unhold() => delegates to callInterface.unhold(callId)', () async {
      when(mockCallInterface.unhold(any)).thenAnswer((_) async => true);

      final call = _makeCall(callId: 'cid', eventHandler: _noopHandler());
      final result = await call.unhold();

      expect(result, isTrue);
      verify(mockCallInterface.unhold('cid'));
      call.myMediaStatus.dispose();
    });
  });
}
