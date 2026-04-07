// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_platform_peer_control_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PeerControlEvent _$PeerControlEventFromJson(Map<String, dynamic> json) =>
    PeerControlEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const PeerControlEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
    );

HoldEvent _$HoldEventFromJson(Map<String, dynamic> json) => HoldEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const PeerControlEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      json['reason'] as String?,
    );

UpdateAudioDescriptionEvent _$UpdateAudioDescriptionEventFromJson(
        Map<String, dynamic> json) =>
    UpdateAudioDescriptionEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const PeerControlEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      (json['averageVolumeLevel'] as num).toInt(),
    );

UpdateVideoEvent _$UpdateVideoEventFromJson(Map<String, dynamic> json) =>
    UpdateVideoEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const PeerControlEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      PlanetKitVideoStatus.fromJson(json['status'] as Map<String, dynamic>),
    );

UpdateScreenShareEvent _$UpdateScreenShareEventFromJson(
        Map<String, dynamic> json) =>
    UpdateScreenShareEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const PeerControlEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      const PlanetKitScreenShareStateConverter()
          .fromJson((json['state'] as num).toInt()),
    );
