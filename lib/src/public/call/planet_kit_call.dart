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
import 'dart:typed_data';

import 'package:planet_kit_flutter/src/public/my_media_status/planet_kit_my_media_status.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_types.dart';

import '../audio/planet_kit_audio_sample_type.dart';
import '../planet_kit_disconnect_source.dart';
import '../planet_kit_disconnect_reason.dart';
import '../audio/planet_kit_hooked_audio.dart';
import '../../internal/planet_kit_platform_interface.dart';
import '../../internal/call/planet_kit_platform_call_event.dart';
import '../../internal/call/planet_kit_platform_call_event_type.dart';
import '../../internal/planet_kit_platform_resource_manager.dart';
import '../statistics/planet_kit_statistics.dart';

/// A handler for managing call events within the PlanetKit framework.
///
/// This class provides a set of callbacks to handle various call states and events.
class PlanetKitCallEventHandler {
  /// Callback triggered when the outgoing call is waiting to be connected.
  final void Function(PlanetKitCall call) onWaitConnected;

  /// Callback triggered when the call is successfully connected.
  final void Function(PlanetKitCall call, bool isInResponderPreparation,
      bool shouldFinishPreparation) onConnected;

  /// Callback triggered when the call is disconnected.
  ///
  /// This callback has detailed parameters including [PlanetKitDisconnectReason] for the disconnect reason,
  /// [PlanetKitDisconnectSource] for the disconnect source, and [byRemote] as a flag indicating whether the disconnection was initiated by the remote peer.
  final void Function(PlanetKitCall call, PlanetKitDisconnectReason reason,
      PlanetKitDisconnectSource source, bool byRemote) onDisconnected;

  /// Callback triggered when the incoming call is verified.
  final void Function(PlanetKitCall call, bool peerUseResponderPreparation)
      onVerified;

  /// Optional callback triggered when the peer's microphone is muted.
  final void Function(PlanetKitCall call)? onPeerMicMuted;

  /// Optional callback triggered when the peer's microphone is unmuted.
  final void Function(PlanetKitCall call)? onPeerMicUnmuted;

  /// Optional callback triggered when the network becomes unavailable.
  /// Call will automatically disconnect after [willDisconnect].
  /// Use [isPeer] to identify the cause of the network unavilability.
  final void Function(PlanetKitCall call, bool isPeer, Duration willDisconnect)?
      onNetworkUnavailable;

  /// Optional callback triggered when the network becomes available after it had been unavailable.
  /// Use [isPeer] to identify the cause of the network unavilability.
  final void Function(PlanetKitCall call, bool isPeer)? onNetworkReavailable;

  /// Callback triggered when the responder preparation is finished.
  final void Function(PlanetKitCall call) onPreparationFinished;

  /// Optional callback triggered when the peer hold the call.
  final void Function(PlanetKitCall call, String? reason)? onPeerHold;

  /// Optional callback triggered when the peer unhold the call.
  final void Function(PlanetKitCall call)? onPeerUnhold;

  /// Optional callback triggered when the peer request mute to the local user.
  final void Function(PlanetKitCall call, bool mute)?
      onMyAudioMuteRequestedByPeer;

  /// Optional callback triggered when the peer's video is paused.
  final void Function(PlanetKitCall call, PlanetKitVideoPauseReason reason)?
      onPeerVideoPaused;

  /// Optional callback triggered when the peer's video is resumed.
  final void Function(PlanetKitCall call)? onPeerVideoResumed;

  /// Optional callback triggered when the peer enables video.
  final void Function(PlanetKitCall call)? onVideoEnabledByPeer;

  /// Optional callback triggered when the peer disables video.
  final void Function(PlanetKitCall call, PlanetKitMediaDisableReason reason)?
      onVideoDisabledByPeer;

  /// Optional callback triggered when the local user's video source is not detected.
  final void Function(PlanetKitCall call)? onDetectedMyVideoNoSource;

  /// Optional callback triggered when the peer starts screen share.
  final void Function(PlanetKitCall call)? onPeerScreenShareStarted;

  /// Optional callback triggered when the peer stops screen share.
  final void Function(PlanetKitCall call)? onPeerScreenShareStopped;

  /// Constructs a [PlanetKitCallEventHandler].
  const PlanetKitCallEventHandler(
      {required this.onWaitConnected,
      required this.onConnected,
      required this.onDisconnected,
      required this.onVerified,
      required this.onPreparationFinished,
      this.onPeerMicMuted,
      this.onPeerMicUnmuted,
      this.onNetworkReavailable,
      this.onNetworkUnavailable,
      this.onPeerHold,
      this.onPeerUnhold,
      this.onMyAudioMuteRequestedByPeer,
      this.onPeerVideoPaused,
      this.onPeerVideoResumed,
      this.onVideoEnabledByPeer,
      this.onVideoDisabledByPeer,
      this.onDetectedMyVideoNoSource,
      this.onPeerScreenShareStarted,
      this.onPeerScreenShareStopped});
}

/// A handler for hooked audio within the PlanetKit framework.
///
/// Provides a callback to handle hooked audio data during a call.
class PlanetKitCallHookedAudioHandler {
  /// Callback triggered when audio data is hooked during a call.
  final void Function(PlanetKitCall call, PlanetKitHookedAudio audio) onHook;

  /// Constructs a [PlanetKitCallHookedAudioHandler].
  PlanetKitCallHookedAudioHandler({required this.onHook});
}

/// Represents a call managed by the PlanetKit framework.
///
/// This class is used to manage the call session.
class PlanetKitCall implements HookedAudioHandler {
  final PlanetKitCallEventHandler? _eventHandler;
  PlanetKitCallHookedAudioHandler? _hookedAudioHandler;
  StreamSubscription<CallEvent>? _subscription;
  PlanetKitMyMediaStatus myMediaStatus;

  /// @nodoc
  final String callId;

  /// @nodoc
  PlanetKitCall(
      {required this.callId,
      required PlanetKitCallEventHandler eventHandler,
      required this.myMediaStatus})
      : _eventHandler = eventHandler {
    NativeResourceManager.instance.add(this, callId);
    _subscription =
        Platform.instance.eventManager.onCallEvent.listen(_onCallEvent);
  }

  /// Whether the local user's audio is muted.
  Future<bool> get isMyAudioMuted async =>
      await Platform.instance.callInterface.isMyAudioMuted(callId);

  /// Whether the speaker output is enabled.
  Future<bool> get isSpeakerOut async =>
      await Platform.instance.callInterface.isSpeakerOut(callId);

  /// Whether the call is on hold.
  Future<bool> get isOnHold async =>
      await Platform.instance.callInterface.isOnHold(callId);

  /// Accepts the incoming call.
  Future<bool> acceptCall({bool useResponderPreparation = false}) async {
    return await Platform.instance.callInterface
        .acceptCall(callId, useResponderPreparation);
  }

  /// Ends the current call.
  Future<bool> endCall({String? userReleasePhrase}) async {
    return await Platform.instance.callInterface
        .endCall(callId, userReleasePhrase);
  }

  /// Ends the current call with an error.
  Future<bool> endCallWithError(String userReleasePhrase) async {
    return await Platform.instance.callInterface
        .endCallWithError(callId, userReleasePhrase);
  }

  /// Mutes or unmutes the local user's audio.
  Future<bool> muteMyAudio(bool mute) async {
    return await Platform.instance.callInterface.muteMyAudio(callId, mute);
  }

  /// Enables or disables the speaker output.
  Future<bool> speakerOut(bool speakerOut) async {
    return await Platform.instance.callInterface.speakerOut(callId, speakerOut);
  }

  /// Notifies CallKit of audio activation on iOS platform.
  /// For Android Platform, this will have no effect.
  Future<bool> notifyCallKitAudioActivation() async {
    return await Platform.instance.callInterface
        .notifyCallKitAudioActivation(callId);
  }

  /// Finishes preparation. To check whether the call is in preparation, check [isInResponderPreparation] in [PlanetKitCallEventHandler].
  /// If [shouldFinishPreparation] is true, the local app client must finish preparation.
  Future<bool> finishPreparation() async {
    return await Platform.instance.callInterface.finishPreparation(callId);
  }

  /// Holds the current call.
  Future<bool> hold({String? reason}) async {
    return await Platform.instance.callInterface.hold(callId, reason);
  }

  /// Unholds the current call.
  Future<bool> unhold() async {
    return await Platform.instance.callInterface.unhold(callId);
  }

  /// Requests the peer to mute their audio.
  Future<bool> requestPeerMute(bool mute) async {
    return await Platform.instance.callInterface.requestPeerMute(callId, mute);
  }

  /// Silences the peer's audio on this device.
  Future<bool> silencePeerAudio(bool silent) async {
    return await Platform.instance.callInterface
        .silencePeerAudio(callId, silent);
  }

  /// Adds the local user's video view.
  Future<bool> addMyVideoView(String viewId) async {
    return await Platform.instance.callInterface.addMyVideoView(callId, viewId);
  }

  /// Removes the local user's video view.
  Future<bool> removeMyVideoView(String viewId) async {
    return await Platform.instance.callInterface
        .removeMyVideoView(callId, viewId);
  }

  /// Adds the peer's video view.
  Future<bool> addPeerVideoView(String viewId) async {
    return await Platform.instance.callInterface
        .addPeerVideoView(callId, viewId);
  }

  /// Removes the peer's video view.
  Future<bool> removePeerVideoView(String viewId) async {
    return await Platform.instance.callInterface
        .removePeerVideoView(callId, viewId);
  }

  /// Adds the peer's screen share view.
  Future<bool> addPeerScreenShareView(String viewId) async {
    return await Platform.instance.callInterface
        .addPeerScreenShareView(callId, viewId);
  }

  /// Removes the peer's screen share view.
  Future<bool> removePeerScreenShareView(String viewId) async {
    return await Platform.instance.callInterface
        .removePeerScreenShareView(callId, viewId);
  }

  /// Pauses the local user's video.
  Future<bool> pauseMyVideo() async {
    return await Platform.instance.callInterface.pauseMyVideo(callId);
  }

  /// Resumes the local user's video.
  Future<bool> resumeMyVideo() async {
    return await Platform.instance.callInterface.resumeMyVideo(callId);
  }

  /// Enables a video call.
  Future<bool> enableVideo() async {
    return await Platform.instance.callInterface.enableVideo(callId);
  }

  /// Disables a video call.
  Future<bool> disableVideo(
      {PlanetKitMediaDisableReason reason =
          PlanetKitMediaDisableReason.user}) async {
    return await Platform.instance.callInterface.disableVideo(callId, reason);
  }

  /// Retrieves call statistics.
  Future<PlanetKitStatistics?> getStatistics() async {
    return await Platform.instance.callInterface.getStatistics(callId);
  }

  void _onCallEvent(CallEvent event) {
    if (event.id != this.callId) {
      print("#flutter_kit_call event not for current instance");
      return;
    }

    print("#flutter_kit_call event: $event");
    final type = event.subType;

    if (type == CallEventType.connected) {
      _handleConnectedEvent(event);
    } else if (type == CallEventType.disconnected) {
      _handleDisconnectedEvent(event);
    } else if (type == CallEventType.waitConnect) {
      _eventHandler?.onWaitConnected.call(this);
    } else if (type == CallEventType.verified) {
      _handlerVerifiedEvent(event);
    } else if (type == CallEventType.peerMicMuted) {
      _eventHandler?.onPeerMicMuted?.call(this);
    } else if (type == CallEventType.peerMicUnmuted) {
      _eventHandler?.onPeerMicUnmuted?.call(this);
    } else if (type == CallEventType.networkDidUnavailable) {
      _handleNetworkUnavailableEvent(event);
    } else if (type == CallEventType.networkDidReavailable) {
      _handleNetworkReavailableEvent(event);
    } else if (type == CallEventType.finishPreparation) {
      _eventHandler?.onPreparationFinished(this);
    } else if (type == CallEventType.peerHold) {
      _handlePeerHoldEvent(event);
    } else if (type == CallEventType.peerUnhold) {
      _eventHandler?.onPeerUnhold?.call(this);
    } else if (type == CallEventType.muteMyAudioRequestByPeer) {
      _handleMuteMyAudioRequestByPeerEvent(event);
    } else if (type == CallEventType.peerVideoDidPause) {
      _handlePeerVideoDidPauseEvent(event);
    } else if (type == CallEventType.peerVideoDidResume) {
      _eventHandler?.onPeerVideoResumed?.call(this);
    } else if (type == CallEventType.videoEnabledByPeer) {
      _eventHandler?.onVideoEnabledByPeer?.call(this);
    } else if (type == CallEventType.videoDisabledByPeer) {
      _handleVideoDisabledByPeerEvent(event);
    } else if (type == CallEventType.detectedMyVideoNoSource) {
      _eventHandler?.onDetectedMyVideoNoSource?.call(this);
    } else if (type == CallEventType.peerDidStartScreenShare) {
      _eventHandler?.onPeerScreenShareStarted?.call(this);
    } else if (type == CallEventType.peerDidStopScreenShare) {
      _eventHandler?.onPeerScreenShareStopped?.call(this);
    } else {
      print("#planet_kit_call event unknown");
    }
  }

  void _handlePeerVideoDidPauseEvent(CallEvent event) {
    final pauseEvent = event as PeerVideoDidPauseEvent;
    _eventHandler?.onPeerVideoPaused?.call(this, pauseEvent.reason);
  }

  void _handleVideoDisabledByPeerEvent(CallEvent event) {
    final disableEvent = event as VideoDisabledByPeerEvent;
    _eventHandler?.onVideoDisabledByPeer?.call(this, disableEvent.reason);
  }

  void _handleConnectedEvent(CallEvent event) {
    final connectedEvent = event as ConnectedEvent;
    _eventHandler?.onConnected.call(
        this,
        connectedEvent.isInResponderPreparation,
        connectedEvent.shouldFinishPreparation);
  }

  void _handleDisconnectedEvent(CallEvent event) {
    final disconnectedEvent = event as DisconnectedEvent;
    _subscription?.cancel();
    _eventHandler?.onDisconnected(this, disconnectedEvent.disconnectReason,
        disconnectedEvent.disconnectSource, disconnectedEvent.byRemote);
  }

  void _handlerVerifiedEvent(CallEvent event) {
    final verifiedEvent = event as VerifiedEvent;
    _eventHandler?.onVerified(this, verifiedEvent.peerUseResponderPreparation);
  }

  void _handleNetworkUnavailableEvent(CallEvent event) {
    final networkDidUnavailableEvent = event as NetworkDidUnavailableEvent;
    _eventHandler?.onNetworkUnavailable?.call(
        this,
        networkDidUnavailableEvent.isPeer,
        Duration(seconds: networkDidUnavailableEvent.willDisconnectSec));
  }

  void _handleNetworkReavailableEvent(CallEvent event) {
    final networkDidReavailableEvent = event as NetworkDidReavailableEvent;
    _eventHandler?.onNetworkReavailable
        ?.call(this, networkDidReavailableEvent.isPeer);
  }

  void _handlePeerHoldEvent(CallEvent event) {
    final peerHoldEvent = event as PeerHoldEvent;
    _eventHandler?.onPeerHold?.call(this, peerHoldEvent.reason);
  }

  void _handleMuteMyAudioRequestByPeerEvent(CallEvent event) {
    final myAudioMuteRequestByPeerEvent =
        event as MyAudioMuteRequestByPeerEvent;
    _eventHandler?.onMyAudioMuteRequestedByPeer
        ?.call(this, myAudioMuteRequestByPeerEvent.mute);
  }

  /// @nodoc
  @override
  void onHookedAudio(String callId, Map<String, dynamic> audioData) {
    final String audioId = audioData["audioId"];
    final int sampleRate = audioData["sampleRate"];
    final int channel = audioData["channel"];
    final PlanetKitAudioSampleType sampleType =
        PlanetKitAudioSampleType.fromInt(audioData["sampleType"]);
    final int sampleCount = audioData["sampleCount"];
    final int seq = audioData["seq"];
    final Uint8List data = audioData["data"];

    final hookedAudio = PlanetKitHookedAudio(
        id: audioId,
        sampleRate: sampleRate,
        channel: channel,
        sampleType: sampleType,
        sampleCount: sampleCount,
        seq: seq,
        data: data);

    _hookedAudioHandler?.onHook(this, hookedAudio);
  }
}

/// Extension on [PlanetKitCall] to manage audio hooking.
extension HookAudioExtension on PlanetKitCall {
  /// Whether hooking of the local user's audio is enabled.
  Future<bool> get isHookMyAudioEnabled async =>
      await Platform.instance.callInterface.isHookMyAudioEnabled(callId);

  /// Enables hooking of the local user's audio.
  ///
  /// Requires a [handler] to manage hooked audio events.
  Future<bool> enableHookMyAudio(
      PlanetKitCallHookedAudioHandler handler) async {
    if (!await Platform.instance.callInterface
        .enableHookMyAudio(callId, this)) {
      print("#planet_kit_call enableHookMyAudio failed");
      return false;
    }

    Platform.instance.eventManager.addHookedAudioHandler(callId, this);

    _hookedAudioHandler = handler;
    return true;
  }

  /// Disables hooking of the local user's audio.
  Future<bool> disableHookMyAudio() async {
    if (!await Platform.instance.callInterface.disableHookMyAudio(callId)) {
      print("#planet_kit_call disableHookMyAudio failed");
      return false;
    }

    Platform.instance.eventManager.removeHookedAudioHandler(callId);

    _hookedAudioHandler = null;
    return true;
  }

  /// Puts back the hooked audio data so that it can be sent to the peer.
  Future<bool> putHookedMyAudioBack(PlanetKitHookedAudio audio) async {
    if (!await Platform.instance.callInterface
        .putHookedMyAudioBack(callId, audio.id)) {
      print("#planet_kit_call putHookedMyAudioBack failed");
      return false;
    }

    return true;
  }
}
