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

import 'package:json_annotation/json_annotation.dart';

class PlanetKitDisconnectSourceConverter
    implements JsonConverter<PlanetKitDisconnectSource, int> {
  const PlanetKitDisconnectSourceConverter();

  @override
  PlanetKitDisconnectSource fromJson(int json) =>
      PlanetKitDisconnectSource.fromInt(json);

  @override
  int toJson(PlanetKitDisconnectSource object) => object.intValue;
}

enum PlanetKitDisconnectSource {
  undefined,
  callee,
  caller,
  participant,
  cloudServer,
  appServer,
  extension;

  int get intValue {
    switch (this) {
      case PlanetKitDisconnectSource.undefined:
        return 0;
      case PlanetKitDisconnectSource.callee:
        return 1;
      case PlanetKitDisconnectSource.caller:
        return 2;
      case PlanetKitDisconnectSource.participant:
        return 3;
      case PlanetKitDisconnectSource.cloudServer:
        return 4;
      case PlanetKitDisconnectSource.appServer:
        return 5;
      default:
        return 0;
    }
  }

  static PlanetKitDisconnectSource fromInt(int rawValue) {
    switch (rawValue) {
      case 0:
        return PlanetKitDisconnectSource.undefined;
      case 1:
        return PlanetKitDisconnectSource.callee;
      case 2:
        return PlanetKitDisconnectSource.caller;
      case 3:
        return PlanetKitDisconnectSource.participant;
      case 4:
        return PlanetKitDisconnectSource.cloudServer;
      case 5:
        return PlanetKitDisconnectSource.appServer;
      default:
        return PlanetKitDisconnectSource.undefined;
    }
  }
}
