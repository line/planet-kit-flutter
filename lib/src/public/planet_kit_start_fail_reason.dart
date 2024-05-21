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

class PlanetKitStartFailReasonConverter
    implements JsonConverter<PlanetKitStartFailReason, int> {
  const PlanetKitStartFailReasonConverter();

  @override
  PlanetKitStartFailReason fromJson(int json) =>
      PlanetKitStartFailReason.fromInt(json);

  @override
  int toJson(PlanetKitStartFailReason object) => object.intValue;
}

enum PlanetKitStartFailReason {
  none,
  invalidParam,
  alreadyExist,
  decodeCallParam,
  memoryError,
  idConflict,
  reuse,
  invalidUserId,
  invalidServiceId,
  invalidAPIKey,
  invalidRoomId,
  tooLongAppServerData,
  notInitialized,

  // apple
  kitUnknownMediaType,
  kitInvalidRoomId,
  kitInvalidPeerId,
  kitInvalidPushMessage,
  kitNoMetalDevice,
  kitInvalidAuthentication,
  kitInternalInitializationError,

  // android
  kitNoPermissionRecordAudio,
  kitCallInitDataInvalidSize,
  kitMyUserIdBlank,
  kitMyServiceIdBlank,
  kitPeerUserIdBlank,
  kitPeerServiceIdBlank,
  kitInvalidStateToMakeCall,
  kitCannotCreateNewSession,
  kitInvalidStateToJoinConference,
  kitRoomIdBlank,
  kitRoomServiceIdBlank,
  kitNoPermissionReadPhoneState,
  kitInternalUnknownExceptionAtVerifyCall,
  kitInternalJNIEnv,
  kitInternalJNIHandleNullptr,
  kitInternalJNIObjNullptr,
  kitInternalJNIClassNullptr,
  kitInternalUndefined;

  int get intValue {
    switch (this) {
      case PlanetKitStartFailReason.none:
        return 0;
      case PlanetKitStartFailReason.invalidParam:
        return 1;
      case PlanetKitStartFailReason.alreadyExist:
        return 2;
      case PlanetKitStartFailReason.decodeCallParam:
        return 3;
      case PlanetKitStartFailReason.memoryError:
        return 4;
      case PlanetKitStartFailReason.idConflict:
        return 5;
      case PlanetKitStartFailReason.reuse:
        return 6;
      case PlanetKitStartFailReason.invalidUserId:
        return 7;
      case PlanetKitStartFailReason.invalidServiceId:
        return 8;
      case PlanetKitStartFailReason.invalidAPIKey:
        return 9;
      case PlanetKitStartFailReason.invalidRoomId:
        return 10;
      case PlanetKitStartFailReason.tooLongAppServerData:
        return 11;
      case PlanetKitStartFailReason.notInitialized:
        return 12;

      // apple
      case PlanetKitStartFailReason.kitUnknownMediaType:
        return 2001;
      case PlanetKitStartFailReason.kitInvalidRoomId:
        return 2002;
      case PlanetKitStartFailReason.kitInvalidPeerId:
        return 2003;
      case PlanetKitStartFailReason.kitInvalidPushMessage:
        return 2004;
      case PlanetKitStartFailReason.kitNoMetalDevice:
        return 2005;
      case PlanetKitStartFailReason.kitInvalidAuthentication:
        return 2006;
      case PlanetKitStartFailReason.kitInternalInitializationError:
        return 2999;

      // android
      case PlanetKitStartFailReason.kitNoPermissionRecordAudio:
        return 3013;
      case PlanetKitStartFailReason.kitCallInitDataInvalidSize:
        return 3014;
      case PlanetKitStartFailReason.kitMyUserIdBlank:
        return 3015;
      case PlanetKitStartFailReason.kitMyServiceIdBlank:
        return 3016;
      case PlanetKitStartFailReason.kitPeerUserIdBlank:
        return 3017;
      case PlanetKitStartFailReason.kitPeerServiceIdBlank:
        return 3018;
      case PlanetKitStartFailReason.kitInvalidStateToMakeCall:
        return 3019;
      case PlanetKitStartFailReason.kitCannotCreateNewSession:
        return 3020;
      case PlanetKitStartFailReason.kitInvalidStateToJoinConference:
        return 3021;
      case PlanetKitStartFailReason.kitRoomIdBlank:
        return 3022;
      case PlanetKitStartFailReason.kitRoomServiceIdBlank:
        return 3023;
      case PlanetKitStartFailReason.kitNoPermissionReadPhoneState:
        return 3024;
      case PlanetKitStartFailReason.kitInternalUnknownExceptionAtVerifyCall:
        return 3025;
      case PlanetKitStartFailReason.kitInternalJNIEnv:
        return 3026;
      case PlanetKitStartFailReason.kitInternalJNIHandleNullptr:
        return 3027;
      case PlanetKitStartFailReason.kitInternalJNIObjNullptr:
        return 3028;
      case PlanetKitStartFailReason.kitInternalJNIClassNullptr:
        return 3029;
      case PlanetKitStartFailReason.kitInternalUndefined:
        return 3030;
      default:
        return -1;
    }
  }

  static PlanetKitStartFailReason fromInt(int value) {
    switch (value) {
      case 0:
        return PlanetKitStartFailReason.none;
      case 1:
        return PlanetKitStartFailReason.invalidParam;
      case 2:
        return PlanetKitStartFailReason.alreadyExist;
      case 3:
        return PlanetKitStartFailReason.decodeCallParam;
      case 4:
        return PlanetKitStartFailReason.memoryError;
      case 5:
        return PlanetKitStartFailReason.idConflict;
      case 6:
        return PlanetKitStartFailReason.reuse;
      case 7:
        return PlanetKitStartFailReason.invalidUserId;
      case 8:
        return PlanetKitStartFailReason.invalidServiceId;
      case 9:
        return PlanetKitStartFailReason.invalidAPIKey;
      case 10:
        return PlanetKitStartFailReason.invalidRoomId;
      case 11:
        return PlanetKitStartFailReason.tooLongAppServerData;
      case 12:
        return PlanetKitStartFailReason.notInitialized;
      //apple
      case 2001:
        return PlanetKitStartFailReason.kitUnknownMediaType;
      case 2002:
        return PlanetKitStartFailReason.kitInvalidRoomId;
      case 2003:
        return PlanetKitStartFailReason.kitInvalidPeerId;
      case 2004:
        return PlanetKitStartFailReason.kitInvalidPushMessage;
      case 2005:
        return PlanetKitStartFailReason.kitNoMetalDevice;
      case 2006:
        return PlanetKitStartFailReason.kitInvalidAuthentication;
      case 2999:
        return PlanetKitStartFailReason.kitInternalInitializationError;
      // android
      case 3013:
        return PlanetKitStartFailReason.kitNoPermissionRecordAudio;
      case 3014:
        return PlanetKitStartFailReason.kitCallInitDataInvalidSize;
      case 3015:
        return PlanetKitStartFailReason.kitMyUserIdBlank;
      case 3016:
        return PlanetKitStartFailReason.kitMyServiceIdBlank;
      case 3017:
        return PlanetKitStartFailReason.kitPeerUserIdBlank;
      case 3018:
        return PlanetKitStartFailReason.kitPeerServiceIdBlank;
      case 3019:
        return PlanetKitStartFailReason.kitInvalidStateToMakeCall;
      case 3020:
        return PlanetKitStartFailReason.kitCannotCreateNewSession;
      case 3021:
        return PlanetKitStartFailReason.kitInvalidStateToJoinConference;
      case 3022:
        return PlanetKitStartFailReason.kitRoomIdBlank;
      case 3023:
        return PlanetKitStartFailReason.kitRoomServiceIdBlank;
      case 3024:
        return PlanetKitStartFailReason.kitNoPermissionReadPhoneState;
      case 3025:
        return PlanetKitStartFailReason.kitInternalUnknownExceptionAtVerifyCall;
      case 3026:
        return PlanetKitStartFailReason.kitInternalJNIEnv;
      case 3027:
        return PlanetKitStartFailReason.kitInternalJNIHandleNullptr;
      case 3028:
        return PlanetKitStartFailReason.kitInternalJNIObjNullptr;
      case 3029:
        return PlanetKitStartFailReason.kitInternalJNIClassNullptr;
      case 3030:
        return PlanetKitStartFailReason.kitInternalUndefined;
      default:
        return PlanetKitStartFailReason.none;
    }
  }
}
