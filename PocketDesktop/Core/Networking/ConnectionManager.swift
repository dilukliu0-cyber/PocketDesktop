import Foundation
import Combine
import SwiftUI

public enum ConnectionState: String {
    case disconnected = "Disconnected"
    case connecting = "Connecting..."
    case authenticating = "Verifying Computer..."
    case connected = "Connected"
    case reconnecting = "Reconnecting..."
    case offline = "Offline"
    case paused = "Remote Control Paused"
}

public final class ConnectionManager: ObservableObject, SignalingClientDelegate {
    public static let shared = ConnectionManager()
    
    @Published public var state: ConnectionState = .disconnected
    @Published public var currentDevice: PairedDevice?
    @Published public var displays: [DisplayItem] = []
    @Published public var selectedDisplayId: Int = 0
    @Published public var liveStreamImage: UIImage?
    @Published public var isStreaming: Bool = false
    @Published public var openWindows: [DesktopWindow] = []
    @Published public var runningApps: [DesktopApp] = []
    @Published public var browserTabs: [BrowserTab] = []
    @Published public var currentFiles: [FileItem] = []
    @Published public var currentDirectory: String = "Desktop"
    @Published public var lastScreenshotImage: UIImage?
    @Published public var volumeLevel: Float = 0.65
    @Published public var isMuted: Bool = false
    @Published public var isDemoMode: Bool = false
    @Published public var mediaStatus: MediaStatusPayload?
    @Published public var isPlaying: Bool = false
    @Published public var playbackRate: Float = 1.0
    @Published public var mediaProgress: Double = 0.28
    
    private let signalingClient = SignalingClient()
    private var reconnectAttempts: Int = 0
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        signalingClient.delegate = self
        
        // Listen to active device changes
        DeviceRepository.shared.$activeDeviceId
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.loadActiveDevice()
            }
            .store(in: &cancellables)
            
        loadActiveDevice()
    }
    
    public func loadActiveDevice() {
        if let device = DeviceRepository.shared.activeDevice {
            self.currentDevice = device
            if device.userSettings.autoConnect && state == .disconnected {
                connect(to: device)
            }
        }
    }
    
    public func connect(to device: PairedDevice) {
        self.currentDevice = device
        self.state = .connecting
        
        if isDemoMode {
            // Decoupled demo mode
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.state = .authenticating
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.state = .connected
                Haptics.shared.success()
                self.requestInitialData()
            }
            return
        }
        
        signalingClient.connect(host: device.host, port: device.port)
    }
    
    public func disconnect() {
        signalingClient.disconnect()
        WebRTCManager.shared.stopSession()
        state = .disconnected
        LatencyMonitor.shared.markOffline()
        Haptics.shared.warning()
    }
    
    public func retryConnection() {
        guard let device = currentDevice else { return }
        connect(to: device)
    }
    
    public func pauseRemoteControl() {
        state = .paused
    }
    
    public func resumeRemoteControl() {
        if currentDevice != nil {
            state = .connected
        }
    }
    
    // MARK: - SignalingClientDelegate
    
    public func signalingDidConnect() {
        state = .authenticating
        // Authenticate pairing token
        guard let device = currentDevice else { return }
        let authMsg = PocketMessage.make(type: .authVerify, data: [
            "deviceId": device.id,
            "token": device.pairingToken
        ])
        if let msg = authMsg {
            signalingClient.send(message: msg)
        }
    }
    
    public func signalingDidDisconnect(error: Error?) {
        if state == .connected {
            state = .reconnecting
            attemptReconnect()
        } else {
            state = .offline
            LatencyMonitor.shared.markOffline()
        }
    }
    
    private func attemptReconnect() {
        guard reconnectAttempts < 5 else {
            state = .offline
            reconnectAttempts = 0
            return
        }
        
        reconnectAttempts += 1
        let delay = Double(min(reconnectAttempts * 2, 8))
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, self.state == .reconnecting else { return }
            if let device = self.currentDevice {
                self.signalingClient.connect(host: device.host, port: device.port)
            }
        }
    }
    
    public func signalingDidReceiveMessage(_ message: PocketMessage) {
        switch message.type {
        case .authSuccess:
            DispatchQueue.main.async {
                self.state = .connected
                self.reconnectAttempts = 0
                Haptics.shared.success()
                self.requestInitialData()
            }
            
        case .authRevoked:
            DispatchQueue.main.async {
                self.disconnect()
                if let id = self.currentDevice?.id {
                    DeviceRepository.shared.removeDevice(id: id)
                }
            }
            
        case .pong:
            LatencyMonitor.shared.recordPongReceived(id: message.id)
            
        case .displaysList:
            if let displays = message.decodePayload([DisplayItem].self) {
                DispatchQueue.main.async {
                    self.displays = displays
                    if self.selectedDisplayId == 0, let first = displays.first {
                        self.selectedDisplayId = first.id
                    }
                }
            }
            
        case .windowsList:
            if let windows = message.decodePayload([DesktopWindow].self) {
                DispatchQueue.main.async {
                    self.openWindows = windows
                }
            }
            
        case .streamFrame:
            if let frame = message.decodePayload(StreamFramePayload.self),
               let data = Data(base64Encoded: frame.frameBase64),
               let img = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.liveStreamImage = img
                }
            }
            
        case .mediaStatus:
            if let status = message.decodePayload(MediaStatusPayload.self) {
                DispatchQueue.main.async {
                    self.mediaStatus = status
                    self.isPlaying = status.isPlaying
                    if let rate = status.rate {
                        self.playbackRate = rate
                    }
                }
            }
            
        case .appsList:
            if let apps = message.decodePayload([DesktopApp].self) {
                DispatchQueue.main.async {
                    self.runningApps = apps
                }
            }
            
        case .browserTabsList:
            if let tabs = message.decodePayload([BrowserTab].self) {
                DispatchQueue.main.async {
                    self.browserTabs = tabs
                }
            }
            
        case .filesList:
            if let files = message.decodePayload([FileItem].self) {
                DispatchQueue.main.async {
                    self.currentFiles = files
                }
            }
            
        case .screenshotData:
            if let data = message.payload, let img = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.lastScreenshotImage = img
                }
            }
            
        default:
            break
        }
    }
    
    // MARK: - Actions
    
    public func requestInitialData() {
        sendMessage(.getDisplays)
        sendMessage(.getWindows)
    }
    
    public func sendMessage(_ type: PocketMessageType) {
        let msg = PocketMessage(type: type)
        if !isDemoMode {
            signalingClient.send(message: msg)
        }
    }
    
    // MARK: - Native Mouse Input via Active WebSocket
    
    public func sendMouseMove(dx: Double, dy: Double) {
        let payload = MouseInputPayload(action: .move, deltaX: dx, deltaY: dy)
        if let msg = PocketMessage.make(type: .mouseInput, data: payload) {
            if !isDemoMode { signalingClient.send(message: msg) }
        }
    }
    
    public func sendMouseSet(x: Double, y: Double) {
        let payload = MouseInputPayload(action: .move, x: x, y: y)
        if let msg = PocketMessage.make(type: .mouseInput, data: payload) {
            if !isDemoMode { signalingClient.send(message: msg) }
        }
    }
    
    public func sendMouseClick(button: MouseButton = .left, double: Bool = false) {
        let action: MouseActionType = double ? .doubleClick : (button == .right ? .rightClick : .click)
        let payload = MouseInputPayload(action: action, button: button)
        if let msg = PocketMessage.make(type: .mouseInput, data: payload) {
            if !isDemoMode { signalingClient.send(message: msg) }
        }
    }
    
    public func sendMouseDown(button: MouseButton = .left) {
        let payload = MouseInputPayload(action: .down, button: button)
        if let msg = PocketMessage.make(type: .mouseInput, data: payload) {
            if !isDemoMode { signalingClient.send(message: msg) }
        }
    }
    
    public func sendMouseUp(button: MouseButton = .left) {
        let payload = MouseInputPayload(action: .up, button: button)
        if let msg = PocketMessage.make(type: .mouseInput, data: payload) {
            if !isDemoMode { signalingClient.send(message: msg) }
        }
    }
    
    public func sendMouseScroll(deltaY: Double) {
        let payload = MouseInputPayload(action: .scroll, scrollDeltaY: deltaY)
        if let msg = PocketMessage.make(type: .mouseInput, data: payload) {
            if !isDemoMode { signalingClient.send(message: msg) }
        }
    }
    
    // MARK: - Native Keyboard Input via Active WebSocket
    
    public func sendKeyText(_ text: String) {
        let payload = KeyboardInputPayload(action: .text, text: text)
        if let msg = PocketMessage.make(type: .keyboardInput, data: payload) {
            if !isDemoMode { signalingClient.send(message: msg) }
        }
    }
    
    public func sendKeyPress(_ key: String, modifiers: KeyboardModifierFlags = []) {
        let payload = KeyboardInputPayload(action: .keyPress, key: key, keyCode: key, modifiers: modifiers)
        if let msg = PocketMessage.make(type: .keyboardInput, data: payload) {
            if !isDemoMode { signalingClient.send(message: msg) }
        }
    }
    
    public func sendShortcut(_ shortcut: String, modifiers: KeyboardModifierFlags = []) {
        let payload = KeyboardInputPayload(action: .shortcut, modifiers: modifiers, shortcut: shortcut)
        if let msg = PocketMessage.make(type: .keyboardInput, data: payload) {
            if !isDemoMode { signalingClient.send(message: msg) }
        }
    }
    
    // MARK: - Window Snapping & Physical Display Routing
    
    public func sendWindowMove(windowId: String, displayId: Int, zone: String) {
        Haptics.shared.click()
        let payload = WindowMovePayload(windowId: windowId, displayId: displayId, zone: zone)
        if let msg = PocketMessage.make(type: .windowMove, data: payload) {
            if !isDemoMode { signalingClient.send(message: msg) }
        }
        // Optimistically update
        DispatchQueue.main.async {
            if let idx = self.openWindows.firstIndex(where: { $0.id == windowId }) {
                self.openWindows[idx].displayId = displayId
            }
        }
    }
    
    public func performWindowAction(windowId: String, action: WindowActionType) {
        Haptics.shared.click()
        let payload = WindowActionPayload(windowId: windowId, action: action)
        if let msg = PocketMessage.make(type: .windowAction, data: payload) {
            if !isDemoMode {
                signalingClient.send(message: msg)
            }
        }
        
        switch action {
        case .close:
            openWindows.removeAll(where: { $0.id == windowId })
        case .focus:
            for i in 0..<openWindows.count {
                openWindows[i].isFocused = (openWindows[i].id == windowId)
            }
        case .minimize:
            openWindows.removeAll(where: { $0.id == windowId })
        case .maximize:
            break
        }
    }
    
    // MARK: - Live Screen Stream Control
    
    public func startStream(displayId: Int? = nil, fps: Int = 20, quality: Int = 65) {
        let targetId = displayId ?? selectedDisplayId
        self.selectedDisplayId = targetId
        self.isStreaming = true
        let payload = StreamControlPayload(displayId: targetId, fps: fps, quality: quality)
        if let msg = PocketMessage.make(type: .streamStart, data: payload) {
            if !isDemoMode { signalingClient.send(message: msg) }
        }
    }
    
    public func stopStream() {
        self.isStreaming = false
        sendMessage(.streamStop)
    }
    
    public func requestDisplays() {
        sendMessage(.getDisplays)
    }
    
    public func requestWindows() {
        sendMessage(.getWindows)
    }
    
    // MARK: - Media Controls
    
    public func performMediaCommand(_ command: MediaCommandType, volume: Float? = nil, rate: Float? = nil) {
        Haptics.shared.click()
        if let v = volume {
            self.volumeLevel = v
        }
        if let r = rate {
            self.playbackRate = r
        }
        if command == .playPause {
            self.isPlaying.toggle()
        }
        let payload = MediaControlPayload(command: command, volumeLevel: volumeLevel, rate: rate ?? playbackRate)
        if let msg = PocketMessage.make(type: .mediaControl, data: payload) {
            if !isDemoMode {
                signalingClient.send(message: msg)
            }
        }
    }
    
    public func performBrowserAction(_ action: BrowserActionPayload) {
        Haptics.shared.click()
        if let msg = PocketMessage.make(type: .browserAction, data: action) {
            if !isDemoMode {
                signalingClient.send(message: msg)
            }
        }
    }
    
    public func launchApp(_ app: DesktopApp) {
        Haptics.shared.click()
        if let msg = PocketMessage.make(type: .launchApp, data: ["appId": app.id, "path": app.executablePath]) {
            if !isDemoMode {
                signalingClient.send(message: msg)
            }
        }
    }
    
    public func performSystemCommand(_ command: SystemCommandType) {
        Haptics.shared.click()
        let payload = SystemCommandPayload(command: command)
        if let msg = PocketMessage.make(type: .systemCommand, data: payload) {
            if !isDemoMode {
                signalingClient.send(message: msg)
            }
        }
    }
    
    public func performFileAction(_ payload: FileActionPayload) {
        Haptics.shared.click()
        if let msg = PocketMessage.make(type: .fileAction, data: payload) {
            if !isDemoMode {
                signalingClient.send(message: msg)
            }
        }
    }
}
