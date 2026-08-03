// Copyright 2026 LINE Plus Corporation
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

import 'package:flutter/services.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_interface.dart';

// Generate mocks for all sub-interfaces.
// MockPlatform itself is hand-written below because it needs MockPlatformInterfaceMixin
// to bypass PlatformInterface.verifyToken when setting Platform.instance in tests.
@GenerateMocks([
  EventManagerInterface,
  BackgroundEventManagerInterface,
  CallInterface,
  ConferenceInterface,
  MyMediaStatusInterface,
  PeerControlInterface,
  EventChannel,
])
void main() {}

// ---------------------------------------------------------------------------
// Minimal fake implementations used ONLY as dummy `returnValue` parameters
// inside MockPlatform.noSuchMethod calls below. These are never actually
// invoked — they exist solely to satisfy Dart's non-nullable type system
// during mockito `when(...)` recording.
// ---------------------------------------------------------------------------
class _FakeEventManager extends Fake implements EventManagerInterface {}

class _FakeBackgroundEventManager extends Fake
    implements BackgroundEventManagerInterface {}

class _FakeCallInterface extends Fake implements CallInterface {}

class _FakeConferenceInterface extends Fake implements ConferenceInterface {}

class _FakePeerControlInterface extends Fake implements PeerControlInterface {}

/// A mock [Platform] that can be assigned to [Platform.instance] in tests.
///
/// Uses [MockPlatformInterfaceMixin] to bypass the token verification that
/// [PlatformInterface.verifyToken] performs — without it the setter would throw.
///
/// All concrete getters on [Platform] that delegate to `_instance` are
/// overridden here so they correctly route through mockito's [noSuchMethod]
/// dispatch, making `when(mockPlatform.eventManager).thenReturn(...)` work.
class MockPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements Platform {
  @override
  EventManagerInterface get eventManager => (super.noSuchMethod(
        Invocation.getter(#eventManager),
        returnValue: _FakeEventManager(),
        returnValueForMissingStub: _FakeEventManager(),
      )) as EventManagerInterface;

  @override
  BackgroundEventManagerInterface get backgroundEventManager =>
      (super.noSuchMethod(
        Invocation.getter(#backgroundEventManager),
        returnValue: _FakeBackgroundEventManager(),
        returnValueForMissingStub: _FakeBackgroundEventManager(),
      )) as BackgroundEventManagerInterface;

  @override
  CallInterface get callInterface => (super.noSuchMethod(
        Invocation.getter(#callInterface),
        returnValue: _FakeCallInterface(),
        returnValueForMissingStub: _FakeCallInterface(),
      )) as CallInterface;

  @override
  ConferenceInterface get conferenceInterface => (super.noSuchMethod(
        Invocation.getter(#conferenceInterface),
        returnValue: _FakeConferenceInterface(),
        returnValueForMissingStub: _FakeConferenceInterface(),
      )) as ConferenceInterface;

  @override
  PeerControlInterface get peerControlInterface => (super.noSuchMethod(
        Invocation.getter(#peerControlInterface),
        returnValue: _FakePeerControlInterface(),
        returnValueForMissingStub: _FakePeerControlInterface(),
      )) as PeerControlInterface;

  @override
  Future<bool> releaseInstance(String id) => (super.noSuchMethod(
        Invocation.method(#releaseInstance, [id]),
        returnValue: Future.value(true),
        returnValueForMissingStub: Future.value(true),
      )) as Future<bool>;
}
