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

import '../planet_kit_disconnect_reason.dart';
import '../planet_kit_disconnect_source.dart';

/// A handler for background call lifecycle events.
///
/// Used with [PlanetKitManager.verifyBackgroundCall] to receive events while a
/// call is running in a background isolate (for example, a service or headless
/// handler). Currently supports the disconnection event of the background-
/// verified call.
class PlanetKitBackgroundCallEventHandler {
    /// Callback triggered when the background-verified call is disconnected.
    ///
    /// Provides the disconnect [reason], [source], an optional [userCode], and
    /// whether the disconnection was initiated [byRemote]. The [call] instance
    /// represents the background call mapping, not a foreground [PlanetKitCall].
    final void Function(
        PlanetKitBackgroundCall call,
        PlanetKitDisconnectReason reason,
        PlanetKitDisconnectSource source,
        String? userCode,
        bool byRemote) onDisconnected;

    /// Callback triggered when the background call is verified.
    final void Function(PlanetKitBackgroundCall call, bool peerUseResponderPreparation) onVerified;

    /// Callback triggered when the background call encounters an error.
    final void Function(PlanetKitBackgroundCall call) onError;

    /// Callback triggered when the background call is adopted.
    /// The background call will no longer receive events.
    final void Function(PlanetKitBackgroundCall call) onBackgroundCallAdopted;

    const PlanetKitBackgroundCallEventHandler({required this.onDisconnected, required this.onVerified, required this.onError, required this.onBackgroundCallAdopted});
}

/// Represents a handle to a call verified in a background isolate.
///
/// This handle does not expose media/control APIs. To take over the call in the
/// foreground isolate, pass [backgroundCallId] to
/// [PlanetKitManager.adoptBackgroundCall] to obtain a [PlanetKitCall].
class PlanetKitBackgroundCall {
    /// Unique identifier for the background-verified call mapping.
    final String backgroundCallId;
    /// The event handler used to receive background lifecycle events.
    final PlanetKitBackgroundCallEventHandler eventHandler;
    
    PlanetKitBackgroundCall({required this.backgroundCallId, required this.eventHandler});
}