// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_platform_my_media_status_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyMediaStatusEvent _$MyMediaStatusEventFromJson(Map<String, dynamic> json) =>
    MyMediaStatusEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const MyMediaStatusEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
    );

UpdateAudioDescriptionEvent _$UpdateAudioDescriptionEventFromJson(
        Map<String, dynamic> json) =>
    UpdateAudioDescriptionEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const MyMediaStatusEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      (json['averageVolumeLevel'] as num).toInt(),
    );

UpdateVideoStatusEvent _$UpdateVideoStatusEventFromJson(
        Map<String, dynamic> json) =>
    UpdateVideoStatusEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const MyMediaStatusEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      PlanetKitVideoStatus.fromJson(json['status'] as Map<String, dynamic>),
    );

UpdateScreenShareStateEvent _$UpdateScreenShareStateEventFromJson(
        Map<String, dynamic> json) =>
    UpdateScreenShareStateEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const MyMediaStatusEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      const PlanetKitScreenShareStateConverter()
          .fromJson((json['state'] as num).toInt()),
    );
