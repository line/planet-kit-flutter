// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_platform_camera_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CameraEvent _$CameraEventFromJson(Map<String, dynamic> json) => CameraEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CameraEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
    );
