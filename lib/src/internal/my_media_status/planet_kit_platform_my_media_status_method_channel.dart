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

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_interface.dart';
import 'package:planet_kit_flutter/src/public/video/planet_kit_video_status.dart';

class MyMediaStatusMethodChannel implements MyMediaStatusInterface {
  final MethodChannel methodChannel;

  MyMediaStatusMethodChannel({required this.methodChannel});

  @override
  Future<bool> isMyAudioMuted(String myMediaStatusId) async {
    print(
        "#flutter_method_channel isMyAudioMuted with myMediaStatusId $myMediaStatusId");

    return await methodChannel.invokeMethod<bool>(
        "myMediaStatus_isMyAudioMuted", myMediaStatusId) as bool;
  }

  @override
  Future<PlanetKitVideoStatus?> getMyVideoStatus(String myMediaStatusId) async {
    print(
        "#flutter_method_channel getMyVideoStatus with myMediaStatusId $myMediaStatusId");
    final jsonString = await methodChannel.invokeMethod<String?>(
        'myMediaStatus_getMyVideoStatus', myMediaStatusId);

    if (jsonString == null) {
      print("#flutter_method_channel getMyVideoStatus response null");
      return null;
    }
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    final response = PlanetKitVideoStatus.fromJson(jsonMap);
    return response;
  }
}
