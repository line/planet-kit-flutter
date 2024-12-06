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

import 'package:flutter/services.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_types.dart';
import 'package:planet_kit_flutter/src/public/video/planet_kit_video_status.dart';
import '../../../public/conference/planet_kit_conference_peer.dart';
import '../../planet_kit_platform_interface.dart';

class ConferencePeerMethodChannel implements ConferencePeerInterface {
  final MethodChannel methodChannel;

  ConferencePeerMethodChannel({required this.methodChannel});

  @override
  Future<PlanetKitHoldStatus?> getHoldStatus(String id) async {
    print("#flutter_method_channel getHoldStatus with $id");
    final jsonString = await methodChannel.invokeMethod<String?>(
        'conferencePeer_getHoldStatus', id);

    if (jsonString == null) {
      print("#flutter_method_channel getHoldStatus response null");
      return null;
    }

    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return PlanetKitHoldStatus.fromJson(jsonMap);
  }

  @override
  Future<bool> isMuted(String id) async {
    print("#flutter_method_channel getHoldStatus with $id");
    final isMuted = await methodChannel.invokeMethod<bool>(
        'conferencePeer_isMuted', id) as bool;
    return isMuted;
  }

  @override
  Future<PlanetKitVideoStatus?> getVideoStatus(String id) async {
    print("#flutter_method_channel getVideoStatus with $id");
    final jsonString = await methodChannel.invokeMethod<String?>(
        'conferencePeer_getVideoStatus', id);

    if (jsonString == null) {
      print("#flutter_method_channel getMyVideoStatus response null");
      return null;
    }

    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return PlanetKitVideoStatus.fromJson(jsonMap);
  }

  @override
  Future<PlanetKitScreenShareState?> getScreenShareState(String id) async {
    print("#flutter_method_channel getVideoStatus with $id");
    final state = await methodChannel.invokeMethod<int?>(
        'conferencePeer_getScreenShareState', id);

    if (state == null) {
      print("#flutter_method_channel getScreenShareState response null");
      return null;
    }

    return PlanetKitScreenShareState.fromInt(state);
  }
}
