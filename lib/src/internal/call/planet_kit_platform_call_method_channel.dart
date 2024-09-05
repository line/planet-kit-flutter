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
import 'dart:io' as ioPlatform;

import 'package:flutter/services.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_types.dart';
import 'package:planet_kit_flutter/src/public/statistics/planet_kit_statistics.dart';
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
    return await methodChannel.invokeMethod<bool>(
        'call_acceptCall', param.toJson()) as bool;
  }

  @override
  Future<bool> endCall(String callId, String? userReleasePhrase) async {
    print(
        "#flutter_method_channel endCall with callId $callId $userReleasePhrase");
    final param =
        EndCallParam(callId: callId, userReleasePhrase: userReleasePhrase);
    return await methodChannel.invokeMethod<bool>(
        'call_endCall', param.toJson()) as bool;
  }

  @override
  Future<bool> endCallWithError(String callId, String userReleasePhrase) async {
    print(
        "#flutter_method_channel endCallWithError with callId $callId $userReleasePhrase");
    final param = EndCallWithErrorParam(
        callId: callId, userReleasePhrase: userReleasePhrase);
    return await methodChannel.invokeMethod<bool>(
        'call_endCallWithError', param.toJson()) as bool;
  }

  @override
  Future<bool> muteMyAudio(String callId, bool mute) async {
    print("#flutter_method_channel muteMyAudio with callId $callId $mute");
    final param = MuteCallParam(callId: callId, mute: mute);
    return await methodChannel.invokeMethod<bool>(
        'call_muteMyAudio', param.toJson()) as bool;
  }

  @override
  Future<bool> speakerOut(String callId, bool speakerOut) async {
    print(
        "#flutter_method_channel speakerOut with callId $callId and speakerOut $speakerOut");
    final param = CallSpeakerOutParam(callId: callId, speakerOut: speakerOut);
    return await methodChannel.invokeMethod<bool>(
        'call_speakerOut', param.toJson()) as bool;
  }

  @override
  Future<bool> isSpeakerOut(String callId) async {
    print("#flutter_method_channel isSpeakerOut with callId $callId");
    return await methodChannel.invokeMethod<bool>('call_isSpeakerOut', callId)
        as bool;
  }

  @override
  Future<bool> isMyAudioMuted(String callId) async {
    print("#flutter_method_channel isMyAudioMuted with callId $callId");
    return await methodChannel.invokeMethod<bool>('call_isMyAudioMuted', callId)
        as bool;
  }

  @override
  Future<bool> isPeerAudioMuted(String callId) async {
    print("#flutter_method_channel isPeerAudioMuted with callId $callId");
    return await methodChannel.invokeMethod<bool>(
        'call_isPeerAudioMuted', callId) as bool;
  }

  @override
  Future<bool> enableHookMyAudio(
      String callId, HookedAudioHandler handler) async {
    print("#flutter_method_channel enableHookMyAudio with callId $callId");
    return await methodChannel.invokeMethod<bool>(
        'call_enableHookMyAudio', callId) as bool;
  }

  @override
  Future<bool> disableHookMyAudio(String callId) async {
    print("#flutter_method_channel disableHookMyAudio with callId $callId");

    return await methodChannel.invokeMethod<bool>(
        'call_disableHookMyAudio', callId) as bool;
  }

  @override
  Future<bool> putHookedMyAudioBack(String callId, String audioId) async {
    print("#flutter_method_channel putHookedMyAudioBack with callId $callId");
    return await methodChannel.invokeMethod<bool>('call_putHookedMyAudioBack',
            PutHookedAudioBackParam(callId: callId, audioId: audioId).toJson())
        as bool;
  }

  @override
  Future<bool> setHookedAudioData(String audioId, Uint8List data) async {
    return await methodChannel.invokeMethod<bool>(
        'call_setHookedAudioData', {'audioId': audioId, 'data': data}) as bool;
  }

  @override
  Future<bool> isHookMyAudioEnabled(String callId) async {
    print("#flutter_method_channel isHookMyAudioEnabled with callId $callId");
    return await methodChannel.invokeMethod<bool>(
        'call_isHookMyAudioEnabled', callId) as bool;
  }

  @override
  Future<bool> notifyCallKitAudioActivation(String callId) async {
    print(
        "#flutter_method_channel notifyCallKitAudioActivation with callId $callId");
    if (ioPlatform.Platform.isIOS) {
      return await methodChannel.invokeMethod<bool>(
          'call_notifyCallKitAudioActivation', callId) as bool;
    } else {
      return false;
    }
  }

  @override
  Future<bool> finishPreparation(String callId) async {
    print("#flutter_method_channel finishPreparation with callId $callId");
    return await methodChannel.invokeMethod<bool>(
        'call_finishPreparation', callId) as bool;
  }

  @override
  Future<bool> isOnHold(String callId) async {
    print("#flutter_method_channel isOnHold with callId $callId");
    return await methodChannel.invokeMethod<bool>('call_isOnHold', callId)
        as bool;
  }

  @override
  Future<bool> hold(String callId, String? reason) async {
    print("#flutter_method_channel hold with callId $callId $reason");
    final param = HoldCallParam(callId: callId, reason: reason);
    return await methodChannel.invokeMethod<bool>(
        'call_holdCall', param.toJson()) as bool;
  }

  @override
  Future<bool> unhold(String callId) async {
    print("#flutter_method_channel unhold with callId $callId");
    return await methodChannel.invokeMethod<bool>('call_unholdCall', callId)
        as bool;
  }

  @override
  Future<bool> requestPeerMute(String callId, bool mute) async {
    print("#flutter_method_channel unhold with callId $callId $mute");
    final param = RequestPeerMuteParam(callId: callId, mute: mute);
    return await methodChannel.invokeMethod<bool>(
        'call_requestPeerMute', param.toJson()) as bool;
  }

  @override
  Future<String> getMyMediaStatus(String callId) async {
    print("#flutter_method_channel getMyMediaStatus with callId $callId");
    return await methodChannel.invokeMethod<String>(
        'call_getMyMediaStatus', callId) as String;
  }

  @override
  Future<bool> silencePeerAudio(String callId, bool silent) async {
    print("#flutter_method_channel silencePeerAudio with callId $callId");
    final param = SilencePeerAudioParam(callId: callId, silent: silent);
    return await methodChannel.invokeMethod<bool>(
        'call_silencePeerAudio', param.toJson()) as bool;
  }

  @override
  Future<bool> addMyVideoView(String callId, String viewId) async {
    print(
        "#flutter_method_channel addMyVideoView with callId $callId viewId $viewId");
    final param = AddVideoViewParam(callId: callId, viewId: viewId);
    return await methodChannel.invokeMethod<bool>(
        'call_addMyVideoView', param.toJson()) as bool;
  }

  @override
  Future<bool> addPeerVideoView(String callId, String viewId) async {
    print(
        "#flutter_method_channel addPeerVideoView with callId $callId viewId $viewId");
    final param = AddVideoViewParam(callId: callId, viewId: viewId);
    return await methodChannel.invokeMethod<bool>(
        'call_addPeerVideoView', param.toJson()) as bool;
  }

  @override
  Future<bool> removeMyVideoView(String callId, String viewId) async {
    print(
        "#flutter_method_channel removeMyVideoView with callId $callId viewId $viewId");
    final param = RemoveVideoViewParam(callId: callId, viewId: viewId);
    return await methodChannel.invokeMethod<bool>(
        'call_removeMyVideoView', param.toJson()) as bool;
  }

  @override
  Future<bool> removePeerVideoView(String callId, String viewId) async {
    print(
        "#flutter_method_channel removePeerVideoView with callId $callId viewId $viewId");
    final param = RemoveVideoViewParam(callId: callId, viewId: viewId);
    return await methodChannel.invokeMethod<bool>(
        'call_removePeerVideoView', param.toJson()) as bool;
  }

  @override
  Future<bool> pauseMyVideo(String callId) async {
    print("#flutter_method_channel pauseMyVideo with callId $callId");
    return await methodChannel.invokeMethod<bool>('call_pauseMyVideo', callId)
        as bool;
  }

  @override
  Future<bool> resumeMyVideo(String callId) async {
    print("#flutter_method_channel resumeMyVideo with callId $callId");
    return await methodChannel.invokeMethod<bool>('call_resumeMyVideo', callId)
        as bool;
  }

  @override
  Future<bool> disableVideo(
      String callId, PlanetKitMediaDisableReason reason) async {
    print("#flutter_method_channel disableVideo with callId $callId $reason");
    final param = DisableVideoParam(callId: callId, reason: reason);

    return await methodChannel.invokeMethod<bool>(
        'call_disableVideo', param.toJson()) as bool;
  }

  @override
  Future<bool> enableVideo(String callId) async {
    print("#flutter_method_channel enableVideo with callId $callId");
    return await methodChannel.invokeMethod<bool>('call_enableVideo', callId)
        as bool;
  }

  @override
  Future<PlanetKitStatistics?> getStatistics(String callId) async {
    final jsonString = await methodChannel.invokeMethod<String?>(
        'call_getStatistics', callId) as String?;

    if (jsonString == null) {
      return null;
    }

    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    final response = PlanetKitStatistics.fromJson(jsonMap);
    return response;
  }

  @override
  Future<bool> addPeerScreenShareView(String callId, String viewId) async {
    print(
        "#flutter_method_channel addPeerScreenShareView with callId $callId viewId $viewId");
    final param = AddVideoViewParam(callId: callId, viewId: viewId);
    return await methodChannel.invokeMethod<bool>(
        'call_addPeerScreenShareView', param.toJson()) as bool;
  }

  @override
  Future<bool> removePeerScreenShareView(String callId, String viewId) async {
    print(
        "#flutter_method_channel removePeerScreenShareView with callId $callId viewId $viewId");
    final param = RemoveVideoViewParam(callId: callId, viewId: viewId);
    return await methodChannel.invokeMethod<bool>(
        'call_removePeerScreenShareView', param.toJson()) as bool;
  }
}
