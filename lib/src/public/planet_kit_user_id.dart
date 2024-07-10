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
part 'planet_kit_user_id.g.dart';

/// Represents a user identifier within the PlanetKit system.
///
/// This class encapsulates both the user's unique identifier and the service identifier,
/// which together uniquely identify a user within a specific service context.
@JsonSerializable(explicitToJson: true)
class PlanetKitUserId {
  /// The unique identifier for the user.
  final String userId;

  /// The identifier for the service to which the user belongs.
  final String serviceId;

  /// Constructs a [PlanetKitUserId] with a given [userId] and [serviceId].
  PlanetKitUserId({required this.userId, required this.serviceId});

  /// @nodoc
  Map<String, dynamic> toJson() => _$PlanetKitUserIdToJson(this);
}
