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
    @Published public var openWindows: [DesktopWindow] = []
    @Published public var runningApps: [DesktopApp] = []
    @Published public var browserTabs: [BrowserTab] = []
    @Published public var currentFiles: [FileItem] = []
    @Published public var currentDirectory: String = "Desktop"
    @Published public var lastScreenshotImage: UIImage?
    @Published public var volumeLevel: Float = 0.65
    @Published public var isMuted: Bool = false
    @Published public var isDemoMode: Bool = false
    
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
        if let device = currentDevice {
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
            state = .connected
            reconnectAttempts = 0
            Haptics.shared.success()
            WebRTCManager.shared.startSession()
            requestInitialData()
            
        case .authRevoked:
            disconnect()
            if let id = currentDevice?.id {
                DeviceRepository.shared.removeDevice(id: id)
            }
            
        case .pong:
            LatencyMonitor.shared.recordPongReceived(id: message.id)
            
        case .windowsList:
            if let windows = message.decodePayload([DesktopWindow].self) {
                self.openWindows = windows
            }
            
        case .appsList:
            if let apps = message.decodePayload([DesktopApp].self) {
                self.runningApps = apps
            }
            
        case .browserTabsList:
            if let tabs = message.decodePayload([BrowserTab].self) {
                self.browserTabs = tabs
            }
            
        case .filesList:
            if let files = message.decodePayload([FileItem].self) {
                self.currentFiles = files
            }
            
        case .screenshotData:
            if let data = message.payload, let img = UIImage(data: data) {
                self.lastScreenshotImage = img
            }
            
        default:
            break
        }
    }
    
    // MARK: - Actions
    
    public func requestInitialData() {
        sendMessage(.getWindows)
        sendMessage(.getApps)
        sendMessage(.getBrowserTabs)
        sendMessage(.getFiles)
    }
    
    public func sendMessage(_ type: PocketMessageType) {
        let msg = PocketMessage(type: type)
        if !isDemoMode {
            signalingClient.send(message: msg)
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
        
        // Optimistic UI updates
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
    
    public func performMediaCommand(_ command: MediaCommandType, volume: Float? = nil) {
        Haptics.shared.click()
        if let v = volume {
            self.volumeLevel = v
        }
        let payload = MediaControlPayload(command: command, volumeLevel: volumeLevel)
        if let msg = PocketMessage.make(type: .mediaControl, data: payload) {
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
