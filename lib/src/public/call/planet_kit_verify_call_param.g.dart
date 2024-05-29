// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_verify_call_param.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanetKitVerifyCallParam _$PlanetKitVerifyCallParamFromJson(
        Map<String, dynamic> json) =>
    PlanetKitVerifyCallParam(
      myUserId: json['myUserId'] as String,
      myServiceId: json['myServiceId'] as String,
      ccParam:
          PlanetKitCcParam.fromJson(json['ccParam'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PlanetKitVerifyCallParamToJson(
        PlanetKitVerifyCallParam instance) =>
    <String, dynamic>{
      'myUserId': instance.myUserId,
      'myServiceId': instance.myServiceId,
      'ccParam': instance.ccParam.toJson(),
    };
