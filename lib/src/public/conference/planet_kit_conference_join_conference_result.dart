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

import 'planet_kit_conference.dart';
import '../planet_kit_start_fail_reason.dart';

/// A data model representing the result of an attempt to verify a call using PlanetKit.
///
/// This class encapsulates the result of a [PlanetKitManager.joinConference].
/// If [PlanetKitStartFailReason] reason is [PlanetKitStartFailReason.none], store the [PlanetKitConference] instance.
///
/// ```dart
/// final result = await PlanetKitManager.instance.joinConference(param, eventHandler);
/// if (result.reason == PlanetKitStartFailReason.none) {
///   print("verify call success")
///   _conference = result.conference
/// }
/// else {
///   print("join conference failed reason: $param.reason")
/// }
/// ```
///
class PlanetKitJoinConferenceResult {
  /// The [PlanetKitConference] instance representing the incoming call.
  ///
  /// This is `null` if the [PlanetKitManager.joinConference] fails.
  final PlanetKitConference? conference;

  /// The reason for the join failure.
  ///
  /// This is populated with a specific failure reason if the join cannot be completed.
  final PlanetKitStartFailReason reason;

  /// @nodoc
  PlanetKitJoinConferenceResult(
      {required this.conference, required this.reason});
}
