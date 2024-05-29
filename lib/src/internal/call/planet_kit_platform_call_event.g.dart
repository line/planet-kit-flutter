// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_platform_call_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CallEventData _$CallEventDataFromJson(Map<String, dynamic> json) =>
    CallEventData(
      const EventTypeConverter().fromJson(json['type'] as int),
      json['id'] as String,
      const CallEventTypeConverter().fromJson(json['callEventType'] as int),
    );

Map<String, dynamic> _$CallEventDataToJson(CallEventData instance) =>
    <String, dynamic>{
      'type': const EventTypeConverter().toJson(instance.type),
      'id': instance.id,
      'callEventType':
          const CallEventTypeConverter().toJson(instance.callEventType),
    };

DisconnectedEventData _$DisconnectedEventDataFromJson(
        Map<String, dynamic> json) =>
    DisconnectedEventData(
      const EventTypeConverter().fromJson(json['type'] as int),
      json['id'] as String,
      const CallEventTypeConverter().fromJson(json['callEventType'] as int),
      const PlanetKitDisconnectReasonConverter()
          .fromJson(json['disconnectReason'] as int),
      const PlanetKitDisconnectSourceConverter()
          .fromJson(json['disconnectSource'] as int),
      json['byRemote'] as bool,
    );

Map<String, dynamic> _$DisconnectedEventDataToJson(
        DisconnectedEventData instance) =>
    <String, dynamic>{
      'type': const EventTypeConverter().toJson(instance.type),
      'id': instance.id,
      'callEventType':
          const CallEventTypeConverter().toJson(instance.callEventType),
      'disconnectReason': const PlanetKitDisconnectReasonConverter()
          .toJson(instance.disconnectReason),
      'disconnectSource': const PlanetKitDisconnectSourceConverter()
          .toJson(instance.disconnectSource),
      'byRemote': instance.byRemote,
    };
