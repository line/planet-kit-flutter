// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_join_conference_param.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$PlanetKitJoinConferenceParamToJson(
        PlanetKitJoinConferenceParam instance) =>
    <String, dynamic>{
      'myUserId': instance.myUserId,
      'myServiceId': instance.myServiceId,
      'roomId': instance.roomId,
      'roomServiceId': instance.roomServiceId,
      'accessToken': instance.accessToken,
      'endTonePath': instance.endTonePath,
      'allowConferenceWithoutMic': instance.allowConferenceWithoutMic,
      'allowConferenceWithoutMicPermission':
          instance.allowConferenceWithoutMicPermission,
      'enableAudioDescription': instance.enableAudioDescription,
      'audioDescriptionUpdateIntervalMs':
          instance.audioDescriptionUpdateIntervalMs,
      'mediaType':
          const PlanetKitMediaTypeConverter().toJson(instance.mediaType),
      'callKitType':
          const PlanetKitCallKitTypeConverter().toJson(instance.callKitType),
      'enableStatistics': instance.enableStatistics,
      'screenShareKey': instance.screenShareKey?.toJson(),
      'initialMyVideoState': const PlanetKitInitialMyVideoStateConverter()
          .toJson(instance.initialMyVideoState),
    };
