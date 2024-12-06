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

import 'package:flutter/services.dart';
import 'package:planet_kit_flutter/src/internal/peer_control/planet_kit_platform_peer_control_params.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_interface.dart';
import 'package:planet_kit_flutter/src/public/video/planet_kit_video_resolution.dart';

class PeerControlMethodChannel implements PeerControlInterface {
  final MethodChannel methodChannel;

  PeerControlMethodChannel({required this.methodChannel});

  @override
  Future<bool> register(String id) async {
    print("#flutter_method_channel peer control register with id $id");

    return await methodChannel.invokeMethod<bool>("peerControl_register", id)
        as bool;
  }

  @override
  Future<bool> unregister(String id) async {
    print("#flutter_method_channel peer control unregister with id $id");

    return await methodChannel.invokeMethod<bool>("peerControl_unregister", id)
        as bool;
  }

  @override
  Future<bool> startVideo(
      String id, String viewId, PlanetKitVideoResolution maxResolution) async {
    print(
        "#flutter_method_channel startVideo with id $id viewid: $id $maxResolution");
    final param =
        StartVideoParam(id: id, viewId: viewId, maxResolution: maxResolution);

    return await methodChannel.invokeMethod<bool>(
        'peerControl_startVideo', param.toJson()) as bool;
  }

  @override
  Future<bool> stopVideo(String id, String viewId) async {
    print("#flutter_method_channel stopVideo with id $id viewid: $id");
    final param = StopVideoParam(id: id, viewId: viewId);

    return await methodChannel.invokeMethod<bool>(
        'peerControl_stopVideo', param.toJson()) as bool;
  }

  @override
  Future<bool> startScreenShare(String id, String viewId) async {
    print("#flutter_method_channel startScreenShare with id $id viewid: $id");
    final param = StartScreenShareParam(id: id, viewId: viewId);
    return await methodChannel.invokeMethod<bool>(
        'peerControl_startScreenShare', param.toJson()) as bool;
  }

  @override
  Future<bool> stopScreenShare(String id, String viewId) async {
    print("#flutter_method_channel stopScreenShare with id $id viewid: $id");
    final param = StopScreenShareParam(id: id, viewId: viewId);
    return await methodChannel.invokeMethod<bool>(
        'peerControl_stopScreenShare', param.toJson()) as bool;
  }
}
