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
import UIKit
import PlanetKit

extension NSObject {
    var instanceId: String {
        return "\(Unmanaged<AnyObject>.passUnretained(self).toOpaque())"
    }
}

public class PlanetKitFlutterPlugin: NSObject, FlutterPlugin {
    var _nativeInstances: [String: Any] = [:]
    let _nativeInstancesLock = NSLock()
    
    let eventStreamHandler = PlanetKitFlutterStreamHandler()
    let interceptedAudioStreamHandler = PlanetKitFlutterStreamHandler()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        NSLog("\(#function)")
        let messenger = registrar.messenger()
        let channel = FlutterMethodChannel(name: "planetkit_sdk", binaryMessenger: messenger)
        let instance = PlanetKitFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        FlutterEventChannel(name: "planetkit_event", binaryMessenger: messenger).setStreamHandler(instance.eventStreamHandler)        
        FlutterEventChannel(name: "planetkit_intercepted_audio", binaryMessenger: messenger).setStreamHandler(instance.interceptedAudioStreamHandler)
    }
    
    func addNativeInstance(key: String, instance: Any) {
        _nativeInstancesLock.lock()
        defer {
            _nativeInstancesLock.unlock()
        }
        _nativeInstances[key] = instance
    }
    
    func removeNativeInstance(key: String) {
        _nativeInstancesLock.lock()
        defer {
            _nativeInstancesLock.unlock()
        }
        _nativeInstances[key] = nil
    }
    
    func getNativeInstance(key: String) -> Any? {
        _nativeInstancesLock.lock()
        defer {
            _nativeInstancesLock.unlock()
        }
        return _nativeInstances[key]
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
        case "acceptCall":
            acceptCall(call: call, result: result)
        case "endCall":
            endCall(call: call, result: result)
            break
        case "muteMyAudio":
            muteMyAudio(call: call, result: result)
            break
        case "unmuteMyAudio":
            unmuteMyAudio(call: call, result: result)
            break
        case "speakerOut":
            speakerOut(call: call, result: result)
            break
        case "isSpeakerOut":
            isSpeakerOut(call: call, result: result)
            break
        case "isMyAudioMuted":
            isMyAudioMuted(call: call, result: result)
            break
        case "isPeerAudioMuted":
            isPeerAudioMuted(call: call, result: result)
            break
        case "releaseInstance":
            releaseInstance(call: call, result: result)
            break
        case "createCcParam":
            createCcParam(call: call, result: result)
            break
        case "enableInterceptMyAudio":
            enableInterceptMyAudio(call: call, result: result)
            break
        case "disableInterceptMyAudio":
            disableInterceptMyAudio(call: call, result: result)
            break
        case "putInterceptedMyAudioBack":
            putInterceptedMyAudioBack(call: call, result: result)
            break
        case "isInterceptMyAudioEnabled":
            isInterceptMyAudioEnabled(call: call, result: result)
            break
        case "setInterceptedAudioData":
            setInterceptedAudioData(call: call, result: result)
            break
        default:
            NSLog("#flutter unknow call method \(call.method)")
            result(FlutterMethodNotImplemented)
        }
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
        
        PlanetKitManager.shared.initialize(initialSettings: settingsBuilder.build())
        
        PlanetKitLog.v("#flutter \(#function) args: \(args) complete")
        result(true)
    }
    
    
    private func decodeMethodCallArg<T: Codable>(call: FlutterMethodCall, codable: T.Type) -> T {
        let args = call.arguments as! Dictionary<String, Any>
        let jsonData = try! JSONSerialization.data(withJSONObject: args, options: [])
        let param = try! JSONDecoder().decode(T.self, from: jsonData)
        return param
    }
    
    private func encode<T: Codable>(data: T) -> String {
        let responseJsonData = try! JSONEncoder().encode(data)
        PlanetKitLog.v("#flutter \(responseJsonData)")
        return String(data: responseJsonData, encoding: .utf8)!
    }
    
    private func makeCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let param = decodeMethodCallArg(call: call, codable: MakeCallParam.self)

        let myPlanetKitUserId = PlanetKitUserId(id: param.myUserId, serviceId: param.myServiceId)
        let peerPlanetKitUserId = PlanetKitUserId(id: param.peerUserId, serviceId: param.peerServiceId)
        let makeCallParam = PlanetKitCallParam(myUserId: myPlanetKitUserId, peerUserId: peerPlanetKitUserId, delegate: self, accessToken: param.accessToken)
        
        
        let makeCallResult = PlanetKitManager.shared.makeCall(param: makeCallParam)
        
        
        if makeCallResult.reason == .none, let planetKitCall = makeCallResult.call {
            addNativeInstance(key: planetKitCall.instanceId, instance: planetKitCall)
        }
                
        let response = MakeCallResponse(callId: makeCallResult.call?.instanceId, failReason: makeCallResult.reason)
        let encodedResponse = encode(data: response)
        
        PlanetKitLog.v("#flutter \(#function) response: \(encodedResponse)")
        result(encodedResponse)
    }
    
    private func verifyCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let param = decodeMethodCallArg(call: call, codable: VerifyCallParam.self)
        let myPlanetKitUserId = PlanetKitUserId(id: param.myUserId, serviceId: param.myServiceId)

        guard let ccParam = getNativeInstance(key: param.ccParam.id) as? PlanetKitCCParam else {
            PlanetKitLog.e("#flutter \(#function) failed to get cc param")
            let response = VerifyCallResponse(callId: nil, failReason: .invalidParam)
            let encodedResponse = encode(data: response)
            result(response)
            return
        }
        
        let verifyCallResult = PlanetKitManager.shared.verifyCall(myUserId: myPlanetKitUserId, ccParam: ccParam, delegate: self)
        if verifyCallResult.reason == .none, let planetKitCall = verifyCallResult.call {
            addNativeInstance(key: planetKitCall.instanceId, instance: planetKitCall)
        }
        
        let response = VerifyCallResponse(callId: verifyCallResult.call?.instanceId, failReason: verifyCallResult.reason)
        let encodedResponse = encode(data: response)

        PlanetKitLog.v("#flutter \(#function) response: \(encodedResponse)")
        result(encodedResponse)
    }

    private func acceptCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let callId = call.arguments as! String
        guard let call = getNativeInstance(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        call.acceptCall(startMessage: nil, useResponderPreparation: false)
        result(true)
    }
    
    private func endCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let callId = call.arguments as! String
        guard let call = getNativeInstance(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        call.endCall()
        result(true)
    }
    
    private func muteMyAudio(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let callId = call.arguments as! String
        guard let call = getNativeInstance(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        call.muteMyAudio(true) { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }
    
    private func unmuteMyAudio(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let callId = call.arguments as! String
        guard let call = getNativeInstance(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        call.muteMyAudio(false) { success in
            if !success {
                PlanetKitLog.e("#flutter \(#function) platform api returned \(success)")
            }
            result(success)
        }
    }
    
    private func speakerOut(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let param = decodeMethodCallArg(call: call, codable: SpeakerOutParam.self)
        
        let callId = param.callId
        guard let call = getNativeInstance(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        call.audioManager.speakerOut(param.speakerOut)
        result(true)
    }
    
    private func isMyAudioMuted(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let callId = call.arguments as! String
        guard let call = getNativeInstance(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        result(call.isMyAudioMuted)
    }
    
    private func isPeerAudioMuted(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let callId = call.arguments as! String
        guard let call = getNativeInstance(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        result(call.isPeerAudioMuted)
    }
    
    private func isSpeakerOut(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let callId = call.arguments as! String
        guard let call = getNativeInstance(key: callId) as? PlanetKitCall else {
            PlanetKitLog.e("#flutter \(#function) call not found \(callId)")
            result(false)
            return
        }
        
        result(call.audioManager.isSpeakerOut)
    }
    
    private func releaseInstance(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")

        let id = call.arguments as! String
        removeNativeInstance(key: id)
        result(true)
    }
    
    private func createCcParam(call: FlutterMethodCall, result: @escaping FlutterResult) {
        PlanetKitLog.v("#flutter \(#function) \(String(describing: call.arguments))")
        
        let ccParamString = call.arguments as! String
        guard let ccParam = PlanetKitCCParam(ccParam: ccParamString) else {
            PlanetKitLog.e("#flutter \(#function) failed to create ccparam with \(ccParamString)")
            result(nil)
            return
        }
        
        addNativeInstance(key: ccParam.instanceId, instance: ccParam)
        result(ccParam.instanceId)
    }
}


extension PlanetKitFlutterPlugin: PlanetKitCallDelegate {
    public func didWaitConnect(_ call: PlanetKit.PlanetKitCall) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            
            let event = CallWaitConnectEventData(id: call.instanceId)
            let encodedEvent = self.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func didConnect(_ call: PlanetKit.PlanetKitCall, connected: PlanetKit.PlanetKitCallConnectedParam) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            
            let event = CallConnectedEventData(id: call.instanceId)
            let encodedEvent = self.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func didDisconnect(_ call: PlanetKit.PlanetKitCall, disconnected: PlanetKit.PlanetKitDisconnectedParam) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function) \(disconnected.reason)")
            let event = CallDisconnectedEventData(id: call.instanceId, disconnectReason: disconnected.reason, disconnectSource: disconnected.source, byRemote: disconnected.byRemote)
            let encodedEvent = self.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func didVerify(_ call: PlanetKit.PlanetKitCall, peerStartMessage: PlanetKit.PlanetKitCallStartMessage?, peerUseResponderPreparation: Bool) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = CallVerifiedEventData(id: call.instanceId)
            let encodedEvent = self.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func didFinishPreparation(_ call: PlanetKit.PlanetKitCall) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
        }
    }
    
    public func peerMicDidMute(_ call: PlanetKitCall) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = CallPeerMicMutedEventData(id: call.instanceId)
            let encodedEvent = self.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
    
    public func peerMicDidUnmute(_ call: PlanetKitCall) {
        DispatchQueue.main.async {
            PlanetKitLog.v("#flutter \(#function)")
            let event = CallPeerMicUnmutedEventData(id: call.instanceId)
            let encodedEvent = self.encode(data: event)
            self.eventStreamHandler.eventSink?(encodedEvent)
        }
    }
}
