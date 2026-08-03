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
import 'package:planet_kit_flutter/src/internal/conference/planet_kit_platform_conference_event.dart'
    as conf;
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_interface.dart';
import 'package:planet_kit_flutter/src/public/call/planet_kit_call.dart';
import 'package:planet_kit_flutter/src/public/conference/planet_kit_conference.dart';
import 'package:planet_kit_flutter/src/public/data_session/planet_kit_data_session.dart';
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
    void Function(PlanetKitCall, PlanetKitDataSessionStreamId,
            PlanetKitDataSessionType)?
        onDataSessionIncoming,
  }) {
    final handler = PlanetKitCallEventHandler(
      onWaitConnected: (_) {},
      onConnected: (_, __, ___) {},
      onDisconnected: (_, __, ___, ____, _____) {},
      onVerified: (_, __) {},
      onPreparationFinished: (_) {},
      onDataSessionIncoming: onDataSessionIncoming,
    );
    return PlanetKitCall(
        callId: callId,
        eventHandler: handler,
        myMediaStatus: PlanetKitMyMediaStatus(myMediaStatusId: 'media-$callId'));
  }

  PlanetKitConference makeConference({
    String id = 'conf-id',
    void Function(PlanetKitConference, PlanetKitDataSessionStreamId,
            PlanetKitDataSessionType)?
        onDataSessionIncoming,
  }) {
    final handler = PlanetKitConferenceEventHandler(
      onConnected: (_) {},
      onDisconnected: (_, __, ___, ____, _____) {},
      onPeerListUpdated: (_, __) {},
      onDataSessionIncoming: onDataSessionIncoming,
    );
    return PlanetKitConference(
        id: id,
        eventHandler: handler,
        myMediaStatus: PlanetKitMyMediaStatus(myMediaStatusId: 'media-$id'));
  }

  // =========================================================================
  // Type / fail-reason int mapping (wire contract with native)
  // =========================================================================
  group('Data Session - enum int mapping', () {
    test('type int values match native', () {
      expect(PlanetKitDataSessionType.reliableMessage.intValue, 1);
      expect(PlanetKitDataSessionType.reliableBytes.intValue, 2);
      expect(PlanetKitDataSessionType.unreliableBytes.intValue, 3);
      expect(PlanetKitDataSessionType.unreliableMessage.intValue, 4);
      expect(PlanetKitDataSessionType.fromInt(0), isNull);
      expect(PlanetKitDataSessionType.fromInt(2),
          PlanetKitDataSessionType.reliableBytes);
    });

    test('fail reason int values match native (2 unused)', () {
      expect(PlanetKitDataSessionFailReason.fromInt(0),
          PlanetKitDataSessionFailReason.none);
      expect(PlanetKitDataSessionFailReason.fromInt(3),
          PlanetKitDataSessionFailReason.notIncoming);
      expect(PlanetKitDataSessionFailReason.fromInt(4),
          PlanetKitDataSessionFailReason.alreadyExist);
      expect(PlanetKitDataSessionFailReason.fromInt(5),
          PlanetKitDataSessionFailReason.invalidId);
    });

    test('closed reason int values match native', () {
      expect(PlanetKitDataSessionClosedReason.fromInt(0),
          PlanetKitDataSessionClosedReason.sessionEnd);
      expect(PlanetKitDataSessionClosedReason.fromInt(2),
          PlanetKitDataSessionClosedReason.unsupported);
    });
  });

  // =========================================================================
  // Outbound — call
  // =========================================================================
  group('Data Session - outbound (call)', () {
    test('makeOutbound success returns session and send delegates', () async {
      final data = Uint8List.fromList([1, 2, 3]);
      when(mockCallInterface.makeOutboundDataSession('c1', 100, 2))
          .thenAnswer((_) async => 0);
      when(mockCallInterface.dataSessionSend('c1', 100, data, 42))
          .thenAnswer((_) async => true);

      final result = await makeCall(callId: 'c1').makeOutboundDataSession(
          100,
          PlanetKitDataSessionType.reliableBytes,
          const PlanetKitOutboundDataSessionHandler());

      expect(result.reason, PlanetKitDataSessionFailReason.none);
      expect(result.dataSession, isNotNull);
      expect(result.dataSession!.streamId, 100);
      expect(result.dataSession!.type, PlanetKitDataSessionType.reliableBytes);
      expect(await result.dataSession!.send(data, 42), isTrue);
      verify(mockCallInterface.dataSessionSend('c1', 100, data, 42)).called(1);
    });

    test('makeOutbound failure (alreadyExist) returns null session', () async {
      when(mockCallInterface.makeOutboundDataSession('c1', 100, 1))
          .thenAnswer((_) async => 4);

      final result = await makeCall(callId: 'c1').makeOutboundDataSession(
          100,
          PlanetKitDataSessionType.reliableMessage,
          const PlanetKitOutboundDataSessionHandler());

      expect(result.reason, PlanetKitDataSessionFailReason.alreadyExist);
      expect(result.dataSession, isNull);
    });

    test('makeOutbound failure (invalidId) returns null session', () async {
      when(mockCallInterface.makeOutboundDataSession('c1', 5, 1))
          .thenAnswer((_) async => 5);

      final result = await makeCall(callId: 'c1').makeOutboundDataSession(
          5,
          PlanetKitDataSessionType.reliableMessage,
          const PlanetKitOutboundDataSessionHandler());

      expect(result.reason, PlanetKitDataSessionFailReason.invalidId);
      expect(result.dataSession, isNull);
    });

    test('outbound close routes to handler and removes session', () async {
      when(mockCallInterface.makeOutboundDataSession('c1', 100, 2))
          .thenAnswer((_) async => 0);
      when(mockCallInterface.getOutboundDataSessionType('c1', 100))
          .thenAnswer((_) async => null);

      PlanetKitDataSessionClosedReason? gotReason;
      final completer = Completer<void>();
      final call = makeCall(callId: 'c1');
      await call.makeOutboundDataSession(
          100,
          PlanetKitDataSessionType.reliableBytes,
          PlanetKitOutboundDataSessionHandler(onClose: (_, r) {
            gotReason = r;
            completer.complete();
          }));

      streams.callEventController.add(DataSessionOutboundClosedEvent.fromJson({
        'type': 0,
        'id': 'c1',
        'subType': 28,
        'streamId': 100,
        'closedReason': 2,
      }));
      await completer.future;
      expect(gotReason, PlanetKitDataSessionClosedReason.unsupported);
      // After close the session is removed; getOutbound falls back to native (null).
      expect(await call.getOutboundDataSession(100), isNull);
    });

    test('tooLongQueuedData routes enabled flag to handler', () async {
      when(mockCallInterface.makeOutboundDataSession('c1', 100, 2))
          .thenAnswer((_) async => 0);
      final flags = <bool>[];
      final completer = Completer<void>();
      final call = makeCall(callId: 'c1');
      await call.makeOutboundDataSession(
          100,
          PlanetKitDataSessionType.reliableBytes,
          PlanetKitOutboundDataSessionHandler(onTooLongQueuedData: (_, e) {
            flags.add(e);
            if (flags.length == 2) completer.complete();
          }));

      streams.callEventController
          .add(DataSessionOutboundTooLongQueuedDataEvent.fromJson({
        'type': 0,
        'id': 'c1',
        'subType': 29,
        'streamId': 100,
        'enabled': true,
      }));
      streams.callEventController
          .add(DataSessionOutboundTooLongQueuedDataEvent.fromJson({
        'type': 0,
        'id': 'c1',
        'subType': 29,
        'streamId': 100,
        'enabled': false,
      }));
      await completer.future;
      expect(flags, equals([true, false]));
    });
  });

  // =========================================================================
  // Inbound + incoming — call
  // =========================================================================
  group('Data Session - inbound (call)', () {
    test('incoming notification delivers streamId + type', () async {
      PlanetKitDataSessionStreamId? gotStreamId;
      PlanetKitDataSessionType? gotType;
      final completer = Completer<void>();
      makeCall(
          callId: 'c1',
          onDataSessionIncoming: (_, s, t) {
            gotStreamId = s;
            gotType = t;
            completer.complete();
          });

      streams.callEventController.add(DataSessionIncomingEvent.fromJson({
        'type': 0,
        'id': 'c1',
        'subType': 25,
        'streamId': 200,
        'dataSessionType': 3,
      }));
      await completer.future;
      expect(gotStreamId, 200);
      expect(gotType, PlanetKitDataSessionType.unreliableBytes);
    });

    test('makeInbound without incoming fails with notIncoming', () async {
      when(mockCallInterface.makeInboundDataSession('c1', 100))
          .thenAnswer((_) async => 3);

      final result = await makeCall(callId: 'c1').makeInboundDataSession(
          100, const PlanetKitInboundDataSessionHandler());

      expect(result.reason, PlanetKitDataSessionFailReason.notIncoming);
      expect(result.dataSession, isNull);
    });

    test('makeInbound after incoming succeeds and receive routes data',
        () async {
      final incoming = Completer<void>();
      final call = makeCall(
          callId: 'c1', onDataSessionIncoming: (_, __, ___) => incoming.complete());
      // Drive the incoming notification so the inbound type is known.
      streams.callEventController.add(DataSessionIncomingEvent.fromJson({
        'type': 0,
        'id': 'c1',
        'subType': 25,
        'streamId': 100,
        'dataSessionType': 2,
      }));
      await incoming.future;

      when(mockCallInterface.makeInboundDataSession('c1', 100))
          .thenAnswer((_) async => 0);

      PlanetKitUserId? gotPeer;
      Uint8List? gotData;
      int? gotTs;
      int? gotOffset;
      final received = Completer<void>();
      final result = await call.makeInboundDataSession(
          100,
          PlanetKitInboundDataSessionHandler(onReceive: (_, peer, d, ts, off) {
            gotPeer = peer;
            gotData = d;
            gotTs = ts;
            gotOffset = off;
            received.complete();
          }));
      expect(result.reason, PlanetKitDataSessionFailReason.none);
      expect(result.dataSession!.type, PlanetKitDataSessionType.reliableBytes);

      final raw = Uint8List.fromList([5, 6, 7]);
      streams.callEventController
          .add(DataSessionInboundReceivedEvent.fromJson({
        'type': 0,
        'id': 'c1',
        'subType': 26,
        'streamId': 100,
        'userId': 'u1',
        'serviceId': 's1',
        'data': base64Encode(raw),
        'timestamp': 99,
        'offset': 3,
      }));
      await received.future;
      expect(gotPeer!.userId, 'u1');
      expect(gotPeer!.serviceId, 's1');
      expect(gotData, equals(raw));
      expect(gotTs, 99);
      expect(gotOffset, 3);
    });

    test('inbound close routes reason to handler', () async {
      final incoming = Completer<void>();
      final call = makeCall(
          callId: 'c1', onDataSessionIncoming: (_, __, ___) => incoming.complete());
      streams.callEventController.add(DataSessionIncomingEvent.fromJson({
        'type': 0,
        'id': 'c1',
        'subType': 25,
        'streamId': 100,
        'dataSessionType': 1,
      }));
      await incoming.future;

      when(mockCallInterface.makeInboundDataSession('c1', 100))
          .thenAnswer((_) async => 0);

      PlanetKitDataSessionClosedReason? gotReason;
      final closed = Completer<void>();
      await call.makeInboundDataSession(
          100,
          PlanetKitInboundDataSessionHandler(onClose: (_, r) {
            gotReason = r;
            closed.complete();
          }));
      streams.callEventController.add(DataSessionInboundClosedEvent.fromJson({
        'type': 0,
        'id': 'c1',
        'subType': 27,
        'streamId': 100,
        'closedReason': 0,
      }));
      await closed.future;
      expect(gotReason, PlanetKitDataSessionClosedReason.sessionEnd);
    });

    test('unsupportInboundDataSession delegates', () async {
      when(mockCallInterface.unsupportInboundDataSession('c1', 300))
          .thenAnswer((_) async => true);
      expect(await makeCall(callId: 'c1').unsupportInboundDataSession(300),
          isTrue);
      verify(mockCallInterface.unsupportInboundDataSession('c1', 300))
          .called(1);
    });
  });

  // =========================================================================
  // Conference (parity smoke: outbound make/send + incoming + receive)
  // =========================================================================
  group('Data Session - conference', () {
    test('makeOutbound success + send delegates', () async {
      final data = Uint8List.fromList([8, 9]);
      when(mockConferenceInterface.makeOutboundDataSession('cf1', 100, 2))
          .thenAnswer((_) async => 0);
      when(mockConferenceInterface.dataSessionSend('cf1', 100, data, 7))
          .thenAnswer((_) async => true);

      final result = await makeConference(id: 'cf1').makeOutboundDataSession(
          100,
          PlanetKitDataSessionType.reliableBytes,
          const PlanetKitOutboundDataSessionHandler());
      expect(result.reason, PlanetKitDataSessionFailReason.none);
      expect(await result.dataSession!.send(data, 7), isTrue);
    });

    test('incoming + inbound receive routes peerId/data/offset', () async {
      final incoming = Completer<void>();
      final conference = makeConference(
          id: 'cf1',
          onDataSessionIncoming: (_, __, ___) => incoming.complete());
      streams.conferenceEventController
          .add(conf.DataSessionIncomingEvent.fromJson({
        'type': 2,
        'id': 'cf1',
        'subType': 17,
        'streamId': 100,
        'dataSessionType': 2,
      }));
      await incoming.future;

      when(mockConferenceInterface.makeInboundDataSession('cf1', 100))
          .thenAnswer((_) async => 0);

      PlanetKitUserId? gotPeer;
      Uint8List? gotData;
      int? gotOffset;
      final received = Completer<void>();
      await conference.makeInboundDataSession(
          100,
          PlanetKitInboundDataSessionHandler(onReceive: (_, peer, d, ts, off) {
            gotPeer = peer;
            gotData = d;
            gotOffset = off;
            received.complete();
          }));

      final raw = Uint8List.fromList([1, 1, 2]);
      streams.conferenceEventController
          .add(conf.DataSessionInboundReceivedEvent.fromJson({
        'type': 2,
        'id': 'cf1',
        'subType': 18,
        'streamId': 100,
        'userId': 'pu',
        'serviceId': 'ps',
        'data': base64Encode(raw),
        'timestamp': 3,
        'offset': 0,
      }));
      await received.future;
      expect(gotPeer!.userId, 'pu');
      expect(gotData, equals(raw));
      expect(gotOffset, 0);
    });
  });

  // =========================================================================
  // isDataSessionSupported (call connect param + conference per-peer)
  // =========================================================================
  group('Data Session - isDataSessionSupported', () {
    test('call: set from connected event (true)', () async {
      final call = makeCall(callId: 'c1');
      expect(call.isDataSessionSupported, isFalse); // default before connect
      streams.callEventController.add(ConnectedEvent.fromJson({
        'type': 0,
        'id': 'c1',
        'subType': 0,
        'isInResponderPreparation': false,
        'shouldFinishPreparation': false,
        'isDataSessionSupported': true,
      }));
      await Future<void>.delayed(Duration.zero);
      expect(call.isDataSessionSupported, isTrue);
    });

    test('call: defaults to false when field absent', () async {
      final call = makeCall(callId: 'c2');
      streams.callEventController.add(ConnectedEvent.fromJson({
        'type': 0,
        'id': 'c2',
        'subType': 0,
        'isInResponderPreparation': false,
        'shouldFinishPreparation': false,
      }));
      await Future<void>.delayed(Duration.zero);
      expect(call.isDataSessionSupported, isFalse);
    });

    test('conference: per-peer flag from peer list update', () async {
      final conference = makeConference(id: 'cf1');
      streams.conferenceEventController.add(conf.PeerListUpdateEvent.fromJson({
        'type': 2,
        'id': 'cf1',
        'subType': 2,
        'added': [
          {
            'id': 'p1',
            'userId': 'u1',
            'serviceId': 's1',
            'isDataSessionSupported': true
          },
          {'id': 'p2', 'userId': 'u2', 'serviceId': 's2'}
        ],
        'removed': <String>[],
        'totalPeersCount': 2,
      }));
      await Future<void>.delayed(Duration.zero);
      final p1 = conference.peers.firstWhere((p) => p.id == 'p1');
      final p2 = conference.peers.firstWhere((p) => p.id == 'p2');
      expect(p1.isDataSessionSupported, isTrue);
      expect(p2.isDataSessionSupported, isFalse); // absent → default false
    });
  });

  // =========================================================================
  // get* must not cache a handler-less session (review P3)
  // =========================================================================
  group('Data Session - get does not mask a later make', () {
    test('close routes to the real handler attached by a make after get',
        () async {
      // Native reports an existing outbound session (type reliableBytes)...
      when(mockCallInterface.getOutboundDataSessionType('c1', 100))
          .thenAnswer((_) async => 2);
      when(mockCallInterface.makeOutboundDataSession('c1', 100, 2))
          .thenAnswer((_) async => 0);
      final call = makeCall(callId: 'c1');

      // get before make: returns a session but must NOT cache a no-op handler.
      final got = await call.getOutboundDataSession(100);
      expect(got, isNotNull);

      // A subsequent make with a real handler must register and receive events.
      PlanetKitDataSessionClosedReason? gotReason;
      final closed = Completer<void>();
      await call.makeOutboundDataSession(
          100,
          PlanetKitDataSessionType.reliableBytes,
          PlanetKitOutboundDataSessionHandler(onClose: (_, r) {
            gotReason = r;
            closed.complete();
          }));
      streams.callEventController.add(DataSessionOutboundClosedEvent.fromJson({
        'type': 0,
        'id': 'c1',
        'subType': 28,
        'streamId': 100,
        'closedReason': 2,
      }));
      await closed.future;
      expect(gotReason, PlanetKitDataSessionClosedReason.unsupported);
    });
  });
}
