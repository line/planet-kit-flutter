// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_platform_peer_control_params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$StartVideoParamToJson(StartVideoParam instance) =>
    <String, dynamic>{
      'id': instance.id,
      'viewId': instance.viewId,
      'maxResolution': const PlanetKitVideoResolutionConverter()
          .toJson(instance.maxResolution),
    };

Map<String, dynamic> _$StopVideoParamToJson(StopVideoParam instance) =>
    <String, dynamic>{
      'id': instance.id,
      'viewId': instance.viewId,
    };

Map<String, dynamic> _$StartScreenShareParamToJson(
        StartScreenShareParam instance) =>
    <String, dynamic>{
      'id': instance.id,
      'viewId': instance.viewId,
    };

Map<String, dynamic> _$StopScreenShareParamToJson(
        StopScreenShareParam instance) =>
    <String, dynamic>{
      'id': instance.id,
      'viewId': instance.viewId,
    };
