// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_kit_platform_conference_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConferenceEvent _$ConferenceEventFromJson(Map<String, dynamic> json) =>
    ConferenceEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
    );

DisconnectedEvent _$DisconnectedEventFromJson(Map<String, dynamic> json) =>
    DisconnectedEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      const PlanetKitDisconnectReasonConverter()
          .fromJson((json['disconnectReason'] as num).toInt()),
      const PlanetKitDisconnectSourceConverter()
          .fromJson((json['disconnectSource'] as num).toInt()),
      json['userCode'] as String?,
      json['byRemote'] as bool,
    );

InitialPeerInfo _$InitialPeerInfoFromJson(Map<String, dynamic> json) =>
    InitialPeerInfo(
      id: json['id'] as String,
      userId: json['userId'] as String,
      serviceId: json['serviceId'] as String,
      isDataSessionSupported: json['isDataSessionSupported'] as bool? ?? false,
    );

PeerListUpdateEvent _$PeerListUpdateEventFromJson(Map<String, dynamic> json) =>
    PeerListUpdateEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      (json['added'] as List<dynamic>)
          .map((e) => InitialPeerInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['removed'] as List<dynamic>).map((e) => e as String).toList(),
      (json['totalPeersCount'] as num).toInt(),
    );

NetworkDidUnavailableEvent _$NetworkDidUnavailableEventFromJson(
        Map<String, dynamic> json) =>
    NetworkDidUnavailableEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      (json['willDisconnectSec'] as num).toInt(),
    );

PeerHoldEventData _$PeerHoldEventDataFromJson(Map<String, dynamic> json) =>
    PeerHoldEventData(
      peer: json['peer'] as String,
      reason: json['reason'] as String?,
    );

PeersHoldEvent _$PeersHoldEventFromJson(Map<String, dynamic> json) =>
    PeersHoldEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      (json['peers'] as List<dynamic>)
          .map((e) => PeerHoldEventData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

PeersUnholdEvent _$PeersUnholdEventFromJson(Map<String, dynamic> json) =>
    PeersUnholdEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      (json['peers'] as List<dynamic>).map((e) => e as String).toList(),
    );

MyAudioMuteRequestedByPeerEvent _$MyAudioMuteRequestedByPeerEventFromJson(
        Map<String, dynamic> json) =>
    MyAudioMuteRequestedByPeerEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      json['peer'] as String,
      json['mute'] as bool,
    );

PeersMicMuteEvent _$PeersMicMuteEventFromJson(Map<String, dynamic> json) =>
    PeersMicMuteEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      (json['peers'] as List<dynamic>).map((e) => e as String).toList(),
    );

PeersMicUnmuteEvent _$PeersMicUnmuteEventFromJson(Map<String, dynamic> json) =>
    PeersMicUnmuteEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      (json['peers'] as List<dynamic>).map((e) => e as String).toList(),
    );

PeerSharedContentsEventData _$PeerSharedContentsEventDataFromJson(
        Map<String, dynamic> json) =>
    PeerSharedContentsEventData(
      peer: json['peer'] as String,
      data: const Base64DataConverter().fromJson(json['data'] as String),
      elapsedMillis: (json['elapsedMillis'] as num).toInt(),
    );

PeersSharedContentsSetEvent _$PeersSharedContentsSetEventFromJson(
        Map<String, dynamic> json) =>
    PeersSharedContentsSetEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      (json['contents'] as List<dynamic>)
          .map((e) =>
              PeerSharedContentsEventData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

PeersSharedContentsUnsetEvent _$PeersSharedContentsUnsetEventFromJson(
        Map<String, dynamic> json) =>
    PeersSharedContentsUnsetEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      (json['peers'] as List<dynamic>).map((e) => e as String).toList(),
    );

PeerExclusivelySharedContentsSetEvent
    _$PeerExclusivelySharedContentsSetEventFromJson(
            Map<String, dynamic> json) =>
        PeerExclusivelySharedContentsSetEvent(
          const EventTypeConverter().fromJson((json['type'] as num).toInt()),
          json['id'] as String,
          const ConferenceEventTypeConverter()
              .fromJson((json['subType'] as num).toInt()),
          json['peer'] as String,
          const Base64DataConverter().fromJson(json['data'] as String),
          (json['elapsedMillis'] as num).toInt(),
        );

PeerExclusivelySharedContentsUnsetEvent
    _$PeerExclusivelySharedContentsUnsetEventFromJson(
            Map<String, dynamic> json) =>
        PeerExclusivelySharedContentsUnsetEvent(
          const EventTypeConverter().fromJson((json['type'] as num).toInt()),
          json['id'] as String,
          const ConferenceEventTypeConverter()
              .fromJson((json['subType'] as num).toInt()),
          json['peer'] as String,
        );

PeerRoomSharedContentsSetEvent _$PeerRoomSharedContentsSetEventFromJson(
        Map<String, dynamic> json) =>
    PeerRoomSharedContentsSetEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      json['userId'] as String,
      json['serviceId'] as String,
      const Base64DataConverter().fromJson(json['data'] as String),
      (json['elapsedMillis'] as num).toInt(),
    );

PeerRoomSharedContentsUnsetEvent _$PeerRoomSharedContentsUnsetEventFromJson(
        Map<String, dynamic> json) =>
    PeerRoomSharedContentsUnsetEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      json['userId'] as String,
      json['serviceId'] as String,
    );

ShortDataReceivedEvent _$ShortDataReceivedEventFromJson(
        Map<String, dynamic> json) =>
    ShortDataReceivedEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      json['userId'] as String,
      json['serviceId'] as String,
      json['dataType'] as String,
      const Base64DataConverter().fromJson(json['data'] as String),
    );

DataSessionIncomingEvent _$DataSessionIncomingEventFromJson(
        Map<String, dynamic> json) =>
    DataSessionIncomingEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      (json['streamId'] as num).toInt(),
      (json['dataSessionType'] as num).toInt(),
    );

DataSessionInboundReceivedEvent _$DataSessionInboundReceivedEventFromJson(
        Map<String, dynamic> json) =>
    DataSessionInboundReceivedEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
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
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      (json['streamId'] as num).toInt(),
      (json['closedReason'] as num).toInt(),
    );

DataSessionOutboundClosedEvent _$DataSessionOutboundClosedEventFromJson(
        Map<String, dynamic> json) =>
    DataSessionOutboundClosedEvent(
      const EventTypeConverter().fromJson((json['type'] as num).toInt()),
      json['id'] as String,
      const ConferenceEventTypeConverter()
          .fromJson((json['subType'] as num).toInt()),
      (json['streamId'] as num).toInt(),
      (json['closedReason'] as num).toInt(),
    );

DataSessionOutboundTooLongQueuedDataEvent
    _$DataSessionOutboundTooLongQueuedDataEventFromJson(
            Map<String, dynamic> json) =>
        DataSessionOutboundTooLongQueuedDataEvent(
          const EventTypeConverter().fromJson((json['type'] as num).toInt()),
          json['id'] as String,
          const ConferenceEventTypeConverter()
              .fromJson((json['subType'] as num).toInt()),
          (json['streamId'] as num).toInt(),
          json['enabled'] as bool,
        );
