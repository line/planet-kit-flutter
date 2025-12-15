// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_video_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanetKitVideoStatus _$PlanetKitVideoStatusFromJson(
        Map<String, dynamic> json) =>
    PlanetKitVideoStatus(
      const PlanetKitVideoStateConverter()
          .fromJson((json['state'] as num).toInt()),
      const PlanetKitVideoPauseReasonConverter()
          .fromJson((json['pauseReason'] as num).toInt()),
    );
