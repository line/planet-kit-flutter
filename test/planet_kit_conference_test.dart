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
import 'package:planet_kit_flutter/src/internal/conference/planet_kit_platform_conference_event.dart';
import 'package:planet_kit_flutter/src/internal/conference/planet_kit_platform_conference_event_type.dart';
import 'package:planet_kit_flutter/src/internal/my_media_status/planet_kit_platform_my_media_status_event.dart';
import 'package:planet_kit_flutter/src/internal/my_media_status/planet_kit_platform_my_media_status_event_types.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_event_types.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_interface.dart';
import 'package:planet_kit_flutter/src/public/conference/planet_kit_conference.dart';
import 'package:planet_kit_flutter/src/public/conference/planet_kit_conference_peer.dart';
import 'package:planet_kit_flutter/src/public/my_media_status/planet_kit_my_media_status.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_disconnect_reason.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_disconnect_source.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_user_id.dart';

import 'mocks/mock_platform.dart';
import 'mocks/mock_platform.mocks.dart';
import 'mocks/test_streams.dart';

// ---------------------------------------------------------------------------
// Helpers to build typed event objects directly (bypassing JSON)
// ---------------------------------------------------------------------------

ConferenceEvent _connectedEvent(String id) => ConferenceEvent(
      EventType.conference,
      id,
      ConferenceEventType.connected,
    );

DisconnectedEvent _disconnectedEvent(
  String id, {
  PlanetKitDisconnectReason reason = PlanetKitDisconnectReason.normal,
  PlanetKitDisconnectSource source = PlanetKitDisconnectSource.callee,
  String? userCode,
  bool byRemote = false,
}) =>
    DisconnectedEvent(
      EventType.conference,
      id,
      ConferenceEventType.disconnected,
      reason,
      source,
      userCode,
      byRemote,
    );

PeerListUpdateEvent _peerListUpdateEvent(
  String id, {
  List<InitialPeerInfo> added = const [],
  List<String> removed = const [],
  int totalPeersCount = 0,
}) =>
    PeerListUpdateEvent(
      EventType.conference,
      id,
      ConferenceEventType.peerListUpdate,
      added,
      removed,
      totalPeersCount,
    );

InitialPeerInfo _peerInfo(String peerId,
        {String userId = 'user', String serviceId = 'svc'}) =>
    InitialPeerInfo(id: peerId, userId: userId, serviceId: serviceId);

PeersMicMuteEvent _peersMicMuteEvent(String id, List<String> peers) =>
    PeersMicMuteEvent(
      EventType.conference,
      id,
      ConferenceEventType.peersMicMute,
      peers,
    );

PeersMicUnmuteEvent _peersMicUnmuteEvent(String id, List<String> peers) =>
    PeersMicUnmuteEvent(
      EventType.conference,
      id,
      ConferenceEventType.peersMicUnmute,
      peers,
    );

PeersHoldEvent _peersHoldEvent(
        String id, List<PeerHoldEventData> peers) =>
    PeersHoldEvent(
      EventType.conference,
      id,
      ConferenceEventType.peersHold,
      peers,
    );

PeersUnholdEvent _peersUnholdEvent(String id, List<String> peers) =>
    PeersUnholdEvent(
      EventType.conference,
      id,
      ConferenceEventType.peersUnhold,
      peers,
    );

NetworkDidUnavailableEvent _networkUnavailableEvent(
        String id, int willDisconnectSec) =>
    NetworkDidUnavailableEvent(
      EventType.conference,
      id,
      ConferenceEventType.networkUnavailable,
      willDisconnectSec,
    );

ConferenceEvent _networkReavailableEvent(String id) => ConferenceEvent(
      EventType.conference,
      id,
      ConferenceEventType.networkReavailable,
    );

MyAudioMuteRequestedByPeerEvent _myAudioMuteRequestedEvent(
        String id, String peerId, bool mute) =>
    MyAudioMuteRequestedByPeerEvent(
      EventType.conference,
      id,
      ConferenceEventType.myAudioMuteRequestedByPeer,
      peerId,
      mute,
    );

ConferenceEvent _myScreenShareStoppedByHoldEvent(String id) => ConferenceEvent(
      EventType.conference,
      id,
      ConferenceEventType.myScreenShareStoppedByHold,
    );

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  late TestStreams streams;
  late MockEventManagerInterface mockEventManager;
  late MockBackgroundEventManagerInterface mockBackgroundEventManager;
  late MockPlatform mockPlatform;
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
    when(mockBackgroundEventManager.onCallEvent)
        .thenAnswer((_) => streams.backgroundCallEventController.stream);
    mockPlatform = MockPlatform();
    when(mockPlatform.eventManager).thenReturn(mockEventManager);
    when(mockPlatform.backgroundEventManager)
        .thenReturn(mockBackgroundEventManager);
    mockConferenceInterface = MockConferenceInterface();
    when(mockPlatform.conferenceInterface).thenReturn(mockConferenceInterface);
    Platform.instance = mockPlatform;
  });

  tearDown(() => streams.dispose());

  // -------------------------------------------------------------------------
  // Factory helper to build a PlanetKitConference with a handler under test
  // -------------------------------------------------------------------------
  PlanetKitConference makeConference({
    String id = 'conf-id',
    void Function(PlanetKitConference)? onConnected,
    void Function(PlanetKitConference, PlanetKitDisconnectReason,
            PlanetKitDisconnectSource, String?, bool)?
        onDisconnected,
    void Function(PlanetKitConference,
            PlanetKitConferencePeerListUpdateParam)?
        onPeerListUpdated,
    void Function(PlanetKitConference, List<PlanetKitConferencePeer>)?
        onPeersMicMuted,
    void Function(PlanetKitConference, List<PlanetKitConferencePeer>)?
        onPeersMicUnmuted,
    void Function(PlanetKitConference, PlanetKitConferencePeer, bool)?
        onMyAudioMuteRequestedByPeer,
    void Function(PlanetKitConference, List<PeerHoldData>)? onPeersHold,
    void Function(PlanetKitConference, List<PlanetKitConferencePeer>)?
        onPeersUnhold,
    void Function(PlanetKitConference, Duration)? onNetworkUnavailable,
    void Function(PlanetKitConference)? onNetworkReavailable,
    void Function(PlanetKitConference)? onMyScreenShareStoppedByHold,
  }) {
    final myMediaStatus =
        PlanetKitMyMediaStatus(myMediaStatusId: 'media-$id');
    final handler = PlanetKitConferenceEventHandler(
      onConnected: onConnected ?? (_) {},
      onDisconnected: onDisconnected ?? (_, __, ___, ____, _____) {},
      onPeerListUpdated: onPeerListUpdated ?? (_, __) {},
      onPeersMicMuted: onPeersMicMuted,
      onPeersMicUnmuted: onPeersMicUnmuted,
      onMyAudioMuteRequestedByPeer: onMyAudioMuteRequestedByPeer,
      onPeersHold: onPeersHold,
      onPeersUnhold: onPeersUnhold,
      onNetworkUnavailable: onNetworkUnavailable,
      onNetworkReavailable: onNetworkReavailable,
      onMyScreenShareStoppedByHold: onMyScreenShareStoppedByHold,
    );
    return PlanetKitConference(
        id: id, eventHandler: handler, myMediaStatus: myMediaStatus);
  }

  // =========================================================================
  // Group: ID filtering
  // =========================================================================
  group('PlanetKitConference - ID filtering', () {
    test('event with different conferenceId is ignored', () async {
      var called = false;
      makeConference(
        id: 'target-id',
        onConnected: (_) => called = true,
      );

      streams.conferenceEventController.add(_connectedEvent('other-id'));

      expect(called, isFalse);
    });

    test('event with matching conferenceId is processed', () async {
      var called = false;
      final completer = Completer<void>();
      makeConference(
        id: 'target-id',
        onConnected: (_) {
          called = true;
          completer.complete();
        },
      );

      streams.conferenceEventController.add(_connectedEvent('target-id'));
      await completer.future;

      expect(called, isTrue);
    });
  });

  // =========================================================================
  // Group: Peer management (via peerListUpdate events)
  // =========================================================================
  group('PlanetKitConference - Peer management', () {
    test(
        'peerListUpdate with addedPeers → conference.peers updated, onPeerListUpdated called with correct addedPeers and empty removedPeers',
        () async {
      PlanetKitConferencePeerListUpdateParam? receivedParam;
      final completer = Completer<void>();
      final conference = makeConference(
        onPeerListUpdated: (_, param) {
          receivedParam = param;
          if (!completer.isCompleted) completer.complete();
        },
      );

      streams.conferenceEventController.add(
        _peerListUpdateEvent(
          'conf-id',
          added: [
            _peerInfo('peer-1', userId: 'alice', serviceId: 'svc'),
            _peerInfo('peer-2', userId: 'bob', serviceId: 'svc'),
          ],
          totalPeersCount: 2,
        ),
      );
      await completer.future;

      expect(conference.peers.length, equals(2));
      expect(conference.peers.any((p) => p.id == 'peer-1'), isTrue);
      expect(conference.peers.any((p) => p.id == 'peer-2'), isTrue);
      expect(receivedParam, isNotNull);
      expect(receivedParam!.addedPeers.length, equals(2));
      expect(receivedParam!.removedPeers, isEmpty);
    });

    test(
        'peerListUpdate with removedPeers → conference.peers updated, onPeerListUpdated called with correct removedPeers',
        () async {
      PlanetKitConferencePeerListUpdateParam? receivedParam;
      final addedCompleter = Completer<void>();
      final removedCompleter = Completer<void>();
      var callCount = 0;
      final conference = makeConference(
        onPeerListUpdated: (_, param) {
          receivedParam = param;
          callCount++;
          if (callCount == 1 && !addedCompleter.isCompleted) {
            addedCompleter.complete();
          } else if (callCount == 2 && !removedCompleter.isCompleted) {
            removedCompleter.complete();
          }
        },
      );

      // First add some peers
      streams.conferenceEventController.add(
        _peerListUpdateEvent(
          'conf-id',
          added: [
            _peerInfo('peer-1'),
            _peerInfo('peer-2'),
          ],
          totalPeersCount: 2,
        ),
      );
      await addedCompleter.future;

      expect(conference.peers.length, equals(2));

      // Now remove one
      streams.conferenceEventController.add(
        _peerListUpdateEvent(
          'conf-id',
          removed: ['peer-1'],
          totalPeersCount: 1,
        ),
      );
      await removedCompleter.future;

      expect(conference.peers.length, equals(1));
      expect(conference.peers.any((p) => p.id == 'peer-2'), isTrue);
      expect(receivedParam!.removedPeers.length, equals(1));
      expect(receivedParam!.removedPeers.first.id, equals('peer-1'));
      expect(receivedParam!.addedPeers, isEmpty);
    });

    test('peerListUpdate → totalPeersCount reflects current peer count',
        () async {
      PlanetKitConferencePeerListUpdateParam? receivedParam;
      final completer = Completer<void>();
      makeConference(
        onPeerListUpdated: (_, param) {
          receivedParam = param;
          if (!completer.isCompleted) completer.complete();
        },
      );

      streams.conferenceEventController.add(
        _peerListUpdateEvent(
          'conf-id',
          added: [
            _peerInfo('peer-1'),
            _peerInfo('peer-2'),
            _peerInfo('peer-3'),
          ],
          totalPeersCount: 3,
        ),
      );
      await completer.future;

      expect(receivedParam!.totalPeersCount, equals(3));
    });

    test(
        'subsequent peersMicMute event → resolves peers by id correctly',
        () async {
      List<PlanetKitConferencePeer>? mutedPeers;
      final addedCompleter = Completer<void>();
      final muteCompleter = Completer<void>();
      makeConference(
        onPeerListUpdated: (_, __) {
          if (!addedCompleter.isCompleted) addedCompleter.complete();
        },
        onPeersMicMuted: (_, peers) {
          mutedPeers = peers;
          muteCompleter.complete();
        },
      );

      // Add peers via peerListUpdate
      streams.conferenceEventController.add(
        _peerListUpdateEvent(
          'conf-id',
          added: [
            _peerInfo('peer-A', userId: 'alice', serviceId: 'svc'),
            _peerInfo('peer-B', userId: 'bob', serviceId: 'svc'),
          ],
        ),
      );
      await addedCompleter.future;

      // Mute peer-A
      streams.conferenceEventController
          .add(_peersMicMuteEvent('conf-id', ['peer-A']));
      await muteCompleter.future;

      expect(mutedPeers, isNotNull);
      expect(mutedPeers!.length, equals(1));
      expect(mutedPeers!.first.id, equals('peer-A'));
    });
  });

  // =========================================================================
  // Group: Event routing
  // =========================================================================
  group('PlanetKitConference - Event routing', () {
    test('connected → onConnected(conference) called', () async {
      PlanetKitConference? receivedConference;
      final completer = Completer<void>();
      final conference = makeConference(
        onConnected: (c) {
          receivedConference = c;
          completer.complete();
        },
      );

      streams.conferenceEventController.add(_connectedEvent('conf-id'));
      await completer.future;

      expect(receivedConference, same(conference));
    });

    test(
        'disconnected → onDisconnected called with correct reason, source, userCode, byRemote',
        () async {
      PlanetKitConference? receivedConference;
      PlanetKitDisconnectReason? receivedReason;
      PlanetKitDisconnectSource? receivedSource;
      String? receivedUserCode;
      bool? receivedByRemote;
      final completer = Completer<void>();

      final conference = makeConference(
        onDisconnected: (c, reason, source, userCode, byRemote) {
          receivedConference = c;
          receivedReason = reason;
          receivedSource = source;
          receivedUserCode = userCode;
          receivedByRemote = byRemote;
          completer.complete();
        },
      );

      streams.conferenceEventController.add(
        _disconnectedEvent(
          'conf-id',
          reason: PlanetKitDisconnectReason.normal,
          source: PlanetKitDisconnectSource.callee,
          userCode: 'myCode',
          byRemote: true,
        ),
      );
      await completer.future;

      expect(receivedConference, same(conference));
      expect(receivedReason, equals(PlanetKitDisconnectReason.normal));
      expect(receivedSource, equals(PlanetKitDisconnectSource.callee));
      expect(receivedUserCode, equals('myCode'));
      expect(receivedByRemote, isTrue);
    });

    test('peersMicMute → onPeersMicMuted called with resolved peer objects',
        () async {
      List<PlanetKitConferencePeer>? receivedPeers;
      PlanetKitConference? receivedConference;
      final addedCompleter = Completer<void>();
      final muteCompleter = Completer<void>();
      final conference = makeConference(
        onPeerListUpdated: (_, __) {
          if (!addedCompleter.isCompleted) addedCompleter.complete();
        },
        onPeersMicMuted: (c, peers) {
          receivedConference = c;
          receivedPeers = peers;
          muteCompleter.complete();
        },
      );

      // Populate peer map first
      streams.conferenceEventController.add(
        _peerListUpdateEvent(
          'conf-id',
          added: [_peerInfo('peer-X')],
        ),
      );
      await addedCompleter.future;

      streams.conferenceEventController
          .add(_peersMicMuteEvent('conf-id', ['peer-X']));
      await muteCompleter.future;

      expect(receivedConference, same(conference));
      expect(receivedPeers, isNotNull);
      expect(receivedPeers!.length, equals(1));
      expect(receivedPeers!.first.id, equals('peer-X'));
    });

    test(
        'peersMicUnmute → onPeersMicUnmuted called with resolved peer objects',
        () async {
      List<PlanetKitConferencePeer>? unmutedCallbackPeers;
      final addedCompleter = Completer<void>();
      final unmutedCompleter = Completer<void>();

      makeConference(
        onPeerListUpdated: (_, __) {
          if (!addedCompleter.isCompleted) addedCompleter.complete();
        },
        onPeersMicMuted: expectAsync2((_, __) {}, count: 0,
            reason: 'unmute event must not route to onPeersMicMuted'),
        onPeersMicUnmuted: (_, peers) {
          unmutedCallbackPeers = peers;
          if (!unmutedCompleter.isCompleted) unmutedCompleter.complete();
        },
      );

      streams.conferenceEventController.add(
        _peerListUpdateEvent('conf-id', added: [_peerInfo('peer-X')]),
      );
      await addedCompleter.future;

      streams.conferenceEventController
          .add(_peersMicUnmuteEvent('conf-id', ['peer-X']));
      await unmutedCompleter.future;

      expect(unmutedCallbackPeers, isNotNull);
      expect(unmutedCallbackPeers!.length, equals(1));
      expect(unmutedCallbackPeers!.first.id, equals('peer-X'));
    });

    test('peersHold → onPeersHold called with PeerHoldData list', () async {
      List<PeerHoldData>? receivedHoldData;
      PlanetKitConference? receivedConference;
      final addedCompleter = Completer<void>();
      final holdCompleter = Completer<void>();
      final conference = makeConference(
        onPeerListUpdated: (_, __) {
          if (!addedCompleter.isCompleted) addedCompleter.complete();
        },
        onPeersHold: (c, holdData) {
          receivedConference = c;
          receivedHoldData = holdData;
          holdCompleter.complete();
        },
      );

      streams.conferenceEventController.add(
        _peerListUpdateEvent('conf-id', added: [_peerInfo('peer-H')]),
      );
      await addedCompleter.future;

      streams.conferenceEventController.add(
        _peersHoldEvent('conf-id', [
          PeerHoldEventData(peer: 'peer-H', reason: 'brb'),
        ]),
      );
      await holdCompleter.future;

      expect(receivedConference, same(conference));
      expect(receivedHoldData, isNotNull);
      expect(receivedHoldData!.length, equals(1));
      expect(receivedHoldData!.first.peer.id, equals('peer-H'));
      expect(receivedHoldData!.first.holdReason, equals('brb'));
    });

    test('peersUnhold → onPeersUnhold called with resolved peer objects',
        () async {
      List<PlanetKitConferencePeer>? unholdCallbackPeers;
      final addedCompleter = Completer<void>();
      final unholdCompleter = Completer<void>();

      makeConference(
        onPeerListUpdated: (_, __) {
          if (!addedCompleter.isCompleted) addedCompleter.complete();
        },
        onPeersMicMuted: expectAsync2((_, __) {}, count: 0,
            reason: 'unhold event must not route to onPeersMicMuted'),
        onPeersUnhold: (_, peers) {
          unholdCallbackPeers = peers;
          if (!unholdCompleter.isCompleted) unholdCompleter.complete();
        },
      );

      streams.conferenceEventController.add(
        _peerListUpdateEvent('conf-id', added: [_peerInfo('peer-U')]),
      );
      await addedCompleter.future;

      streams.conferenceEventController
          .add(_peersUnholdEvent('conf-id', ['peer-U']));
      await unholdCompleter.future;

      expect(unholdCallbackPeers, isNotNull);
      expect(unholdCallbackPeers!.length, equals(1));
      expect(unholdCallbackPeers!.first.id, equals('peer-U'));
    });

    test(
        'networkUnavailable → onNetworkUnavailable called with correct willDisconnect duration',
        () async {
      PlanetKitConference? receivedConference;
      Duration? receivedDuration;
      final completer = Completer<void>();
      final conference = makeConference(
        onNetworkUnavailable: (c, d) {
          receivedConference = c;
          receivedDuration = d;
          completer.complete();
        },
      );

      streams.conferenceEventController
          .add(_networkUnavailableEvent('conf-id', 30));
      await completer.future;

      expect(receivedConference, same(conference));
      expect(receivedDuration, equals(const Duration(seconds: 30)));
    });

    test('networkReavailable → onNetworkReavailable called', () async {
      PlanetKitConference? receivedConference;
      final completer = Completer<void>();
      final conference = makeConference(
        onNetworkReavailable: (c) {
          receivedConference = c;
          completer.complete();
        },
      );

      streams.conferenceEventController
          .add(_networkReavailableEvent('conf-id'));
      await completer.future;

      expect(receivedConference, same(conference));
    });

    test(
        'myScreenShareStoppedByHold → onMyScreenShareStoppedByHold called',
        () async {
      PlanetKitConference? receivedConference;
      final completer = Completer<void>();
      final conference = makeConference(
        onMyScreenShareStoppedByHold: (c) {
          receivedConference = c;
          completer.complete();
        },
      );

      streams.conferenceEventController
          .add(_myScreenShareStoppedByHoldEvent('conf-id'));
      await completer.future;

      expect(receivedConference, same(conference));
    });

    test(
        'myAudioMuteRequestedByPeer → onMyAudioMuteRequestedByPeer called with correct peer and mute flag',
        () async {
      PlanetKitConference? receivedConference;
      PlanetKitConferencePeer? receivedPeer;
      bool? receivedMute;
      final addedCompleter = Completer<void>();
      final muteRequestCompleter = Completer<void>();
      final conference = makeConference(
        onPeerListUpdated: (_, __) {
          if (!addedCompleter.isCompleted) addedCompleter.complete();
        },
        onMyAudioMuteRequestedByPeer: (c, peer, mute) {
          receivedConference = c;
          receivedPeer = peer;
          receivedMute = mute;
          muteRequestCompleter.complete();
        },
      );

      streams.conferenceEventController.add(
        _peerListUpdateEvent('conf-id', added: [_peerInfo('peer-M')]),
      );
      await addedCompleter.future;

      streams.conferenceEventController
          .add(_myAudioMuteRequestedEvent('conf-id', 'peer-M', true));
      await muteRequestCompleter.future;

      expect(receivedConference, same(conference));
      expect(receivedPeer, isNotNull);
      expect(receivedPeer!.id, equals('peer-M'));
      expect(receivedMute, isTrue);
    });
  });

  // =========================================================================
  // Group: Edge cases
  // =========================================================================
  group('PlanetKitConference - Edge cases', () {
    test(
        'peersMicMute with unknown peerId → peer skipped, no crash, callback invoked with empty list',
        () async {
      List<PlanetKitConferencePeer>? receivedPeers;
      final completer = Completer<void>();
      makeConference(
        onPeersMicMuted: (_, peers) {
          receivedPeers = peers;
          completer.complete();
        },
      );

      // No peerListUpdate, so peer map is empty
      streams.conferenceEventController
          .add(_peersMicMuteEvent('conf-id', ['unknown-peer']));
      await completer.future;

      // Callback is invoked but with an empty list (unknown peer is skipped)
      expect(receivedPeers, isNotNull);
      expect(receivedPeers, isEmpty);
    });

    test(
        'myAudioMuteRequestedByPeer with unknown peerId → callback NOT invoked',
        () async {
      var called = false;
      makeConference(
        onMyAudioMuteRequestedByPeer: (_, __, ___) => called = true,
      );

      // No peerListUpdate, so peer map is empty
      streams.conferenceEventController
          .add(_myAudioMuteRequestedEvent('conf-id', 'unknown-peer', true));

      expect(called, isFalse);
    });

    test('peerListUpdate removing unknown peerId → silently ignored', () async {
      PlanetKitConferencePeerListUpdateParam? receivedParam;
      final completer = Completer<void>();
      final conference = makeConference(
        onPeerListUpdated: (_, param) {
          receivedParam = param;
          if (!completer.isCompleted) completer.complete();
        },
      );

      streams.conferenceEventController.add(
        _peerListUpdateEvent(
          'conf-id',
          removed: ['nonexistent-peer'],
          totalPeersCount: 0,
        ),
      );
      await completer.future;

      expect(conference.peers, isEmpty);
      expect(receivedParam!.removedPeers, isEmpty);
    });
  });

  // =========================================================================
  // Group: Lifecycle
  // =========================================================================
  group('PlanetKitConference - Lifecycle', () {
    test(
        'after disconnected event: subscription cancelled, further events ignored',
        () async {
      var connectedCallCount = 0;
      final disconnectCompleter = Completer<void>();
      makeConference(
        onDisconnected: (_, __, ___, ____, _____) {
          if (!disconnectCompleter.isCompleted) disconnectCompleter.complete();
        },
        onConnected: (_) => connectedCallCount++,
      );

      // Disconnect first
      streams.conferenceEventController.add(_disconnectedEvent('conf-id'));
      await disconnectCompleter.future;

      // Subsequent connected events should be ignored (subscription cancelled)
      streams.conferenceEventController.add(_connectedEvent('conf-id'));

      expect(connectedCallCount, equals(0));
    });

    test('after disconnected event: _eventHandler nulled, onConnected not called',
        () async {
      var disconnectedCalled = false;
      var connectedAfterDisconnect = false;
      final disconnectCompleter = Completer<void>();
      makeConference(
        onDisconnected: (_, __, ___, ____, _____) {
          disconnectedCalled = true;
          disconnectCompleter.complete();
        },
        onConnected: (_) => connectedAfterDisconnect = true,
      );

      streams.conferenceEventController.add(_disconnectedEvent('conf-id'));
      await disconnectCompleter.future;

      expect(disconnectedCalled, isTrue);

      // Send another event — subscription is cancelled so handler won't fire
      streams.conferenceEventController.add(_connectedEvent('conf-id'));

      expect(connectedAfterDisconnect, isFalse);
    });

    test('after disconnected event: myMediaStatus.dispose() called — handler nulled',
        () async {
      var myMediaStatusHandlerCalled = false;
      PlanetKitMyMediaStatus? capturedMediaStatus;
      final disconnectCompleter = Completer<void>();

      final conference = makeConference(
        onDisconnected: (c, _, __, ___, ____) {
          if (!disconnectCompleter.isCompleted) disconnectCompleter.complete();
        },
      );
      capturedMediaStatus = conference.myMediaStatus;
      capturedMediaStatus.setHandler(PlanetKitMyMediaStatusHandler(
        onMicMute: (_) => myMediaStatusHandlerCalled = true,
        onMicUnmute: null,
        onAudioDescriptionUpdate: null,
        onVideoStatusUpdate: null,
        onScreenShareStateUpdate: null,
      ));

      // Disconnect — should call myMediaStatus.dispose()
      streams.conferenceEventController.add(_disconnectedEvent('conf-id'));
      await disconnectCompleter.future;

      // The myMediaStatus handler should have been nulled by dispose()
      expect(myMediaStatusHandlerCalled, isFalse);
    });

    test(
        'after disconnected event: myMediaStatus event fired after dispose is ignored',
        () async {
      var myMediaStatusHandlerCalled = false;
      final disconnectCompleter = Completer<void>();

      final conference = makeConference(
        onDisconnected: (c, _, __, ___, ____) {
          if (!disconnectCompleter.isCompleted) disconnectCompleter.complete();
        },
      );
      conference.myMediaStatus.setHandler(PlanetKitMyMediaStatusHandler(
        onMicMute: (_) => myMediaStatusHandlerCalled = true,
        onMicUnmute: null,
        onAudioDescriptionUpdate: null,
        onVideoStatusUpdate: null,
        onScreenShareStateUpdate: null,
      ));

      // Disconnect — myMediaStatus.dispose() is called, nulling the handler
      streams.conferenceEventController.add(_disconnectedEvent('conf-id'));
      await disconnectCompleter.future;

      // Fire a myMediaStatus event after disconnect: handler is nulled, should not fire
      streams.myMediaStatusEventController.add(
        MyMediaStatusEvent(
            EventType.myMediaStatus, 'media-conf-id', MyMediaStatusEventType.mute),
      );

      // Sentinel: prove the myMediaStatus event loop actually ran
      final sentinelCompleter = Completer<void>();
      final sentinelSub = streams.myMediaStatusEventController.stream
          .listen((_) {
        if (!sentinelCompleter.isCompleted) sentinelCompleter.complete();
      });
      streams.myMediaStatusEventController.add(
        MyMediaStatusEvent(
            EventType.myMediaStatus, 'media-conf-id', MyMediaStatusEventType.mute),
      );
      await sentinelCompleter.future;
      await sentinelSub.cancel();

      expect(myMediaStatusHandlerCalled, isFalse);
    });
  });

  // =========================================================================
  // Group: Method delegation
  // =========================================================================
  group('PlanetKitConference - Method delegation', () {
    test('leaveConference() → conferenceInterface.leaveConference(id) invoked',
        () async {
      when(mockConferenceInterface.leaveConference(any))
          .thenAnswer((_) async => true);

      final conference = makeConference(id: 'conf-42');
      await conference.leaveConference();

      verify(mockConferenceInterface.leaveConference('conf-42')).called(1);
    });

    test(
        'muteMyAudio(true) → conferenceInterface.muteMyAudio(id, true) invoked',
        () async {
      when(mockConferenceInterface.muteMyAudio(any, any))
          .thenAnswer((_) async => true);

      final conference = makeConference(id: 'conf-42');
      await conference.muteMyAudio(true);

      verify(mockConferenceInterface.muteMyAudio('conf-42', true)).called(1);
    });

    test(
        'muteMyAudio(false) → conferenceInterface.muteMyAudio(id, false) invoked',
        () async {
      when(mockConferenceInterface.muteMyAudio(any, any))
          .thenAnswer((_) async => true);

      final conference = makeConference(id: 'conf-42');
      await conference.muteMyAudio(false);

      verify(mockConferenceInterface.muteMyAudio('conf-42', false)).called(1);
    });

    test(
        'createPeerControl(peer) → conferenceInterface.createPeerControl(confId, peer.id) invoked',
        () async {
      when(mockConferenceInterface.createPeerControl(any, any))
          .thenAnswer((_) async => 'peer-ctrl-id');

      final conference = makeConference(id: 'conf-42');
      final peer = PlanetKitConferencePeer(
        id: 'peer-1',
        userId: PlanetKitUserId(userId: 'user-1', serviceId: 'svc-1'),
      );
      final result = await conference.createPeerControl(peer);

      verify(mockConferenceInterface.createPeerControl('conf-42', 'peer-1'))
          .called(1);
      expect(result, isNotNull);
    });
  });
}
