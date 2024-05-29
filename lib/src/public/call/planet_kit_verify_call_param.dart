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
import 'planet_kit_cc_param.dart';
part 'planet_kit_verify_call_param.g.dart';

/// A data model representing the parameters required to verify a call with PlanetKit.
///
/// This class encapsulates details necessary for verifying a call, including user and
/// service identifiers, along with a configuration parameter object.
@JsonSerializable(explicitToJson: true)
class PlanetKitVerifyCallParam {
  /// The user ID of the individual initiating the verification.
  final String myUserId;

  /// The service ID associated with the user's service.
  final String myServiceId;

  /// A [PlanetKitCcParam] instance.
  final PlanetKitCcParam ccParam;

  /// Constructs a [PlanetKitVerifyCallParam] with necessary details for call verification.
  PlanetKitVerifyCallParam(
      {required this.myUserId,
      required this.myServiceId,
      required this.ccParam});

  /// @nodoc
  Map<String, dynamic> toJson() => _$PlanetKitVerifyCallParamToJson(this);
}
