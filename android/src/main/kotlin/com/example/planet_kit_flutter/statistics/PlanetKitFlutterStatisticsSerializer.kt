package com.example.planet_kit_flutter.statistics

import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.JsonSerializationContext
import com.google.gson.JsonSerializer
import com.linecorp.planetkit.PlanetKitStatistics
import java.lang.reflect.Type

class PlanetKitStatisticsSerializer : JsonSerializer<PlanetKitStatistics> {
    override fun serialize(
        src: PlanetKitStatistics,
        typeOfSrc: Type,
        context: JsonSerializationContext
    ): JsonElement {
        val jsonObject = JsonObject()
        jsonObject.add("myAudio", context.serialize(src.myAudio))
        jsonObject.add(
            "peersAudio",
            context.serialize(src.peerAudio)
        ) //TODO: set property name equal in both iOS and Android
        jsonObject.add("myVideo", context.serialize(src.myVideo))
        jsonObject.add("peerVideos", context.serialize(src.peersVideo))
        jsonObject.add("myScreenShare", context.serialize(src.myScreenShare))
        jsonObject.add("peerScreenShares", context.serialize(src.peersScreenShare))
        return jsonObject
    }
}

class MyAudioSerializer : JsonSerializer<PlanetKitStatistics.MyAudio> {
    override fun serialize(
        src: PlanetKitStatistics.MyAudio,
        typeOfSrc: Type,
        context: JsonSerializationContext
    ): JsonElement {
        val jsonObject = JsonObject()
        jsonObject.add("network", context.serialize(src.network))
        return jsonObject
    }
}

class NetworkSerializer : JsonSerializer<PlanetKitStatistics.Network> {
    override fun serialize(
        src: PlanetKitStatistics.Network,
        typeOfSrc: Type,
        context: JsonSerializationContext
    ): JsonElement {
        val jsonObject = JsonObject()
        jsonObject.addProperty("lossRate", src.lossRate)
        jsonObject.addProperty("jitterMs", src.jitterMs)
        jsonObject.addProperty("latencyMs", src.latencyMs)
        jsonObject.addProperty("bps", src.bps)
        return jsonObject
    }
}

class MyVideoSerializer : JsonSerializer<PlanetKitStatistics.MyVideo> {
    override fun serialize(
        src: PlanetKitStatistics.MyVideo,
        typeOfSrc: Type,
        context: JsonSerializationContext
    ): JsonElement {
        val jsonObject = JsonObject()
        jsonObject.add("network", context.serialize(src.network))
        jsonObject.add("video", context.serialize(src.video))
        return jsonObject
    }
}

data class UserId(
    val userId: String,
    val serviceId: String
)
class PeerAudioSerializer : JsonSerializer<PlanetKitStatistics.PeerAudio> {
    override fun serialize(
        src: PlanetKitStatistics.PeerAudio,
        typeOfSrc: Type,
        context: JsonSerializationContext
    ): JsonElement {
        val jsonObject = JsonObject()
        jsonObject.add("network", context.serialize(src.network))
        return jsonObject
    }
}

class PeerVideoSerializer : JsonSerializer<PlanetKitStatistics.PeerVideo> {
    override fun serialize(
        src: PlanetKitStatistics.PeerVideo,
        typeOfSrc: Type,
        context: JsonSerializationContext
    ): JsonElement {
        val jsonObject = JsonObject()
        jsonObject.add("peerId", context.serialize(UserId(src.peerId, src.peerServiceId)))
        jsonObject.addProperty("subgroupName", src.subgroupName)
        jsonObject.add("network", context.serialize(src.network))
        jsonObject.add("video", context.serialize(src.video))
        return jsonObject
    }
}

class MyScreenShareSerializer : JsonSerializer<PlanetKitStatistics.MyScreenShare> {
    override fun serialize(
        src: PlanetKitStatistics.MyScreenShare,
        typeOfSrc: Type,
        context: JsonSerializationContext
    ): JsonElement {
        val jsonObject = JsonObject()
        jsonObject.add("network", context.serialize(src.network))
        jsonObject.add("video", context.serialize(src.video))
        return jsonObject
    }
}

class PeerScreenShareSerializer : JsonSerializer<PlanetKitStatistics.PeerScreenShare> {
    override fun serialize(
        src: PlanetKitStatistics.PeerScreenShare,
        typeOfSrc: Type,
        context: JsonSerializationContext
    ): JsonElement {
        val jsonObject = JsonObject()
        jsonObject.add("peerId", context.serialize(UserId(src.peerId, src.peerServiceId)))
        jsonObject.addProperty("subgroupName", src.subgroupName)
        jsonObject.add("network", context.serialize(src.network))
        jsonObject.add("video", context.serialize(src.video))
        return jsonObject
    }
}

class VideoSerializer : JsonSerializer<PlanetKitStatistics.Video> {
    override fun serialize(
        src: PlanetKitStatistics.Video,
        typeOfSrc: Type,
        context: JsonSerializationContext
    ): JsonElement {
        val jsonObject = JsonObject()
        jsonObject.addProperty("width", src.width)
        jsonObject.addProperty("height", src.height)
        jsonObject.addProperty("fps", src.fps)
        return jsonObject
    }
}