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

import '../planet_kit_user_id.dart';

/// A stream ID that identifies a data session.
///
/// The application statically defines this value in the range [100, 999].
/// The same stream ID identifies both the outbound and inbound channels.
typedef PlanetKitDataSessionStreamId = int;

/// The transfer type of a data session.
enum PlanetKitDataSessionType {
  /// Reliable message: retransmitted on loss. One send is delivered as exactly
  /// one receive callback.
  ///
  /// The receive offset is still the session-cumulative byte position, exactly
  /// as for the byte types — it is 0 only for the first message on a session.
  reliableMessage,

  /// Reliable bytes: retransmitted on loss. Delivered as one or more receive
  /// callbacks, each carrying an offset within the inbound byte stream.
  reliableBytes,

  /// Unreliable bytes: not retransmitted. Delivered as one or more receive
  /// callbacks, each carrying an offset within the inbound byte stream.
  unreliableBytes,

  /// Unreliable message: not retransmitted. One send is delivered as exactly
  /// one receive callback.
  ///
  /// The receive offset is still the session-cumulative byte position, exactly
  /// as for the byte types — it is 0 only for the first message on a session.
  unreliableMessage;

  /// @nodoc
  int get intValue {
    switch (this) {
      case PlanetKitDataSessionType.reliableMessage:
        return 1;
      case PlanetKitDataSessionType.reliableBytes:
        return 2;
      case PlanetKitDataSessionType.unreliableBytes:
        return 3;
      case PlanetKitDataSessionType.unreliableMessage:
        return 4;
    }
  }

  /// @nodoc
  /// Returns null for the internal `unknown` (0) value, which is not exposed.
  static PlanetKitDataSessionType? fromInt(int value) {
    switch (value) {
      case 1:
        return PlanetKitDataSessionType.reliableMessage;
      case 2:
        return PlanetKitDataSessionType.reliableBytes;
      case 3:
        return PlanetKitDataSessionType.unreliableBytes;
      case 4:
        return PlanetKitDataSessionType.unreliableMessage;
      default:
        return null;
    }
  }
}

/// The reason a data session creation (make) call failed.
///
/// All reasons reported by the native SDK are exposed.
enum PlanetKitDataSessionFailReason {
  /// Success.
  none,

  /// An unexpected internal error occurred. (Defensive reason; the app does not
  /// trigger this directly.)
  internal,

  /// An inbound data session was requested without a preceding incoming event.
  /// Inbound sessions can only be created after an `onDataSessionIncoming`
  /// notification.
  notIncoming,

  /// A data session with the same stream ID already exists.
  /// Retrieve the existing instance with `getOutboundDataSession` /
  /// `getInboundDataSession`.
  alreadyExist,

  /// The stream ID is invalid. The valid range is [100, 999].
  invalidId,

  /// The data session type is invalid. (The public Dart `type` is a closed
  /// enum, so this is a native-consistency reason that is not produced on the
  /// normal path.)
  invalidType;

  /// @nodoc
  static PlanetKitDataSessionFailReason fromInt(int value) {
    switch (value) {
      case 0:
        return PlanetKitDataSessionFailReason.none;
      case 1:
        return PlanetKitDataSessionFailReason.internal;
      case 3:
        return PlanetKitDataSessionFailReason.notIncoming;
      case 4:
        return PlanetKitDataSessionFailReason.alreadyExist;
      case 5:
        return PlanetKitDataSessionFailReason.invalidId;
      case 6:
        return PlanetKitDataSessionFailReason.invalidType;
      default:
        return PlanetKitDataSessionFailReason.internal;
    }
  }
}

/// The reason a data session was closed.
enum PlanetKitDataSessionClosedReason {
  /// The session ended normally (for example, the call/conference ended).
  sessionEnd,

  /// The session was closed abnormally due to an internal error.
  internal,

  /// The peer does not support the stream ID (marked as unsupported).
  unsupported;

  /// @nodoc
  static PlanetKitDataSessionClosedReason fromInt(int value) {
    switch (value) {
      case 0:
        return PlanetKitDataSessionClosedReason.sessionEnd;
      case 1:
        return PlanetKitDataSessionClosedReason.internal;
      case 2:
        return PlanetKitDataSessionClosedReason.unsupported;
      default:
        return PlanetKitDataSessionClosedReason.internal;
    }
  }
}

/// An outbound data session used to send binary data to the peer(s).
class PlanetKitOutboundDataSession {
  /// The stream ID that identifies this data session.
  final PlanetKitDataSessionStreamId streamId;

  /// The transfer type of this data session.
  final PlanetKitDataSessionType type;

  final Future<bool> Function(Uint8List data, int timestamp) _send;
  final Future<bool> Function(PlanetKitUserId? target) _changeDestination;

  PlanetKitUserId? _target;

  /// @nodoc
  PlanetKitOutboundDataSession(
      {required this.streamId,
      required this.type,
      required Future<bool> Function(Uint8List data, int timestamp) send,
      required Future<bool> Function(PlanetKitUserId? target)
          changeDestination})
      : _send = send,
        _changeDestination = changeDestination;

  /// The current receiver target, or null when data is sent to all peers.
  ///
  /// Starts as null (all peers). Updated by a successful [changeDestination].
  PlanetKitUserId? get target => _target;

  /// Sends binary [data] over the data session and returns whether the send
  /// request was accepted.
  ///
  /// [timestamp] is an app-defined value forwarded to the receiver's
  /// `onReceive` callback unchanged. Its meaning is entirely up to the app.
  ///
  /// One way to use it, when several logical transfers share a session, is to
  /// set it to the transfer's absolute end position — the offset the transfer
  /// started at plus its payload size — so the receiver can derive the payload
  /// size as `timestamp - offset`. This release does not expose the session's
  /// cumulative send offset, so an app doing that has to track the offset
  /// itself, by summing the payload sizes of the sends that were accepted.
  Future<bool> send(Uint8List data, int timestamp) => _send(data, timestamp);

  /// Changes the receiver [target] to a specific peer, or to all peers when
  /// [target] is null, and returns whether the change was accepted.
  ///
  /// On success the current [target] is updated. This is meaningful for a
  /// conference.
  Future<bool> changeDestination(PlanetKitUserId? target) async {
    final changed = await _changeDestination(target);
    if (changed) {
      _target = target;
    }
    return changed;
  }
}

/// A handler for outbound data session events.
class PlanetKitOutboundDataSessionHandler {
  /// Called when the session is closed.
  final void Function(PlanetKitOutboundDataSession session,
      PlanetKitDataSessionClosedReason reason)? onClose;

  /// Called when the send back-pressure state is raised (`enabled == true`)
  /// or cleared (`enabled == false`).
  final void Function(PlanetKitOutboundDataSession session, bool enabled)?
      onTooLongQueuedData;

  /// Constructs a [PlanetKitOutboundDataSessionHandler].
  const PlanetKitOutboundDataSessionHandler(
      {this.onClose, this.onTooLongQueuedData});
}

/// An inbound data session used to receive binary data from the peer(s).
class PlanetKitInboundDataSession {
  /// The stream ID that identifies this data session.
  final PlanetKitDataSessionStreamId streamId;

  /// The transfer type of this data session.
  final PlanetKitDataSessionType type;

  /// @nodoc
  PlanetKitInboundDataSession({required this.streamId, required this.type});
}

/// A handler for inbound data session events.
class PlanetKitInboundDataSessionHandler {
  /// Called when the session is closed.
  final void Function(PlanetKitInboundDataSession session,
      PlanetKitDataSessionClosedReason reason)? onClose;

  /// Called when data is received.
  ///
  /// [offset] is the byte position of this data within the inbound stream. It
  /// is cumulative over the session's whole lifetime and is *not* reset between
  /// logical transfers, so it is 0 only for the first chunk received on a
  /// session. This holds for message types too, which differ from the byte
  /// types only in that one send arrives as exactly one callback.
  ///
  /// [timestamp] is the value the sender passed to
  /// [PlanetKitOutboundDataSession.send], forwarded unchanged. Its meaning is
  /// defined by the app on both ends: if the sender sets it to a transfer's
  /// absolute end position, for instance, the payload size on receive is
  /// `timestamp - offset`.
  final void Function(PlanetKitInboundDataSession session, PlanetKitUserId peerId,
      Uint8List data, int timestamp, int offset)? onReceive;

  /// Constructs a [PlanetKitInboundDataSessionHandler].
  const PlanetKitInboundDataSessionHandler({this.onClose, this.onReceive});
}

/// The result of creating an outbound data session.
///
/// On success, [dataSession] is non-null and [reason] is
/// [PlanetKitDataSessionFailReason.none].
class PlanetKitMakeOutboundDataSessionResult {
  /// The fail reason. [PlanetKitDataSessionFailReason.none] on success.
  final PlanetKitDataSessionFailReason reason;

  /// The created session, or null on failure.
  final PlanetKitOutboundDataSession? dataSession;

  /// @nodoc
  PlanetKitMakeOutboundDataSessionResult(
      {required this.reason, this.dataSession});
}

/// The result of creating an inbound data session.
///
/// On success, [dataSession] is non-null and [reason] is
/// [PlanetKitDataSessionFailReason.none].
class PlanetKitMakeInboundDataSessionResult {
  /// The fail reason. [PlanetKitDataSessionFailReason.none] on success.
  final PlanetKitDataSessionFailReason reason;

  /// The created session, or null on failure.
  final PlanetKitInboundDataSession? dataSession;

  /// @nodoc
  PlanetKitMakeInboundDataSessionResult(
      {required this.reason, this.dataSession});
}
