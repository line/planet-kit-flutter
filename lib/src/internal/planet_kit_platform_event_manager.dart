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

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:planet_kit_flutter/src/internal/camera/planet_kit_platform_camera_event.dart';
import 'package:planet_kit_flutter/src/internal/peer_control/planet_kit_platform_peer_control_event.dart';
import 'conference/planet_kit_platform_conference_event.dart';
import 'call/planet_kit_platform_call_event.dart';
import 'my_media_status/planet_kit_platform_my_media_status_event.dart';
import 'planet_kit_platform_event_types.dart';
import 'planet_kit_platform_event.dart';
import 'planet_kit_platform_interface.dart';

class EventManager implements EventManagerInterface {
  final EventChannel _eventChannel = const EventChannel('planetkit_event');
  final EventChannel _interceptedAudioStream =
      const EventChannel('planetkit_hooked_audio');

  final Map<String, HookedAudioHandler> _interceptedAudioHandlers = {};

  void initializeEventChannel() {
    print("#flutter_method_channel setEventChannel");
    _eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
    _interceptedAudioStream
        .receiveBroadcastStream()
        .listen(_onInterceptedAudio, onError: _onInterceptedAudioError);
  }

  void _onError(Object error) {
    print("Received error: ${error.toString()}");
  }

  void _onEvent(dynamic data) {
    Map<String, dynamic> jsonMap = jsonDecode(data);
    final eventData = Event.fromJson(jsonMap);

    if (eventData.type == EventType.call) {
      final callEvent = CallEventFactory.fromJson(jsonMap);
      _callEventController.add(callEvent);
    } else if (eventData.type == EventType.myMediaStatus) {
      final eventData = MyMediaStatusEventFactory.fromJson(jsonMap);
      _myMediaStatusEventController.add(eventData);
    } else if (eventData.type == EventType.conference) {
      final eventData = ConferenceEventFactory.fromJson(jsonMap);
      _conferenceEventController.add(eventData);
    } else if (eventData.type == EventType.peerControl) {
      final eventData = PeerControlEventFactory.fromJson(jsonMap);
      _peerControlEventController.add(eventData);
    } else if (eventData.type == EventType.camera) {
      final eventData = CameraEventFactory.fromJson(jsonMap);
      _cameraEventController.add(eventData);
    }
  }

  void _onInterceptedAudio(dynamic data) {
    final audioData = Map<String, dynamic>.from(data);
    final callId = audioData['callId'];

    if (_interceptedAudioHandlers.containsKey(callId)) {
      _interceptedAudioHandlers[callId]?.onHookedAudio(callId, audioData);
    }
  }

  void _onInterceptedAudioError(Object error) {
    print("Received error: ${error.toString()}");
  }

  @override
  void addHookedAudioHandler(String id, HookedAudioHandler handler) {
    _interceptedAudioHandlers[id] = handler;
  }

  @override
  void removeHookedAudioHandler(String id) {
    _interceptedAudioHandlers.remove(id);
  }

  @override
  Stream<CallEvent> get onCallEvent => _callEventController.stream;
  final StreamController<CallEvent> _callEventController =
      StreamController<CallEvent>.broadcast();

  @override
  void dispose() {
    _callEventController.close();
    _myMediaStatusEventController.close();
    _conferenceEventController.close();
    _peerControlEventController.close();
  }

  @override
  Stream<MyMediaStatusEvent> get onMyMediaStatusEvent =>
      _myMediaStatusEventController.stream;
  final StreamController<MyMediaStatusEvent> _myMediaStatusEventController =
      StreamController<MyMediaStatusEvent>.broadcast();

  @override
  Stream<ConferenceEvent> get onConferenceEvent =>
      _conferenceEventController.stream;
  final StreamController<ConferenceEvent> _conferenceEventController =
      StreamController<ConferenceEvent>.broadcast();

  @override
  Stream<PeerControlEvent> get onPeerControlEvent =>
      _peerControlEventController.stream;
  final StreamController<PeerControlEvent> _peerControlEventController =
      StreamController<PeerControlEvent>.broadcast();

  @override
  Stream<CameraEvent> get onCameraEvent => _cameraEventController.stream;
  final StreamController<CameraEvent> _cameraEventController =
      StreamController<CameraEvent>.broadcast();
}
