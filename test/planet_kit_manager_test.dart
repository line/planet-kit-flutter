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

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:planet_kit_flutter/src/internal/call/planet_kit_platform_call_reponses.dart';
import 'package:planet_kit_flutter/src/internal/conference/planet_kit_platform_conference_responses.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_interface.dart';
import 'package:planet_kit_flutter/src/public/call/planet_kit_background_call.dart';
import 'package:planet_kit_flutter/src/public/call/planet_kit_call.dart';
import 'package:planet_kit_flutter/src/public/call/planet_kit_make_call_param.dart';
import 'package:planet_kit_flutter/src/public/call/planet_kit_verify_call_param.dart';
import 'package:planet_kit_flutter/src/public/conference/planet_kit_conference.dart';
import 'package:planet_kit_flutter/src/public/conference/planet_kit_join_conference_param.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_manager.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_start_fail_reason.dart';
import 'package:planet_kit_flutter/src/public/call/planet_kit_cc_param.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_types.dart';

import 'mocks/mock_platform.dart';
import 'mocks/mock_platform.mocks.dart';
import 'mocks/test_streams.dart';

// ---------------------------------------------------------------------------
// Minimal stub event handlers used as dummy arguments.
// ---------------------------------------------------------------------------
PlanetKitCallEventHandler _dummyCallEventHandler() =>
    PlanetKitCallEventHandler(
      onWaitConnected: (_call) {},
      onConnected: (_call, _prep, _cc) {},
      onDisconnected: (_call, _reason, _source, _code, _byRemote) {},
      onVerified: (_call, _prep) {},
      onPreparationFinished: (_call) {},
    );

PlanetKitBackgroundCallEventHandler _dummyBackgroundCallEventHandler() =>
    PlanetKitBackgroundCallEventHandler(
      onDisconnected: (_call, _reason, _source, _code, _byRemote) {},
      onVerified: (_call, _prep) {},
      onError: (_call) {},
      onBackgroundCallAdopted: (_call) {},
    );

PlanetKitConferenceEventHandler _dummyConferenceEventHandler() =>
    PlanetKitConferenceEventHandler(
      onConnected: (_conf) {},
      onDisconnected: (_conf, _reason, _source, _code, _byRemote) {},
      onPeerListUpdated: (_conf, _param) {},
    );

// ---------------------------------------------------------------------------
// Param builders — create new instance each time so tests are independent.
// ---------------------------------------------------------------------------
PlanetKitMakeCallParam _makeCallParam() =>
    PlanetKitMakeCallParamBuilder()
        .setMyUserId('myUser')
        .setMyServiceId('myService')
        .setPeerUserId('peerUser')
        .setPeerServiceId('peerService')
        .setAccessToken('token')
        .build();

PlanetKitCcParam _dummyCcParam() => PlanetKitCcParam(
    id: 'cc-param-id',
    peerId: 'peer',
    peerServiceId: 'peerService',
    mediaType: PlanetKitMediaType.audio);

PlanetKitVerifyCallParam _verifyCallParam() =>
    PlanetKitVerifyCallParamBuilder()
        .setMyUserId('myUser')
        .setMyServiceId('myService')
        .setCcParam(_dummyCcParam())
        .build();

PlanetKitJoinConferenceParam _joinConferenceParam() =>
    PlanetKitJoinConferenceParamBuilder()
        .setMyUserId('myUser')
        .setMyServiceId('myService')
        .setRoomId('room1')
        .setRoomServiceId('roomService')
        .setAccessToken('token')
        .build();

// ---------------------------------------------------------------------------
// _StubPlatform returns canned responses without validating call arguments.
// This is a deliberate trade-off: these tests focus on the manager's
// response-handling logic; argument validation is the responsibility of
// integration tests that exercise the platform channel layer.
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// A thin MockPlatform subclass that exposes the platform methods through
// mockito so that when()/thenAnswer() work without needing argument matchers.
// ---------------------------------------------------------------------------
class _StubPlatform extends MockPlatform {
  MakeCallResponse? _makeCallResponse;
  VerifyCallResponse? _verifyCallResponse;
  VerifyCallResponse? _verifyBackgroundCallResponse;
  JoinConferenceResponse? _joinConferenceResponse;

  void stubMakeCall(MakeCallResponse r) => _makeCallResponse = r;
  void stubVerifyCall(VerifyCallResponse r) => _verifyCallResponse = r;
  void stubVerifyBackgroundCall(VerifyCallResponse r) =>
      _verifyBackgroundCallResponse = r;
  void stubJoinConference(JoinConferenceResponse r) =>
      _joinConferenceResponse = r;

  @override
  Future<MakeCallResponse> makeCall(PlanetKitMakeCallParam param) async =>
      _makeCallResponse!;

  @override
  Future<VerifyCallResponse> verifyCall(PlanetKitVerifyCallParam param) async =>
      _verifyCallResponse!;

  @override
  Future<VerifyCallResponse> verifyBackgroundCall(
          PlanetKitVerifyCallParam param) async =>
      _verifyBackgroundCallResponse!;

  @override
  Future<JoinConferenceResponse> joinConference(
          PlanetKitJoinConferenceParam param) async =>
      _joinConferenceResponse!;
}

void main() {
  late TestStreams streams;
  late MockEventManagerInterface mockEventManager;
  late MockBackgroundEventManagerInterface mockBackgroundEventManager;
  late _StubPlatform mockPlatform;
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
    when(mockBackgroundEventManager.onCallEvent)
        .thenAnswer((_) => streams.backgroundCallEventController.stream);
    mockPlatform = _StubPlatform();
    when(mockPlatform.eventManager).thenReturn(mockEventManager);
    when(mockPlatform.backgroundEventManager)
        .thenReturn(mockBackgroundEventManager);
    mockCallInterface = MockCallInterface();
    when(mockPlatform.callInterface).thenReturn(mockCallInterface);
    mockConferenceInterface = MockConferenceInterface();
    when(mockPlatform.conferenceInterface).thenReturn(mockConferenceInterface);
    Platform.instance = mockPlatform;
  });

  tearDown(() => streams.dispose());

  // =========================================================================
  // makeCall
  // =========================================================================
  group('PlanetKitManager.makeCall', () {
    test('returns null call and failure reason when platform reports failure',
        () async {
      mockPlatform.stubMakeCall(MakeCallResponse(
        callId: null,
        failReason: PlanetKitStartFailReason.invalidParam,
      ));

      final result = await PlanetKitManager.instance
          .makeCall(_makeCallParam(), _dummyCallEventHandler());

      expect(result.call, isNull);
      expect(result.reason, equals(PlanetKitStartFailReason.invalidParam));
    });

    test('returns PlanetKitCall instance when platform reports success',
        () async {
      const callId = 'call-id-1';
      const mediaStatusId = 'media-status-id-1';

      mockPlatform.stubMakeCall(MakeCallResponse(
        callId: callId,
        failReason: PlanetKitStartFailReason.none,
      ));
      when(mockCallInterface.getMyMediaStatus(callId))
          .thenAnswer((_) async => mediaStatusId);

      final result = await PlanetKitManager.instance
          .makeCall(_makeCallParam(), _dummyCallEventHandler());

      expect(result.reason, equals(PlanetKitStartFailReason.none));
      expect(result.call, isA<PlanetKitCall>());
      expect(result.call?.callId, equals(callId));
    });

    test(
        'returns null call when getMyMediaStatus returns null even though callId is present',
        () async {
      const callId = 'call-id-2';

      mockPlatform.stubMakeCall(MakeCallResponse(
        callId: callId,
        failReason: PlanetKitStartFailReason.none,
      ));
      when(mockCallInterface.getMyMediaStatus(callId))
          .thenAnswer((_) async => null);

      final result = await PlanetKitManager.instance
          .makeCall(_makeCallParam(), _dummyCallEventHandler());

      expect(result.reason, equals(PlanetKitStartFailReason.none));
      expect(result.call, isNull);
    });
  });

  // =========================================================================
  // verifyCall
  // =========================================================================
  group('PlanetKitManager.verifyCall', () {
    test('returns null call and failure reason when platform reports failure',
        () async {
      mockPlatform.stubVerifyCall(VerifyCallResponse(
        callId: null,
        failReason: PlanetKitStartFailReason.notInitialized,
      ));

      final result = await PlanetKitManager.instance
          .verifyCall(_verifyCallParam(), _dummyCallEventHandler());

      expect(result.call, isNull);
      expect(result.reason, equals(PlanetKitStartFailReason.notInitialized));
    });

    test('returns PlanetKitCall instance when platform reports success',
        () async {
      const callId = 'verify-call-id-1';
      const mediaStatusId = 'media-status-id-2';

      mockPlatform.stubVerifyCall(VerifyCallResponse(
        callId: callId,
        failReason: PlanetKitStartFailReason.none,
      ));
      when(mockCallInterface.getMyMediaStatus(callId))
          .thenAnswer((_) async => mediaStatusId);

      final result = await PlanetKitManager.instance
          .verifyCall(_verifyCallParam(), _dummyCallEventHandler());

      expect(result.reason, equals(PlanetKitStartFailReason.none));
      expect(result.call, isA<PlanetKitCall>());
      expect(result.call?.callId, equals(callId));
    });

    test(
        'returns null call when getMyMediaStatus returns null even though callId is present',
        () async {
      const callId = 'verify-call-id-2';

      mockPlatform.stubVerifyCall(VerifyCallResponse(
        callId: callId,
        failReason: PlanetKitStartFailReason.none,
      ));
      when(mockCallInterface.getMyMediaStatus(callId))
          .thenAnswer((_) async => null);

      final result = await PlanetKitManager.instance
          .verifyCall(_verifyCallParam(), _dummyCallEventHandler());

      expect(result.reason, equals(PlanetKitStartFailReason.none));
      expect(result.call, isNull);
    });
  });

  // =========================================================================
  // verifyBackgroundCall
  // =========================================================================
  group('PlanetKitManager.verifyBackgroundCall', () {
    test('returns null call and failure reason when platform reports failure',
        () async {
      mockPlatform.stubVerifyBackgroundCall(VerifyCallResponse(
        callId: null,
        failReason: PlanetKitStartFailReason.invalidParam,
      ));

      final result = await PlanetKitManager.instance.verifyBackgroundCall(
        _verifyCallParam(),
        _dummyBackgroundCallEventHandler(),
      );

      expect(result.call, isNull);
      expect(result.reason, equals(PlanetKitStartFailReason.invalidParam));
    });

    test(
        'returns PlanetKitBackgroundCall instance when platform reports success',
        () async {
      const callId = 'bg-call-id-1';

      mockPlatform.stubVerifyBackgroundCall(VerifyCallResponse(
        callId: callId,
        failReason: PlanetKitStartFailReason.none,
      ));

      final result = await PlanetKitManager.instance.verifyBackgroundCall(
        _verifyCallParam(),
        _dummyBackgroundCallEventHandler(),
      );

      expect(result.reason, equals(PlanetKitStartFailReason.none));
      expect(result.call, isA<PlanetKitBackgroundCall>());
      expect(result.call!.backgroundCallId, equals(callId));
    });

    test('returns null call when callId is null even if failReason is none',
        () async {
      mockPlatform.stubVerifyBackgroundCall(VerifyCallResponse(
        callId: null,
        failReason: PlanetKitStartFailReason.none,
      ));

      final result = await PlanetKitManager.instance.verifyBackgroundCall(
        _verifyCallParam(),
        _dummyBackgroundCallEventHandler(),
      );

      expect(result.reason, equals(PlanetKitStartFailReason.none));
      expect(result.call, isNull);
    });
  });

  // =========================================================================
  // joinConference
  // =========================================================================
  group('PlanetKitManager.joinConference', () {
    test(
        'returns null conference and failure reason when platform reports failure',
        () async {
      mockPlatform.stubJoinConference(JoinConferenceResponse(
        id: null,
        failReason: PlanetKitStartFailReason.invalidParam,
      ));

      final result = await PlanetKitManager.instance.joinConference(
          _joinConferenceParam(), _dummyConferenceEventHandler());

      expect(result.conference, isNull);
      expect(result.reason, equals(PlanetKitStartFailReason.invalidParam));
    });

    test('returns PlanetKitConference instance when platform reports success',
        () async {
      const conferenceId = 'conf-id-1';
      const mediaStatusId = 'media-status-id-3';

      mockPlatform.stubJoinConference(JoinConferenceResponse(
        id: conferenceId,
        failReason: PlanetKitStartFailReason.none,
      ));
      when(mockConferenceInterface.getMyMediaStatus(conferenceId))
          .thenAnswer((_) async => mediaStatusId);

      final result = await PlanetKitManager.instance.joinConference(
          _joinConferenceParam(), _dummyConferenceEventHandler());

      expect(result.reason, equals(PlanetKitStartFailReason.none));
      expect(result.conference, isA<PlanetKitConference>());
    });

    test(
        'returns null conference when getMyMediaStatus returns null even though id is present',
        () async {
      const conferenceId = 'conf-id-2';

      mockPlatform.stubJoinConference(JoinConferenceResponse(
        id: conferenceId,
        failReason: PlanetKitStartFailReason.none,
      ));
      when(mockConferenceInterface.getMyMediaStatus(conferenceId))
          .thenAnswer((_) async => null);

      final result = await PlanetKitManager.instance.joinConference(
          _joinConferenceParam(), _dummyConferenceEventHandler());

      expect(result.reason, equals(PlanetKitStartFailReason.none));
      expect(result.conference, isNull);
    });
  });
}
