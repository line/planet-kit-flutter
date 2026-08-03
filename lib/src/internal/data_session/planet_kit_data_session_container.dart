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

import '../../public/data_session/planet_kit_data_session.dart';
import '../../public/planet_kit_user_id.dart';

/// @nodoc
typedef DataSessionMakeOutboundFn = Future<int> Function(int streamId, int type);

/// @nodoc
typedef DataSessionMakeInboundFn = Future<int> Function(int streamId);

/// @nodoc
typedef DataSessionUnsupportFn = Future<bool> Function(int streamId);

/// @nodoc
typedef DataSessionGetTypeFn = Future<int?> Function(int streamId);

/// @nodoc
typedef DataSessionSendFn = Future<bool> Function(
    int streamId, Uint8List data, int timestamp);

/// @nodoc
typedef DataSessionChangeDestinationFn = Future<bool> Function(
    int streamId, PlanetKitUserId? target);

class _OutboundEntry {
  final PlanetKitOutboundDataSession session;
  final PlanetKitOutboundDataSessionHandler handler;
  _OutboundEntry(this.session, this.handler);
}

class _InboundEntry {
  final PlanetKitInboundDataSession session;
  final PlanetKitInboundDataSessionHandler handler;
  _InboundEntry(this.session, this.handler);
}

/// Holds the active outbound/inbound data sessions for a single call or
/// conference and routes data session events to the matching session handler.
///
/// The container is platform-agnostic: the owner injects the six platform
/// operations as closures so that the same logic serves both call and
/// conference surfaces.
class PlanetKitDataSessionContainer {
  final DataSessionMakeOutboundFn _makeOutbound;
  final DataSessionMakeInboundFn _makeInbound;
  final DataSessionUnsupportFn _unsupport;
  final DataSessionGetTypeFn _getOutboundType;
  final DataSessionGetTypeFn _getInboundType;
  final DataSessionSendFn _send;
  final DataSessionChangeDestinationFn _changeDestination;

  final Map<int, _OutboundEntry> _outbound = {};
  final Map<int, _InboundEntry> _inbound = {};

  /// Types announced by incoming notifications, used to build inbound sessions
  /// (an inbound session can only be made after its incoming notification).
  final Map<int, PlanetKitDataSessionType> _incomingTypes = {};

  PlanetKitDataSessionContainer({
    required DataSessionMakeOutboundFn makeOutbound,
    required DataSessionMakeInboundFn makeInbound,
    required DataSessionUnsupportFn unsupport,
    required DataSessionGetTypeFn getOutboundType,
    required DataSessionGetTypeFn getInboundType,
    required DataSessionSendFn send,
    required DataSessionChangeDestinationFn changeDestination,
  })  : _makeOutbound = makeOutbound,
        _makeInbound = makeInbound,
        _unsupport = unsupport,
        _getOutboundType = getOutboundType,
        _getInboundType = getInboundType,
        _send = send,
        _changeDestination = changeDestination;

  Future<PlanetKitMakeOutboundDataSessionResult> makeOutbound(
      PlanetKitDataSessionStreamId streamId,
      PlanetKitDataSessionType type,
      PlanetKitOutboundDataSessionHandler handler) async {
    final reason =
        PlanetKitDataSessionFailReason.fromInt(await _makeOutbound(streamId, type.intValue));
    if (reason != PlanetKitDataSessionFailReason.none) {
      return PlanetKitMakeOutboundDataSessionResult(reason: reason);
    }

    final session = PlanetKitOutboundDataSession(
        streamId: streamId,
        type: type,
        send: (data, timestamp) => _send(streamId, data, timestamp),
        changeDestination: (target) => _changeDestination(streamId, target));
    _outbound[streamId] = _OutboundEntry(session, handler);
    return PlanetKitMakeOutboundDataSessionResult(
        reason: reason, dataSession: session);
  }

  Future<PlanetKitMakeInboundDataSessionResult> makeInbound(
      PlanetKitDataSessionStreamId streamId,
      PlanetKitInboundDataSessionHandler handler) async {
    final reason =
        PlanetKitDataSessionFailReason.fromInt(await _makeInbound(streamId));
    if (reason != PlanetKitDataSessionFailReason.none) {
      return PlanetKitMakeInboundDataSessionResult(reason: reason);
    }

    // The type is known from the incoming notification; fall back to native if
    // it is somehow missing.
    final type = _incomingTypes[streamId] ??
        PlanetKitDataSessionType.fromInt(await _getInboundType(streamId) ?? -1);
    if (type == null) {
      return PlanetKitMakeInboundDataSessionResult(
          reason: PlanetKitDataSessionFailReason.internal);
    }

    final session =
        PlanetKitInboundDataSession(streamId: streamId, type: type);
    _inbound[streamId] = _InboundEntry(session, handler);
    return PlanetKitMakeInboundDataSessionResult(
        reason: reason, dataSession: session);
  }

  Future<bool> unsupportInbound(PlanetKitDataSessionStreamId streamId) =>
      _unsupport(streamId);

  Future<PlanetKitOutboundDataSession?> getOutbound(
      PlanetKitDataSessionStreamId streamId) async {
    final existing = _outbound[streamId];
    if (existing != null) {
      return existing.session;
    }
    final type = PlanetKitDataSessionType.fromInt(
        await _getOutboundType(streamId) ?? -1);
    if (type == null) {
      return null;
    }
    // Do NOT cache a handler-less entry here: doing so would mask a later
    // makeOutbound() (which returns alreadyExist without replacing the entry),
    // leaving the app's real onClose/onTooLongQueuedData handler unwired. A
    // session retrieved via get simply has no handler attached.
    return PlanetKitOutboundDataSession(
        streamId: streamId,
        type: type,
        send: (data, timestamp) => _send(streamId, data, timestamp),
        changeDestination: (target) => _changeDestination(streamId, target));
  }

  Future<PlanetKitInboundDataSession?> getInbound(
      PlanetKitDataSessionStreamId streamId) async {
    final existing = _inbound[streamId];
    if (existing != null) {
      return existing.session;
    }
    final type = PlanetKitDataSessionType.fromInt(
        await _getInboundType(streamId) ?? -1);
    if (type == null) {
      return null;
    }
    // Do NOT cache a handler-less entry here (see getOutbound): it would mask a
    // later makeInbound() and drop the app's real onReceive/onClose handler.
    return PlanetKitInboundDataSession(streamId: streamId, type: type);
  }

  // ── Event routing ──────────────────────────────────────────────────────────

  /// Records the type announced by an incoming notification so that a
  /// subsequent inbound session can be built with the correct type.
  void recordIncoming(
      PlanetKitDataSessionStreamId streamId, PlanetKitDataSessionType type) {
    _incomingTypes[streamId] = type;
  }

  void handleInboundReceived(PlanetKitDataSessionStreamId streamId,
      PlanetKitUserId peerId, Uint8List data, int timestamp, int offset) {
    final entry = _inbound[streamId];
    if (entry == null) {
      return;
    }
    entry.handler.onReceive
        ?.call(entry.session, peerId, data, timestamp, offset);
  }

  void handleInboundClosed(PlanetKitDataSessionStreamId streamId,
      PlanetKitDataSessionClosedReason reason) {
    final entry = _inbound.remove(streamId);
    if (entry == null) {
      return;
    }
    entry.handler.onClose?.call(entry.session, reason);
  }

  void handleOutboundClosed(PlanetKitDataSessionStreamId streamId,
      PlanetKitDataSessionClosedReason reason) {
    final entry = _outbound.remove(streamId);
    if (entry == null) {
      return;
    }
    entry.handler.onClose?.call(entry.session, reason);
  }

  void handleOutboundTooLongQueuedData(
      PlanetKitDataSessionStreamId streamId, bool enabled) {
    final entry = _outbound[streamId];
    if (entry == null) {
      return;
    }
    entry.handler.onTooLongQueuedData?.call(entry.session, enabled);
  }
}
