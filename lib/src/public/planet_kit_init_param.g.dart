// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_init_param.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanetKitInitParam _$PlanetKitInitParamFromJson(Map<String, dynamic> json) =>
    PlanetKitInitParam(
      logSetting: PlanetKitLogSetting.fromJson(
          json['logSetting'] as Map<String, dynamic>),
      serverUrl: json['serverUrl'] as String,
    );

Map<String, dynamic> _$PlanetKitInitParamToJson(PlanetKitInitParam instance) =>
    <String, dynamic>{
      'logSetting': instance.logSetting.toJson(),
      'serverUrl': instance.serverUrl,
    };

PlanetKitLogSetting _$PlanetKitLogSettingFromJson(Map<String, dynamic> json) =>
    PlanetKitLogSetting(
      enabled: json['enabled'] as bool,
      logLevel:
          const PlanetKitLogLevelConverter().fromJson(json['logLevel'] as int),
      logSizeLimit: const PlanetKitLogSizeLimitConverter()
          .fromJson(json['logSizeLimit'] as int),
    );

Map<String, dynamic> _$PlanetKitLogSettingToJson(
        PlanetKitLogSetting instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'logLevel': const PlanetKitLogLevelConverter().toJson(instance.logLevel),
      'logSizeLimit':
          const PlanetKitLogSizeLimitConverter().toJson(instance.logSizeLimit),
    };
