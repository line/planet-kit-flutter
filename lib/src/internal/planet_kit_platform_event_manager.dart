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

import 'dart:convert';

import 'package:flutter/services.dart';

import 'planet_kit_platform_event_types.dart';
import 'planet_kit_platform_event.dart';
import 'planet_kit_platform_interface.dart';

class EventManager implements EventManagerInterface {
  final EventChannel _eventChannel = const EventChannel('planetkit_event');
  final EventChannel _interceptedAudioStream =
      const EventChannel('planetkit_intercepted_audio');

  final Map<String, CallEventHandler> _callEventHandlers = {};
  final Map<String, InterceptedAudioHandler> _interceptedAudioHandlers = {};

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
    final eventData = EventData.fromJson(jsonMap);

    if (eventData.type == EventType.call) {
      if (_callEventHandlers.containsKey(eventData.id)) {
        _callEventHandlers[eventData.id]?.onCallEvent(eventData.id, jsonMap);
      }
    }
  }

  @override
  void addCallEventHandler(String id, CallEventHandler eventHandler) {
    _callEventHandlers[id] = eventHandler;
  }

  @override
  void removeCallEventHandler(String id) {
    _callEventHandlers.remove(id);
  }

  void _onInterceptedAudio(dynamic data) {
    final audioData = Map<String, dynamic>.from(data);
    final callId = audioData['callId'];

    if (_interceptedAudioHandlers.containsKey(callId)) {
      _interceptedAudioHandlers[callId]?.onInterceptedAudio(callId, audioData);
    }
  }

  void _onInterceptedAudioError(Object error) {
    print("Received error: ${error.toString()}");
  }

  @override
  void addInterceptedAudioHandler(String id, InterceptedAudioHandler handler) {
    _interceptedAudioHandlers[id] = handler;
  }

  @override
  void removeInterceptedAudioHandler(String id) {
    _interceptedAudioHandlers.remove(id);
  }
}
