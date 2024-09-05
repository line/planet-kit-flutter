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
import 'package:planet_kit_flutter/src/internal/camera/planet_kit_platform_camera_method_channel.dart';
import 'package:planet_kit_flutter/src/internal/conference/peer/planet_kit_platfom_conference_peer_method_channel.dart';
import 'package:planet_kit_flutter/src/internal/conference/planet_kit_platform_conference_method_channel.dart';
import 'package:planet_kit_flutter/src/internal/peer_control/planet_kit_platform_peer_control_method_channel.dart';

import '../public/call/planet_kit_cc_param.dart';
import '../public/call/planet_kit_make_call_param.dart';
import '../public/call/planet_kit_verify_call_param.dart';
import '../public/conference/planet_kit_join_conference_param.dart';
import '../public/planet_kit_init_param.dart';

import 'call/planet_kit_platform_call_reponses.dart';
import 'call/planet_kit_platform_call_method_channel.dart';
import 'conference/planet_kit_platform_conference_responses.dart';
import 'planet_kit_platform_interface.dart';
import 'planet_kit_platform_event_manager.dart';
import 'my_media_status/planet_kit_platform_my_media_status_method_channel.dart';

/// An implementation of [Platform] that uses method channels.
class MethodChannelPlanetKit extends Platform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('planetkit_sdk');
  late final CallMethodChannel _callMethodChannel;
  late final MyMediaStatusMethodChannel _myMediaStatusMethodChannel;
  late final ConferencePeerMethodChannel _conferencePeerMethodChannel;
  late final ConferenceMethodChannel _conferenceMethodChannel;
  late final PeerControlMethodChannel _peerControlMethodChannel;
  late final CameraInterface _cameraInterface;
  final EventManager _eventManager = EventManager();

  MethodChannelPlanetKit() {
    print("#flutter_method_channel Constructor");
    _eventManager.initializeEventChannel();
    _callMethodChannel = CallMethodChannel(methodChannel: methodChannel);
    _myMediaStatusMethodChannel =
        MyMediaStatusMethodChannel(methodChannel: methodChannel);
    _conferenceMethodChannel =
        ConferenceMethodChannel(methodChannel: methodChannel);
    _conferencePeerMethodChannel =
        ConferencePeerMethodChannel(methodChannel: methodChannel);
    _peerControlMethodChannel =
        PeerControlMethodChannel(methodChannel: methodChannel);
    _cameraInterface = CameraMethodChannel(methodChannel: methodChannel);
  }

  @override
  EventManagerInterface get eventManager => _eventManager;

  @override
  CallInterface get callInterface => _callMethodChannel;

  @override
  MyMediaStatusInterface get myMediaStatusInterface =>
      _myMediaStatusMethodChannel;

  @override
  ConferenceInterface get conferenceInterface => _conferenceMethodChannel;

  @override
  ConferencePeerInterface get conferencePeerInterface =>
      _conferencePeerMethodChannel;

  @override
  PeerControlInterface get peerControlInterface => _peerControlMethodChannel;

  @override
  CameraInterface get cameraInterface => _cameraInterface;

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
  Future<JoinConferenceResponse> joinConference(
      PlanetKitJoinConferenceParam param) async {
    print("#flutter_method_channel joinConference with ${param.toJson()}");
    final jsonString = await methodChannel.invokeMethod<String>(
        'joinConference', param.toJson()) as String;
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    final response = JoinConferenceResponse.fromJson(jsonMap);
    return response;
  }

  @override
  Future<PlanetKitCcParam?> createCcParam(String ccParam) async {
    print("#flutter_method_channel createCcParam $ccParam");
    final jsonString =
        await methodChannel.invokeMethod<String?>('createCcParam', ccParam);

    if (jsonString == null) {
      print("#flutter_method_channel createCcParam response null");
      return null;
    }

    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    final response = CreateCCParamResponse.fromJson(jsonMap);

    return PlanetKitCcParam(
        id: response.id,
        peerId: response.peerId,
        peerServiceId: response.peerServiceId,
        mediaType: response.mediaType);
  }

  @override
  Future<bool> releaseInstance(String id) async {
    print("#flutter_method_channel releaseInstance $id");
    return await methodChannel.invokeMethod<bool>('releaseInstance', id)
        as bool;
  }
}
