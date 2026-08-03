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
import 'package:planet_kit_flutter/src/public/call/planet_kit_make_call_param.dart';
import 'package:planet_kit_flutter/src/public/conference/planet_kit_join_conference_param.dart';

void main() {
  group('appServerData param serialization', () {
    test('MakeCallParam carries appServerData when set', () {
      final param = PlanetKitMakeCallParamBuilder()
          .setMyUserId('myUser')
          .setMyServiceId('myService')
          .setPeerUserId('peerUser')
          .setPeerServiceId('peerService')
          .setAccessToken('token')
          .setAppServerData('hello-server')
          .build();

      expect(param.appServerData, 'hello-server');
      expect(param.toJson()['appServerData'], 'hello-server');
    });

    test('MakeCallParam appServerData is null when not set', () {
      final param = PlanetKitMakeCallParamBuilder()
          .setMyUserId('myUser')
          .setMyServiceId('myService')
          .setPeerUserId('peerUser')
          .setPeerServiceId('peerService')
          .setAccessToken('token')
          .build();

      expect(param.appServerData, isNull);
      expect(param.toJson()['appServerData'], isNull);
    });

    test('MakeCallParam empty appServerData is treated as unset (null)', () {
      final param = PlanetKitMakeCallParamBuilder()
          .setMyUserId('myUser')
          .setMyServiceId('myService')
          .setPeerUserId('peerUser')
          .setPeerServiceId('peerService')
          .setAccessToken('token')
          .setAppServerData('')
          .build();

      expect(param.appServerData, isNull);
      expect(param.toJson()['appServerData'], isNull);
    });

    test('JoinConferenceParam carries appServerData when set', () {
      final param = PlanetKitJoinConferenceParamBuilder()
          .setMyUserId('myUser')
          .setMyServiceId('myService')
          .setRoomId('room1')
          .setRoomServiceId('roomService')
          .setAccessToken('token')
          .setAppServerData('hello-server')
          .build();

      expect(param.appServerData, 'hello-server');
      expect(param.toJson()['appServerData'], 'hello-server');
    });

    test('JoinConferenceParam appServerData is null when not set', () {
      final param = PlanetKitJoinConferenceParamBuilder()
          .setMyUserId('myUser')
          .setMyServiceId('myService')
          .setRoomId('room1')
          .setRoomServiceId('roomService')
          .setAccessToken('token')
          .build();

      expect(param.appServerData, isNull);
      expect(param.toJson()['appServerData'], isNull);
    });

    test('JoinConferenceParam empty appServerData is treated as unset (null)',
        () {
      final param = PlanetKitJoinConferenceParamBuilder()
          .setMyUserId('myUser')
          .setMyServiceId('myService')
          .setRoomId('room1')
          .setRoomServiceId('roomService')
          .setAccessToken('token')
          .setAppServerData('')
          .build();

      expect(param.appServerData, isNull);
      expect(param.toJson()['appServerData'], isNull);
    });
  });
}
