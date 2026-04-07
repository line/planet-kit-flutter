// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_platform_conference_responses.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JoinConferenceResponse _$JoinConferenceResponseFromJson(
        Map<String, dynamic> json) =>
    JoinConferenceResponse(
      id: json['id'] as String?,
      failReason: const PlanetKitStartFailReasonConverter()
          .fromJson((json['failReason'] as num).toInt()),
    );
