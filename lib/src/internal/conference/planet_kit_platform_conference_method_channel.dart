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
import 'package:planet_kit_flutter/src/public/statistics/planet_kit_statistics.dart';
import '../../public/planet_kit_user_id.dart';
import '../planet_kit_platform_interface.dart';
import 'planet_kit_platform_conference_params.dart';

class ConferenceMethodChannel implements ConferenceInterface {
  final MethodChannel methodChannel;

  ConferenceMethodChannel({required this.methodChannel});

  @override
  Future<String> getMyMediaStatus(String id) async {
    print("#flutter_method_channel getMyMediaStatus with id $id");
    return await methodChannel.invokeMethod<String>(
        'conference_getMyMediaStatus', id) as String;
  }

  @override
  Future<bool> hold(String id, String? reason) async {
    print("#flutter_method_channel hold with id $id $reason");
    final param = HoldConferenceParam(id: id, reason: reason);
    return await methodChannel.invokeMethod<bool>(
        'conference_hold', param.toJson()) as bool;
  }

  @override
  Future<bool> isSpeakerOut(String id) async {
    print("#flutter_method_channel isSpeakerOut with id $id");
    return await methodChannel.invokeMethod<bool>('conference_isSpeakerOut', id)
        as bool;
  }

  @override
  Future<bool> leaveConference(String id) async {
    print("#flutter_method_channel leaveConference with id $id");
    return await methodChannel.invokeMethod<bool>(
        'conference_leaveConference', id) as bool;
  }

  @override
  Future<bool> muteMyAudio(String id, bool mute) async {
    print("#flutter_method_channel muteMyAudio with id $id $mute");
    final param = MuteMuAudioParam(id: id, mute: mute);
    return await methodChannel.invokeMethod<bool>(
        'conference_muteMyAudio', param.toJson()) as bool;
  }

  @override
  Future<bool> notifyCallKitAudioActivation(String id) async {
    print("#flutter_method_channel notifyCallKitAudioActivation with id $id");
    if (ioPlatform.Platform.isIOS) {
      return await methodChannel.invokeMethod<bool>(
          'conference_notifyCallKitAudioActivation', id) as bool;
    } else {
      return false;
    }
  }

  @override
  Future<bool> requestPeerMute(
      String id, bool mute, PlanetKitUserId peerId) async {
    print("#flutter_method_channel requestPeerMute with id $id $mute $peerId");
    final param = RequestPeerMuteParam(id: id, mute: mute, peerId: peerId);
    return await methodChannel.invokeMethod<bool>(
        'conference_requestPeerMute', param.toJson()) as bool;
  }

  @override
  Future<bool> silencePeersAudio(String id, bool silent) async {
    print("#flutter_method_channel silencePeersAudio with id $id $silent");
    final param = SilencePeersAudioParam(id: id, silent: silent);
    return await methodChannel.invokeMethod<bool>(
        'conference_silencePeersAudio', param.toJson()) as bool;
  }

  @override
  Future<bool> speakerOut(String id, bool speakerOut) async {
    print("#flutter_method_channel speakerOut with id $id $speakerOut");
    final param = SpeakerOutParam(id: id, speakerOut: speakerOut);
    return await methodChannel.invokeMethod<bool>(
        'conference_speakerOut', param.toJson()) as bool;
  }

  @override
  Future<bool> unhold(String id) async {
    print("#flutter_method_channel unhold with id $id");
    return await methodChannel.invokeMethod<bool>('conference_unhold', id)
        as bool;
  }

  @override
  Future<bool> isOnHold(String id) async {
    print("#flutter_method_channel isOnHold with id $id");
    return await methodChannel.invokeMethod<bool>('conference_isOnHold', id)
        as bool;
  }

  @override
  Future<String> createPeerControl(String conferenceId, String peerId) async {
    print(
        "#flutter_method_channel createPeerControl with conf id $conferenceId peerId $peerId");
    final param =
        CreatePeerControlParam(conferenceId: conferenceId, peerId: peerId);

    return await methodChannel.invokeMethod<String>(
        'conference_createPeerControl', param.toJson()) as String;
  }

  @override
  Future<bool> requestPeersMute(String id, bool mute) async {
    print("#flutter_method_channel requestPeersMute with id $id $mute");
    final param = RequestPeersMuteParam(id: id, mute: mute);
    return await methodChannel.invokeMethod<bool>(
        'conference_requestPeersMute', param.toJson()) as bool;
  }

  @override
  Future<bool> addMyVideoView(String conferenceId, String viewId) async {
    print(
        "#flutter_method_channel addMyVideoView with id $conferenceId $viewId");
    final param =
        AddMyVideoViewParam(conferenceId: conferenceId, viewId: viewId);
    return await methodChannel.invokeMethod<bool>(
        'conference_addMyVideoView', param.toJson()) as bool;
  }

  @override
  Future<bool> removeMyVideoView(String conferenceId, String viewId) async {
    print(
        "#flutter_method_channel removeMyVideoView with id $conferenceId $viewId");
    final param =
        RemoveMyVideoViewParam(conferenceId: conferenceId, viewId: viewId);
    return await methodChannel.invokeMethod<bool>(
        'conference_removeMyVideoView', param.toJson()) as bool;
  }

  @override
  Future<bool> enableVideo(String id) async {
    print("#flutter_method_channel enableVideo with id $id");
    return await methodChannel.invokeMethod<bool>('conference_enableVideo', id)
        as bool;
  }

  @override
  Future<bool> disableVideo(String id) async {
    print("#flutter_method_channel disableVideo with id $id");
    return await methodChannel.invokeMethod<bool>('conference_disableVideo', id)
        as bool;
  }

  @override
  Future<bool> pauseMyVideo(String id) async {
    print("#flutter_method_channel pauseMyVideo with id $id");
    return await methodChannel.invokeMethod<bool>('conference_pauseMyVideo', id)
        as bool;
  }

  @override
  Future<bool> resumeMyVideo(String id) async {
    print("#flutter_method_channel resumeMyVideo with id $id");
    return await methodChannel.invokeMethod<bool>(
        'conference_resumeMyVideo', id) as bool;
  }

  @override
  Future<PlanetKitStatistics?> getStatistics(String id) async {
    final jsonString = await methodChannel.invokeMethod<String?>(
        'conference_getStatistics', id) as String?;

    if (jsonString == null) {
      return null;
    }

    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    final response = PlanetKitStatistics.fromJson(jsonMap);
    return response;
  }
}
