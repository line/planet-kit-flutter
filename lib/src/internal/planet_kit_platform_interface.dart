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
import 'package:planet_kit_flutter/src/internal/conference/planet_kit_platform_conference_responses.dart';
import 'package:planet_kit_flutter/src/public/conference/planet_kit_join_conference_param.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_types.dart';
import 'package:planet_kit_flutter/src/public/statistics/planet_kit_statistics.dart';
import 'package:planet_kit_flutter/src/public/video/planet_kit_video_status.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import '../public/call/planet_kit_cc_param.dart';
import '../public/conference/planet_kit_conference_peer.dart';
import '../public/planet_kit_user_id.dart';
import '../public/video/planet_kit_video_resolution.dart';
import 'call/planet_kit_platform_call_event.dart';
import 'call/planet_kit_platform_call_reponses.dart';
import 'conference/planet_kit_platform_conference_event.dart';
import 'my_media_status/planet_kit_platform_my_media_status_event.dart';
import 'peer_control/planet_kit_platform_peer_control_event.dart';
import 'planet_kit_method_channel.dart';

import '../public/planet_kit_init_param.dart';
import '../public/call/planet_kit_make_call_param.dart';
import '../public/call/planet_kit_verify_call_param.dart';

// TODO: consider enclosing the creation of PlanetKit instance
// that has mapping native instance to be within MethodChannelPlanetKit.
// This will allow MethodChannelPlanetKit user would only use PlanetKit Flutter instances and not instance id.
// Also MethodChannelPlanetKit user would not have to consider native instance management
// and attaching/detaching native events.

abstract class HookedAudioHandler {
  void onHookedAudio(String callId, Map<String, dynamic> audioData);
}

abstract class EventManagerInterface {
  Stream<CallEvent> get onCallEvent;
  Stream<MyMediaStatusEvent> get onMyMediaStatusEvent;
  Stream<ConferenceEvent> get onConferenceEvent;
  Stream<PeerControlEvent> get onPeerControlEvent;

  void dispose();

  void addHookedAudioHandler(String id, HookedAudioHandler handler);
  void removeHookedAudioHandler(String id);
}

abstract class CallInterface {
  Future<bool> acceptCall(String callId, bool useResponderPreparation);
  Future<bool> endCall(String callId, String? userReleasePhrase);
  Future<bool> endCallWithError(String callId, String userReleasePhrase);
  Future<bool> muteMyAudio(String callId, bool mute);
  Future<bool> speakerOut(String callId, bool speakerOut);
  Future<bool> isSpeakerOut(String callId);
  Future<bool> isMyAudioMuted(String callId);
  Future<bool> isPeerAudioMuted(String callId);
  Future<bool> enableHookMyAudio(String callId, HookedAudioHandler handler);
  Future<bool> disableHookMyAudio(String callId);
  Future<bool> putHookedMyAudioBack(String callId, String audioId);
  Future<bool> setHookedAudioData(String audioId, Uint8List data);
  Future<bool> isHookMyAudioEnabled(String callId);
  Future<bool> notifyCallKitAudioActivation(String callId);
  Future<bool> finishPreparation(String callId);
  Future<bool> isOnHold(String callId);
  Future<bool> hold(String callId, String? reason);
  Future<bool> unhold(String callId);
  Future<bool> requestPeerMute(String callId, bool mute);
  Future<String?> getMyMediaStatus(String callId);
  Future<bool> silencePeerAudio(String callId, bool silent);
  Future<bool> addMyVideoView(String callId, String viewId);
  Future<bool> removeMyVideoView(String callId, String viewId);
  Future<bool> addPeerVideoView(String callId, String viewId);
  Future<bool> removePeerVideoView(String callId, String viewId);
  Future<bool> pauseMyVideo(String callId);
  Future<bool> resumeMyVideo(String callId);
  Future<bool> enableVideo(String callId);
  Future<bool> disableVideo(String callId, PlanetKitMediaDisableReason reason);
  Future<PlanetKitStatistics?> getStatistics(String callId);

  Future<bool> addPeerScreenShareView(String callId, String viewId);
  Future<bool> removePeerScreenShareView(String callId, String viewId);
}

abstract class ConferenceInterface {
  Future<bool> leaveConference(String id);
  Future<bool> muteMyAudio(String id, bool mute);
  Future<bool> speakerOut(String id, bool speakerOut);
  Future<bool> isSpeakerOut(String id);
  Future<bool> notifyCallKitAudioActivation(String id);
  Future<bool> silencePeersAudio(String id, bool silent);
  Future<bool> requestPeerMute(String id, bool mute, PlanetKitUserId peerId);
  Future<bool> requestPeersMute(String id, bool mute);
  Future<bool> isOnHold(String id);
  Future<bool> hold(String id, String? reason);
  Future<bool> unhold(String id);
  Future<String?> getMyMediaStatus(String id);
  Future<String?> createPeerControl(String conferenceId, String peerId);
  Future<bool> addMyVideoView(String conferenceId, String viewId);
  Future<bool> removeMyVideoView(String conferenceId, String viewId);
  Future<bool> enableVideo(String id);
  Future<bool> disableVideo(String id);
  Future<bool> pauseMyVideo(String id);
  Future<bool> resumeMyVideo(String id);
  Future<PlanetKitStatistics?> getStatistics(String id);
}

abstract class ConferencePeerInterface {
  Future<PlanetKitHoldStatus?> getHoldStatus(String id);
  Future<bool> isMuted(String id);
  Future<PlanetKitVideoStatus?> getVideoStatus(String id);
  Future<PlanetKitScreenShareState?> getScreenShareState(String id);
}

abstract class MyMediaStatusInterface {
  Future<bool> isMyAudioMuted(String myMediaStatusId);
  Future<PlanetKitVideoStatus?> getMyVideoStatus(String myMediaStatusId);
}

abstract class PeerControlInterface {
  Future<bool> register(String id);
  Future<bool> unregister(String id);
  Future<bool> startVideo(
      String id, String viewId, PlanetKitVideoResolution resolution);
  Future<bool> stopVideo(String id, String viewId);
  Future<bool> startScreenShare(String id, String viewId);
  Future<bool> stopScreenShare(String id, String viewId);
}

abstract class CameraInterface {
  Future<bool> startPreview(String viewId);
  Future<bool> stopPreview(String viewId);
  Future<bool> switchPosition();
  Future<bool> setVirtualBackgroundWithImage(String filePath);
  Future<bool> setVirtualBackgroundWithBlur(int radius);
  Future<bool> clearVirtualBackground();
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

  CallInterface get callInterface =>
      throw UnimplementedError('callInterface not available');

  ConferenceInterface get conferenceInterface =>
      throw UnimplementedError('conferenceInterface not available');

  MyMediaStatusInterface get myMediaStatusInterface =>
      throw UnimplementedError('MyMediaStatusInterface not available');

  ConferencePeerInterface get conferencePeerInterface =>
      throw UnimplementedError('ConferencePeerInterface not available');

  PeerControlInterface get peerControlInterface =>
      throw UnimplementedError('PeerControlInterface not available');

  CameraInterface get cameraInterface =>
      throw UnimplementedError('CameraInterface not available');

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

  Future<JoinConferenceResponse> joinConference(
      PlanetKitJoinConferenceParam param) {
    throw UnimplementedError('joinConference() has not been implemented.');
  }

  Future<bool> releaseInstance(String id) {
    throw UnimplementedError('releaseInstance() has not been implemented.');
  }

  Future<PlanetKitCcParam?> createCcParam(String ccParam) {
    throw UnimplementedError('createCcParam() has not been implemented.');
  }
}
