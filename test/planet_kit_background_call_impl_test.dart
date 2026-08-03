// Copyright 2025 LINE Plus Corporation
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
import 'package:planet_kit_flutter/src/internal/call/planet_kit_background_call_impl.dart';
import 'package:planet_kit_flutter/src/internal/call/planet_kit_platform_background_call_event.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_interface.dart';
import 'package:planet_kit_flutter/src/public/call/planet_kit_background_call.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_disconnect_reason.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_disconnect_source.dart';

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

  // ---------------------------------------------------------------------------
  // Group: ID filtering
  // ---------------------------------------------------------------------------
  group('PlanetKitBackgroundCallImpl - ID filtering', () {
    test('event with different backgroundCallId is ignored', () async {
      var wrongIdCalled = false;
      final sentinelCompleter = Completer<void>();

      final impl = PlanetKitBackgroundCallImpl(
        backgroundCallId: 'target-id',
        eventHandler: PlanetKitBackgroundCallEventHandler(
          onDisconnected: (_call, _reason, _source, _userCode, _byRemote) =>
              wrongIdCalled = true,
          onVerified: (_call, _prep) => sentinelCompleter.complete(),
          onError: (_call) => wrongIdCalled = true,
          onBackgroundCallAdopted: (_call) => wrongIdCalled = true,
        ),
      );

      // Fire wrong-ID event — should be filtered out
      streams.backgroundCallEventController.add(
        BackgroundCallDisconnectedEvent(
          id: 'other-id',
          disconnectReason: PlanetKitDisconnectReason.normal,
          disconnectSource: PlanetKitDisconnectSource.callee,
          userCode: null,
          byRemote: true,
        ),
      );

      // Fire matching-ID sentinel (verified) to prove the event loop ran
      streams.backgroundCallEventController.add(
        BackgroundCallVerifiedEvent(
          id: 'target-id',
          peerUseResponderPreparation: false,
        ),
      );
      await sentinelCompleter.future;

      expect(wrongIdCalled, isFalse);
      expect(impl.backgroundCallId, equals('target-id'));
    });

    test('event with matching backgroundCallId invokes handler', () async {
      final completer = Completer<void>();

      PlanetKitBackgroundCallImpl(
        backgroundCallId: 'target-id',
        eventHandler: PlanetKitBackgroundCallEventHandler(
          onDisconnected: (_call, _reason, _source, _userCode, _byRemote) => completer.complete(),
          onVerified: (_call, _prep) {},
          onError: (_call) {},
          onBackgroundCallAdopted: (_call) {},
        ),
      );

      streams.backgroundCallEventController.add(
        BackgroundCallDisconnectedEvent(
          id: 'target-id',
          disconnectReason: PlanetKitDisconnectReason.normal,
          disconnectSource: PlanetKitDisconnectSource.callee,
          userCode: null,
          byRemote: true,
        ),
      );
      await completer.future;

      // reaching here proves callback fired
    });
  });

  // ---------------------------------------------------------------------------
  // Group: Event routing
  // ---------------------------------------------------------------------------
  group('PlanetKitBackgroundCallImpl - Event routing', () {
    test(
        'BackgroundCallDisconnectedEvent -> onDisconnected called with correct args',
        () async {
      final completer = Completer<void>();
      PlanetKitBackgroundCall? receivedCall;
      PlanetKitDisconnectReason? receivedReason;
      PlanetKitDisconnectSource? receivedSource;
      String? receivedUserCode;
      bool? receivedByRemote;

      final impl = PlanetKitBackgroundCallImpl(
        backgroundCallId: 'call-1',
        eventHandler: PlanetKitBackgroundCallEventHandler(
          onDisconnected: (call, reason, source, userCode, byRemote) {
            receivedCall = call;
            receivedReason = reason;
            receivedSource = source;
            receivedUserCode = userCode;
            receivedByRemote = byRemote;
            completer.complete();
          },
          onVerified: (_call, _prep) {},
          onError: (_call) {},
          onBackgroundCallAdopted: (_call) {},
        ),
      );

      streams.backgroundCallEventController.add(
        BackgroundCallDisconnectedEvent(
          id: 'call-1',
          disconnectReason: PlanetKitDisconnectReason.normal,
          disconnectSource: PlanetKitDisconnectSource.callee,
          userCode: 'code-42',
          byRemote: true,
        ),
      );
      await completer.future;

      expect(receivedCall, same(impl));
      expect(receivedReason, equals(PlanetKitDisconnectReason.normal));
      expect(receivedSource, equals(PlanetKitDisconnectSource.callee));
      expect(receivedUserCode, equals('code-42'));
      expect(receivedByRemote, isTrue);
    });

    test(
        'BackgroundCallVerifiedEvent -> onVerified called with peerUseResponderPreparation=true',
        () async {
      final completer = Completer<void>();
      PlanetKitBackgroundCall? receivedCall;
      bool? receivedPeerUseResponderPreparation;

      final impl = PlanetKitBackgroundCallImpl(
        backgroundCallId: 'call-1',
        eventHandler: PlanetKitBackgroundCallEventHandler(
          onDisconnected: (_call, _reason, _source, _userCode, _byRemote) {},
          onVerified: (call, peerUseResponderPreparation) {
            receivedCall = call;
            receivedPeerUseResponderPreparation = peerUseResponderPreparation;
            completer.complete();
          },
          onError: (_call) {},
          onBackgroundCallAdopted: (_call) {},
        ),
      );

      streams.backgroundCallEventController.add(
        BackgroundCallVerifiedEvent(
          id: 'call-1',
          peerUseResponderPreparation: true,
        ),
      );
      await completer.future;

      expect(receivedCall, same(impl));
      expect(receivedPeerUseResponderPreparation, isTrue);
    });

    test(
        'BackgroundCallVerifiedEvent -> onVerified called with peerUseResponderPreparation=false',
        () async {
      final completer = Completer<void>();
      bool? receivedPeerUseResponderPreparation;

      PlanetKitBackgroundCallImpl(
        backgroundCallId: 'call-1',
        eventHandler: PlanetKitBackgroundCallEventHandler(
          onDisconnected: (_call, _reason, _source, _userCode, _byRemote) {},
          onVerified: (_, peerUseResponderPreparation) {
            receivedPeerUseResponderPreparation = peerUseResponderPreparation;
            completer.complete();
          },
          onError: (_call) {},
          onBackgroundCallAdopted: (_call) {},
        ),
      );

      streams.backgroundCallEventController.add(
        BackgroundCallVerifiedEvent(
          id: 'call-1',
          peerUseResponderPreparation: false,
        ),
      );
      await completer.future;

      expect(receivedPeerUseResponderPreparation, isFalse);
    });

    test(
        'BackgroundCallErrorEvent -> onError called with correct call instance',
        () async {
      final completer = Completer<void>();
      PlanetKitBackgroundCall? receivedCall;

      final impl = PlanetKitBackgroundCallImpl(
        backgroundCallId: 'call-1',
        eventHandler: PlanetKitBackgroundCallEventHandler(
          onDisconnected: (_call, _reason, _source, _userCode, _byRemote) {},
          onVerified: (_call, _prep) {},
          onError: (call) {
            receivedCall = call;
            completer.complete();
          },
          onBackgroundCallAdopted: (_call) {},
        ),
      );

      streams.backgroundCallEventController.add(
        BackgroundCallErrorEvent(id: 'call-1'),
      );
      await completer.future;

      expect(receivedCall, same(impl));
    });

    test(
        'BackgroundCallAdoptedEvent -> onBackgroundCallAdopted called with correct call instance',
        () async {
      final completer = Completer<void>();
      PlanetKitBackgroundCall? receivedCall;

      final impl = PlanetKitBackgroundCallImpl(
        backgroundCallId: 'call-1',
        eventHandler: PlanetKitBackgroundCallEventHandler(
          onDisconnected: (_call, _reason, _source, _userCode, _byRemote) {},
          onVerified: (_call, _prep) {},
          onError: (_call) {},
          onBackgroundCallAdopted: (call) {
            receivedCall = call;
            completer.complete();
          },
        ),
      );

      streams.backgroundCallEventController.add(
        BackgroundCallAdoptedEvent(id: 'call-1'),
      );
      await completer.future;

      expect(receivedCall, same(impl));
    });

    test(
        'BackgroundCallDisconnectedEvent with null userCode passes null to handler',
        () async {
      final completer = Completer<void>();
      String? receivedUserCode = 'sentinel';

      PlanetKitBackgroundCallImpl(
        backgroundCallId: 'call-1',
        eventHandler: PlanetKitBackgroundCallEventHandler(
          onDisconnected: (_call, _reason, _source, userCode, _byRemote) {
            receivedUserCode = userCode;
            completer.complete();
          },
          onVerified: (_call, _prep) {},
          onError: (_call) {},
          onBackgroundCallAdopted: (_call) {},
        ),
      );

      streams.backgroundCallEventController.add(
        BackgroundCallDisconnectedEvent(
          id: 'call-1',
          disconnectReason: PlanetKitDisconnectReason.cancel,
          disconnectSource: PlanetKitDisconnectSource.caller,
          userCode: null,
          byRemote: false,
        ),
      );
      await completer.future;

      expect(receivedUserCode, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Group: Terminal event lifecycle
  // ---------------------------------------------------------------------------
  group('PlanetKitBackgroundCallImpl - Terminal event lifecycle', () {
    test(
        'disconnected event cancels subscription — no further callbacks after terminal event',
        () async {
      final completer = Completer<void>();
      var callCount = 0;

      PlanetKitBackgroundCallImpl(
        backgroundCallId: 'call-1',
        eventHandler: PlanetKitBackgroundCallEventHandler(
          onDisconnected: (_call, _reason, _source, _userCode, _byRemote) {
            callCount++;
            completer.complete();
          },
          onVerified: (_call, _prep) => callCount++,
          onError: (_call) => callCount++,
          onBackgroundCallAdopted: (_call) => callCount++,
        ),
      );

      // Send terminal disconnected event
      streams.backgroundCallEventController.add(
        BackgroundCallDisconnectedEvent(
          id: 'call-1',
          disconnectReason: PlanetKitDisconnectReason.normal,
          disconnectSource: PlanetKitDisconnectSource.callee,
          userCode: null,
          byRemote: true,
        ),
      );
      await completer.future;
      expect(callCount, equals(1));

      // Subsequent event — subscription should be cancelled, so ignored
      streams.backgroundCallEventController.add(
        BackgroundCallVerifiedEvent(
          id: 'call-1',
          peerUseResponderPreparation: false,
        ),
      );

      expect(callCount, equals(1));
    });

    test(
        'error event cancels subscription — no further callbacks after terminal event',
        () async {
      final completer = Completer<void>();
      var callCount = 0;

      PlanetKitBackgroundCallImpl(
        backgroundCallId: 'call-1',
        eventHandler: PlanetKitBackgroundCallEventHandler(
          onDisconnected: (_call, _reason, _source, _userCode, _byRemote) => callCount++,
          onVerified: (_call, _prep) => callCount++,
          onError: (_call) {
            callCount++;
            completer.complete();
          },
          onBackgroundCallAdopted: (_call) => callCount++,
        ),
      );

      // Send terminal error event
      streams.backgroundCallEventController.add(
        BackgroundCallErrorEvent(id: 'call-1'),
      );
      await completer.future;
      expect(callCount, equals(1));

      // Subsequent event — subscription should be cancelled, so ignored
      streams.backgroundCallEventController.add(
        BackgroundCallDisconnectedEvent(
          id: 'call-1',
          disconnectReason: PlanetKitDisconnectReason.internalError,
          disconnectSource: PlanetKitDisconnectSource.cloudServer,
          userCode: null,
          byRemote: false,
        ),
      );

      expect(callCount, equals(1));
    });

    test(
        'adopted event cancels subscription — no further callbacks after terminal event',
        () async {
      final completer = Completer<void>();
      var callCount = 0;

      PlanetKitBackgroundCallImpl(
        backgroundCallId: 'call-1',
        eventHandler: PlanetKitBackgroundCallEventHandler(
          onDisconnected: (_call, _reason, _source, _userCode, _byRemote) => callCount++,
          onVerified: (_call, _prep) => callCount++,
          onError: (_call) => callCount++,
          onBackgroundCallAdopted: (_call) {
            callCount++;
            completer.complete();
          },
        ),
      );

      // Send terminal adopted event
      streams.backgroundCallEventController.add(
        BackgroundCallAdoptedEvent(id: 'call-1'),
      );
      await completer.future;
      expect(callCount, equals(1));

      // Subsequent event — subscription should be cancelled, so ignored
      streams.backgroundCallEventController.add(
        BackgroundCallVerifiedEvent(
          id: 'call-1',
          peerUseResponderPreparation: true,
        ),
      );

      expect(callCount, equals(1));
    });

    test(
        'verified event is non-terminal — subsequent events are still processed',
        () async {
      final completer1 = Completer<void>();
      final completer2 = Completer<void>();
      var callCount = 0;

      PlanetKitBackgroundCallImpl(
        backgroundCallId: 'call-1',
        eventHandler: PlanetKitBackgroundCallEventHandler(
          onDisconnected: (_call, _reason, _source, _userCode, _byRemote) {
            callCount++;
            completer2.complete();
          },
          onVerified: (_call, _prep) {
            callCount++;
            completer1.complete();
          },
          onError: (_call) => callCount++,
          onBackgroundCallAdopted: (_call) => callCount++,
        ),
      );

      // Send non-terminal verified event
      streams.backgroundCallEventController.add(
        BackgroundCallVerifiedEvent(
          id: 'call-1',
          peerUseResponderPreparation: false,
        ),
      );
      await completer1.future;
      expect(callCount, equals(1));

      // Subsequent disconnect event should still be processed
      streams.backgroundCallEventController.add(
        BackgroundCallDisconnectedEvent(
          id: 'call-1',
          disconnectReason: PlanetKitDisconnectReason.normal,
          disconnectSource: PlanetKitDisconnectSource.callee,
          userCode: null,
          byRemote: true,
        ),
      );
      await completer2.future;

      expect(callCount, equals(2));
    });

    test(
        'multiple instances with different IDs — each only reacts to its own events',
        () async {
      final completer1 = Completer<void>();
      final completer2 = Completer<void>();
      var count1 = 0;
      var count2 = 0;

      PlanetKitBackgroundCallImpl(
        backgroundCallId: 'call-1',
        eventHandler: PlanetKitBackgroundCallEventHandler(
          onDisconnected: (_call, _reason, _source, _userCode, _byRemote) => count1++,
          onVerified: (_call, _prep) {
            count1++;
            completer1.complete();
          },
          onError: (_call) => count1++,
          onBackgroundCallAdopted: (_call) => count1++,
        ),
      );

      PlanetKitBackgroundCallImpl(
        backgroundCallId: 'call-2',
        eventHandler: PlanetKitBackgroundCallEventHandler(
          onDisconnected: (_call, _reason, _source, _userCode, _byRemote) => count2++,
          onVerified: (_call, _prep) => count2++,
          onError: (_call) {
            count2++;
            completer2.complete();
          },
          onBackgroundCallAdopted: (_call) => count2++,
        ),
      );

      // Event targeting only call-1
      streams.backgroundCallEventController.add(
        BackgroundCallVerifiedEvent(
          id: 'call-1',
          peerUseResponderPreparation: true,
        ),
      );
      await completer1.future;

      expect(count1, equals(1));
      expect(count2, equals(0));

      // Event targeting only call-2
      streams.backgroundCallEventController.add(
        BackgroundCallErrorEvent(id: 'call-2'),
      );
      await completer2.future;

      expect(count1, equals(1));
      expect(count2, equals(1));
    });
  });
}
