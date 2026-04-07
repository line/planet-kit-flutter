// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_platform_call_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CallEvent _$CallEventFromJson(Map<String, dynamic> json) => CallEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
    );

DisconnectedEvent _$DisconnectedEventFromJson(Map<String, dynamic> json) =>
    DisconnectedEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      const PlanetKitDisconnectReasonConverter()
          .fromJson((json['disconnectReason'] as num).toInt()),
      const PlanetKitDisconnectSourceConverter()
          .fromJson((json['disconnectSource'] as num).toInt()),
      json['userCode'] as String?,
      json['byRemote'] as bool,
    );

NetworkDidUnavailableEvent _$NetworkDidUnavailableEventFromJson(
        Map<String, dynamic> json) =>
    NetworkDidUnavailableEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      json['isPeer'] as bool,
      (json['willDisconnectSec'] as num).toInt(),
    );

NetworkDidReavailableEvent _$NetworkDidReavailableEventFromJson(
        Map<String, dynamic> json) =>
    NetworkDidReavailableEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      json['isPeer'] as bool,
    );

ConnectedEvent _$ConnectedEventFromJson(Map<String, dynamic> json) =>
    ConnectedEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      json['isInResponderPreparation'] as bool,
      json['shouldFinishPreparation'] as bool,
    );

VerifiedEvent _$VerifiedEventFromJson(Map<String, dynamic> json) =>
    VerifiedEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      json['peerUseResponderPreparation'] as bool,
    );

PeerHoldEvent _$PeerHoldEventFromJson(Map<String, dynamic> json) =>
    PeerHoldEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      json['reason'] as String?,
    );

MyAudioMuteRequestByPeerEvent _$MyAudioMuteRequestByPeerEventFromJson(
        Map<String, dynamic> json) =>
    MyAudioMuteRequestByPeerEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      json['mute'] as bool,
    );

PeerVideoDidPauseEvent _$PeerVideoDidPauseEventFromJson(
        Map<String, dynamic> json) =>
    PeerVideoDidPauseEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      const PlanetKitVideoPauseReasonConverter()
          .fromJson((json['reason'] as num).toInt()),
    );

VideoDisabledByPeerEvent _$VideoDisabledByPeerEventFromJson(
        Map<String, dynamic> json) =>
    VideoDisabledByPeerEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      const PlanetKitMediaDisableReasonConverter()
          .fromJson((json['reason'] as num).toInt()),
    );

PeerDidStartScreenShareEvent _$PeerDidStartScreenShareEventFromJson(
        Map<String, dynamic> json) =>
    PeerDidStartScreenShareEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
    );

PeerDidStopScreenShareEvent _$PeerDidStopScreenShareEventFromJson(
        Map<String, dynamic> json) =>
    PeerDidStopScreenShareEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
    );

PeerAudioDescriptionUpdateEvent _$PeerAudioDescriptionUpdateEventFromJson(
        Map<String, dynamic> json) =>
    PeerAudioDescriptionUpdateEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      (json['averageVolumeLevel'] as num).toInt(),
    );

AdoptBackgroundCallEvent _$AdoptBackgroundCallEventFromJson(
        Map<String, dynamic> json) =>
    AdoptBackgroundCallEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
    );
