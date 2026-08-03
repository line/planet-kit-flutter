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
      json['isDataSessionSupported'] as bool? ?? false,
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

PeerSharedContentsSetEvent _$PeerSharedContentsSetEventFromJson(
        Map<String, dynamic> json) =>
    PeerSharedContentsSetEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      const Base64DataConverter().fromJson(json['data'] as String),
      (json['elapsedMillis'] as num).toInt(),
    );

PeerExclusivelySharedContentsSetEvent
    _$PeerExclusivelySharedContentsSetEventFromJson(
            Map<String, dynamic> json) =>
        PeerExclusivelySharedContentsSetEvent(
          const EventTypeConverter().fromJson((json['type'] as num).toInt()),
          json['id'] as String,
          const CallEventTypeConverter()
              .fromJson((json['subType'] as num).toInt()),
          const Base64DataConverter().fromJson(json['data'] as String),
          (json['elapsedMillis'] as num).toInt(),
        );

ShortDataReceivedEvent _$ShortDataReceivedEventFromJson(
        Map<String, dynamic> json) =>
    ShortDataReceivedEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      json['dataType'] as String,
      const Base64DataConverter().fromJson(json['data'] as String),
    );

DataSessionIncomingEvent _$DataSessionIncomingEventFromJson(
        Map<String, dynamic> json) =>
    DataSessionIncomingEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      (json['streamId'] as num).toInt(),
      (json['dataSessionType'] as num).toInt(),
    );

DataSessionInboundReceivedEvent _$DataSessionInboundReceivedEventFromJson(
        Map<String, dynamic> json) =>
    DataSessionInboundReceivedEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      (json['streamId'] as num).toInt(),
      json['userId'] as String,
      json['serviceId'] as String,
      const Base64DataConverter().fromJson(json['data'] as String),
      (json['timestamp'] as num).toInt(),
      (json['offset'] as num).toInt(),
    );

DataSessionInboundClosedEvent _$DataSessionInboundClosedEventFromJson(
        Map<String, dynamic> json) =>
    DataSessionInboundClosedEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      (json['streamId'] as num).toInt(),
      (json['closedReason'] as num).toInt(),
    );

DataSessionOutboundClosedEvent _$DataSessionOutboundClosedEventFromJson(
        Map<String, dynamic> json) =>
    DataSessionOutboundClosedEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const CallEventTypeConverter().fromJson((json['subType'] as num).toInt()),
      (json['streamId'] as num).toInt(),
      (json['closedReason'] as num).toInt(),
    );

DataSessionOutboundTooLongQueuedDataEvent
    _$DataSessionOutboundTooLongQueuedDataEventFromJson(
            Map<String, dynamic> json) =>
        DataSessionOutboundTooLongQueuedDataEvent(
          const EventTypeConverter().fromJson((json['type'] as num).toInt()),
          json['id'] as String,
          const CallEventTypeConverter()
              .fromJson((json['subType'] as num).toInt()),
          (json['streamId'] as num).toInt(),
          json['enabled'] as bool,
        );
