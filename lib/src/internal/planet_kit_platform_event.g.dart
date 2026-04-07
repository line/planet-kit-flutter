// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_platform_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) => Event(
      type: const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      id: json['id'] as String,
    );
