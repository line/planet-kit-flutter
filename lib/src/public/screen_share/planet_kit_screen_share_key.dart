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
part 'planet_kit_screen_share_key.g.dart';

/// Represents the key information required for screen share in PlanetKit.
@JsonSerializable(explicitToJson: true, createFactory: false)
class ScreenShareKey {
  /// The port used for broadcasting the screen share.
  final int broadcastPort;

  /// Peer token for the screen share broadcast.
  final String broadcastPeerToken;

  /// The local user's token for the screen share broadcast.
  final String broadcastMyToken;

  /// Constructs a [ScreenShareKey] with the given broadcast port and tokens.
  ScreenShareKey({
    required this.broadcastPort,
    required this.broadcastPeerToken,
    required this.broadcastMyToken,
  });

  /// @nodoc
  Map<String, dynamic> toJson() => _$ScreenShareKeyToJson(this);
}
