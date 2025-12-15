// Copyright 2024 LINE Plus Corporation
//
// LINE Plus Corporation licenses this file to you under the Apache License,
// version 2.0 (the "License"); you may not use this file except in compliance
// with the License. You may obtain a copy of the License at:
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

import Flutter
import PlanetKit

protocol PluginInstance {
    var instanceId: String { get }
}

extension PlanetKitCCParam: PluginInstance {
    var instanceId: String {
        return "\(Unmanaged<AnyObject>.passUnretained(self).toOpaque())"
    }
}


public class PlanetKitFlutterPlugin: NSObject, FlutterPlugin {
    static let planetKitFlutterVersion = "1.1.0"
    var registrar: FlutterPluginRegistrar?
    let eventStreamHandler = PlanetKitFlutterStreamHandler()
    let backgroundEventStreamHandler = PlanetKitFlutterStreamHandler()
    let hookedAudioStreamHandler = PlanetKitFlutterStreamHandler()
    let nativeInstances = PlanetKitFlutterNativeInstances()
    
    lazy var hookedAudioPlugin: PlanetKitFlutterHookedAudioPlugin = {
        PlanetKitFlutterHookedAudioPlugin(nativeInstances: nativeInstances, hookedAudioStreamHandler: hookedAudioStreamHandler)
    }()
    
    lazy var callPlugin: PlanetKitFlutterCallPlugin = {
        PlanetKitFlutterCallPlugin(nativeInstances: nativeInstances, eventStreamHandler: eventStreamHandler, backgroundEventStreamHandler: backgroundEventStreamHandler)
    }()
    
    lazy var myMediaStatusPlugin: PlanetKitFlutterMyMediaStatusPlugin = {
        PlanetKitFlutterMyMediaStatusPlugin(nativeInstances: nativeInstances, eventStreamHandler: eventStreamHandler)
    }()
    
    lazy var conferencePlugin: PlanetKitFlutterConferencePlugin = {
        PlanetKitFlutterConferencePlugin(nativeInstances: nativeInstances, eventStreamHandler: eventStreamHandler)
    }()
    
    lazy var conferencePeerPlugin: PlanetKitFlutterConferencePeerPlugin = {
        PlanetKitFlutterConferencePeerPlugin(nativeInstances: nativeInstances, eventStreamHandler: eventStreamHandler)
    }()
    
    lazy var peerControlPlugin: PlanetKitFlutterPeerControlPlugin = {
        PlanetKitFlutterPeerControlPlugin(nativeInstances: nativeInstances, eventStreamHandler: eventStreamHandler)
    }()
    
    lazy var cameraPlugin: PlanetKitFlutterCameraPlugin = {
        PlanetKitFlutterCameraPlugin(eventStreamHandler: eventStreamHandler)
    }()

    lazy var videoViewPlugin: PlanetKitFlutterVideoViewPlugin = {
        PlanetKitFlutterVideoViewPlugin()
    }()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        NSLog("\(#function)")
        let messenger = registrar.messenger()
        let channel = FlutterMethodChannel(name: "planetkit_sdk", binaryMessenger: messenger)
        let instance = PlanetKitFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.registrar = registrar

        FlutterEventChannel(name: "planetkit_event", binaryMessenger: messenger).setStreamHandler(instance.eventStreamHandler)
        FlutterEventChannel(name: "planetkit_hooked_audio", binaryMessenger: messenger).setStreamHandler(instance.hookedAudioStreamHandler)
        FlutterEventChannel(name: "planetkit_background_event", binaryMessenger: messenger).setStreamHandler(instance.backgroundEventStreamHandler)

        let factory = PlanetKitVideoViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "planet_kit_video_view")
        
        instance.listenForOrientationChange()
    }
    
    // TODO: separate handler by features
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "initializePlanetKit":
            initializePlanetKit(call: call, result: result)
        case "makeCall":
            makeCall(call: call, result: result)
            break
        case "verifyCall":
            verifyCall(call: call, result: result)
            break
        case "verifyBackgroundCall":
            verifyBackgroundCall(call: call, result: result)
            break
        case "joinConference":
            joinConference(call: call, result: result)
            break
        case "releaseInstance":
            releaseInstance(call: call, result: result)
            break
        case "createCcParam":
            createCcParam(call: call, result: result)
            break
        case "setServerUrl":
            setServerUrl(call: call, result: result)
            break
        case "adoptBackgroundCall":
            adoptBackgroundCall(call: call, result: result)
            break
            
        case "call_enableHookMyAudio":
            hookedAudioPlugin.enableHookMyAudio(call: call, result: result)
            break
        case "call_disableHookMyAudio":
            hookedAudioPlugin.disableHookMyAudio(call: call, result: result)
            break
        case "call_putHookedMyAudioBack":
            hookedAudioPlugin.putHookedMyAudioBack(call: call, result: result)
            break
        case "call_isHookMyAudioEnabled":
            hookedAudioPlugin.isHookMyAudioEnabled(call: call, result: result)
            break
        case "call_setHookedAudioData":
            hookedAudioPlugin.setHookedAudioData(call: call, result: result)
            break
            
            // MARK: call
        case "call_acceptCall":
            callPlugin.acceptCall(call: call, result: result)
        case "call_endCall":
            callPlugin.endCall(call: call, result: result)
            break
        case "call_endCallWithError":
            callPlugin.endCallWithError(call: call, result: result)
            break
        case "call_muteMyAudio":
            callPlugin.muteMyAudio(call: call, result: result)
            break
        case "call_speakerOut":
            callPlugin.speakerOut(call: call, result: result)
            break
        case "call_isSpeakerOut":
            callPlugin.isSpeakerOut(call: call, result: result)
            break
        case "call_isMyAudioMuted":
            callPlugin.isMyAudioMuted(call: call, result: result)
            break
        case "call_isPeerAudioMuted":
            callPlugin.isPeerAudioMuted(call: call, result: result)
            break
        case "call_notifyCallKitAudioActivation":
            callPlugin.notifyCallKitAudioActivation(call: call, result: result)
            break
        case "call_finishPreparation":
            callPlugin.finishPreparation(call: call, result: result)
            break
        case "call_holdCall":
            callPlugin.hold(call: call, result: result)
            break
        case "call_unholdCall":
            callPlugin.unhold(call: call, result: result)
            break
        case "call_isOnHold":
            callPlugin.isOnHold(call: call, result: result)
            break
        case "call_requestPeerMute":
            callPlugin.requestPeerMute(call: call, result: result)
            break
        case "call_getMyMediaStatus":
            callPlugin.getMyMediaStatus(call: call, delegate: myMediaStatusPlugin, result: result)
            break
        case "call_silencePeerAudio":
            callPlugin.silencePeerAudio(call: call, result: result)
            break
        case "call_addMyVideoView":
            callPlugin.addMyVideoView(call: call, result: result)
            break
        case "call_removeMyVideoView":
            callPlugin.removeMyVideoView(call: call, result: result)
            break
        case "call_addPeerVideoView":
            callPlugin.addPeerVideoView(call: call, result: result)
            break
        case "call_removePeerVideoView":
            callPlugin.removePeerVideoView(call: call, result: result)
            break
        case "call_pauseMyVideo":
            callPlugin.pauseMyVideo(call: call, result: result)
            break
        case "call_resumeMyVideo":
            callPlugin.resumeMyVideo(call: call, result: result)
            break
        case "call_enableVideo":
            callPlugin.enableVideo(call: call, result: result)
            break
        case "call_disableVideo":
            callPlugin.disableVideo(call: call, result: result)
            break
        case "call_getStatistics":
            callPlugin.getStatistics(call: call, result: result)
            break
        case "call_addPeerScreenShareView":
            callPlugin.addPeerScreenShareView(call: call, result: result)
            break
        case "call_removePeerScreenShareView":
            callPlugin.removePeerScreenShareView(call: call, result: result)
            break
            
            // MARK: my media status
        case "myMediaStatus_isMyAudioMuted":
            myMediaStatusPlugin.isMyAudioMutedMyMediaStatus(call: call, result: result)
            break
        case "myMediaStatus_getMyVideoStatus":
            myMediaStatusPlugin.getMyVideoStatus(call: call, result: result)
            break
            
            
            // MARK: conference
        case "conference_leaveConference":
            conferencePlugin.leaveConference(call: call, result: result)
            break
        case "conference_muteMyAudio":
            conferencePlugin.muteMyAudio(call: call, result: result)
            break
        case "conference_speakerOut":
            conferencePlugin.speakerOut(call: call, result: result)
            break
        case "conference_isSpeakerOut":
            conferencePlugin.isSpeakerOut(call: call, result: result)
            break
        case "conference_notifyCallKitAudioActivation":
            conferencePlugin.notifyCallKitAudioActivation(call: call, result: result)
            break
        case "conference_silencePeersAudio":
            conferencePlugin.silencePeersAudio(call: call, result: result)
            break
        case "conference_requestPeerMute":
            conferencePlugin.requestPeerMute(call: call, result: result)
            break
        case "conference_requestPeersMute":
            conferencePlugin.requestPeersMute(call: call, result: result)
            break
        case "conference_hold":
            conferencePlugin.hold(call: call, result: result)
            break
        case "conference_unhold":
            conferencePlugin.unhold(call: call, result: result)
            break
        case "conference_isOnHold":
            conferencePlugin.isOnHold(call: call, result: result)
            break
        case "conference_getMyMediaStatus":
            conferencePlugin.getMyMediaStatus(call: call, delegate: myMediaStatusPlugin, result: result)
            break
        case "conference_isPeersAudioSilenced":
            conferencePlugin.isPeersAudioSilenced(call: call, result: result)
            break
        case "conference_createPeerControl":
            conferencePlugin.createPeerControl(call: call, delegate: peerControlPlugin, result: result)
            break
        case "conference_addMyVideoView":
            conferencePlugin.addMyVideoView(call: call, result: result)
            break
        case "conference_removeMyVideoView":
            conferencePlugin.removeMyVideoView(call: call, result: result)
            break
        case "conference_enableVideo":
            conferencePlugin.enableVideo(call: call, result: result)
            break
        case "conference_disableVideo":
            conferencePlugin.disableVideo(call: call, result: result)
            break
        case "conference_pauseMyVideo":
            conferencePlugin.pauseMyVideo(call: call, result: result)
            break
        case "conference_resumeMyVideo":
            conferencePlugin.resumeMyVideo(call: call, result: result)
            break
        case "conference_getStatistics":
            conferencePlugin.getStatistics(call: call, result: result)
            break
            
            // MARK: conference peer
        case "conferencePeer_getVideoStatus":
            conferencePeerPlugin.getVideoStatus(call: call, result: result)
            break
        case "conferencePeer_getHoldStatus":
            conferencePeerPlugin.getHoldStatus(call: call, result: result)
            break
        case "conferencePeer_isMuted":
            conferencePeerPlugin.isMuted(call: call, result: result)
            break
        case "conferencePeer_getScreenShareState":
            conferencePeerPlugin.getScreenShareState(call: call, result: result)
            break

            
            // MARK: peer control
        case "peerControl_register":
            peerControlPlugin.register(call: call, result: result)
            break
        case "peerControl_unregister":
            peerControlPlugin.unregister(call: call, result: result)
            break
        case "peerControl_startVideo":
            peerControlPlugin.startVideo(call: call, result: result)
            break
        case "peerControl_stopVideo":
            peerControlPlugin.stopVideo(call: call, result: result)
            break
        case "peerControl_startScreenShare":
            peerControlPlugin.startScreenShare(call: call, result: result)
            break
        case "peerControl_stopScreenShare":
            peerControlPlugin.stopScreenShare(call: call, result: result)
            break
            
            // MARK: camera
        case "camera_startPreview":
            cameraPlugin.startPreview(call: call, result: result)
            break
        case "camera_stopPreview":
            cameraPlugin.stopPreview(call: call, result: result)
            break
        case "camera_switchPosition":
            cameraPlugin.switchPosition(call: call, result: result)
            break
        case "camera_setVirtualBackgroundWithImage":
            cameraPlugin.setVirtualBackgroundWithImage(call: call, result: result)
            break
        case "camera_setVirtualBackgroundWithBlur":
            cameraPlugin.setVirtualBackgroundWithBlur(call: call, result: result)
            break
        case "camera_clearVirtualBackground":
            cameraPlugin.clearVirtualBackground(call: call, result: result)
            break
            
        case "videoView_disposeVideoView":
            videoViewPlugin.disposeVideoView(call: call, result: result)
            break
        default:
            NSLog("#flutter unknown call method \(call.method)")
            result(FlutterMethodNotImplemented)
        }
    }
    
    deinit {
        cameraPlugin.removeCameraDelegate()
    }
    
    private func initializePlanetKit(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let args = call.arguments as! Dictionary<String, Any>
        let jsonData = try! JSONSerialization.data(withJSONObject: args, options: [])
        let param = try! JSONDecoder().decode(InitParam.self, from: jsonData)

        PlanetKitLog.v("\(#function) \(param)")
        
        var settingsBuilder = PlanetKitInitialSettingBuilder()
        
        if let logSetting = param.logSetting {
            settingsBuilder = settingsBuilder.withEnableKitLogKey(level: PlanetKitLogLevel(rawValue: Int32(logSetting.logLevel)) ?? .simple, enable: logSetting.enabled, logSize: PlanetKitLogSizeLimit(rawValue: logSetting.logSizeLimit) ?? .medium)
            PlanetKitLog.v("#flutter \(#function) plugin logSetting: \(logSetting)")
        }
        
        if let serverUrl = param.serverUrl {
            settingsBuilder = settingsBuilder.withSetKitServerKey(serverUrl: serverUrl)
            PlanetKitLog.v("#flutter \(#function) plugin serverUrl: \(serverUrl)")
        }
        
        UserDefaults.standard.setValue(PlanetKitFlutterPlugin.planetKitFlutterVersion, forKey: "com.linecorp.planetkit.flutter.version")
        
        PlanetKitManager.shared.initialize(initialSettings: settingsBuilder.build())
        
        cameraPlugin.addCameraDelegate()
        PlanetKitLog.v("#flutter \(#function) args: \(args) complete")
        result(true)
    }
    
    func makeCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: MakeCallParam.self)

        
        let myPlanetKitUserId: PlanetKitUserId = {
            guard let planetKitUserId = PlanetKitUserId(id: param.myUserId, serviceId: param.myServiceId, country: param.myCountryCode) else {
                return PlanetKitUserId(id: param.myUserId, serviceId: param.myServiceId);
            }
            return planetKitUserId
        }()
        
        let peerPlanetKitUserId: PlanetKitUserId = {
            guard let planetKitUserId = PlanetKitUserId(id: param.peerUserId, serviceId: param.peerServiceId, country: param.peerCountryCode) else {
                return PlanetKitUserId(id: param.peerUserId, serviceId: param.peerServiceId);
            }
            return planetKitUserId
        }()
        
        // Regular makeCall uses the plugin instance directly (no broadcaster)
        let makeCallParam = PlanetKitCallParam(myUserId: myPlanetKitUserId, peerUserId: peerPlanetKitUserId, delegate: callPlugin, accessToken: param.accessToken)
        
        makeCallParam.useResponderPreparation = param.useResponderPreparation
        makeCallParam.mediaType = param.mediaType
        makeCallParam.initialMyVideoState = param.initialMyVideoState
        
        var settings = PlanetKitMakeCallSettingBuilder()
        
        if let callKitType = param.callKitType {
            let callKitSetting = PlanetKitCallKitSetting(type: callKitType, param: nil)
            settings = settings.withCallKitSettingsKey(setting: callKitSetting)
        }
        
        if let holdTonePath = param.holdTonePath, let key = registrar?.lookupKey(forAsset: holdTonePath), let url = Bundle.main.url(forResource: key, withExtension: nil), let resultSettings = try?  settings.withSetHoldToneKey(fileResourceUrl: url) {
            PlanetKitLog.i("#flutter \(#function) hold url set")
            settings = resultSettings
        }
        
        if let ringbackTonePath = param.ringbackTonePath, let key = registrar?.lookupKey(forAsset: ringbackTonePath), let url = Bundle.main.url(forResource: key, withExtension: nil), let resultSettings = try?  settings.withSetRingbackToneKey(fileResourceUrl: url) {
            PlanetKitLog.i("#flutter \(#function) ringbacktone url set")
            settings = resultSettings
        }
        
        if let endTonePath = param.endTonePath, let key = registrar?.lookupKey(forAsset: endTonePath), let url = Bundle.main.url(forResource: key, withExtension: nil), let resultSettings = try?  settings.withSetEndToneKey(fileResourceUrl: url) {
            PlanetKitLog.v("#flutter \(#function) endtone url set")
            settings = resultSettings
        }
        
        if let allowCallWithoutMic = param.allowCallWithoutMic {
            PlanetKitLog.v("#flutter \(#function) allowCallWithoutMic: \(allowCallWithoutMic)")
            settings = settings.withAllowCallWithoutMicKey(allow: allowCallWithoutMic)
        }
        
        if let enableAudioDescription = param.enableAudioDescription {
            PlanetKitLog.v("#flutter \(#function) enableAudioDescription: \(enableAudioDescription)")
            settings = settings.withEnableAudioDescriptionKey(enable: enableAudioDescription)
        }
        
        if let audioDescriptionUpdateIntervalMs = param.audioDescriptionUpdateIntervalMs {
            PlanetKitLog.v("#flutter \(#function) audioDescriptionUpdateIntervalMs: \(audioDescriptionUpdateIntervalMs)")
            let interval = TimeInterval(audioDescriptionUpdateIntervalMs) / 1000.0
            settings = settings.withAudioDescriptionUpdateIntervalKey(interval: interval)
        }
        
        if let screenShareKey = param.screenShareKey {
            PlanetKitLog.v("#flutter \(#function) screenShareKey: \(screenShareKey)")
            settings = settings.withEnableScreenShareKey(broadcastPort: UInt16(screenShareKey.broadcastPort), broadcastPeerToken: screenShareKey.broadcastPeerToken, broadcastMyToken: screenShareKey.broadcastMyToken)
        }
        
        settings = settings.withResponseOnEnableVideo(response: param.responseOnEnableVideo)
        settings = settings.withEnableStatisticsKey(enable: param.enableStatistics)

        
        let makeCallResult = PlanetKitManager.shared.makeCall(param: makeCallParam, settings: settings.build())
        
        
        if makeCallResult.reason == .none, let planetKitCall = makeCallResult.call {
            nativeInstances.add(key: planetKitCall.instanceId, instance: planetKitCall)
            
            if let enableAudioDescription = param.enableAudioDescription {
                PlanetKitLog.v("#flutter \(#function) enableAudioDescription: \(enableAudioDescription)")
                settings = settings.withEnableAudioDescriptionKey(enable: enableAudioDescription)
                callPlugin.setPeerAudioDescriptionDelegate(call: planetKitCall)
            }
        }
        
                
        let response = MakeCallResponse(callId: makeCallResult.call?.instanceId, failReason: makeCallResult.reason)
        let encodedResponse = PlanetKitFlutterPlugin.encode(data: response)
        
        PlanetKitLog.v("#flutter \(#function) response: \(encodedResponse)")
        result(encodedResponse)
    }
    
    func verifyCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: VerifyCallParam.self)
        let myPlanetKitUserId = PlanetKitUserId(id: param.myUserId, serviceId: param.myServiceId)

        guard let ccParam = nativeInstances.get(key: param.ccParam.id) as? PlanetKitCCParam else {
            PlanetKitLog.e("#flutter \(#function) failed to get cc param")
            let response = VerifyCallResponse(callId: nil, failReason: .invalidParam)
            let encodedResponse = PlanetKitFlutterPlugin.encode(data: response)
            result(response)
            return
        }
        
        var settings = PlanetKitVerifyCallSettingBuilder()
        
        if let callKitType = param.callKitType {
            let callKitSetting = PlanetKitCallKitSetting(type: callKitType, param: nil)
            settings = settings.withCallKitSettingsKey(setting: callKitSetting)
        }
        
        if let holdTonePath = param.holdTonePath, let key = registrar?.lookupKey(forAsset: holdTonePath), let url = Bundle.main.url(forResource: key, withExtension: nil), let resultSettings = try?  settings.withSetHoldToneKey(fileResourceUrl: url) {
            PlanetKitLog.v("#flutter \(#function) hold url set")
            settings = resultSettings
        }
        
        if let ringbackTonePath = param.ringtonePath, let key = registrar?.lookupKey(forAsset: ringbackTonePath), let url = Bundle.main.url(forResource: key, withExtension: nil), let resultSettings = try?  settings.withSetRingToneKey(fileResourceUrl: url) {
            PlanetKitLog.v("#flutter \(#function) ringtone url set")
            settings = resultSettings
        }
        
        if let endTonePath = param.endTonePath, let key = registrar?.lookupKey(forAsset: endTonePath), let url = Bundle.main.url(forResource: key, withExtension: nil), let resultSettings = try? settings.withSetEndToneKey(fileResourceUrl: url) {
            PlanetKitLog.v("#flutter \(#function) endtone url set")
            settings = resultSettings
        }
        
        if let allowCallWithoutMic = param.allowCallWithoutMic {
            PlanetKitLog.v("#flutter \(#function) allowCallWithoutMic: \(allowCallWithoutMic)")
            settings = settings.withAllowCallWithoutMicKey(allow: allowCallWithoutMic)
        }
        
        if let enableAudioDescription = param.enableAudioDescription {
            PlanetKitLog.v("#flutter \(#function) enableAudioDescription: \(enableAudioDescription)")
            settings = settings.withEnableAudioDescriptionKey(enable: enableAudioDescription)
        }
        
        if let audioDescriptionUpdateIntervalMs = param.audioDescriptionUpdateIntervalMs {
            PlanetKitLog.v("#flutter \(#function) audioDescriptionUpdateIntervalSec: \(audioDescriptionUpdateIntervalMs)")
            let interval = TimeInterval(audioDescriptionUpdateIntervalMs) / 1000.0
            settings = settings.withAudioDescriptionUpdateIntervalKey(interval: interval)
        }
        
        if let screenShareKey = param.screenShareKey {
            PlanetKitLog.v("#flutter \(#function) screenShareKey: \(screenShareKey)")
            settings = settings.withEnableScreenShareKey(broadcastPort: UInt16(screenShareKey.broadcastPort), broadcastPeerToken: screenShareKey.broadcastPeerToken, broadcastMyToken: screenShareKey.broadcastMyToken)
        }
        
        settings = settings.withResponseOnEnableVideo(response: param.responseOnEnableVideo)
        settings = settings.withEnableStatisticsKey(enable: param.enableStatistics)

        // Regular verifyCall uses the plugin instance directly (no broadcaster)
        let verifyCallResult = PlanetKitManager.shared.verifyCall(myUserId: myPlanetKitUserId, ccParam: ccParam, settings: settings.build(), delegate: callPlugin)
        
        if verifyCallResult.reason == .none, let planetKitCall = verifyCallResult.call {
            nativeInstances.add(key: planetKitCall.instanceId, instance: planetKitCall)
            if let enableAudioDescription = param.enableAudioDescription {
                PlanetKitLog.v("#flutter \(#function) enableAudioDescription: \(enableAudioDescription)")
                settings = settings.withEnableAudioDescriptionKey(enable: enableAudioDescription)
                callPlugin.setPeerAudioDescriptionDelegate(call: planetKitCall)
            }
        }
        
        let response = VerifyCallResponse(callId: verifyCallResult.call?.instanceId, failReason: verifyCallResult.reason)
        let encodedResponse = PlanetKitFlutterPlugin.encode(data: response)

        PlanetKitLog.v("#flutter \(#function) response: \(encodedResponse)")
        result(encodedResponse)
    }

    func verifyBackgroundCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: VerifyCallParam.self)
        let myPlanetKitUserId = PlanetKitUserId(id: param.myUserId, serviceId: param.myServiceId)

        guard let ccParam = nativeInstances.get(key: param.ccParam.id) as? PlanetKitCCParam else {
            PlanetKitLog.e("#flutter \(#function) failed to get cc param")
            let response = VerifyCallResponse(callId: nil, failReason: .invalidParam)
            let encodedResponse = PlanetKitFlutterPlugin.encode(data: response)
            result(encodedResponse)
            return
        }

        var settings = PlanetKitVerifyCallSettingBuilder()

        if let callKitType = param.callKitType {
            let callKitSetting = PlanetKitCallKitSetting(type: callKitType, param: nil)
            settings = settings.withCallKitSettingsKey(setting: callKitSetting)
        }

        if let holdTonePath = param.holdTonePath, let key = registrar?.lookupKey(forAsset: holdTonePath), let url = Bundle.main.url(forResource: key, withExtension: nil), let resultSettings = try?  settings.withSetHoldToneKey(fileResourceUrl: url) {
            PlanetKitLog.v("#flutter \(#function) hold url set")
            settings = resultSettings
        }

        if let ringTonePath = param.ringtonePath, let key = registrar?.lookupKey(forAsset: ringTonePath), let url = Bundle.main.url(forResource: key, withExtension: nil), let resultSettings = try?  settings.withSetRingToneKey(fileResourceUrl: url) {
            PlanetKitLog.v("#flutter \(#function) ringtone url set")
            settings = resultSettings
        }

        if let endTonePath = param.endTonePath, let key = registrar?.lookupKey(forAsset: endTonePath), let url = Bundle.main.url(forResource: key, withExtension: nil), let resultSettings = try? settings.withSetEndToneKey(fileResourceUrl: url) {
            PlanetKitLog.v("#flutter \(#function) endtone url set")
            settings = resultSettings
        }

        if let allowCallWithoutMic = param.allowCallWithoutMic {
            PlanetKitLog.v("#flutter \(#function) allowCallWithoutMic: \(allowCallWithoutMic)")
            settings = settings.withAllowCallWithoutMicKey(allow: allowCallWithoutMic)
        }

        if let enableAudioDescription = param.enableAudioDescription {
            PlanetKitLog.v("#flutter \(#function) enableAudioDescription: \(enableAudioDescription)")
            settings = settings.withEnableAudioDescriptionKey(enable: enableAudioDescription)
        }

        if let audioDescriptionUpdateIntervalMs = param.audioDescriptionUpdateIntervalMs {
            PlanetKitLog.v("#flutter \(#function) audioDescriptionUpdateIntervalMs: \(audioDescriptionUpdateIntervalMs)")
            let interval = TimeInterval(audioDescriptionUpdateIntervalMs) / 1000.0
            settings = settings.withAudioDescriptionUpdateIntervalKey(interval: interval)
        }

        if let screenShareKey = param.screenShareKey {
            PlanetKitLog.v("#flutter \(#function) screenShareKey: \(screenShareKey)")
            settings = settings.withEnableScreenShareKey(broadcastPort: UInt16(screenShareKey.broadcastPort), broadcastPeerToken: screenShareKey.broadcastPeerToken, broadcastMyToken: screenShareKey.broadcastMyToken)
        }

        settings = settings.withResponseOnEnableVideo(response: param.responseOnEnableVideo)
        settings = settings.withEnableStatisticsKey(enable: param.enableStatistics)

        // IMPORTANT: Use the global broadcaster for background-verified calls
        // Flow: 1) Background engine: broadcaster → background plugin
        //       2) After adoptBackgroundCall(): broadcaster → foreground plugin  
        //       3) After acceptCall(): foreground plugin directly (no broadcaster)
        let verifyCallResult = PlanetKitManager.shared.verifyCall(myUserId: myPlanetKitUserId, ccParam: ccParam, settings: settings.build(), delegate: PlanetKitFlutterCallDelegateBroadcaster.shared)

        if verifyCallResult.reason == .none, let planetKitCall = verifyCallResult.call {
            // Keep in background pool; do not add to active nativeInstances yet
            callPlugin.addBackgroundCall(planetKitCall)
        }

        let response = VerifyCallResponse(callId: verifyCallResult.call?.instanceId, failReason: verifyCallResult.reason)
        let encodedResponse = PlanetKitFlutterPlugin.encode(data: response)
        PlanetKitLog.v("#flutter \(#function) response: \(encodedResponse)")
        result(encodedResponse)
    }

    // MARK: Background call adoption
    func adoptBackgroundCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        let callId = call.arguments as! String
        let adopted = callPlugin.adoptBackgroundCall(callId: callId, nativeInstances: nativeInstances)
        result(adopted)
    }
    
    func joinConference(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let param = PlanetKitFlutterPlugin.decodeMethodCallArg(call: call, codable: ConferenceParams.JoinConferenceParam.self)
        let myPlanetKitUserId = PlanetKitUserId(id: param.myUserId, serviceId: param.myServiceId)
        
        let joinConferenceParam = PlanetKitConferenceParam(myUserId: myPlanetKitUserId, roomId: param.roomId, roomServiceId: param.roomServiceId, displayName: nil, delegate: conferencePlugin, accessToken: param.accessToken)
        
        joinConferenceParam.mediaType = param.mediaType
        joinConferenceParam.initialMyVideoState = param.initialMyVideoState
        
        var settings = PlanetKitJoinConferenceSettingBuilder()

        if let endTonePath = param.endTonePath, let key = registrar?.lookupKey(forAsset: endTonePath), let url = Bundle.main.url(forResource: key, withExtension: nil), let resultSettings = try? settings.withSetEndToneKey(fileResourceUrl: url) {
            PlanetKitLog.v("#flutter \(#function) endtone url set")
            settings = resultSettings
        }
        
        if let allowConferenceWithoutMic = param.allowConferenceWithoutMic {
            PlanetKitLog.v("#flutter \(#function) allowConferenceWithoutMic: \(allowConferenceWithoutMic)")
            settings = settings.withAllowConferenceWithoutMicKey(allow: allowConferenceWithoutMic)
        }
        
        if let enableAudioDescription = param.enableAudioDescription {
            PlanetKitLog.v("#flutter \(#function) enableAudioDescription: \(enableAudioDescription)")
            settings = settings.withEnableAudioDescriptionKey(enable: enableAudioDescription)
        }
        
        if let audioDescriptionUpdateIntervalMs = param.audioDescriptionUpdateIntervalMs {
            PlanetKitLog.v("#flutter \(#function) audioDescriptionUpdateIntervalSec: \(audioDescriptionUpdateIntervalMs)")
            let interval = TimeInterval(audioDescriptionUpdateIntervalMs) / 1000.0
            settings = settings.withAudioDescriptionUpdateIntervalKey(interval: interval)
        }
        
        if let screenShareKey = param.screenShareKey {
            PlanetKitLog.v("#flutter \(#function) screenShareKey: \(screenShareKey)")
            settings = settings.withEnableScreenShareKey(broadcastPort: UInt16(screenShareKey.broadcastPort), broadcastPeerToken: screenShareKey.broadcastPeerToken, broadcastMyToken: screenShareKey.broadcastMyToken)
        }
        
        settings = settings.withEnableStatisticsKey(enable: param.enableStatistics)
        
        let joinConferenceResult = PlanetKitManager.shared.joinConference(param: joinConferenceParam, settings: settings.build())
        
        if joinConferenceResult.reason == .none, let conference = joinConferenceResult.conference {
            nativeInstances.add(key: conference.instanceId, instance: conference)
        }
        
        let response = JoinConferenceResponse(id: joinConferenceResult.conference?.instanceId, failReason: joinConferenceResult.reason)
        let encodedResponse = PlanetKitFlutterPlugin.encode(data: response)

        PlanetKitLog.v("#flutter \(#function) response: \(encodedResponse)")
        result(encodedResponse)
    }

    static func decodeMethodCallArg<T: Decodable>(call: FlutterMethodCall, codable: T.Type) -> T {
        let args = call.arguments as! Dictionary<String, Any>
        let jsonData = try! JSONSerialization.data(withJSONObject: args, options: [])
        let param = try! JSONDecoder().decode(T.self, from: jsonData)
        return param
    }
    
    static func encode<T: Encodable>(data: T) -> String {
        let responseJsonData = try! JSONEncoder().encode(data)
        return String(data: responseJsonData, encoding: .utf8)!
    }

    func releaseInstance(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let id = call.arguments as! String
        nativeInstances.remove(key: id)
        result(true)
    }
    
    func createCcParam(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let ccParamString = call.arguments as! String
        guard let ccParam = PlanetKitCCParam(ccParam: ccParamString) else {
            PlanetKitLog.e("#flutter \(#function) failed to create ccparam with \(ccParamString)")
            result(nil)
            return
        }
        
        nativeInstances.add(key: ccParam.instanceId, instance: ccParam)
        
        let response = CreateCcParamResponse(id: ccParam.instanceId, peerId: ccParam.peerId, peerServiceId: ccParam.serviceId, mediaType: ccParam.mediaType)
        
        let encodedResponse = PlanetKitFlutterPlugin.encode(data: response)

        PlanetKitLog.v("#flutter \(#function) response: \(encodedResponse)")
        result(encodedResponse)
    }
    
    func setServerUrl(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let serverUrl = call.arguments as! String
        let initialSettings = PlanetKitInitialSettingBuilder().withSetKitServerKey(serverUrl: serverUrl).build()
        
        PlanetKitManager.shared.update(initialSettings: initialSettings)

        result(true)
    }
}

