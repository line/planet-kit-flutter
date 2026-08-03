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
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:planet_kit_flutter/src/internal/call/planet_kit_platform_call_event.dart';
import 'package:planet_kit_flutter/src/internal/call/planet_kit_platform_call_event_type.dart';
import 'package:planet_kit_flutter/src/internal/conference/planet_kit_platform_conference_event.dart'
    as conf;
import 'package:planet_kit_flutter/src/internal/conference/planet_kit_platform_conference_event_type.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_event_types.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_interface.dart';
import 'package:planet_kit_flutter/src/public/call/planet_kit_call.dart';
import 'package:planet_kit_flutter/src/public/conference/planet_kit_conference.dart';
import 'package:planet_kit_flutter/src/public/my_media_status/planet_kit_my_media_status.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_user_id.dart';

import 'mocks/mock_platform.dart';
import 'mocks/mock_platform.mocks.dart';
import 'mocks/test_streams.dart';

void main() {
  late TestStreams streams;
  late MockEventManagerInterface mockEventManager;
  late MockBackgroundEventManagerInterface mockBackgroundEventManager;
  late MockPlatform mockPlatform;
  late MockCallInterface mockCallInterface;
  late MockConferenceInterface mockConferenceInterface;

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
    mockPlatform = MockPlatform();
    when(mockPlatform.eventManager).thenReturn(mockEventManager);
    when(mockPlatform.backgroundEventManager)
        .thenReturn(mockBackgroundEventManager);
    mockCallInterface = MockCallInterface();
    mockConferenceInterface = MockConferenceInterface();
    when(mockPlatform.callInterface).thenReturn(mockCallInterface);
    when(mockPlatform.conferenceInterface).thenReturn(mockConferenceInterface);
    Platform.instance = mockPlatform;
  });

  tearDown(() => streams.dispose());

  PlanetKitCall makeCall({
    String callId = 'call-id',
    void Function(PlanetKitCall, String, Uint8List)? onShortDataReceived,
  }) {
    final handler = PlanetKitCallEventHandler(
      onWaitConnected: (_) {},
      onConnected: (_, __, ___) {},
      onDisconnected: (_, __, ___, ____, _____) {},
      onVerified: (_, __) {},
      onPreparationFinished: (_) {},
      onShortDataReceived: onShortDataReceived,
    );
    return PlanetKitCall(
        callId: callId,
        eventHandler: handler,
        myMediaStatus: PlanetKitMyMediaStatus(myMediaStatusId: 'media-$callId'));
  }

  PlanetKitConference makeConference({
    String id = 'conf-id',
    void Function(PlanetKitConference, PlanetKitUserId, String, Uint8List)?
        onShortDataReceived,
  }) {
    final handler = PlanetKitConferenceEventHandler(
      onConnected: (_) {},
      onDisconnected: (_, __, ___, ____, _____) {},
      onPeerListUpdated: (_, __) {},
      onShortDataReceived: onShortDataReceived,
    );
    return PlanetKitConference(
        id: id,
        eventHandler: handler,
        myMediaStatus: PlanetKitMyMediaStatus(myMediaStatusId: 'media-$id'));
  }

  // =========================================================================
  // Send — call
  // =========================================================================
  group('Short Data - send (call)', () {
    test('call.sendShortData delegates to callInterface and returns its result',
        () async {
      final data = Uint8List.fromList([0x01, 0x02, 0x03]);
      when(mockCallInterface.sendShortData('call-id', 'reaction', data))
          .thenAnswer((_) async => true);

      final call = makeCall();
      final ret = await call.sendShortData(type: 'reaction', data: data);

      expect(ret, isTrue);
      verify(mockCallInterface.sendShortData('call-id', 'reaction', data))
          .called(1);
    });

    test('call.sendShortData propagates a false result', () async {
      final data = Uint8List.fromList([0x09]);
      when(mockCallInterface.sendShortData(any, any, any))
          .thenAnswer((_) async => false);

      final call = makeCall();
      expect(await call.sendShortData(type: 't', data: data), isFalse);
    });
  });

  // =========================================================================
  // Send — conference (broadcast + targeted)
  // =========================================================================
  group('Short Data - send (conference)', () {
    test('conference.sendShortData (broadcast) delegates to conferenceInterface',
        () async {
      final data = Uint8List.fromList([0x01]);
      when(mockConferenceInterface.sendShortData('conf-id', 'reaction', data))
          .thenAnswer((_) async => true);

      final conference = makeConference();
      expect(
          await conference.sendShortData(type: 'reaction', data: data), isTrue);
      verify(mockConferenceInterface.sendShortData('conf-id', 'reaction', data))
          .called(1);
    });

    test('conference.sendShortDataToPeer delegates with the target peerId',
        () async {
      final data = Uint8List.fromList([0x02, 0x02]);
      final peer = PlanetKitUserId(userId: 'u1', serviceId: 's1');
      when(mockConferenceInterface.sendShortDataToPeer(
              'conf-id', peer, 'reaction', data))
          .thenAnswer((_) async => true);

      final conference = makeConference();
      expect(
          await conference.sendShortDataToPeer(
              peerId: peer, type: 'reaction', data: data),
          isTrue);
      verify(mockConferenceInterface.sendShortDataToPeer(
              'conf-id', peer, 'reaction', data))
          .called(1);
    });
  });

  // =========================================================================
  // Receive — call
  // =========================================================================
  group('Short Data - receive (call)', () {
    test('ShortDataReceivedEvent is dispatched to onShortDataReceived',
        () async {
      String? gotType;
      Uint8List? gotData;
      final completer = Completer<void>();
      makeCall(
        callId: 'call-1',
        onShortDataReceived: (c, t, d) {
          gotType = t;
          gotData = d;
          completer.complete();
        },
      );

      final data = Uint8List.fromList([0x01, 0x02]);
      streams.callEventController.add(ShortDataReceivedEvent(
          EventType.call, 'call-1', CallEventType.shortDataReceived,
          'reaction', data));

      await completer.future;
      expect(gotType, equals('reaction'));
      expect(gotData, equals(data));
    });

    test('event for a different callId is ignored', () async {
      var called = false;
      makeCall(
          callId: 'target',
          onShortDataReceived: (_, __, ___) => called = true);

      streams.callEventController.add(ShortDataReceivedEvent(
          EventType.call, 'other', CallEventType.shortDataReceived, 't',
          Uint8List.fromList([0x01])));

      await Future<void>.delayed(Duration.zero);
      expect(called, isFalse);
    });
  });

  // =========================================================================
  // Receive — conference (with senderId)
  // =========================================================================
  group('Short Data - receive (conference)', () {
    test('ShortDataReceivedEvent is dispatched with the sender identity',
        () async {
      PlanetKitUserId? sender;
      String? gotType;
      Uint8List? gotData;
      final completer = Completer<void>();
      makeConference(
        id: 'conf-1',
        onShortDataReceived: (c, s, t, d) {
          sender = s;
          gotType = t;
          gotData = d;
          completer.complete();
        },
      );

      final data = Uint8List.fromList([0x07, 0x08, 0x09]);
      streams.conferenceEventController.add(conf.ShortDataReceivedEvent(
          EventType.conference,
          'conf-1',
          ConferenceEventType.shortDataReceived,
          'u1',
          's1',
          'reaction',
          data));

      await completer.future;
      expect(sender?.userId, equals('u1'));
      expect(sender?.serviceId, equals('s1'));
      expect(gotType, equals('reaction'));
      expect(gotData, equals(data));
    });
  });

  // =========================================================================
  // Event decoding from native JSON (base64 payload)
  // =========================================================================
  group('Short Data - event JSON decode', () {
    test('call ShortDataReceivedEvent.fromJson base64-decodes the data',
        () {
      final raw = Uint8List.fromList([10, 20, 30]);
      final event = ShortDataReceivedEvent.fromJson({
        'type': 0,
        'id': 'c',
        'subType': 20,
        'dataType': 'reaction',
        'data': base64Encode(raw),
      });

      expect(event.subType, equals(CallEventType.shortDataReceived));
      expect(event.dataType, equals('reaction'));
      expect(event.data, equals(raw));
    });

    test(
        'conference ShortDataReceivedEvent.fromJson base64-decodes data and reads sender',
        () {
      final raw = Uint8List.fromList([5, 6]);
      final event = conf.ShortDataReceivedEvent.fromJson({
        'type': 2,
        'id': 'cf',
        'subType': 10,
        'userId': 'u',
        'serviceId': 's',
        'dataType': 'reaction',
        'data': base64Encode(raw),
      });

      expect(event.subType, equals(ConferenceEventType.shortDataReceived));
      expect(event.userId, equals('u'));
      expect(event.serviceId, equals('s'));
      expect(event.dataType, equals('reaction'));
      expect(event.data, equals(raw));
    });

    test('event-type codes map to shortDataReceived', () {
      expect(CallEventType.fromInt(20), equals(CallEventType.shortDataReceived));
      expect(ConferenceEventType.fromInt(10),
          equals(ConferenceEventType.shortDataReceived));
    });
  });
}
