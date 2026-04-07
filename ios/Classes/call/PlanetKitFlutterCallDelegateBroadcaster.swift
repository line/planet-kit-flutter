// Copyright 2025 LINE Plus Corporation
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

import Foundation
import PlanetKit

/**
 * Global singleton that implements PlanetKitCallDelegate for background-verified calls.
 * This solves the multi-engine problem where background and foreground Flutter engines
 * have different plugin instances.
 *
 * Usage:
 * - Only used for verifyBackgroundCall() - regular makeCall() and verifyCall() bypass this
 * - Routes events to background plugin while in background engine
 * - Routes events to foreground plugin after adoptBackgroundCall()
 * - After acceptCall() re-registers foreground plugin, this broadcaster is no longer used
 *
 * Note: Does NOT use DispatchQueue.main - delegates are responsible for their own threading
 */
class PlanetKitFlutterCallDelegateBroadcaster: PlanetKitCallDelegate {
    
    // Singleton instance
    static let shared = PlanetKitFlutterCallDelegateBroadcaster()
    
    // Use weak references to avoid retain cycles
    private var delegates: [Weak<PlanetKitCallDelegate>] = []
    private let lock = NSLock()
    
    private init() {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster initialized")
    }
    
    /**
     * Register a delegate to receive events
     */
    func registerDelegate(_ delegate: PlanetKitCallDelegate) {
        lock.lock()
        defer { lock.unlock() }
        
        // Clean up nil references
        delegates.removeAll { $0.value == nil }
        
        // Add if not already present
        if !delegates.contains(where: { $0.value === delegate }) {
            delegates.append(Weak(value: delegate))
            PlanetKitLog.v("#flutter CallDelegateBroadcaster registered delegate, total: \(delegates.count)")
        }
    }
    
    /**
     * Unregister a delegate
     */
    func unregisterDelegate(_ delegate: PlanetKitCallDelegate) {
        lock.lock()
        defer { lock.unlock() }
        
        delegates.removeAll { $0.value === delegate || $0.value == nil }
        PlanetKitLog.v("#flutter CallDelegateBroadcaster unregistered delegate, remaining: \(delegates.count)")
    }
    
    /**
     * Broadcast event to all registered delegates.
     * Each delegate decides whether to handle the event based on call state.
     * Does NOT use DispatchQueue - delegates handle their own threading.
     */
    private func broadcast(_ action: (PlanetKitCallDelegate) -> Void) {
        lock.lock()
        // Clean up nil references
        delegates.removeAll { $0.value == nil }
        let activeDelegates = delegates.compactMap { $0.value }
        lock.unlock()
        
        // Broadcast to all active delegates
        activeDelegates.forEach { delegate in
            action(delegate)
        }
    }
    
    // MARK: - PlanetKitCallDelegate methods - broadcast to all delegates
    
    func didWaitConnect(_ call: PlanetKit.PlanetKitCall) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster didWaitConnect")
        broadcast { $0.didWaitConnect(call) }
    }
    
    func didConnect(_ call: PlanetKit.PlanetKitCall, connected: PlanetKit.PlanetKitCallConnectedParam) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster didConnect")
        broadcast { $0.didConnect(call, connected: connected) }
    }
    
    func didDisconnect(_ call: PlanetKit.PlanetKitCall, disconnected: PlanetKit.PlanetKitDisconnectedParam) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster didDisconnect")
        broadcast { $0.didDisconnect(call, disconnected: disconnected) }
    }
    
    func didVerify(_ call: PlanetKit.PlanetKitCall, peerStartMessage: PlanetKit.PlanetKitCallStartMessage?, peerUseResponderPreparation: Bool) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster didVerify")
        broadcast { $0.didVerify(call, peerStartMessage: peerStartMessage, peerUseResponderPreparation: peerUseResponderPreparation) }
    }
    
    func didFinishPreparation(_ call: PlanetKit.PlanetKitCall) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster didFinishPreparation")
        broadcast { $0.didFinishPreparation(call) }
    }
    
    func peerMicDidMute(_ call: PlanetKitCall) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster peerMicDidMute")
        broadcast { $0.peerMicDidMute?(call) }
    }
    
    func peerMicDidUnmute(_ call: PlanetKitCall) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster peerMicDidUnmute")
        broadcast { $0.peerMicDidUnmute?(call) }
    }
    
    func networkDidUnavailable(_ call: PlanetKitCall, isPeer: Bool, willDisconnected seconds: TimeInterval) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster networkDidUnavailable")
        broadcast { $0.networkDidUnavailable?(call, isPeer: isPeer, willDisconnected: seconds) }
    }
    
    func networkDidReavailable(_ call: PlanetKitCall, isPeer: Bool) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster networkDidReavailable")
        broadcast { $0.networkDidReavailable?(call, isPeer: isPeer) }
    }
    
    func peerDidHold(_ call: PlanetKitCall, reason: String?) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster peerDidHold")
        broadcast { $0.peerDidHold?(call, reason: reason) }
    }
    
    func peerDidUnhold(_ call: PlanetKitCall) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster peerDidUnhold")
        broadcast { $0.peerDidUnhold?(call) }
    }
    
    func myMuteRequestedByPeer(_ call: PlanetKitCall, mute: Bool) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster myMuteRequestedByPeer")
        broadcast { $0.myMuteRequestedByPeer?(call, mute: mute) }
    }
    
    // MARK: Video events
    
    func peerVideoDidPause(_ call: PlanetKitCall, reason: PlanetKitVideoPauseReason) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster peerVideoDidPause")
        broadcast { $0.peerVideoDidPause?(call, reason: reason) }
    }
    
    func peerVideoDidResume(_ call: PlanetKitCall) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster peerVideoDidResume")
        broadcast { $0.peerVideoDidResume?(call) }
    }
    
    func videoEnabledByPeer(_ call: PlanetKitCall) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster videoEnabledByPeer")
        broadcast { $0.videoEnabledByPeer?(call) }
    }
    
    func videoDisabledByPeer(_ call: PlanetKitCall, reason: PlanetKitMediaDisableReason) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster videoDisabledByPeer")
        broadcast { $0.videoDisabledByPeer?(call, reason: reason) }
    }
    
    func didDetectMyVideoNoSource(_ call: PlanetKitCall) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster didDetectMyVideoNoSource")
        broadcast { $0.didDetectMyVideoNoSource?(call) }
    }
    
    // MARK: Screen share events
    
    func didStartMyBroadcast(_ call: PlanetKit.PlanetKitCall) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster didStartMyBroadcast")
        broadcast { $0.didStartMyBroadcast?(call) }
    }
    
    func didFinishMyBroadcast(_ call: PlanetKit.PlanetKitCall) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster didFinishMyBroadcast")
        broadcast { $0.didFinishMyBroadcast?(call) }
    }
    
    func didErrorMyBroadcast(_ call: PlanetKit.PlanetKitCall, error: PlanetKit.PlanetKitScreenShare.BroadcastError) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster didErrorMyBroadcast")
        broadcast { $0.didErrorMyBroadcast?(call, error: error) }
    }
    
    func peerDidStartScreenShare(_ call: PlanetKitCall) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster peerDidStartScreenShare")
        broadcast { $0.peerDidStartScreenShare?(call) }
    }
    
    func peerDidStopScreenShare(_ call: PlanetKitCall, reason: Int32) {
        PlanetKitLog.v("#flutter CallDelegateBroadcaster peerDidStopScreenShare")
        broadcast { $0.peerDidStopScreenShare?(call, reason: reason) }
    }
}

