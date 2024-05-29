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

import '../audio/planet_kit_audio_sample_type.dart';
import '../planet_kit_disconnect_source.dart';
import '../planet_kit_disconnect_reason.dart';
import '../audio/planet_kit_intercepted_audio.dart';
import '../../internal/planet_kit_platform_interface.dart';
import '../../internal/call/planet_kit_platform_call_event.dart';
import '../../internal/call/planet_kit_platform_call_event_types.dart';
import '../../internal/planet_kit_platform_resource_manager.dart';

/// A handler for managing call events within the PlanetKit framework.
///
/// This class provides a set of callbacks to handle various call states and events.
class PlanetKitCallEventHandler {
  /// Callback triggered when the outgoing call is waiting to be connected.
  final void Function(PlanetKitCall call) onWaitConnected;

  /// Callback triggered when the call is successfully connected.
  final void Function(PlanetKitCall call) onConnected;

  /// Callback triggered when the call is disconnected.
  ///
  /// This callback has detailed parameters including [PlanetKitDisconnectReason] for the disconnect reason, 
  /// [PlanetKitDisconnectSource] for the disconnect source, and [byRemote] as a flag indicating whether the disconnection was initiated by the remote peer.
  final void Function(PlanetKitCall call, PlanetKitDisconnectReason reason,
      PlanetKitDisconnectSource source, bool byRemote) onDisconnected;

  /// Callback triggered when the incoming call is verified.
  final void Function(PlanetKitCall call) onVerified;

  /// Optional callback triggered when the peer's microphone is muted.
  final void Function(PlanetKitCall call)? onPeerMicMuted;

  /// Optional callback triggered when the peer's microphone is unmuted.
  final void Function(PlanetKitCall call)? onPeerMicUnmuted;

  /// Constructs a [PlanetKitCallEventHandler].
  const PlanetKitCallEventHandler({
      required this.onWaitConnected,
      required this.onConnected,
      required this.onDisconnected,
      required this.onVerified,
      this.onPeerMicMuted,
      this.onPeerMicUnmuted});
}

/// A handler for intercepted audio within the PlanetKit framework.
///
/// Provides a callback to handle intercepted audio data during a call.
class PlanetKitCallInterceptedAudioHandler {
  /// Callback triggered when audio data is intercepted during a call.
  final void Function(PlanetKitCall call, PlanetKitInterceptedAudio audio) onIntercept;

  /// Constructs a [PlanetKitCallInterceptedAudioHandler].
  PlanetKitCallInterceptedAudioHandler({required this.onIntercept});
}

/// Represents a call managed by the PlanetKit framework.
///
/// This class is used to manage the call session.
class PlanetKitCall implements CallEventHandler, InterceptedAudioHandler {
  final PlanetKitCallEventHandler? _eventHandler;
  PlanetKitCallInterceptedAudioHandler? _interceptedAudioHandler;
  /// @nodoc
  final String callId;

  /// @nodoc
  PlanetKitCall({
      required this.callId,
      required PlanetKitCallEventHandler eventHandler}) : _eventHandler = eventHandler {
    NativeResourceManager.instance.add(this, callId);
    Platform.instance.eventManager.addCallEventHandler(callId, this);
  }

  /// Whether the local user's audio is muted.
  Future<bool> get isMyAudioMuted async =>
      await Platform.instance.isMyAudioMuted(callId);

  /// Whether the speaker output is enabled.
  Future<bool> get isSpeakerOut async =>
      await Platform.instance.isSpeakerOut(callId);

  /// Accepts the incoming call.
  Future<bool> acceptCall() async {
    return await Platform.instance.acceptCall(callId);
  }

  /// Ends the current call.
  Future<bool> endCall() async {
    return await Platform.instance.endCall(callId);
  }

  /// Mutes the local user's audio.
  Future<bool> muteMyAudio() async {
    return await Platform.instance.muteMyAudio(callId);
  }

  /// Unmutes the local user's audio.
  Future<bool> unmuteMyAudio() async {
    return await Platform.instance.unmuteMyAudio(callId);
  }

  /// Enables or disables the speaker output.
  Future<bool> speakerOut(bool speakerOut) async {
    return await Platform.instance.speakerOut(callId, speakerOut);
  }

  /// @nodoc
  @override
  void onCallEvent(String callId, Map<String, dynamic> data) {
    if (callId != this.callId) {
      print("#flutter_kit_call event not for current instance");
      return;
    }

    print("#flutter_kit_call $data");

    final eventData = CallEventData.fromJson(data);

    if (eventData.callEventType == CallEventType.connected) {
      _eventHandler?.onConnected.call(this);
    } else if (eventData.callEventType == CallEventType.disconnected) {
      _handleDisconnectEvent(callId, data);
    } else if (eventData.callEventType == CallEventType.waitConnect) {
      _eventHandler?.onWaitConnected.call(this);
    } else if (eventData.callEventType == CallEventType.verified) {
      _eventHandler?.onVerified.call(this);
    } else if (eventData.callEventType == CallEventType.peerMicMuted) {
      _eventHandler?.onPeerMicMuted?.call(this);
    } else if (eventData.callEventType == CallEventType.peerMicUnmuted) {
      _eventHandler?.onPeerMicUnmuted?.call(this);
    } else {
      print("#planet_kit_call event unknown");
    }
  }

  void _handleDisconnectEvent(String callId, Map<String, dynamic> data) {
    final eventData = DisconnectedEventData.fromJson(data);
    Platform.instance.eventManager.removeCallEventHandler(callId);
    _eventHandler?.onDisconnected(this, eventData.disconnectReason,
        eventData.disconnectSource, eventData.byRemote);
  }

  /// @nodoc  
  @override
  void onInterceptedAudio(String callId, Map<String, dynamic> audioData) {
    final String audioId = audioData["audioId"];
    final int sampleRate = audioData["sampleRate"];
    final int channel = audioData["channel"];
    final PlanetKitAudioSampleType sampleType =
        PlanetKitAudioSampleType.fromInt(audioData["sampleType"]);
    final int sampleCount = audioData["sampleCount"];
    final int seq = audioData["seq"];
    final Uint8List data = audioData["data"];

    final interceptedAudio = PlanetKitInterceptedAudio(
        id: audioId,
        sampleRate: sampleRate,
        channel: channel,
        sampleType: sampleType,
        sampleCount: sampleCount,
        seq: seq,
        data: data);

    _interceptedAudioHandler?.onIntercept(this, interceptedAudio);
  }
}

/// Extension on [PlanetKitCall] to manage audio interception.
extension InterceptAudioExtension on PlanetKitCall {
  /// Wheter interception of the local user's audio is enabled.
  Future<bool> get isInterceptMyAudioEnabled async =>
      await Platform.instance.isInterceptMyAudioEnabled(callId);

  /// Enables interception of the local user's audio.
  ///
  /// Requires a [handler] to manage intercepted audio events.
  Future<bool> enableInterceptMyAudio(
      PlanetKitCallInterceptedAudioHandler handler) async {
    if (!await Platform.instance.enableInterceptMyAudio(callId, this)) {
      print("#planet_kit_call enableInterceptMyAudio failed");
      return false;
    }

    Platform.instance.eventManager.addInterceptedAudioHandler(callId, this);

    _interceptedAudioHandler = handler;
    return true;
  }

  /// Disables interception of the local user's audio.
  Future<bool> disableInterceptMyAudio() async {
    if (!await Platform.instance.disableInterceptMyAudio(callId)) {
      print("#planet_kit_call disableInterceptMyAudio failed");
      return false;
    }

    Platform.instance.eventManager.removeInterceptedAudioHandler(callId);

    _interceptedAudioHandler = null;
    return true;
  }

  /// Puts back the intercepted audio data so that it can be sent to the peer.
  Future<bool> putInterceptedMyAudioBack(
      PlanetKitInterceptedAudio audio) async {
    if (!await Platform.instance.putInterceptedMyAudioBack(callId, audio.id)) {
      print("#planet_kit_call disableInterceptMyAudio failed");
      return false;
    }

    return true;
  }
}
