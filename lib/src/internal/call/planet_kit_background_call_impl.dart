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

import 'dart:async';

import '../../public/call/planet_kit_background_call.dart';
import '../../internal/planet_kit_platform_interface.dart';
import 'planet_kit_platform_background_call_event.dart';

class PlanetKitBackgroundCallImpl implements PlanetKitBackgroundCall {
  final String backgroundCallId;
  final PlanetKitBackgroundCallEventHandler eventHandler;
  StreamSubscription<BackgroundCallEvent>? _subscription;

  PlanetKitBackgroundCallImpl(
      {required this.backgroundCallId, required this.eventHandler}) {
    _subscription = Platform.instance.backgroundEventManager.onCallEvent
        .listen(_onCallEvent);
  }

  void _onCallEvent(BackgroundCallEvent event) {
    if (event.id != backgroundCallId) {
      print("#flutter_kit_background_call event not for current instance");
      return;
    }
    if (event is BackgroundCallDisconnectedEvent) {
      print("#flutter_kit_background_call onDisconnected ${event.id}");
      _subscription?.cancel();
      eventHandler.onDisconnected(this, event.disconnectReason,
          event.disconnectSource, event.userCode, event.byRemote);
    } else if (event is BackgroundCallVerifiedEvent) {
      print("#flutter_kit_background_call onVerified ${event.id}");

      eventHandler.onVerified(this, event.peerUseResponderPreparation);
    } else if (event is BackgroundCallErrorEvent) {
      print("#flutter_kit_background_call onError ${event.id}");
      _subscription?.cancel();
      eventHandler.onError(this);
    } else if (event is BackgroundCallAdoptedEvent) {
      print("#flutter_kit_background_call onBackgroundCallAdopted ${event.id}");
      _subscription?.cancel();
      eventHandler.onBackgroundCallAdopted(this);
    }
  }
}
