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
import 'call/planet_kit_background_call.dart';
import 'call/planet_kit_verify_background_call_result.dart';
import '../internal/call/planet_kit_background_call_impl.dart'
    as internal_impl;
import 'my_media_status/planet_kit_my_media_status.dart';
import 'planet_kit_start_fail_reason.dart';
import 'planet_kit_init_param.dart';
import 'call/planet_kit_call.dart';
import 'call/planet_kit_verify_call_param.dart';
import 'call/planet_kit_verify_call_result.dart';
import 'call/planet_kit_make_call_result.dart';
import 'call/planet_kit_make_call_param.dart';
import 'conference/planet_kit_conference.dart';
import 'conference/planet_kit_conference_join_conference_result.dart';
import 'conference/planet_kit_join_conference_param.dart';

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
  Future<bool> initializePlanetKit(PlanetKitInitParam initParam) async {
    return await Platform.instance.initializePlanetKit(initParam);
  }

  /// Sets the server URL for the PlanetKit.
  ///
  /// Use it to change server URL set with `PlanetKitInitParam.serverUrl`
  ///
  Future<bool> setServerUrl(String serverURL) async {
    return await Platform.instance.setServerUrl(serverURL);
  }

  /// Makes a call with the specified parameters and event handler.
  Future<PlanetKitMakeCallResult> makeCall(PlanetKitMakeCallParam param,
      PlanetKitCallEventHandler eventHandler) async {
    var response = await Platform.instance.makeCall(param);

    PlanetKitCall? call;
    PlanetKitStartFailReason failReason = response.failReason;

    if (response.failReason == PlanetKitStartFailReason.none) {
      call = await _createPlanetKitCall(response.callId!, eventHandler);
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
      call = await _createPlanetKitCall(response.callId!, eventHandler);
    }

    final result = PlanetKitVerifyCallResult(call: call, reason: failReason);
    return result;
  }

  /// Verifies a call in a background isolate.
  ///
  /// Use this when you need to verify and monitor an incoming call outside the
  /// UI isolate (for example, in a background service or headless isolate).
  /// If successful, returns a [PlanetKitVerifyBackgroundCallResult] whose
  /// [PlanetKitVerifyBackgroundCallResult.call] contains a
  /// [PlanetKitBackgroundCall] handle that receives background events via the
  /// provided [eventHandler].
  ///
  /// To continue the call in the foreground, adopt it with
  /// [adoptBackgroundCall] by passing the `backgroundCallId` obtained from the
  /// returned [PlanetKitBackgroundCall].
  ///
  /// ```dart
  /// final result = await PlanetKitManager.instance.verifyBackgroundCall(
  ///   param,
  ///   PlanetKitBackgroundCallEventHandler(
  ///     onDisconnected: (bgCall, reason, source, userCode, byRemote) {
  ///       // Handle background disconnection
  ///     },
  ///   ),
  /// );
  /// if (result.reason == PlanetKitStartFailReason.none) {
  ///   final bgCall = result.call!;
  ///   // Later in UI isolate: adopt the call into a PlanetKitCall
  ///   // final call = await PlanetKitManager.instance
  ///   //     .adoptBackgroundCall(bgCall.backgroundCallId, uiEventHandler);
  /// }
  /// ```
  Future<PlanetKitVerifyBackgroundCallResult> verifyBackgroundCall(
      PlanetKitVerifyCallParam param,
      PlanetKitBackgroundCallEventHandler eventHandler) async {
    final response = await Platform.instance.verifyBackgroundCall(param);

    PlanetKitBackgroundCall? call;
    final PlanetKitStartFailReason failReason = response.failReason;

    if (response.failReason == PlanetKitStartFailReason.none && response.callId != null) {
      call = internal_impl.PlanetKitBackgroundCallImpl(
          backgroundCallId: response.callId!, eventHandler: eventHandler);
    }

    return PlanetKitVerifyBackgroundCallResult(call: call, reason: failReason);
  }
  
  /// Adopts a background-verified call into the foreground isolate.
  ///
  /// Pass the [backgroundCallId] retrieved from a successful
  /// [verifyBackgroundCall] result to obtain a fully featured [PlanetKitCall].
  /// Returns `null` if the native call is not found or media status mapping
  /// fails.
  ///
  /// Typical flow:
  /// 1) Call [verifyBackgroundCall] in background, store `backgroundCallId`.
  /// 2) In UI isolate, call [adoptBackgroundCall] and provide a
  ///    [PlanetKitCallEventHandler] to receive foreground call events.
  Future<PlanetKitCall?> adoptBackgroundCall(String backgroundCallId,
      PlanetKitCallEventHandler eventHandler) async {
    // Ask native layer to move background-verified call into active instances if present
    await Platform.instance.adoptBackgroundCall(backgroundCallId);
    return _createPlanetKitCall(backgroundCallId, eventHandler);
  }

  Future<PlanetKitCall?> _createPlanetKitCall(
      String callId, PlanetKitCallEventHandler eventHandler) async {
    final myMediaStatusId =
        await Platform.instance.callInterface.getMyMediaStatus(callId);

    if (myMediaStatusId == null) {
      print("#manager _createPlanetKitCall myMediaStatusId is null");
      return null;
    }
    final myMediaStatus =
        PlanetKitMyMediaStatus(myMediaStatusId: myMediaStatusId);

    final call = PlanetKitCall(
        callId: callId,
        eventHandler: eventHandler,
        myMediaStatus: myMediaStatus);
    print("#manager call instance created $call");
    return call;
  }

  /// Joins a conference with the specified parameters and event handler.
  ///
  /// Returns a [PlanetKitJoinConferenceResult] which contains the conference instance if successful,
  /// or the reason for failure if not.
  Future<PlanetKitJoinConferenceResult> joinConference(
      PlanetKitJoinConferenceParam param,
      PlanetKitConferenceEventHandler eventHandler) async {
    var response = await Platform.instance.joinConference(param);
    PlanetKitConference? conference;
    PlanetKitStartFailReason failReason = response.failReason;

    if (response.failReason == PlanetKitStartFailReason.none) {
      final myMediaStatusId = await Platform.instance.conferenceInterface
          .getMyMediaStatus(response.id!);

      if (myMediaStatusId == null) {
        print("#manager joinConference myMediaStatusId is null");
      } else {
        final myMediaStatus =
            PlanetKitMyMediaStatus(myMediaStatusId: myMediaStatusId);

        conference = PlanetKitConference(
            id: response.id!,
            eventHandler: eventHandler,
            myMediaStatus: myMediaStatus);
      }
    }
    final result = PlanetKitJoinConferenceResult(
        conference: conference, reason: failReason);
    return result;
  }
}
