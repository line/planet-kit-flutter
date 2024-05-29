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

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planet_kit_flutter/src/public/call/planet_kit_make_call_param.dart';
import 'package:planet_kit_flutter/src/public/call/planet_kit_verify_call_param.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_init_param.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_manager.dart';
import 'package:planet_kit_flutter/src/internal/call/responses/planet_kit_platform_make_call_response.dart';
import 'package:planet_kit_flutter/src/internal/call/responses/planet_kit_platform_verify_call_response.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_interface.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPlanetKitFlutterPlatform
    with MockPlatformInterfaceMixin
    implements Platform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> acceptCall(String callId) {
    // TODO: implement acceptCall
    throw UnimplementedError();
  }

  @override
  Future<bool> endCall(String callId) {
    // TODO: implement endCall
    throw UnimplementedError();
  }

  @override
  Future<bool> initializePlanetKit(PlanetKitInitParam initParam) {
    // TODO: implement initializePlanetKit
    throw UnimplementedError();
  }

  @override
  Future<bool> isMyAudioMuted(String callId) {
    // TODO: implement isMyAudioMuted
    throw UnimplementedError();
  }

  @override
  Future<bool> isSpeakerOut(String callId) {
    // TODO: implement isMySpeakerOut
    throw UnimplementedError();
  }

  @override
  Future<MakeCallResponse> makeCall(PlanetKitMakeCallParam param) {
    // TODO: implement makeCall
    throw UnimplementedError();
  }

  @override
  Future<bool> muteMyAudio(String callId) {
    // TODO: implement muteMyAudio
    throw UnimplementedError();
  }

  @override
  Future<bool> speakerOut(String callId, bool speakerOut) {
    // TODO: implement speakerOut
    throw UnimplementedError();
  }

  @override
  Future<bool> unmuteMyAudio(String callId) {
    // TODO: implement unmuteMyAudio
    throw UnimplementedError();
  }

  @override
  Future<VerifyCallResponse> verifyCall(PlanetKitVerifyCallParam param) {
    // TODO: implement verifyCall
    throw UnimplementedError();
  }

  @override
  Future<String?> createCcParam(String ccParam) {
    // TODO: implement createCcParam
    throw UnimplementedError();
  }

  @override
  Future<bool> disableHookMyAudio(String callId) {
    // TODO: implement disableInterceptMyAduio
    throw UnimplementedError();
  }

  @override
  Future<bool> enableHookMyAudio(
      String callId, HookedAudioHandler handler) {
    // TODO: implement enableInterceptMyAduio
    throw UnimplementedError();
  }

  @override
  Future<bool> isPeerAudioMuted(String callId) {
    // TODO: implement isPeerAudioMuted
    throw UnimplementedError();
  }

  @override
  Future<bool> putHookedMyAudioBack(String callId, String interceptedAudioId) {
    // TODO: implement putInterceptedMyAudioBack
    throw UnimplementedError();
  }

  @override
  Future<bool> releaseInstance(String id) {
    // TODO: implement releaseInstance
    throw UnimplementedError();
  }

  @override
  Future<bool> setHookedAudioData(String audioId, Uint8List data) {
    // TODO: implement setInterceptedAudioData
    throw UnimplementedError();
  }

  @override
  // TODO: implement eventManager
  EventManagerInterface get eventManager => throw UnimplementedError();

  @override
  Future<bool> isHookMyAudioEnabled(String callId) {
    // TODO: implement isInterceptMyAudioEnabled
    throw UnimplementedError();
  }
}

void main() {
  final Platform initialPlatform = Platform.instance;

  test('$MethodChannelPlanetKit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPlanetKit>());
  });

  test('getPlatformVersion', () async {
    PlanetKitManager planetKitFlutterPlugin = PlanetKitManager.instance;
    MockPlanetKitFlutterPlatform fakePlatform = MockPlanetKitFlutterPlatform();
    Platform.instance = fakePlatform;

    expect(await planetKitFlutterPlugin.getPlatformVersion(), '42');
  });
}
