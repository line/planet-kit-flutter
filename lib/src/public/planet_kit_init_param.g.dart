// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_init_param.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$PlanetKitInitParamToJson(PlanetKitInitParam instance) =>
    <String, dynamic>{
      'logSetting': instance.logSetting.toJson(),
      'serverUrl': instance.serverUrl,
    };

Map<String, dynamic> _$PlanetKitLogSettingToJson(
        PlanetKitLogSetting instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'logLevel': const PlanetKitLogLevelConverter().toJson(instance.logLevel),
      'logSizeLimit':
          const PlanetKitLogSizeLimitConverter().toJson(instance.logSizeLimit),
    };
