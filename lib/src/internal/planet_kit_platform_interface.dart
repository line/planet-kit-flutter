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

import 'dart:typed_data';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'call/responses/planet_kit_platform_make_call_response.dart';
import 'call/responses/planet_kit_platform_verify_call_response.dart';
import 'planet_kit_method_channel.dart';

import '../public/planet_kit_init_param.dart';
import '../public/call/planet_kit_make_call_param.dart';
import '../public/call/planet_kit_verify_call_param.dart';

// TODO: consider enclosing the creation of PlanetKit instance
// that has mapping native instance to be within MethodChannelPlanetKit.
// This will allow MethodChannelPlanetKit user would only use PlanetKit Flutter instances and not instance id.
// Also MethodChannelPlanetKit user would not have to consider native instance management
// and attaching/detaching native events.

abstract class CallEventHandler {
  void onCallEvent(String callId, Map<String, dynamic> data);
}

abstract class HookedAudioHandler {
  void onHookedAudio(String callId, Map<String, dynamic> audioData);
}

abstract class EventManagerInterface {
  void addCallEventHandler(String callId, CallEventHandler eventHandler);
  void removeCallEventHandler(String callId);
  void addHookedAudioHandler(String id, HookedAudioHandler handler);
  void removeHookedAudioHandler(String id);
}

abstract class Platform extends PlatformInterface {
  /// Constructs a PlanetKitFlutterPlatform.
  Platform() : super(token: _token);

  static final Object _token = Object();

  static Platform _instance = MethodChannelPlanetKit();

  /// The default instance of [Platform] to use.
  ///
  /// Defaults to [MethodChannelPlanetKit].
  static Platform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [Platform] when
  /// they register themselves.
  static set instance(Platform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  EventManagerInterface get eventManager => _instance.eventManager;

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool> initializePlanetKit(PlanetKitInitParam initParam) {
    throw UnimplementedError('initializePlanetKit() has not been implemented.');
  }

  Future<MakeCallResponse> makeCall(PlanetKitMakeCallParam param) {
    throw UnimplementedError('makeCall() has not been implemented.');
  }

  Future<VerifyCallResponse> verifyCall(PlanetKitVerifyCallParam param) {
    throw UnimplementedError('verifyCall() has not been implemented.');
  }

  Future<bool> acceptCall(String callId) {
    throw UnimplementedError('acceptCall() has not been implemented.');
  }

  Future<bool> endCall(String callId) {
    throw UnimplementedError('endCall() has not been implemented.');
  }

  Future<bool> muteMyAudio(String callId) {
    throw UnimplementedError('muteMyAudio() has not been implemented.');
  }

  Future<bool> unmuteMyAudio(String callId) {
    throw UnimplementedError('unmuteMyAudio() has not been implemented.');
  }

  Future<bool> speakerOut(String callId, bool speakerOut) {
    throw UnimplementedError('speakerOut() has not been implemented.');
  }

  Future<bool> isSpeakerOut(String callId) {
    throw UnimplementedError('isMySpeakerOut() has not been implemented.');
  }

  Future<bool> isMyAudioMuted(String callId) {
    throw UnimplementedError('isMyAudioMuted() has not been implemented.');
  }

  Future<bool> isPeerAudioMuted(String callId) {
    throw UnimplementedError('isPeerAudioMuted() has not been implemented.');
  }

  Future<bool> enableHookMyAudio(
      String callId, HookedAudioHandler handler) {
    throw UnimplementedError(
        'enableHookMyAudio() has not been implemented.');
  }

  Future<bool> disableHookMyAudio(String callId) {
    throw UnimplementedError(
        'disableHookMyAudio() has not been implemented.');
  }

  Future<bool> putHookedMyAudioBack(String callId, String audioId) {
    throw UnimplementedError(
        'putHookedMyAudioBack() has not been implemented.');
  }

  Future<bool> setHookedAudioData(String audioId, Uint8List data) {
    throw UnimplementedError(
        'setHookedAudioData() has not been implemented.');
  }

  Future<bool> isHookMyAudioEnabled(String callId) {
    throw UnimplementedError(
        'isHookMyAudioEnabled() has not been implemented.');
  }

  Future<bool> releaseInstance(String id) {
    throw UnimplementedError('releaseInstance() has not been implemented.');
  }

  Future<String?> createCcParam(String ccParam) {
    throw UnimplementedError('createCcParam() has not been implemented.');
  }
}
