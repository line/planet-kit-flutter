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

import '../internal/planet_kit_platform_interface.dart';

import 'planet_kit_start_fail_reason.dart';
import 'planet_kit_init_param.dart';
import 'call/planet_kit_call.dart';
import 'call/planet_kit_verify_call_param.dart';
import 'call/planet_kit_verify_call_result.dart';
import 'call/planet_kit_make_call_result.dart';
import 'call/planet_kit_make_call_param.dart';

/// Manager providing methods to initialize the system, make calls, and verify calls.
///
class PlanetKitManager {
  PlanetKitManager._privateConstructor();

  /// The singleton instance of [PlanetKitManager].
  static final PlanetKitManager instance =
      PlanetKitManager._privateConstructor();

  /// Retrieves the platform version.
  Future<String?> getPlatformVersion() {
    return Platform.instance.getPlatformVersion();
  }

  /// Initializes the PlanetKit with the given initialization parameters.
  ///
  /// PlanetKit user must call this method before using PlanetKit features.
  ///
  Future<bool> initializePlanetKit(PlanetKitInitParam initParam) {
    return Platform.instance.initializePlanetKit(initParam);
  }

  /// Makes a call with the specified parameters and event handler.
  Future<PlanetKitMakeCallResult> makeCall(PlanetKitMakeCallParam param,
      PlanetKitCallEventHandler eventHandler) async {
    var response = await Platform.instance.makeCall(param);

    PlanetKitCall? call;
    PlanetKitStartFailReason failReason = response.failReason;

    if (response.failReason == PlanetKitStartFailReason.none) {
      call =
          PlanetKitCall(callId: response.callId!, eventHandler: eventHandler);
    }

    final result = PlanetKitMakeCallResult(call: call, reason: failReason);

    return result;
  }

  /// Verifies a call with the specified parameters and event handler.
  Future<PlanetKitVerifyCallResult> verifyCall(PlanetKitVerifyCallParam param,
      PlanetKitCallEventHandler eventHandler) async {
    var response = await Platform.instance.verifyCall(param);

    PlanetKitCall? call;
    PlanetKitStartFailReason failReason = response.failReason;

    if (response.failReason == PlanetKitStartFailReason.none) {
      call =
          PlanetKitCall(callId: response.callId!, eventHandler: eventHandler);
    }

    final result = PlanetKitVerifyCallResult(call: call, reason: failReason);
    return result;
  }
}
