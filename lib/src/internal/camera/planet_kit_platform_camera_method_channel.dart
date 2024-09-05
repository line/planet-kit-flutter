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
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_interface.dart';

class CameraMethodChannel implements CameraInterface {
  final MethodChannel methodChannel;

  CameraMethodChannel({required this.methodChannel});

  @override
  Future<bool> startPreview(String id) async {
    print("#CameraMethodChannel startPreview $id");
    return await methodChannel.invokeMethod<bool>("camera_startPreview", id)
        as bool;
  }

  @override
  Future<bool> stopPreview(String id) async {
    print("#CameraMethodChannel stopPreview $id");
    return await methodChannel.invokeMethod<bool>("camera_stopPreview", id)
        as bool;
  }

  @override
  Future<bool> switchPosition() async {
    print("#CameraMethodChannel switchPosition");
    return await methodChannel.invokeMethod<bool>("camera_switchPosition")
        as bool;
  }

  @override
  Future<bool> clearVirtualBackground() async {
    print("#CameraMethodChannel switchPosition");
    return await methodChannel
        .invokeMethod<bool>("camera_clearVirtualBackground") as bool;
  }

  @override
  Future<bool> setVirtualBackgroundWithBlur(int radius) async {
    print("#CameraMethodChannel switchPosition");
    return await methodChannel.invokeMethod<bool>(
        "camera_setVirtualBackgroundWithBlur", radius) as bool;
  }

  @override
  Future<bool> setVirtualBackgroundWithImage(String fileUri) async {
    print("#CameraMethodChannel switchPosition");
    return await methodChannel.invokeMethod<bool>(
        "camera_setVirtualBackgroundWithImage", fileUri) as bool;
  }
}
