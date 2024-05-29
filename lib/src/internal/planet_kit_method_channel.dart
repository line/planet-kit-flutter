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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:planet_kit_flutter/src/internal/call/params/planet_kit_platform_call_hook_audio_param.dart';

import '../public/planet_kit_init_param.dart';
import '../public/call/planet_kit_make_call_param.dart';
import '../public/call/planet_kit_verify_call_param.dart';

import 'planet_kit_platform_interface.dart';
import 'planet_kit_platform_event_manager.dart';
import 'call/params/planet_kit_platform_call_speaker_out_param.dart';
import 'call/responses/planet_kit_platform_make_call_response.dart';
import 'call/responses/planet_kit_platform_verify_call_response.dart';

/// An implementation of [Platform] that uses method channels.
class MethodChannelPlanetKit extends Platform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('planetkit_sdk');

  final EventManager _eventManager = EventManager();

  MethodChannelPlanetKit() {
    print("#flutter_method_channel Constructor");
    _eventManager.initializeEventChannel();
  }

  @override
  EventManagerInterface get eventManager => _eventManager;

  @override
  Future<String?> getPlatformVersion() async {
    print("#flutter_method_channel getPlatformVersion");
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool> initializePlanetKit(PlanetKitInitParam initParam) async {
    print(
        "#flutter_method_channel initializePlanetKit with ${initParam.toJson()}");
    return await methodChannel.invokeMethod<bool>(
            'initializePlanetKit', initParam.toJson()) ??
        false;
  }

  @override
  Future<MakeCallResponse> makeCall(PlanetKitMakeCallParam param) async {
    print("#flutter_method_channel makeCall with ${param.toJson()}");
    final jsonString = await methodChannel.invokeMethod<String>(
        'makeCall', param.toJson()) as String;
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    final response = MakeCallResponse.fromJson(jsonMap);
    return response;
  }

  @override
  Future<VerifyCallResponse> verifyCall(PlanetKitVerifyCallParam param) async {
    print("#flutter_method_channel verifyCall with ${param.toJson()}");
    final jsonString = await methodChannel.invokeMethod<String>(
        'verifyCall', param.toJson()) as String;
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    final response = VerifyCallResponse.fromJson(jsonMap);
    return response;
  }

  @override
  Future<bool> acceptCall(String callId) async {
    print("#flutter_method_channel acceptCall with callId $callId");
    return await methodChannel.invokeMethod<bool>('acceptCall', callId) as bool;
  }

  @override
  Future<bool> endCall(String callId) async {
    print("#flutter_method_channel endCall with callId $callId");
    return await methodChannel.invokeMethod<bool>('endCall', callId) as bool;
  }

  @override
  Future<bool> muteMyAudio(String callId) async {
    print("#flutter_method_channel muteMyAudio with callId $callId");
    return await methodChannel.invokeMethod<bool>('muteMyAudio', callId)
        as bool;
  }

  @override
  Future<bool> unmuteMyAudio(String callId) async {
    print("#flutter_method_channel unmuteMyAudio with callId $callId");
    return await methodChannel.invokeMethod<bool>('unmuteMyAudio', callId)
        as bool;
  }

  @override
  Future<bool> speakerOut(String callId, bool speakerOut) async {
    print(
        "#flutter_method_channel speakerOut with callId $callId and speakerOut $speakerOut");
    final param = CallSpeakerOutParam(callId: callId, speakerOut: speakerOut);
    return await methodChannel.invokeMethod<bool>('speakerOut', param.toJson())
        as bool;
  }

  @override
  Future<bool> isSpeakerOut(String callId) async {
    print("#flutter_method_channel isSpeakerOut with callId $callId");
    return await methodChannel.invokeMethod<bool>('isSpeakerOut', callId)
        as bool;
  }

  @override
  Future<bool> isMyAudioMuted(String callId) async {
    print("#flutter_method_channel isMyAudioMuted with callId $callId");
    return await methodChannel.invokeMethod<bool>('isMyAudioMuted', callId)
        as bool;
  }

  @override
  Future<bool> isPeerAudioMuted(String callId) async {
    print("#flutter_method_channel isPeerAudioMuted with callId $callId");
    return await methodChannel.invokeMethod<bool>('isPeerAudioMuted', callId)
        as bool;
  }

  @override
  Future<String?> createCcParam(String ccParam) async {
    print("#flutter_method_channel createCcParam $ccParam");
    final response =
        await methodChannel.invokeMethod<String?>('createCcParam', ccParam);
    return response;
  }

  @override
  Future<bool> releaseInstance(String id) async {
    print("#flutter_method_channel releaseInstance $id");
    return await methodChannel.invokeMethod<bool>('releaseInstance', id)
        as bool;
  }

  @override
  Future<bool> enableHookMyAudio(
      String callId, HookedAudioHandler handler) async {
    print("#flutter_method_channel enableHookMyAudio with callId $callId");
    return await methodChannel.invokeMethod<bool>(
        'enableHookMyAudio', callId) as bool;
  }

  @override
  Future<bool> disableHookMyAudio(String callId) async {
    print(
        "#flutter_method_channel disableHookMyAudio with callId $callId");

    return await methodChannel.invokeMethod<bool>(
        'disableHookMyAudio', callId) as bool;
  }

  @override
  Future<bool> putHookedMyAudioBack(String callId, String audioId) async {
    print("#flutter_method_channel putHookedMyAudioBack with callId $callId");
    return await methodChannel.invokeMethod<bool>('putHookedMyAudioBack',
            PutHookedAudioBackParam(callId: callId, audioId: audioId).toJson())
        as bool;
  }

  @override
  Future<bool> setHookedAudioData(String audioId, Uint8List data) async {
    return await methodChannel.invokeMethod<bool>(
        'setHookedAudioData', {'audioId': audioId, 'data': data}) as bool;
  }

  @override
  Future<bool> isHookMyAudioEnabled(String callId) async {
    return await methodChannel.invokeMethod<bool>(
        'isHookMyAudioEnabled', callId) as bool;
  }
}
