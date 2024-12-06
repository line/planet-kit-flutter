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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanetKitStatistics _$PlanetKitStatisticsFromJson(Map<String, dynamic> json) =>
    PlanetKitStatistics(
      myAudio: MyAudio.fromJson(json['myAudio'] as Map<String, dynamic>),
      peersAudio:
          PeersAudio.fromJson(json['peersAudio'] as Map<String, dynamic>),
      myVideo: json['myVideo'] == null
          ? null
          : MyVideo.fromJson(json['myVideo'] as Map<String, dynamic>),
      peerVideos: (json['peerVideos'] as List<dynamic>)
          .map((e) => PeerVideo.fromJson(e as Map<String, dynamic>))
          .toList(),
      myScreenShare: json['myScreenShare'] == null
          ? null
          : MyScreenShare.fromJson(
              json['myScreenShare'] as Map<String, dynamic>),
      peerScreenShares: (json['peerScreenShares'] as List<dynamic>)
          .map((e) => PeerScreenShare.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

MyAudio _$MyAudioFromJson(Map<String, dynamic> json) => MyAudio(
      network: Network.fromJson(json['network'] as Map<String, dynamic>),
    );

PeersAudio _$PeersAudioFromJson(Map<String, dynamic> json) => PeersAudio(
      network: Network.fromJson(json['network'] as Map<String, dynamic>),
    );

MyVideo _$MyVideoFromJson(Map<String, dynamic> json) => MyVideo(
      network: Network.fromJson(json['network'] as Map<String, dynamic>),
      video: Video.fromJson(json['video'] as Map<String, dynamic>),
    );

PeerVideo _$PeerVideoFromJson(Map<String, dynamic> json) => PeerVideo(
      peerId: PlanetKitUserId.fromJson(json['peerId'] as Map<String, dynamic>),
      subGroupName: json['subGroupName'] as String?,
      network: Network.fromJson(json['network'] as Map<String, dynamic>),
      video: Video.fromJson(json['video'] as Map<String, dynamic>),
    );

MyScreenShare _$MyScreenShareFromJson(Map<String, dynamic> json) =>
    MyScreenShare(
      network: Network.fromJson(json['network'] as Map<String, dynamic>),
      video: Video.fromJson(json['video'] as Map<String, dynamic>),
    );

PeerScreenShare _$PeerScreenShareFromJson(Map<String, dynamic> json) =>
    PeerScreenShare(
      peerId: PlanetKitUserId.fromJson(json['peerId'] as Map<String, dynamic>),
      subGroupName: json['subGroupName'] as String?,
      network: Network.fromJson(json['network'] as Map<String, dynamic>),
      video: Video.fromJson(json['video'] as Map<String, dynamic>),
    );

Network _$NetworkFromJson(Map<String, dynamic> json) => Network(
      lossRate: (json['lossRate'] as num?)?.toDouble(),
      jitterMs: (json['jitterMs'] as num?)?.toInt(),
      latencyMs: (json['latencyMs'] as num?)?.toInt(),
      bps: (json['bps'] as num).toInt(),
    );

Video _$VideoFromJson(Map<String, dynamic> json) => Video(
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      fps: (json['fps'] as num).toInt(),
    );
