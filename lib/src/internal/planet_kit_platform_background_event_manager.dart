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
import 'dart:convert';

import 'package:flutter/services.dart';

import 'call/planet_kit_platform_call_event.dart';
import 'call/planet_kit_platform_call_event_type.dart';
import 'call/planet_kit_platform_background_call_event.dart';
import 'planet_kit_platform_event.dart';
import 'planet_kit_platform_event_types.dart';
import 'planet_kit_platform_interface.dart';

class BackgroundEventManager implements BackgroundEventManagerInterface {
  final EventChannel _backgroundEventChannel =
      const EventChannel('planetkit_background_event');
  late final StreamSubscription<dynamic> _backgroundEventSubscription;

  final StreamController<BackgroundCallEvent> _backgroundCallEventController =
      StreamController<BackgroundCallEvent>.broadcast();

  BackgroundEventManager() {
    _backgroundEventSubscription = _backgroundEventChannel
        .receiveBroadcastStream()
        .listen(_onBackgroundEvent, onError: _onBackgroundError);
  }

  void _onBackgroundEvent(dynamic data) {
    Map<String, dynamic> jsonMap = jsonDecode(data);
    final eventData = Event.fromJson(jsonMap);
    if (eventData.type == EventType.call) {
      final callEvent = CallEventFactory.fromJson(jsonMap);
      if (callEvent.subType == CallEventType.disconnected) {
        final e = callEvent as DisconnectedEvent;
        _backgroundCallEventController.add(
          BackgroundCallDisconnectedEvent(
            id: e.id,
            disconnectReason: e.disconnectReason,
            disconnectSource: e.disconnectSource,
            userCode: e.userCode,
            byRemote: e.byRemote,
          ),
        );
      } else if (callEvent.subType == CallEventType.verified) {
        final e = callEvent as VerifiedEvent;
        _backgroundCallEventController.add(
          BackgroundCallVerifiedEvent(
            id: e.id,
            peerUseResponderPreparation: e.peerUseResponderPreparation,
          ),
        );
      } else if (callEvent.subType == CallEventType.error) {
        _backgroundCallEventController.add(
          BackgroundCallErrorEvent(id: callEvent.id),
        );
      }
      else if (callEvent.subType == CallEventType.adoptBackgroundCall) {
        _backgroundCallEventController.add(BackgroundCallAdoptedEvent(id: callEvent.id));
      }
    }
  }

  void _onBackgroundError(Object error) {
    print("Received error: ${error.toString()}");
  }
  
  @override
  Stream<BackgroundCallEvent> get onCallEvent =>
      _backgroundCallEventController.stream;

  @override
  void dispose() {
    _backgroundEventSubscription.cancel();
    _backgroundCallEventController.close();
  }
}
