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

import '../../public/planet_kit_disconnect_reason.dart';
import '../../public/planet_kit_disconnect_source.dart';

enum BackgroundCallEventType {
  verified,
  disconnected,
  error,
  adopted,
}

abstract class BackgroundCallEvent {
  final String id;
  final BackgroundCallEventType subType;
  BackgroundCallEvent({required this.id, required this.subType});
}

class BackgroundCallVerifiedEvent extends BackgroundCallEvent {
  final bool peerUseResponderPreparation;
  BackgroundCallVerifiedEvent({
    required super.id,
    required this.peerUseResponderPreparation,
  }) : super(subType: BackgroundCallEventType.verified);
}

class BackgroundCallDisconnectedEvent extends BackgroundCallEvent {
  final PlanetKitDisconnectReason disconnectReason;
  final PlanetKitDisconnectSource disconnectSource;
  final String? userCode;
  final bool byRemote;
  BackgroundCallDisconnectedEvent({
    required super.id,
    required this.disconnectReason,
    required this.disconnectSource,
    required this.userCode,
    required this.byRemote,
  }) : super(subType: BackgroundCallEventType.disconnected);
}

class BackgroundCallErrorEvent extends BackgroundCallEvent {
  BackgroundCallErrorEvent({required super.id})
      : super(subType: BackgroundCallEventType.error);
}

class BackgroundCallAdoptedEvent extends BackgroundCallEvent {
  BackgroundCallAdoptedEvent({required super.id})
      : super(subType: BackgroundCallEventType.adopted);
}
