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

import '../../internal/planet_kit_platform_resource_manager.dart';
import 'planet_kit_audio_sample_type.dart';
import '../../internal/planet_kit_platform_interface.dart';

class PlanetKitInterceptedAudio {
  final String id;
  final int sampleRate;
  final int channel;
  final PlanetKitAudioSampleType sampleType;
  Uint8List _data;
  final int sampleCount;
  final int seq;

  PlanetKitInterceptedAudio({
    required this.id,
    required this.sampleRate,
    required this.channel,
    required this.sampleType,
    required this.sampleCount,
    required this.seq,
    required Uint8List data,
  }) : _data = data {
    NativeResourceManager.instance.add(this, id);
  }

  Future<bool> setData(Uint8List data) async {
    if (!await Platform.instance.setInterceptedAudioData(id, _data)) {
      print("#planet_kit_call setInterceptedAudioData failed");
      return false;
    }
    _data = data;
    return true;
  }

  Uint8List get data => _data;
}
