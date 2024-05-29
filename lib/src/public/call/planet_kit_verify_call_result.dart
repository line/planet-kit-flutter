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

import 'planet_kit_call.dart';
import '../planet_kit_start_fail_reason.dart';

/// A data model representing the result of an attempt to verify a call using PlanetKit.
///
/// This class encapsulates the result of a [PlanetKitManager.verifyCall].
/// If [PlanetKitStartFailReason] reason is [PlanetKitStartFailReason.none], store the [PlanetKitCall] instance.
///
/// ```dart
/// final result = await PlanetKitManager.instance.verifyCall(param, eventHandler);
/// if (result.reason == PlanetKitStartFailReason.none) {
///   print("verify call success")
///   _call = result.call
/// }
/// else {
///   print("verify call failed reason: $param.reason")
/// }
/// ```
///
class PlanetKitVerifyCallResult {
  /// The [PlanetKitCall] instance representing the incoming call.
  ///
  /// This is `null` if the [PlanetKitManager.verifyCall] fails.
  final PlanetKitCall? call;

  /// The reason for the verification failure.
  ///
  /// This is populated with a specific failure reason if the verification cannot be completed.
  final PlanetKitStartFailReason reason;

  /// @nodoc
  PlanetKitVerifyCallResult({required this.call, required this.reason});
}
