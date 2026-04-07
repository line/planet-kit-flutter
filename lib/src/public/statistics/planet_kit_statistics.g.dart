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
