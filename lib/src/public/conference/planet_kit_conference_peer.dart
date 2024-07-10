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

import '../../internal/planet_kit_platform_interface.dart';
import '../../internal/planet_kit_platform_resource_manager.dart';
import '../planet_kit_user_id.dart';
part 'planet_kit_conference_peer.g.dart';

/// Represents the hold status of a conference peer.
@JsonSerializable(createToJson: false)
class PlanetKitHoldStatus {
  /// Indicates whether the peer is currently on hold.
  final bool isOnHold;

  /// Optional reason for the peer being on hold.
  final String? reason;

  /// Constructs a [PlanetKitHoldStatus].
  PlanetKitHoldStatus({required this.isOnHold, this.reason});

  /// Creates a [PlanetKitHoldStatus] from a JSON map.
  factory PlanetKitHoldStatus.fromJson(Map<String, dynamic> json) =>
      _$PlanetKitHoldStatusFromJson(json);
}

/// Represents a peer in a conference within the PlanetKit system.
class PlanetKitConferencePeer {
  /// Unique identifier for the conference peer.
  final String id;

  /// The user ID associated with this peer.
  final PlanetKitUserId userId;

  /// Constructs a [PlanetKitConferencePeer] with a unique identifier and associated user ID.
  PlanetKitConferencePeer({required this.id, required this.userId}) {
    NativeResourceManager.instance.add(this, id);
  }

  /// Checks if the peer is currently muted.
  ///
  /// Returns `true` if the peer is muted, otherwise `false`.
  Future<bool> get isMuted async =>
      await Platform.instance.conferencePeerInterface.isMuted(id);

  /// Retrieves the hold status of the peer.
  ///
  /// Returns a [PlanetKitHoldStatus] indicating whether the peer is on hold and the reason for it.
  Future<PlanetKitHoldStatus> get holdStatus async =>
      await Platform.instance.conferencePeerInterface.getHoldStatus(id);
}
