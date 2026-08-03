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
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:planet_kit_flutter/src/internal/call/planet_kit_platform_background_call_event.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_background_event_manager.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_disconnect_reason.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_disconnect_source.dart';

import 'mocks/mock_platform.mocks.dart';

void main() {
  late StreamController<dynamic> streamController;
  late MockEventChannel mockChannel;
  late BackgroundEventManager bgEventManager;

  setUp(() {
    streamController = StreamController<dynamic>.broadcast();
    mockChannel = MockEventChannel();
    when(mockChannel.receiveBroadcastStream())
        .thenAnswer((_) => streamController.stream);
    bgEventManager =
        BackgroundEventManager(backgroundEventChannel: mockChannel);
  });

  tearDown(() {
    bgEventManager.dispose();
    streamController.close();
  });

  // Helper: encode a JSON map to a string, mimicking native event delivery.
  String encode(Map<String, dynamic> map) => jsonEncode(map);

  group('BackgroundEventManager - Event routing', () {
    test(
        'disconnected call event JSON emits BackgroundCallDisconnectedEvent on onCallEvent',
        () async {
      BackgroundCallEvent? received;
      final completer = Completer<void>();
      bgEventManager.onCallEvent.listen((e) { received = e; completer.complete(); });

      streamController.add(encode({
        'type': 0, // EventType.call
        'id': 'call-id-1',
        'subType': 1, // CallEventType.disconnected
        'disconnectReason': 1001, // PlanetKitDisconnectReason.normal
        'disconnectSource': 2, // PlanetKitDisconnectSource.caller
        'userCode': null,
        'byRemote': false,
      }));
      await completer.future;

      expect(received, isA<BackgroundCallDisconnectedEvent>());
      final e = received as BackgroundCallDisconnectedEvent;
      expect(e.id, equals('call-id-1'));
      expect(e.disconnectReason, equals(PlanetKitDisconnectReason.normal));
      expect(e.disconnectSource, equals(PlanetKitDisconnectSource.caller));
      expect(e.userCode, isNull);
      expect(e.byRemote, isFalse);
    });

    test(
        'verified call event JSON emits BackgroundCallVerifiedEvent on onCallEvent',
        () async {
      BackgroundCallEvent? received;
      final completer = Completer<void>();
      bgEventManager.onCallEvent.listen((e) { received = e; completer.complete(); });

      streamController.add(encode({
        'type': 0, // EventType.call
        'id': 'call-id-2',
        'subType': 2, // CallEventType.verified
        'peerUseResponderPreparation': true,
      }));
      await completer.future;

      expect(received, isA<BackgroundCallVerifiedEvent>());
      final e = received as BackgroundCallVerifiedEvent;
      expect(e.id, equals('call-id-2'));
      expect(e.peerUseResponderPreparation, isTrue);
    });

    test(
        'error call event JSON emits BackgroundCallErrorEvent on onCallEvent',
        () async {
      BackgroundCallEvent? received;
      final completer = Completer<void>();
      bgEventManager.onCallEvent.listen((e) { received = e; completer.complete(); });

      // subType default/unknown maps to CallEventType.error
      streamController.add(encode({
        'type': 0, // EventType.call
        'id': 'call-id-3',
        'subType': 999, // unknown → CallEventType.error
      }));
      await completer.future;

      expect(received, isA<BackgroundCallErrorEvent>());
      expect(received!.id, equals('call-id-3'));
    });

    test(
        'adoptBackgroundCall event JSON emits BackgroundCallAdoptedEvent on onCallEvent',
        () async {
      BackgroundCallEvent? received;
      final completer = Completer<void>();
      bgEventManager.onCallEvent.listen((e) { received = e; completer.complete(); });

      streamController.add(encode({
        'type': 0, // EventType.call
        'id': 'call-id-4',
        'subType': 100, // CallEventType.adoptBackgroundCall
      }));
      await completer.future;

      expect(received, isA<BackgroundCallAdoptedEvent>());
      expect(received!.id, equals('call-id-4'));
    });

    test(
        'non-call event type emits nothing on onCallEvent and does not crash',
        () async {
      BackgroundCallEvent? received;
      bgEventManager.onCallEvent.listen((e) => received = e);

      // type=1 is EventType.myMediaStatus, not a call event
      streamController.add(encode({
        'type': 1,
        'id': 'some-id',
        'subType': 0,
      }));

      expect(received, isNull);
    });
  });
}
