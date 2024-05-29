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

/// A data model used for intercepted audio feature.
///
/// This class encapsulates the details of intercepted audio data,
/// including audio metadata and raw audio data.
class PlanetKitInterceptedAudio {
  /// @nodoc
  final String id;

  /// The sample rate of the audio data in Hz.
  final int sampleRate;

  /// The number of audio channels (e.g., 1 for mono, 2 for stereo).
  final int channel;

  /// The type of audio samples as defined by [PlanetKitAudioSampleType].
  final PlanetKitAudioSampleType sampleType;

  /// The actual audio data as a byte buffer.
  Uint8List _data;

  /// The number of samples in the audio data.
  final int sampleCount;

  /// A sequence number for the audio data, used to handle order and synchronization.
  final int seq;

  /// @nodoc
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

  /// Updates the audio data stored in this object.
  ///
  /// Attempts to set the intercepted audio data on the platform side. If successful, updates the local data.
  /// The new [data] must have the same audio attributes as the original audio data.
  Future<bool> setData(Uint8List data) async {
    if (!await Platform.instance.setInterceptedAudioData(id, _data)) {
      print("#planet_kit_call setInterceptedAudioData failed");
      return false;
    }
    _data = data;
    return true;
  }

  /// Gets the current audio data.
  Uint8List get data => _data;
}
