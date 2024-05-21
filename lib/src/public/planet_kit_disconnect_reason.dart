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

class PlanetKitDisconnectReasonConverter
    implements JsonConverter<PlanetKitDisconnectReason, int> {
  const PlanetKitDisconnectReasonConverter();

  @override
  PlanetKitDisconnectReason fromJson(int json) =>
      PlanetKitDisconnectReason.fromInt(json);

  @override
  int toJson(PlanetKitDisconnectReason object) => object.intValue;
}

enum PlanetKitDisconnectReason {
  normal,
  decline,
  cellCall,
  internalError,
  userError,
  internalKitError,
  micNoSource,
  cancel,
  busy,
  noAnswer,
  alreadyGotACall,
  multiDeviceInUse,
  multiDeviceAnswer,
  multiDeviceDecline,
  networkUnstable,
  pushError,
  authError,
  releasedCall,
  serverInternalError,
  unavailableNetwork,
  appDestroy,
  systemSleep,
  systemLogOff,
  mtuExceeded,
  appServerDataError,
  roomIsFull,
  aloneKickOut,
  roomNotFound,
  anotherInstanceTryToJoin,
  serviceAccessTokenError,
  serviceInvalidID,
  serviceMaintenance,
  serviceBusy,
  serviceInternalError,
  serviceHttpError,
  serviceHttpConnectionTimeOut,
  serviceHttpInvalidPeerCert,
  serviceHttpConnectFail,
  serviceHttpInvalidUrl,
  serviceIncompatiblePlanetKitVer,
  unknown;

  int get intValue {
    switch (this) {
      case PlanetKitDisconnectReason.normal:
        return 1001;
      case PlanetKitDisconnectReason.decline:
        return 1002;
      case PlanetKitDisconnectReason.cellCall:
        return 1003;
      case PlanetKitDisconnectReason.internalError:
        return 1109;
      case PlanetKitDisconnectReason.userError:
        return 1110;
      case PlanetKitDisconnectReason.internalKitError:
        return 1111;
      case PlanetKitDisconnectReason.micNoSource:
        return 1112;
      case PlanetKitDisconnectReason.cancel:
        return 1201;
      case PlanetKitDisconnectReason.busy:
        return 1202;
      case PlanetKitDisconnectReason.noAnswer:
        return 1203;
      case PlanetKitDisconnectReason.alreadyGotACall:
        return 1204;
      case PlanetKitDisconnectReason.multiDeviceInUse:
        return 1205;
      case PlanetKitDisconnectReason.multiDeviceAnswer:
        return 1206;
      case PlanetKitDisconnectReason.multiDeviceDecline:
        return 1207;
      case PlanetKitDisconnectReason.networkUnstable:
        return 1301;
      case PlanetKitDisconnectReason.pushError:
        return 1302;
      case PlanetKitDisconnectReason.authError:
        return 1303;
      case PlanetKitDisconnectReason.releasedCall:
        return 1304;
      case PlanetKitDisconnectReason.serverInternalError:
        return 1305;
      case PlanetKitDisconnectReason.unavailableNetwork:
        return 1308;
      case PlanetKitDisconnectReason.appDestroy:
        return 1309;
      case PlanetKitDisconnectReason.systemSleep:
        return 1310;
      case PlanetKitDisconnectReason.systemLogOff:
        return 1311;
      case PlanetKitDisconnectReason.mtuExceeded:
        return 1312;
      case PlanetKitDisconnectReason.appServerDataError:
        return 1313;
      case PlanetKitDisconnectReason.roomIsFull:
        return 1401;
      case PlanetKitDisconnectReason.aloneKickOut:
        return 1402;
      case PlanetKitDisconnectReason.roomNotFound:
        return 1404;
      case PlanetKitDisconnectReason.anotherInstanceTryToJoin:
        return 1405;
      case PlanetKitDisconnectReason.serviceAccessTokenError:
        return 1501;
      case PlanetKitDisconnectReason.serviceInvalidID:
        return 1502;
      case PlanetKitDisconnectReason.serviceMaintenance:
        return 1503;
      case PlanetKitDisconnectReason.serviceBusy:
        return 1504;
      case PlanetKitDisconnectReason.serviceInternalError:
        return 1505;
      case PlanetKitDisconnectReason.serviceHttpError:
        return 1506;
      case PlanetKitDisconnectReason.serviceHttpConnectionTimeOut:
        return 1507;
      case PlanetKitDisconnectReason.serviceHttpInvalidPeerCert:
        return 1508;
      case PlanetKitDisconnectReason.serviceHttpConnectFail:
        return 1509;
      case PlanetKitDisconnectReason.serviceHttpInvalidUrl:
        return 1510;
      case PlanetKitDisconnectReason.serviceIncompatiblePlanetKitVer:
        return 1511;
      case PlanetKitDisconnectReason.unknown:
      default:
        return -1;
    }
  }

  static PlanetKitDisconnectReason fromInt(int value) {
    switch (value) {
      case 1001:
        return PlanetKitDisconnectReason.normal;
      case 1002:
        return PlanetKitDisconnectReason.decline;
      case 1003:
        return PlanetKitDisconnectReason.cellCall;
      case 1109:
        return PlanetKitDisconnectReason.internalError;
      case 1110:
        return PlanetKitDisconnectReason.userError;
      case 1111:
        return PlanetKitDisconnectReason.internalKitError;
      case 1112:
        return PlanetKitDisconnectReason.micNoSource;
      case 1201:
        return PlanetKitDisconnectReason.cancel;
      case 1202:
        return PlanetKitDisconnectReason.busy;
      case 1203:
        return PlanetKitDisconnectReason.noAnswer;
      case 1204:
        return PlanetKitDisconnectReason.alreadyGotACall;
      case 1205:
        return PlanetKitDisconnectReason.multiDeviceInUse;
      case 1206:
        return PlanetKitDisconnectReason.multiDeviceAnswer;
      case 1207:
        return PlanetKitDisconnectReason.multiDeviceDecline;
      case 1301:
        return PlanetKitDisconnectReason.networkUnstable;
      case 1302:
        return PlanetKitDisconnectReason.pushError;
      case 1303:
        return PlanetKitDisconnectReason.authError;
      case 1304:
        return PlanetKitDisconnectReason.releasedCall;
      case 1305:
        return PlanetKitDisconnectReason.serverInternalError;
      case 1308:
        return PlanetKitDisconnectReason.unavailableNetwork;
      case 1309:
        return PlanetKitDisconnectReason.appDestroy;
      case 1310:
        return PlanetKitDisconnectReason.systemSleep;
      case 1311:
        return PlanetKitDisconnectReason.systemLogOff;
      case 1312:
        return PlanetKitDisconnectReason.mtuExceeded;
      case 1313:
        return PlanetKitDisconnectReason.appServerDataError;
      case 1401:
        return PlanetKitDisconnectReason.roomIsFull;
      case 1402:
        return PlanetKitDisconnectReason.aloneKickOut;
      case 1404:
        return PlanetKitDisconnectReason.roomNotFound;
      case 1405:
        return PlanetKitDisconnectReason.anotherInstanceTryToJoin;
      case 1501:
        return PlanetKitDisconnectReason.serviceAccessTokenError;
      case 1502:
        return PlanetKitDisconnectReason.serviceInvalidID;
      case 1503:
        return PlanetKitDisconnectReason.serviceMaintenance;
      case 1504:
        return PlanetKitDisconnectReason.serviceBusy;
      case 1505:
        return PlanetKitDisconnectReason.serviceInternalError;
      case 1506:
        return PlanetKitDisconnectReason.serviceHttpError;
      case 1507:
        return PlanetKitDisconnectReason.serviceHttpConnectionTimeOut;
      case 1508:
        return PlanetKitDisconnectReason.serviceHttpInvalidPeerCert;
      case 1509:
        return PlanetKitDisconnectReason.serviceHttpConnectFail;
      case 1510:
        return PlanetKitDisconnectReason.serviceHttpInvalidUrl;
      case 1511:
        return PlanetKitDisconnectReason.serviceIncompatiblePlanetKitVer;
      default:
        return PlanetKitDisconnectReason.unknown;
    }
  }
}
