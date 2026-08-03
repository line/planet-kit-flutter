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
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_event_types.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_interface.dart';
import 'package:planet_kit_flutter/src/public/call/planet_kit_call.dart';
import 'package:planet_kit_flutter/src/public/conference/planet_kit_conference.dart';
import 'package:planet_kit_flutter/src/public/conference/planet_kit_conference_peer.dart';
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
    void Function(PlanetKitCall, Uint8List, Duration)? onPeerSharedContentsSet,
    void Function(PlanetKitCall)? onPeerSharedContentsUnset,
    void Function(PlanetKitCall, Uint8List, Duration)?
        onPeerExclusivelySharedContentsSet,
    void Function(PlanetKitCall)? onPeerExclusivelySharedContentsUnset,
  }) {
    final handler = PlanetKitCallEventHandler(
      onWaitConnected: (_) {},
      onConnected: (_, __, ___) {},
      onDisconnected: (_, __, ___, ____, _____) {},
      onVerified: (_, __) {},
      onPreparationFinished: (_) {},
      onPeerSharedContentsSet: onPeerSharedContentsSet,
      onPeerSharedContentsUnset: onPeerSharedContentsUnset,
      onPeerExclusivelySharedContentsSet: onPeerExclusivelySharedContentsSet,
      onPeerExclusivelySharedContentsUnset:
          onPeerExclusivelySharedContentsUnset,
    );
    return PlanetKitCall(
        callId: callId,
        eventHandler: handler,
        myMediaStatus: PlanetKitMyMediaStatus(myMediaStatusId: 'media-$callId'));
  }

  PlanetKitConference makeConference({
    String id = 'conf-id',
    void Function(PlanetKitConference, List<PlanetKitConferenceSharedContents>)?
        onPeersSharedContentsSet,
    void Function(PlanetKitConference, List<PlanetKitConferencePeer>)?
        onPeersSharedContentsUnset,
    void Function(PlanetKitConference, PlanetKitConferencePeer, Uint8List,
            Duration)?
        onPeerExclusivelySharedContentsSet,
    void Function(PlanetKitConference, PlanetKitConferencePeer)?
        onPeerExclusivelySharedContentsUnset,
    void Function(PlanetKitConference, PlanetKitUserId, Uint8List, Duration)?
        onPeerRoomSharedContentsSet,
    void Function(PlanetKitConference, PlanetKitUserId)?
        onPeerRoomSharedContentsUnset,
  }) {
    final handler = PlanetKitConferenceEventHandler(
      onConnected: (_) {},
      onDisconnected: (_, __, ___, ____, _____) {},
      onPeerListUpdated: (_, __) {},
      onPeersSharedContentsSet: onPeersSharedContentsSet,
      onPeersSharedContentsUnset: onPeersSharedContentsUnset,
      onPeerExclusivelySharedContentsSet: onPeerExclusivelySharedContentsSet,
      onPeerExclusivelySharedContentsUnset:
          onPeerExclusivelySharedContentsUnset,
      onPeerRoomSharedContentsSet: onPeerRoomSharedContentsSet,
      onPeerRoomSharedContentsUnset: onPeerRoomSharedContentsUnset,
    );
    return PlanetKitConference(
        id: id,
        eventHandler: handler,
        myMediaStatus: PlanetKitMyMediaStatus(myMediaStatusId: 'media-$id'));
  }

  // Adds a peer 'p1' (u1/s1) to the conference's peer map via a peerListUpdate.
  void addPeer(String confId, String peerId, String userId, String serviceId) {
    streams.conferenceEventController.add(conf.PeerListUpdateEvent.fromJson({
      'type': 2,
      'id': confId,
      'subType': 2,
      'added': [
        {'id': peerId, 'userId': userId, 'serviceId': serviceId}
      ],
      'removed': <String>[],
      'totalPeersCount': 1,
    }));
  }

  // =========================================================================
  // Send — call (normal + exclusive, set + unset)
  // =========================================================================
  group('Contents Sharing - send (call)', () {
    test('setSharedContents delegates', () async {
      final data = Uint8List.fromList([1, 2, 3]);
      when(mockCallInterface.setSharedContents('call-id', data))
          .thenAnswer((_) async => true);
      expect(await makeCall().setSharedContents(data), isTrue);
      verify(mockCallInterface.setSharedContents('call-id', data)).called(1);
    });

    test('unsetSharedContents delegates', () async {
      when(mockCallInterface.unsetSharedContents('call-id'))
          .thenAnswer((_) async => true);
      expect(await makeCall().unsetSharedContents(), isTrue);
      verify(mockCallInterface.unsetSharedContents('call-id')).called(1);
    });

    test('setExclusivelySharedContents delegates', () async {
      final data = Uint8List.fromList([9]);
      when(mockCallInterface.setExclusivelySharedContents('call-id', data))
          .thenAnswer((_) async => true);
      expect(await makeCall().setExclusivelySharedContents(data), isTrue);
      verify(mockCallInterface.setExclusivelySharedContents('call-id', data))
          .called(1);
    });

    test('unsetExclusivelySharedContents delegates', () async {
      when(mockCallInterface.unsetExclusivelySharedContents('call-id'))
          .thenAnswer((_) async => true);
      expect(await makeCall().unsetExclusivelySharedContents(), isTrue);
      verify(mockCallInterface.unsetExclusivelySharedContents('call-id'))
          .called(1);
    });
  });

  // =========================================================================
  // Send — conference (normal + exclusive + room)
  // =========================================================================
  group('Contents Sharing - send (conference)', () {
    test('setSharedContents / unsetSharedContents delegate', () async {
      final data = Uint8List.fromList([1]);
      when(mockConferenceInterface.setSharedContents('conf-id', data))
          .thenAnswer((_) async => true);
      when(mockConferenceInterface.unsetSharedContents('conf-id'))
          .thenAnswer((_) async => true);
      expect(await makeConference().setSharedContents(data), isTrue);
      expect(await makeConference().unsetSharedContents(), isTrue);
      verify(mockConferenceInterface.setSharedContents('conf-id', data))
          .called(1);
      verify(mockConferenceInterface.unsetSharedContents('conf-id')).called(1);
    });

    test('exclusive set/unset delegate', () async {
      final data = Uint8List.fromList([2]);
      when(mockConferenceInterface.setExclusivelySharedContents(
              'conf-id', data))
          .thenAnswer((_) async => true);
      when(mockConferenceInterface.unsetExclusivelySharedContents('conf-id'))
          .thenAnswer((_) async => true);
      expect(await makeConference().setExclusivelySharedContents(data), isTrue);
      expect(await makeConference().unsetExclusivelySharedContents(), isTrue);
      verify(mockConferenceInterface.setExclusivelySharedContents(
              'conf-id', data))
          .called(1);
      verify(mockConferenceInterface.unsetExclusivelySharedContents('conf-id'))
          .called(1);
    });

    test('room set/unset delegate', () async {
      final data = Uint8List.fromList([3]);
      when(mockConferenceInterface.setRoomSharedContents('conf-id', data))
          .thenAnswer((_) async => true);
      when(mockConferenceInterface.unsetRoomSharedContents('conf-id'))
          .thenAnswer((_) async => true);
      expect(await makeConference().setRoomSharedContents(data), isTrue);
      expect(await makeConference().unsetRoomSharedContents(), isTrue);
      verify(mockConferenceInterface.setRoomSharedContents('conf-id', data))
          .called(1);
      verify(mockConferenceInterface.unsetRoomSharedContents('conf-id'))
          .called(1);
    });
  });

  // =========================================================================
  // Receive — call
  // =========================================================================
  group('Contents Sharing - receive (call)', () {
    test('peerSharedContentsSet delivers data + elapsed Duration', () async {
      Uint8List? gotData;
      Duration? gotElapsed;
      final completer = Completer<void>();
      makeCall(
        callId: 'c1',
        onPeerSharedContentsSet: (_, d, e) {
          gotData = d;
          gotElapsed = e;
          completer.complete();
        },
      );
      final raw = Uint8List.fromList([10, 11]);
      streams.callEventController.add(PeerSharedContentsSetEvent.fromJson({
        'type': 0,
        'id': 'c1',
        'subType': 21,
        'data': base64Encode(raw),
        'elapsedMillis': 1500,
      }));
      await completer.future;
      expect(gotData, equals(raw));
      expect(gotElapsed, equals(const Duration(milliseconds: 1500)));
    });

    test('peerSharedContentsUnset invokes the unset callback', () async {
      final completer = Completer<void>();
      makeCall(
          callId: 'c1',
          onPeerSharedContentsUnset: (_) => completer.complete());
      streams.callEventController.add(
          CallEvent(EventType.call, 'c1', CallEventType.peerSharedContentsUnset));
      await completer.future;
    });

    test('peerExclusivelySharedContentsSet delivers data + elapsed', () async {
      Uint8List? gotData;
      Duration? gotElapsed;
      final completer = Completer<void>();
      makeCall(
        callId: 'c1',
        onPeerExclusivelySharedContentsSet: (_, d, e) {
          gotData = d;
          gotElapsed = e;
          completer.complete();
        },
      );
      final raw = Uint8List.fromList([42]);
      streams.callEventController
          .add(PeerExclusivelySharedContentsSetEvent.fromJson({
        'type': 0,
        'id': 'c1',
        'subType': 23,
        'data': base64Encode(raw),
        'elapsedMillis': 2000,
      }));
      await completer.future;
      expect(gotData, equals(raw));
      expect(gotElapsed, equals(const Duration(milliseconds: 2000)));
    });

    test('peerExclusivelySharedContentsUnset invokes the unset callback',
        () async {
      final completer = Completer<void>();
      makeCall(
          callId: 'c1',
          onPeerExclusivelySharedContentsUnset: (_) => completer.complete());
      streams.callEventController.add(CallEvent(
          EventType.call, 'c1', CallEventType.peerExclusivelySharedContentsUnset));
      await completer.future;
    });
  });

  // =========================================================================
  // Receive — conference (peer resolution + room)
  // =========================================================================
  group('Contents Sharing - receive (conference)', () {
    test('peersSharedContentsSet resolves peer and delivers data + elapsed',
        () async {
      List<PlanetKitConferenceSharedContents>? got;
      final completer = Completer<void>();
      final conference = makeConference(
        id: 'cf1',
        onPeersSharedContentsSet: (_, list) {
          got = list;
          completer.complete();
        },
      );
      addPeer('cf1', 'p1', 'u1', 's1');

      final raw = Uint8List.fromList([7, 7]);
      streams.conferenceEventController
          .add(conf.PeersSharedContentsSetEvent.fromJson({
        'type': 2,
        'id': 'cf1',
        'subType': 11,
        'contents': [
          {'peer': 'p1', 'data': base64Encode(raw), 'elapsedMillis': 500}
        ],
      }));
      await completer.future;
      expect(got, isNotNull);
      expect(got!.length, equals(1));
      expect(got!.first.peer.userId.userId, equals('u1'));
      expect(got!.first.data, equals(raw));
      expect(got!.first.elapsed, equals(const Duration(milliseconds: 500)));
    });

    test('peersSharedContentsUnset resolves peers', () async {
      List<PlanetKitConferencePeer>? got;
      final completer = Completer<void>();
      final conference = makeConference(
        id: 'cf1',
        onPeersSharedContentsUnset: (_, peers) {
          got = peers;
          completer.complete();
        },
      );
      addPeer('cf1', 'p1', 'u1', 's1');

      streams.conferenceEventController
          .add(conf.PeersSharedContentsUnsetEvent.fromJson({
        'type': 2,
        'id': 'cf1',
        'subType': 12,
        'peers': ['p1'],
      }));
      await completer.future;
      expect(got, isNotNull);
      expect(got!.single.userId.userId, equals('u1'));
    });

    test('peerRoomSharedContentsSet delivers PlanetKitUserId + data + elapsed',
        () async {
      PlanetKitUserId? sender;
      Uint8List? gotData;
      Duration? gotElapsed;
      final completer = Completer<void>();
      makeConference(
        id: 'cf1',
        onPeerRoomSharedContentsSet: (_, id, d, e) {
          sender = id;
          gotData = d;
          gotElapsed = e;
          completer.complete();
        },
      );
      final raw = Uint8List.fromList([1, 2, 3, 4]);
      streams.conferenceEventController
          .add(conf.PeerRoomSharedContentsSetEvent.fromJson({
        'type': 2,
        'id': 'cf1',
        'subType': 15,
        'userId': 'ru',
        'serviceId': 'rs',
        'data': base64Encode(raw),
        'elapsedMillis': 3000,
      }));
      await completer.future;
      expect(sender?.userId, equals('ru'));
      expect(sender?.serviceId, equals('rs'));
      expect(gotData, equals(raw));
      expect(gotElapsed, equals(const Duration(milliseconds: 3000)));
    });

    test('peerRoomSharedContentsUnset delivers PlanetKitUserId', () async {
      PlanetKitUserId? sender;
      final completer = Completer<void>();
      makeConference(
        id: 'cf1',
        onPeerRoomSharedContentsUnset: (_, id) {
          sender = id;
          completer.complete();
        },
      );
      streams.conferenceEventController
          .add(conf.PeerRoomSharedContentsUnsetEvent.fromJson({
        'type': 2,
        'id': 'cf1',
        'subType': 16,
        'userId': 'ru',
        'serviceId': 'rs',
      }));
      await completer.future;
      expect(sender?.userId, equals('ru'));
      expect(sender?.serviceId, equals('rs'));
    });
  });
}
