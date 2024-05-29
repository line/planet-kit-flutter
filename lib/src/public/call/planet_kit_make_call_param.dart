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
part 'planet_kit_make_call_param.g.dart';

/// A data model representing the parameters required to initiate a call with PlanetKit.
///
/// This class encapsulates all necessary details needed to make a call, including user
/// and service identifiers for both the initiator and the receiver, as well as an access token.
@JsonSerializable(explicitToJson: true)
class PlanetKitMakeCallParam {
  /// The user ID of the caller.
  final String myUserId;

  /// The service ID of the caller's service.
  final String myServiceId;

  /// The user ID of the call receiver.
  final String peerUserId;

  /// The service ID of the call receiver's service.
  final String peerServiceId;

  /// The access token to authenticate the call request.
  final String accessToken;

  /// Constructs a [PlanetKitMakeCallParam] with necessary details for making a call.
  PlanetKitMakeCallParam(
      {required this.myUserId,
      required this.myServiceId,
      required this.peerUserId,
      required this.peerServiceId,
      required this.accessToken});

  /// @nodoc
  Map<String, dynamic> toJson() => _$PlanetKitMakeCallParamToJson(this);
}
