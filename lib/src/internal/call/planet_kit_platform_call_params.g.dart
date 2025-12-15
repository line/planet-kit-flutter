// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_platform_call_params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$AcceptCallParamToJson(AcceptCallParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'useResponderPreparation': instance.useResponderPreparation,
      'initialMyVideoState': const PlanetKitInitialMyVideoStateConverter()
          .toJson(instance.initialMyVideoState),
    };

Map<String, dynamic> _$HoldCallParamToJson(HoldCallParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'reason': instance.reason,
    };

Map<String, dynamic> _$PutHookedAudioBackParamToJson(
        PutHookedAudioBackParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'audioId': instance.audioId,
    };

Map<String, dynamic> _$MuteCallParamToJson(MuteCallParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'mute': instance.mute,
    };

Map<String, dynamic> _$RequestPeerMuteParamToJson(
        RequestPeerMuteParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'mute': instance.mute,
    };

Map<String, dynamic> _$SilencePeerAudioParamToJson(
        SilencePeerAudioParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'silent': instance.silent,
    };

CallSpeakerOutParam _$CallSpeakerOutParamFromJson(Map<String, dynamic> json) =>
    CallSpeakerOutParam(
      callId: json['callId'] as String,
      speakerOut: json['speakerOut'] as bool,
    );

Map<String, dynamic> _$CallSpeakerOutParamToJson(
        CallSpeakerOutParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'speakerOut': instance.speakerOut,
    };

EndCallParam _$EndCallParamFromJson(Map<String, dynamic> json) => EndCallParam(
      callId: json['callId'] as String,
      userReleasePhrase: json['userReleasePhrase'] as String?,
    );

Map<String, dynamic> _$EndCallParamToJson(EndCallParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'userReleasePhrase': instance.userReleasePhrase,
    };

EndCallWithErrorParam _$EndCallWithErrorParamFromJson(
        Map<String, dynamic> json) =>
    EndCallWithErrorParam(
      callId: json['callId'] as String,
      userReleasePhrase: json['userReleasePhrase'] as String,
    );

Map<String, dynamic> _$EndCallWithErrorParamToJson(
        EndCallWithErrorParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'userReleasePhrase': instance.userReleasePhrase,
    };

Map<String, dynamic> _$AddVideoViewParamToJson(AddVideoViewParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'viewId': instance.viewId,
    };

Map<String, dynamic> _$RemoveVideoViewParamToJson(
        RemoveVideoViewParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'viewId': instance.viewId,
    };

Map<String, dynamic> _$DisableVideoParamToJson(DisableVideoParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'reason':
          const PlanetKitMediaDisableReasonConverter().toJson(instance.reason),
    };

Map<String, dynamic> _$EnableVideoParamToJson(EnableVideoParam instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'initialMyVideoState': const PlanetKitInitialMyVideoStateConverter()
          .toJson(instance.initialMyVideoState),
    };
