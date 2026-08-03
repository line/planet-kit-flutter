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

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planet_kit_flutter/planet_kit_flutter.dart';
import 'package:planet_kit_flutter/src/internal/planet_kit_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlanetKitVersionInfo.fromJson', () {
    test('parses all fields', () {
      final info = PlanetKitVersionInfo.fromJson({
        'sdkVersion': '5.5.2',
        'pluginVersion': '1.1.0',
        'userAgent': 'PlanetKit/5.5.2 (flutter 1.1.0)',
      });
      expect(info.sdkVersion, '5.5.2');
      expect(info.pluginVersion, '1.1.0');
      expect(info.userAgent, 'PlanetKit/5.5.2 (flutter 1.1.0)');
    });

    test('userAgent is null when absent', () {
      final info = PlanetKitVersionInfo.fromJson({
        'sdkVersion': '5.5.2',
        'pluginVersion': '1.1.0',
      });
      expect(info.userAgent, isNull);
    });

    test('userAgent is null when empty (not yet initialized)', () {
      final info = PlanetKitVersionInfo.fromJson({
        'sdkVersion': '5.5.2',
        'pluginVersion': '1.1.0',
        'userAgent': '',
      });
      expect(info.userAgent, isNull);
    });

    test('missing version fields default to empty string', () {
      final info = PlanetKitVersionInfo.fromJson({});
      expect(info.sdkVersion, '');
      expect(info.pluginVersion, '');
      expect(info.userAgent, isNull);
    });
  });

  group('MethodChannelPlanetKit.getVersionInfo', () {
    final MethodChannelPlanetKit platform = MethodChannelPlanetKit();
    const MethodChannel channel = MethodChannel('planetkit_sdk');
    String? response;
    String? lastInvokedMethod;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          lastInvokedMethod = methodCall.method;
          return response;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('invokes getPlanetKitVersionInfo and parses the JSON payload',
        () async {
      response =
          '{"sdkVersion":"5.5.2","pluginVersion":"1.1.0","userAgent":"ua-string"}';
      final info = await platform.getVersionInfo();
      expect(lastInvokedMethod, 'getPlanetKitVersionInfo');
      expect(info, isNotNull);
      expect(info!.sdkVersion, '5.5.2');
      expect(info.pluginVersion, '1.1.0');
      expect(info.userAgent, 'ua-string');
    });

    test('returns null when the platform returns null', () async {
      response = null;
      final info = await platform.getVersionInfo();
      expect(info, isNull);
    });
  });
}
