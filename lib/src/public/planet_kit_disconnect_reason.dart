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

/// @nodoc
class PlanetKitDisconnectReasonConverter
    implements JsonConverter<PlanetKitDisconnectReason, int> {
  const PlanetKitDisconnectReasonConverter();

  @override
  PlanetKitDisconnectReason fromJson(int json) =>
      PlanetKitDisconnectReason.fromInt(json);

  @override
  int toJson(PlanetKitDisconnectReason object) => object.intValue;
}

/// Enumerates the reasons for a call being disconnected in the PlanetKit system.
enum PlanetKitDisconnectReason {
  /// (Both)(Caller, Callee, Participant) Disconnected the call without exceptions.
  normal,

  /// (Both)(Callee, CloudServer) 1:1 Call: Responder rejects a call.
  /// Conference: The previously joined conference is declined when entering the same conference room(e.g. Re-join after crash).
  decline,

  /// (Both)(Caller, Callee, Participant) Received cellular call during the Planet call.
  cellCall,

  /// (Both)(Caller, Callee, Participant, CloudServer) Disconnected by internal error.
  internalError,

  /// (Both)(Caller, Callee, AppServer) Application defined error. user_rel_code is accompanied.
  /// 1:1 call: user_rel_code is defined by the call peer.
  /// Group call: user_rel_code is defined by AppServer. For example) https://docs.lineplanet.me/api/server/server-api-kickout.
  userError,

  /// (Both)(Caller, Callee, Participant) Disconnected by OS specific error.
  internalKitError,

  /// (Both)(Caller, Callee, Participant) Audio source (i.e. mic) has not sent any audio data for a while.
  micNoSource,

  /// (1:1)(Caller) Initiator disconnects the call before the responder answers.
  cancel,

  /// (1:1)(Callee) Responder is calling.
  busy,

  /// (1:1)(Caller) Responder doesn't answer. Initiator waits for the answer for 60 seconds.
  noAnswer,

  /// (Both)(CloudServer) The initiator or the participant already has an incoming call but not received push yet.
  alreadyGotACall,

  /// (Both)(CloudServer) The same id pair (user-id and service-id) is calling in another device.
  multiDeviceInUse,

  /// (1:1)(CloudServer) Responder using the same id pair (user-id and service-id) answered the call in another device.
  multiDeviceAnswer,

  /// (1:1)(CloudServer) Responder using the same id pair(user-id and service-id) declined the call in another device.
  multiDeviceDecline,

  /// (Both)(CloudServer) Maximum call time has been reached.
  maxCallTimeExceeded,

  /// (Both)(Caller, Callee, Participant, CloudServer) Network is unavailable to keep a call.
  networkUnstable,

  /// (1:1)(CloudServer) LINE Planet GW failed to call Notify or notify_cb returned a failure. Please check AppServer or Notify url.
  pushError,

  /// (Both)(CloudServer) Authentication failure.
  authError,

  /// (Both)(CloudServer) The call was already released. Ex) Initiator already canceled.
  releasedCall,

  /// (Both)(CloudServer) Server disconnected a call because of internal error.
  serverInternalError,

  /// (Both)(Caller, Callee, Participant) Network is unavailable to keep a call.
  unavailableNetwork,

  /// (Both)(Caller, Callee, Participant) Application process is terminated.
  appDestroy,

  /// (Both)(Caller, Callee, Participant) Application is in sleep mode.
  systemSleep,

  /// (Both)(Caller, Callee, Participant) Application is in logoff.
  systemLogOff,

  /// (Both)(Caller, Callee, Participant) The call could not be connected because the MTU is exceeded.
  mtuExceeded,

  /// (Both)(CloudServer) Server failed to deliver app server data to AppServer.
  appServerDataError,

  /// (Both)(Caller, Callee, Participant) Desktop screen is locked
  desktopScreenLocked,

  /// (Group)(CloudServer) The number of participants in this room is full.
  roomIsFull,

  /// (Group)(CloudServer) Server kicks out a user when the user stays in a conference room alone for a long time.
  aloneKickOut,

  /// (Group)(CloudServer) The room is destroyed because all remaining participants leave before the other participant's join is complete.
  roomNotFound,

  /// (Group)(Participant) Disconnected by trying to join from another instance.
  anotherInstanceTryToJoin,

  /// (Both)(CloudServer) Invalid access token.
  serviceAccessTokenError,

  /// (Both)(CloudServer) Unacceptable character is used in service-id or user-id.
  /// Please refer to https://docs.lineplanet.me/overview/glossary#service-id.
  serviceInvalidID,

  /// (Both)(CloudServer) Under maintenance.
  serviceMaintenance,

  /// (Both)(CloudServer) LINE Planet GW is busy for now.
  serviceBusy,

  /// (Both)(CloudServer) LINE Planet GW internal error. Join failure in old version(<3.6) because the room has the SUBGROUP room attribute(Created by >= 3.6).
  serviceInternalError,

  /// (Both)(Caller, Participant) Could not make a HTTP request.
  /// Please check user network environment.
  /// 1. Firewall https://docs.lineplanet.me/help/troubleshooting/troubleshooting-firewall
  /// 2. Client vaccine program.
  serviceHttpError,

  /// (Both)(Caller, Participant) HTTP connection timed out.
  serviceHttpConnectionTimeOut,

  /// (Both)(Caller, Participant) SSL peer certificate or SSH remote key was not OK.
  serviceHttpInvalidPeerCert,

  /// (Both)(Caller, Participant) HTTP connection failed.
  serviceHttpConnectFail,

  /// (Both)(Caller, Participant) Wrong URL format or could not resolve host or proxy name.
  serviceHttpInvalidUrl,

  /// (Both)(CloudServer) The current PlanetKit version is deprecated. Need to upgrade.
  serviceIncompatiblePlanetKitVer,

  /// (Both)(CloudServer) Too many call connection attempts in a short period of time.
  serviceTooManyRequests,

  /// Represents an unknown or undefined disconnect reason.
  unknown;

  /// @nodoc
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
      case PlanetKitDisconnectReason.maxCallTimeExceeded:
        return 1208;
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
      case PlanetKitDisconnectReason.desktopScreenLocked:
        return 1314;
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
      case PlanetKitDisconnectReason.serviceTooManyRequests:
        return 1512;
      case PlanetKitDisconnectReason.unknown:
      default:
        return -1;
    }
  }

  /// @nodoc
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
      case 1208:
        return PlanetKitDisconnectReason.maxCallTimeExceeded;
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
      case 1314:
        return PlanetKitDisconnectReason.desktopScreenLocked;
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
      case 1512:
        return PlanetKitDisconnectReason.serviceTooManyRequests;
      default:
        return PlanetKitDisconnectReason.unknown;
    }
  }
}
