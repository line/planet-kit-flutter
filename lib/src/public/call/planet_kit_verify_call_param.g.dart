// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_verify_call_param.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$PlanetKitVerifyCallParamToJson(
        PlanetKitVerifyCallParam instance) =>
    <String, dynamic>{
      'myUserId': instance.myUserId,
      'myServiceId': instance.myServiceId,
      'ccParam': instance.ccParam.toJson(),
      'callKitType':
          const PlanetKitCallKitTypeConverter().toJson(instance.callKitType),
      'holdTonePath': instance.holdTonePath,
      'ringtonePath': instance.ringtonePath,
      'endTonePath': instance.endTonePath,
      'allowCallWithoutMic': instance.allowCallWithoutMic,
      'allowCallWithoutMicPermission': instance.allowCallWithoutMicPermission,
      'enableAudioDescription': instance.enableAudioDescription,
      'audioDescriptionUpdateIntervalMs':
          instance.audioDescriptionUpdateIntervalMs,
      'responseOnEnableVideo': const PlanetKitResponseOnEnableVideoConverter()
          .toJson(instance.responseOnEnableVideo),
      'enableStatistics': instance.enableStatistics,
      'screenShareKey': instance.screenShareKey?.toJson(),
    };
