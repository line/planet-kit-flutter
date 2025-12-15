// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_make_call_param.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$PlanetKitMakeCallParamToJson(
        PlanetKitMakeCallParam instance) =>
    <String, dynamic>{
      'myUserId': instance.myUserId,
      'myServiceId': instance.myServiceId,
      'myCountryCode': instance.myCountryCode,
      'peerUserId': instance.peerUserId,
      'peerServiceId': instance.peerServiceId,
      'peerCountryCode': instance.peerCountryCode,
      'accessToken': instance.accessToken,
      'useResponderPreparation': instance.useResponderPreparation,
      'callKitType':
          const PlanetKitCallKitTypeConverter().toJson(instance.callKitType),
      'holdTonePath': instance.holdTonePath,
      'ringbackTonePath': instance.ringbackTonePath,
      'endTonePath': instance.endTonePath,
      'allowCallWithoutMic': instance.allowCallWithoutMic,
      'allowCallWithoutMicPermission': instance.allowCallWithoutMicPermission,
      'enableAudioDescription': instance.enableAudioDescription,
      'audioDescriptionUpdateIntervalMs':
          instance.audioDescriptionUpdateIntervalMs,
      'mediaType':
          const PlanetKitMediaTypeConverter().toJson(instance.mediaType),
      'responseOnEnableVideo': const PlanetKitResponseOnEnableVideoConverter()
          .toJson(instance.responseOnEnableVideo),
      'enableStatistics': instance.enableStatistics,
      'screenShareKey': instance.screenShareKey?.toJson(),
      'initialMyVideoState': const PlanetKitInitialMyVideoStateConverter()
          .toJson(instance.initialMyVideoState),
    };
