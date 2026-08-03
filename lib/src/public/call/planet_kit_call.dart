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
import '../../internal/data_session/planet_kit_data_session_container.dart';
import '../../internal/planet_kit_platform_resource_manager.dart';
import '../data_session/planet_kit_data_session.dart';
import '../planet_kit_user_id.dart';
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
  final void Function(
      PlanetKitCall call,
      PlanetKitDisconnectReason reason,
      PlanetKitDisconnectSource source,
      String? userCode,
      bool byRemote) onDisconnected;

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

  /// Optional callback that is invoked with audio description updates during a call.
  /// It provides the peer's average volume level.
  /// The update interval can be configured through [PlanetKitMakeCallParam] and [PlanetKitVerifyCallParam].
  final void Function(PlanetKitCall call, int averageVolumeLevel)?
      onPeerAudioDescriptionUpdated;

  /// Optional callback triggered when the peer sets shared contents.
  final void Function(PlanetKitCall call, Uint8List data, Duration elapsed)?
      onPeerSharedContentsSet;

  /// Optional callback triggered when the peer unsets shared contents.
  final void Function(PlanetKitCall call)? onPeerSharedContentsUnset;

  /// Optional callback triggered when the peer sets exclusively shared contents.
  final void Function(PlanetKitCall call, Uint8List data, Duration elapsed)?
      onPeerExclusivelySharedContentsSet;

  /// Optional callback triggered when the peer unsets exclusively shared contents.
  final void Function(PlanetKitCall call)? onPeerExclusivelySharedContentsUnset;

  /// Optional callback triggered when short data is received from the peer.
  /// Provides the data [type] string and the binary [data].
  final void Function(PlanetKitCall call, String type, Uint8List data)?
      onShortDataReceived;

  /// Optional callback triggered when the peer starts a data session transfer
  /// on a given [streamId] with the given [type].
  ///
  /// In response, create an inbound data session with
  /// [PlanetKitCall.makeInboundDataSession], or ignore it with
  /// [PlanetKitCall.unsupportInboundDataSession].
  final void Function(PlanetKitCall call,
      PlanetKitDataSessionStreamId streamId, PlanetKitDataSessionType type)?
      onDataSessionIncoming;

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
      this.onPeerScreenShareStopped,
      this.onPeerAudioDescriptionUpdated,
      this.onPeerSharedContentsSet,
      this.onPeerSharedContentsUnset,
      this.onPeerExclusivelySharedContentsSet,
      this.onPeerExclusivelySharedContentsUnset,
      this.onShortDataReceived,
      this.onDataSessionIncoming});
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
  PlanetKitCallEventHandler? _eventHandler;
  PlanetKitCallHookedAudioHandler? _hookedAudioHandler;
  StreamSubscription<CallEvent>? _subscription;
  PlanetKitMyMediaStatus myMediaStatus;
  late final PlanetKitDataSessionContainer _dataSession;

  /// @nodoc
  final String callId;

  /// Whether the data session feature is supported on this call.
  ///
  /// Determined when the call connects (from the connect parameters) and valid
  /// from [PlanetKitCallEventHandler.onConnected] onward. `false` before the
  /// call is connected.
  bool isDataSessionSupported = false;

  /// @nodoc
  PlanetKitCall(
      {required this.callId,
      required PlanetKitCallEventHandler eventHandler,
      required this.myMediaStatus})
      : _eventHandler = eventHandler {
    NativeResourceManager.instance.add(this, callId);
    _dataSession = PlanetKitDataSessionContainer(
      makeOutbound: (streamId, type) => Platform.instance.callInterface
          .makeOutboundDataSession(callId, streamId, type),
      makeInbound: (streamId) => Platform.instance.callInterface
          .makeInboundDataSession(callId, streamId),
      unsupport: (streamId) => Platform.instance.callInterface
          .unsupportInboundDataSession(callId, streamId),
      getOutboundType: (streamId) => Platform.instance.callInterface
          .getOutboundDataSessionType(callId, streamId),
      getInboundType: (streamId) => Platform.instance.callInterface
          .getInboundDataSessionType(callId, streamId),
      send: (streamId, data, timestamp) => Platform.instance.callInterface
          .dataSessionSend(callId, streamId, data, timestamp),
      changeDestination: (streamId, target) => Platform
          .instance.callInterface
          .dataSessionChangeDestination(
              callId, streamId, target?.userId, target?.serviceId),
    );
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
  Future<bool> acceptCall(
      {bool useResponderPreparation = false,
      PlanetKitInitialMyVideoState initialMyVideoState =
          PlanetKitInitialMyVideoState.resume}) async {
    return await Platform.instance.callInterface
        .acceptCall(callId, useResponderPreparation, initialMyVideoState);
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

  /// Starts sending the local screen to the peer. Android only — iOS uses the
  /// broadcast extension flow and always returns false from this method.
  Future<bool> startMyScreenShare() async {
    return await Platform.instance.callInterface.startMyScreenShare(callId);
  }

  /// Stops sending the local screen to the peer.
  Future<bool> stopMyScreenShare() async {
    return await Platform.instance.callInterface.stopMyScreenShare(callId);
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
  Future<bool> enableVideo(
      {PlanetKitInitialMyVideoState initialMyVideoState =
          PlanetKitInitialMyVideoState.resume}) async {
    return await Platform.instance.callInterface
        .enableVideo(callId, initialMyVideoState);
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

  /// Sets shared contents for the call.
  Future<bool> setSharedContents(Uint8List data) async {
    return await Platform.instance.callInterface
        .setSharedContents(callId, data);
  }

  /// Unsets shared contents for the call.
  Future<bool> unsetSharedContents() async {
    return await Platform.instance.callInterface.unsetSharedContents(callId);
  }

  /// Sets exclusively shared contents for the call.
  Future<bool> setExclusivelySharedContents(Uint8List data) async {
    return await Platform.instance.callInterface
        .setExclusivelySharedContents(callId, data);
  }

  /// Unsets exclusively shared contents for the call.
  Future<bool> unsetExclusivelySharedContents() async {
    return await Platform.instance.callInterface
        .unsetExclusivelySharedContents(callId);
  }

  /// Sends short data to the peer with a [type] string and binary [data].
  ///
  /// Returns whether the send request was accepted. The [type] must be at most
  /// 100 bytes (including the null terminator) and [data] at most 800 bytes.
  /// These limits are enforced by the native SDK; a request that exceeds
  /// them (or is made before the session is connected) resolves to `false`.
  Future<bool> sendShortData(
      {required String type, required Uint8List data}) async {
    return await Platform.instance.callInterface
        .sendShortData(callId, type, data);
  }

  /// Creates an outbound data session for [streamId] with the given [type].
  ///
  /// On success the result carries the created session and
  /// [PlanetKitDataSessionFailReason.none]; on failure it carries a null
  /// session and the fail reason.
  Future<PlanetKitMakeOutboundDataSessionResult> makeOutboundDataSession(
          PlanetKitDataSessionStreamId streamId,
          PlanetKitDataSessionType type,
          PlanetKitOutboundDataSessionHandler handler) =>
      _dataSession.makeOutbound(streamId, type, handler);

  /// Creates an inbound data session for [streamId] that received an
  /// [PlanetKitCallEventHandler.onDataSessionIncoming] notification.
  Future<PlanetKitMakeInboundDataSessionResult> makeInboundDataSession(
          PlanetKitDataSessionStreamId streamId,
          PlanetKitInboundDataSessionHandler handler) =>
      _dataSession.makeInbound(streamId, handler);

  /// Marks the inbound data session for [streamId] as unsupported, ignoring
  /// incoming data for that stream.
  ///
  /// The returned bool indicates that the unsupport request was accepted. It is
  /// always `true` on iOS (where the native call returns void) and reflects the
  /// native result on Android. Apps should not branch on this platform-specific
  /// semantic.
  Future<bool> unsupportInboundDataSession(
          PlanetKitDataSessionStreamId streamId) =>
      _dataSession.unsupportInbound(streamId);

  /// Returns the current outbound data session for [streamId], or null.
  Future<PlanetKitOutboundDataSession?> getOutboundDataSession(
          PlanetKitDataSessionStreamId streamId) =>
      _dataSession.getOutbound(streamId);

  /// Returns the current inbound data session for [streamId], or null.
  Future<PlanetKitInboundDataSession?> getInboundDataSession(
          PlanetKitDataSessionStreamId streamId) =>
      _dataSession.getInbound(streamId);

  void _onCallEvent(CallEvent event) {
    if (event.id != this.callId) {
      print("#flutter_kit_call event not for current instance");
      return;
    }

    final type = event.subType;

    if (type != CallEventType.peerAudioDescriptionUpdate) {
      print("#flutter_kit_call event: $event");
    }

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
    } else if (type == CallEventType.peerAudioDescriptionUpdate) {
      _handlePeerAudioDescriptionUpdateEvent(event);
    } else if (type == CallEventType.peerSharedContentsSet) {
      _handlePeerSharedContentsSetEvent(event);
    } else if (type == CallEventType.peerSharedContentsUnset) {
      _eventHandler?.onPeerSharedContentsUnset?.call(this);
    } else if (type == CallEventType.peerExclusivelySharedContentsSet) {
      _handlePeerExclusivelySharedContentsSetEvent(event);
    } else if (type == CallEventType.peerExclusivelySharedContentsUnset) {
      _eventHandler?.onPeerExclusivelySharedContentsUnset?.call(this);
    } else if (type == CallEventType.shortDataReceived) {
      _handleShortDataReceivedEvent(event);
    } else if (type == CallEventType.dataSessionIncoming) {
      _handleDataSessionIncomingEvent(event);
    } else if (type == CallEventType.dataSessionInboundReceived) {
      _handleDataSessionInboundReceivedEvent(event);
    } else if (type == CallEventType.dataSessionInboundClosed) {
      _handleDataSessionInboundClosedEvent(event);
    } else if (type == CallEventType.dataSessionOutboundClosed) {
      _handleDataSessionOutboundClosedEvent(event);
    } else if (type == CallEventType.dataSessionOutboundTooLongQueuedData) {
      _handleDataSessionOutboundTooLongQueuedDataEvent(event);
    } else {
      print("#planet_kit_call event unknown");
    }
  }

  void _handleDataSessionIncomingEvent(CallEvent event) {
    final incomingEvent = event as DataSessionIncomingEvent;
    final type = PlanetKitDataSessionType.fromInt(incomingEvent.dataSessionType);
    if (type == null) {
      print("#planet_kit_call dataSessionIncoming unknown type");
      return;
    }
    _dataSession.recordIncoming(incomingEvent.streamId, type);
    _eventHandler?.onDataSessionIncoming
        ?.call(this, incomingEvent.streamId, type);
  }

  void _handleDataSessionInboundReceivedEvent(CallEvent event) {
    final receivedEvent = event as DataSessionInboundReceivedEvent;
    final peerId = PlanetKitUserId(
        userId: receivedEvent.userId, serviceId: receivedEvent.serviceId);
    _dataSession.handleInboundReceived(
        receivedEvent.streamId,
        peerId,
        receivedEvent.data,
        receivedEvent.timestamp,
        receivedEvent.offset);
  }

  void _handleDataSessionInboundClosedEvent(CallEvent event) {
    final closedEvent = event as DataSessionInboundClosedEvent;
    _dataSession.handleInboundClosed(closedEvent.streamId,
        PlanetKitDataSessionClosedReason.fromInt(closedEvent.closedReason));
  }

  void _handleDataSessionOutboundClosedEvent(CallEvent event) {
    final closedEvent = event as DataSessionOutboundClosedEvent;
    _dataSession.handleOutboundClosed(closedEvent.streamId,
        PlanetKitDataSessionClosedReason.fromInt(closedEvent.closedReason));
  }

  void _handleDataSessionOutboundTooLongQueuedDataEvent(CallEvent event) {
    final queuedEvent = event as DataSessionOutboundTooLongQueuedDataEvent;
    _dataSession.handleOutboundTooLongQueuedData(
        queuedEvent.streamId, queuedEvent.enabled);
  }

  void _handlePeerSharedContentsSetEvent(CallEvent event) {
    final setEvent = event as PeerSharedContentsSetEvent;
    _eventHandler?.onPeerSharedContentsSet?.call(this, setEvent.data,
        Duration(milliseconds: setEvent.elapsedMillis));
  }

  void _handlePeerExclusivelySharedContentsSetEvent(CallEvent event) {
    final setEvent = event as PeerExclusivelySharedContentsSetEvent;
    _eventHandler?.onPeerExclusivelySharedContentsSet?.call(this, setEvent.data,
        Duration(milliseconds: setEvent.elapsedMillis));
  }

  void _handleShortDataReceivedEvent(CallEvent event) {
    final shortDataEvent = event as ShortDataReceivedEvent;
    _eventHandler?.onShortDataReceived
        ?.call(this, shortDataEvent.dataType, shortDataEvent.data);
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
    isDataSessionSupported = connectedEvent.isDataSessionSupported;
    _eventHandler?.onConnected.call(
        this,
        connectedEvent.isInResponderPreparation,
        connectedEvent.shouldFinishPreparation);
  }

  void _handleDisconnectedEvent(CallEvent event) {
    final disconnectedEvent = event as DisconnectedEvent;
    _subscription?.cancel();
    _eventHandler?.onDisconnected(
        this,
        disconnectedEvent.disconnectReason,
        disconnectedEvent.disconnectSource,
        disconnectedEvent.userCode,
        disconnectedEvent.byRemote);
    _eventHandler = null;
    myMediaStatus.dispose();
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

  void _handlePeerAudioDescriptionUpdateEvent(CallEvent event) {
    final peerAudioDescriptionUpdateEvent =
        event as PeerAudioDescriptionUpdateEvent;
    _eventHandler?.onPeerAudioDescriptionUpdated
        ?.call(this, peerAudioDescriptionUpdateEvent.averageVolumeLevel);
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
