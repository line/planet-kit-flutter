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
import 'dart:io' as ioPlatform;

import 'package:flutter/services.dart';
import 'planet_kit_platform_call_params.dart';
import '../planet_kit_platform_interface.dart';

class CallMethodChannel implements CallInterface {
  final MethodChannel methodChannel;

  CallMethodChannel({required this.methodChannel});

  @override
  Future<bool> acceptCall(String callId, bool useResponderPreparation) async {
    print(
        "#flutter_method_channel acceptCall with callId $callId $useResponderPreparation");
    final param = AcceptCallParam(
        callId: callId, useResponderPreparation: useResponderPreparation);
    return await methodChannel.invokeMethod<bool>('acceptCall', param.toJson())
        as bool;
  }

  @override
  Future<bool> endCall(String callId, String? userReleasePhrase) async {
    print(
        "#flutter_method_channel endCall with callId $callId $userReleasePhrase");
    final param =
        EndCallParam(callId: callId, userReleasePhrase: userReleasePhrase);
    return await methodChannel.invokeMethod<bool>('endCall', param.toJson())
        as bool;
  }

  @override
  Future<bool> endCallWithError(String callId, String userReleasePhrase) async {
    print(
        "#flutter_method_channel endCallWithError with callId $callId $userReleasePhrase");
    final param = EndCallWithErrorParam(
        callId: callId, userReleasePhrase: userReleasePhrase);
    return await methodChannel.invokeMethod<bool>(
        'endCallWithError', param.toJson()) as bool;
  }

  @override
  Future<bool> muteMyAudio(String callId, bool mute) async {
    print("#flutter_method_channel muteMyAudio with callId $callId $mute");
    final param = MuteCallParam(callId: callId, mute: mute);
    return await methodChannel.invokeMethod<bool>('muteMyAudio', param.toJson())
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
  Future<bool> enableHookMyAudio(
      String callId, HookedAudioHandler handler) async {
    print("#flutter_method_channel enableHookMyAudio with callId $callId");
    return await methodChannel.invokeMethod<bool>('enableHookMyAudio', callId)
        as bool;
  }

  @override
  Future<bool> disableHookMyAudio(String callId) async {
    print("#flutter_method_channel disableHookMyAudio with callId $callId");

    return await methodChannel.invokeMethod<bool>('disableHookMyAudio', callId)
        as bool;
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
    print("#flutter_method_channel isHookMyAudioEnabled with callId $callId");
    return await methodChannel.invokeMethod<bool>(
        'isHookMyAudioEnabled', callId) as bool;
  }

  @override
  Future<bool> notifyCallKitAudioActivation(String callId) async {
    print(
        "#flutter_method_channel notifyCallKitAudioActivation with callId $callId");
    if (ioPlatform.Platform.isIOS) {
      return await methodChannel.invokeMethod<bool>(
          'notifyCallKitAudioActivation', callId) as bool;
    } else {
      return false;
    }
  }

  @override
  Future<bool> finishPreparation(String callId) async {
    print("#flutter_method_channel finishPreparation with callId $callId");
    return await methodChannel.invokeMethod<bool>('finishPreparation', callId)
        as bool;
  }

  @override
  Future<bool> isOnHold(String callId) async {
    print("#flutter_method_channel isOnHold with callId $callId");
    return await methodChannel.invokeMethod<bool>('isOnHold', callId) as bool;
  }

  @override
  Future<bool> hold(String callId, String? reason) async {
    print("#flutter_method_channel hold with callId $callId $reason");
    final param = HoldCallParam(callId: callId, reason: reason);
    return await methodChannel.invokeMethod<bool>('holdCall', param.toJson())
        as bool;
  }

  @override
  Future<bool> unhold(String callId) async {
    print("#flutter_method_channel unhold with callId $callId");
    return await methodChannel.invokeMethod<bool>('unholdCall', callId) as bool;
  }

  @override
  Future<bool> requestPeerMute(String callId, bool mute) async {
    print("#flutter_method_channel unhold with callId $callId $mute");
    final param = RequestPeerMuteParam(callId: callId, mute: mute);
    return await methodChannel.invokeMethod<bool>(
        'requestPeerMute', param.toJson()) as bool;
  }

  @override
  Future<String> getMyMediaStatus(String callId) async {
    print("#flutter_method_channel getMyMediaStatus with callId $callId");
    return await methodChannel.invokeMethod<String>('getMyMediaStatus', callId)
        as String;
  }

  @override
  Future<bool> silencePeerAudio(String callId, bool silent) async {
    print("#flutter_method_channel silencePeerAudio with callId $callId");
    final param = SilencePeerAudioParam(callId: callId, silent: silent);
    return await methodChannel.invokeMethod<bool>(
        'silencePeerAudio', param.toJson()) as bool;
  }
}
