// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_platform_call_reponses.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MakeCallResponse _$MakeCallResponseFromJson(Map<String, dynamic> json) =>
    MakeCallResponse(
      callId: json['callId'] as String?,
      failReason: const PlanetKitStartFailReasonConverter()
          .fromJson((json['failReason'] as num).toInt()),
    );

VerifyCallResponse _$VerifyCallResponseFromJson(Map<String, dynamic> json) =>
    VerifyCallResponse(
      callId: json['callId'] as String?,
      failReason: const PlanetKitStartFailReasonConverter()
          .fromJson((json['failReason'] as num).toInt()),
    );

CreateCCParamResponse _$CreateCCParamResponseFromJson(
        Map<String, dynamic> json) =>
    CreateCCParamResponse(
      id: json['id'] as String,
      peerId: json['peerId'] as String?,
      peerServiceId: json['peerServiceId'] as String?,
      mediaType: const PlanetKitMediaTypeConverter()
          .fromJson((json['mediaType'] as num).toInt()),
    );
