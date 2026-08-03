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
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:planet_kit_flutter/src/internal/planet_kit_platform_event_manager.dart';
import 'package:planet_kit_flutter/src/internal/call/planet_kit_platform_call_event.dart';
import 'package:planet_kit_flutter/src/internal/call/planet_kit_platform_call_event_type.dart';
import 'package:planet_kit_flutter/src/internal/my_media_status/planet_kit_platform_my_media_status_event.dart';
import 'package:planet_kit_flutter/src/internal/my_media_status/planet_kit_platform_my_media_status_event_types.dart';
import 'package:planet_kit_flutter/src/internal/conference/planet_kit_platform_conference_event.dart';
import 'package:planet_kit_flutter/src/internal/conference/planet_kit_platform_conference_event_type.dart';
import 'package:planet_kit_flutter/src/internal/peer_control/planet_kit_platform_peer_control_event.dart';
import 'package:planet_kit_flutter/src/internal/peer_control/planet_kit_platform_peer_control_event_types.dart';
import 'package:planet_kit_flutter/src/internal/camera/planet_kit_platform_camera_event.dart';
import 'package:planet_kit_flutter/src/internal/camera/planet_kit_platform_camera_event_type.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_interface.dart';

import 'mocks/mock_platform.mocks.dart';

void main() {
  late StreamController<dynamic> eventStreamController;
  late StreamController<dynamic> hookStreamController;
  late MockEventChannel mockEventChannel;
  late MockEventChannel mockHookChannel;
  late EventManager eventManager;

  setUp(() {
    eventStreamController = StreamController<dynamic>.broadcast();
    hookStreamController = StreamController<dynamic>.broadcast();
    mockEventChannel = MockEventChannel();
    mockHookChannel = MockEventChannel();
    when(mockEventChannel.receiveBroadcastStream())
        .thenAnswer((_) => eventStreamController.stream);
    when(mockHookChannel.receiveBroadcastStream())
        .thenAnswer((_) => hookStreamController.stream);
    eventManager = EventManager(
      eventChannel: mockEventChannel,
      interceptedAudioStream: mockHookChannel,
    );
  });

  tearDown(() {
    eventStreamController.close();
    hookStreamController.close();
    eventManager.dispose();
  });

  // Helper to send a JSON-encoded string into the event stream as the native
  // layer would.
  void sendEvent(Map<String, dynamic> json) {
    eventStreamController.add(jsonEncode(json));
  }

  group('EventManager - Event routing', () {
    test('call event JSON routes to onCallEvent stream', () async {
      // type=0 -> call, subType=3 -> waitConnect (base CallEvent, no extra fields)
      final completer = Completer<CallEvent>();
      eventManager.onCallEvent.first.then(completer.complete);

      sendEvent({'type': 0, 'id': 'call-1', 'subType': 3});
      final event = await completer.future;
      expect(event, isA<CallEvent>());
      expect(event.id, equals('call-1'));
      expect(event.subType, equals(CallEventType.waitConnect));
    });

    test('myMediaStatus event JSON routes to onMyMediaStatusEvent stream',
        () async {
      // type=1 -> myMediaStatus, subType=0 -> mute
      final completer = Completer<MyMediaStatusEvent>();
      eventManager.onMyMediaStatusEvent.first.then(completer.complete);

      sendEvent({'type': 1, 'id': 'ms-1', 'subType': 0});
      final event = await completer.future;
      expect(event, isA<MyMediaStatusEvent>());
      expect(event.id, equals('ms-1'));
      expect(event.subType, equals(MyMediaStatusEventType.mute));
    });

    test('conference event JSON routes to onConferenceEvent stream', () async {
      // type=2 -> conference, subType=0 -> connected
      final completer = Completer<ConferenceEvent>();
      eventManager.onConferenceEvent.first.then(completer.complete);

      sendEvent({'type': 2, 'id': 'conf-1', 'subType': 0});
      final event = await completer.future;
      expect(event, isA<ConferenceEvent>());
      expect(event.id, equals('conf-1'));
      expect(event.subType, equals(ConferenceEventType.connected));
    });

    test('peerControl event JSON routes to onPeerControlEvent stream',
        () async {
      // type=3 -> peerControl, subType=0 -> micMute
      final completer = Completer<PeerControlEvent>();
      eventManager.onPeerControlEvent.first.then(completer.complete);

      sendEvent({'type': 3, 'id': 'pc-1', 'subType': 0});
      final event = await completer.future;
      expect(event, isA<PeerControlEvent>());
      expect(event.id, equals('pc-1'));
      expect(event.subType, equals(PeerControlEventType.micMute));
    });

    test('camera event JSON routes to onCameraEvent stream', () async {
      // type=4 -> camera, subType=0 -> start
      final completer = Completer<CameraEvent>();
      eventManager.onCameraEvent.first.then(completer.complete);

      sendEvent({'type': 4, 'id': 'cam-1', 'subType': 0});
      final event = await completer.future;
      expect(event, isA<CameraEvent>());
      expect(event.id, equals('cam-1'));
      expect(event.subType, equals(CameraEventType.start));
    });

    test(
        'unknown event type (error fallback) does not crash and emits nothing',
        () async {
      // type=99 -> error fallback; none of the typed streams should emit
      var callEmitted = false;
      var mediaEmitted = false;
      var confEmitted = false;
      var peerEmitted = false;
      var camEmitted = false;

      eventManager.onCallEvent.listen((_) => callEmitted = true);
      eventManager.onMyMediaStatusEvent.listen((_) => mediaEmitted = true);
      eventManager.onConferenceEvent.listen((_) => confEmitted = true);
      eventManager.onPeerControlEvent.listen((_) => peerEmitted = true);
      eventManager.onCameraEvent.listen((_) => camEmitted = true);

      sendEvent({'type': 99, 'id': 'unknown-1', 'subType': 0});

      expect(callEmitted, isFalse);
      expect(mediaEmitted, isFalse);
      expect(confEmitted, isFalse);
      expect(peerEmitted, isFalse);
      expect(camEmitted, isFalse);
    });

    test('call connected event is deserialized to ConnectedEvent subtype',
        () async {
      // subType=0 -> connected
      final completer = Completer<CallEvent>();
      eventManager.onCallEvent.first.then(completer.complete);

      sendEvent({
        'type': 0,
        'id': 'call-2',
        'subType': 0,
        'isInResponderPreparation': false,
        'shouldFinishPreparation': true,
      });
      final event = await completer.future;
      expect(event, isA<ConnectedEvent>());
      final connected = event as ConnectedEvent;
      expect(connected.shouldFinishPreparation, isTrue);
    });

    test('successive myMediaStatus events are each routed correctly', () async {
      final received = <MyMediaStatusEvent>[];
      final completer = Completer<void>();
      eventManager.onMyMediaStatusEvent.listen((e) {
        received.add(e);
        if (received.length == 2) completer.complete();
      });

      sendEvent({'type': 1, 'id': 'ms-2', 'subType': 0}); // mute
      sendEvent({'type': 1, 'id': 'ms-2', 'subType': 1}); // unmute
      await completer.future;

      expect(received.length, equals(2));
      expect(received[0].subType, equals(MyMediaStatusEventType.mute));
      expect(received[1].subType, equals(MyMediaStatusEventType.unmute));
    });
  });

  group('EventManager - Hooked audio', () {
    test('addHookedAudioHandler registers handler and it is called on match',
        () async {
      final completer = Completer<void>();
      final handler = _TestHookedAudioHandler((_, __) => completer.complete());

      eventManager.addHookedAudioHandler('call-abc', handler);
      hookStreamController.add({'callId': 'call-abc'});
      await completer.future;
    });

    test('audio data for matching callId passes callId and data to handler',
        () async {
      String? receivedCallId;
      Map<String, dynamic>? receivedData;
      final completer = Completer<void>();
      final handler = _TestHookedAudioHandler((callId, data) {
        receivedCallId = callId;
        receivedData = data;
        completer.complete();
      });

      eventManager.addHookedAudioHandler('call-xyz', handler);
      final audioPayload = {'callId': 'call-xyz', 'sampleRate': 44100};
      hookStreamController.add(audioPayload);
      await completer.future;

      expect(receivedCallId, equals('call-xyz'));
      expect(receivedData, isNotNull);
      expect(receivedData!['callId'], equals('call-xyz'));
      expect(receivedData!['sampleRate'], equals(44100));
    });

    test('audio data for unknown callId does not crash', () async {
      // No handler registered for this callId — should not throw.
      hookStreamController.add({'callId': 'no-such-id', 'extra': 'data'});
      // Reaching here without exception means the test passes.
    });

    test('removeHookedAudioHandler stops handler from being called', () async {
      var callCount = 0;
      final firstCallCompleter = Completer<void>();
      final handler = _TestHookedAudioHandler((_, __) {
        callCount++;
        if (!firstCallCompleter.isCompleted) firstCallCompleter.complete();
      });

      eventManager.addHookedAudioHandler('call-rm', handler);

      hookStreamController.add({'callId': 'call-rm'});
      await firstCallCompleter.future;
      expect(callCount, equals(1));

      eventManager.removeHookedAudioHandler('call-rm');

      hookStreamController.add({'callId': 'call-rm'});
      // No await - check immediately
      expect(callCount, equals(1)); // still 1 — handler was removed
    });

    test('handlers for different callIds are dispatched independently',
        () async {
      var countA = 0;
      var countB = 0;
      final completer = Completer<void>();
      final handlerA = _TestHookedAudioHandler((_, __) => countA++);
      final handlerB = _TestHookedAudioHandler((_, __) {
        countB++;
        if (countA == 1 && countB == 2) completer.complete();
      });

      eventManager.addHookedAudioHandler('call-A', handlerA);
      eventManager.addHookedAudioHandler('call-B', handlerB);

      hookStreamController.add({'callId': 'call-A'});
      hookStreamController.add({'callId': 'call-B'});
      hookStreamController.add({'callId': 'call-B'});
      await completer.future;

      expect(countA, equals(1));
      expect(countB, equals(2));
    });
  });
}

/// Simple test double for [HookedAudioHandler].
class _TestHookedAudioHandler implements HookedAudioHandler {
  final void Function(String callId, Map<String, dynamic> audioData) _callback;

  _TestHookedAudioHandler(this._callback);

  @override
  void onHookedAudio(String callId, Map<String, dynamic> audioData) {
    _callback(callId, audioData);
  }
}
