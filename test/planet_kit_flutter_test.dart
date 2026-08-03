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

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:planet_kit_flutter/src/public/planet_kit_manager.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_platform_interface.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_method_channel.dart';

// `extends Mock` lets noSuchMethod satisfy the full [Platform] surface
// (call/conference/etc. live on sub-interfaces), while
// MockPlatformInterfaceMixin bypasses PlatformInterface.verifyToken so the
// fake can be assigned to Platform.instance in tests. Only the members
// exercised below need explicit overrides.
class MockPlanetKitFlutterPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements Platform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final Platform initialPlatform = Platform.instance;

  test('$MethodChannelPlanetKit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPlanetKit>());
  });

  test('getPlatformVersion', () async {
    PlanetKitManager planetKitFlutterPlugin = PlanetKitManager.instance;
    MockPlanetKitFlutterPlatform fakePlatform = MockPlanetKitFlutterPlatform();
    Platform.instance = fakePlatform;

    expect(await planetKitFlutterPlugin.getPlatformVersion(), '42');
  });
}
