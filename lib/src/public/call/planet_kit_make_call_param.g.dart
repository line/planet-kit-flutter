// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_make_call_param.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanetKitMakeCallParam _$PlanetKitMakeCallParamFromJson(
        Map<String, dynamic> json) =>
    PlanetKitMakeCallParam(
      myUserId: json['myUserId'] as String,
      myServiceId: json['myServiceId'] as String,
      peerUserId: json['peerUserId'] as String,
      peerServiceId: json['peerServiceId'] as String,
      accessToken: json['accessToken'] as String,
    );

Map<String, dynamic> _$PlanetKitMakeCallParamToJson(
        PlanetKitMakeCallParam instance) =>
    <String, dynamic>{
      'myUserId': instance.myUserId,
      'myServiceId': instance.myServiceId,
      'peerUserId': instance.peerUserId,
      'peerServiceId': instance.peerServiceId,
      'accessToken': instance.accessToken,
    };
