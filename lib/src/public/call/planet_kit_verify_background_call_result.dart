// Copyright 2025 LINE Plus Corporation
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

import 'planet_kit_background_call.dart';
import '../planet_kit_start_fail_reason.dart';

/// A data model representing the result of verifying a call in a background
/// isolate.
///
/// Returned by [PlanetKitManager.verifyBackgroundCall]. When
/// [reason] is [PlanetKitStartFailReason.none], [call] contains a
/// [PlanetKitBackgroundCall] handle that can receive events and later be
/// adopted by the foreground isolate via
/// [PlanetKitManager.adoptBackgroundCall].
///
/// ```dart
/// final result = await PlanetKitManager.instance
///     .verifyBackgroundCall(param, PlanetKitBackgroundCallEventHandler(
///       onDisconnected: (bgCall, reason, source, userCode, byRemote) {
///         // handle background disconnection
///       },
///     ));
/// if (result.reason == PlanetKitStartFailReason.none) {
///   final bgCall = result.call!;
///   // later in UI isolate: adopt the background call
///   // final call = await PlanetKitManager.instance
///   //     .adoptBackgroundCall(bgCall.backgroundCallId, uiEventHandler);
/// }
/// ```
class PlanetKitVerifyBackgroundCallResult {
  /// The [PlanetKitBackgroundCall] instance representing the background call mapping.
  /// This is `null` if the background call verification fails.
  final PlanetKitBackgroundCall? call;

  /// The reason for the verification failure.
  final PlanetKitStartFailReason reason;

  /// @nodoc
  const PlanetKitVerifyBackgroundCallResult({required this.call, required this.reason});
}