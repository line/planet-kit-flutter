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

import '../planet_kit_user_id.dart';

part 'planet_kit_statistics.g.dart';

/// Represents the statistics of a PlanetKit session.
@JsonSerializable(createToJson: false)
class PlanetKitStatistics {
  /// The audio statistics for the local user.
  final MyAudio myAudio;

  /// The audio statistics for the peers.
  final PeersAudio peersAudio;

  /// The video statistics for the local user.
  final MyVideo? myVideo;

  /// The video statistics for the peers.
  final List<PeerVideo> peerVideos;

  /// @nodoc
  PlanetKitStatistics(
      {required this.myAudio,
      required this.peersAudio,
      this.myVideo,
      required this.peerVideos});

  /// @nodoc
  factory PlanetKitStatistics.fromJson(Map<String, dynamic> json) =>
      _$PlanetKitStatisticsFromJson(json);
}

/// Represents the audio statistics for the local user.
@JsonSerializable(createToJson: false)
class MyAudio {
  /// The network statistics for the local user's audio.
  final Network network;

  /// @nodoc
  MyAudio({required this.network});

  /// @nodoc
  factory MyAudio.fromJson(Map<String, dynamic> json) =>
      _$MyAudioFromJson(json);
}

/// Represents the audio statistics for the peers.
@JsonSerializable(createToJson: false)
class PeersAudio {
  /// The network statistics for the peers' audio.
  final Network network;

  /// @nodoc
  PeersAudio({required this.network});

  /// @nodoc
  factory PeersAudio.fromJson(Map<String, dynamic> json) =>
      _$PeersAudioFromJson(json);
}

/// Represents the video statistics for the local user.
@JsonSerializable(createToJson: false)
class MyVideo {
  /// The network statistics for the local user's video.
  final Network network;

  /// The video statistics for the local user's video.
  final Video video;

  /// @nodoc
  MyVideo({required this.network, required this.video});

  /// @nodoc
  factory MyVideo.fromJson(Map<String, dynamic> json) =>
      _$MyVideoFromJson(json);
}

/// Represents the video statistics for a peer.
@JsonSerializable(createToJson: false)
class PeerVideo {
  // TODO: modify PlanetKitUserId to be serializable in both platforms
  // final PlanetKitUserId? peerId;

  /// The subgroup name of the peer.
  final String? subGroupName;

  /// The network statistics for the peer's video.
  final Network network;

  /// The video statistics for the peer's video.
  final Video video;

  /// @nodoc
  PeerVideo({
    // required this.peerId,
    this.subGroupName,
    required this.network,
    required this.video,
  });

  /// @nodoc
  factory PeerVideo.fromJson(Map<String, dynamic> json) =>
      _$PeerVideoFromJson(json);
}

/// Represents the screen share statistics for the local user.
@JsonSerializable(createToJson: false)
class MyScreenShare {
  /// The network statistics for the local user's screen share.
  final Network network;

  /// The video statistics for the local user's screen share.
  final Video video;

  /// @nodoc
  MyScreenShare({required this.network, required this.video});

  /// @nodoc
  factory MyScreenShare.fromJson(Map<String, dynamic> json) =>
      _$MyScreenShareFromJson(json);
}

/// Represents the screen share statistics for a peer.
@JsonSerializable(createToJson: false)
class PeerScreenShare {
  /// The user ID of the peer.
  final PlanetKitUserId peerId;

  /// The subgroup name of the peer.
  final String? subGroupName;

  /// The network statistics for the peer's screen share.
  final Network network;

  /// The video statistics for the peer's screen share.
  final Video video;

  /// @nodoc
  PeerScreenShare({
    required this.peerId,
    this.subGroupName,
    required this.network,
    required this.video,
  });

  /// @nodoc
  factory PeerScreenShare.fromJson(Map<String, dynamic> json) =>
      _$PeerScreenShareFromJson(json);
}

/// Represents the network statistics.
@JsonSerializable(createToJson: false)
class Network {
  /// The packet loss rate.
  final double? lossRate;

  /// The jitter in milliseconds.
  final int? jitterMs;

  /// The latency in milliseconds.
  final int? latencyMs;

  /// The bitrate in bits per second.
  final int bps;

  /// @nodoc
  Network({this.lossRate, this.jitterMs, this.latencyMs, required this.bps});

  /// @nodoc
  factory Network.fromJson(Map<String, dynamic> json) =>
      _$NetworkFromJson(json);
}

/// Represents the video statistics.
@JsonSerializable(createToJson: false)
class Video {
  /// The width of the video in pixels.
  final int width;

  /// The height of the video in pixels.
  final int height;

  /// The frame rate of the video in frames per second.
  final int fps;

  /// @nodoc
  Video({required this.width, required this.height, required this.fps});

  /// @nodoc
  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
}
