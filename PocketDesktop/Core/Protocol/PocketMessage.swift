import Foundation

// MARK: - Protocol Framing & Envelopes
// Framed protocol messages with versioning, sequence IDs, and typed payloads

public enum PocketMessageType: String, Codable {
    // Pairing & Auth
    case pairingRequest = "pairing_request"
    case pairingResponse = "pairing_response"
    case authChallenge = "auth_challenge"
    case authVerify = "auth_verify"
    case authSuccess = "auth_success"
    case authRevoked = "auth_revoked"
    
    // Telemetry & Heartbeat
    case ping = "ping"
    case pong = "pong"
    case deviceStatus = "device_status"
    
    // Desktop, Displays & Windows
    case getDisplays = "get_displays"
    case displaysList = "displays_list"
    case getWindows = "get_windows"
    case windowsList = "windows_list"
    case windowAction = "window_action"
    case windowMove = "window_move"
    
    // Live Stream
    case streamStart = "stream_start"
    case streamStop = "stream_stop"
    case streamFrame = "stream_frame"
    
    // Browser Controller
    case getBrowserTabs = "get_browser_tabs"
    case browserTabsList = "browser_tabs_list"
    case browserAction = "browser_action"
    
    // App Launcher
    case getApps = "get_apps"
    case appsList = "apps_list"
    case launchApp = "launch_app"
    
    // Files
    case getFiles = "get_files"
    case filesList = "files_list"
    case fileAction = "file_action"
    case fileDownloadChunk = "file_download_chunk"
    
    // Remote Input
    case mouseInput = "mouse_input"
    case keyboardInput = "keyboard_input"
    case mediaControl = "media_control"
    case mediaStatus = "media_status"
    case systemCommand = "system_command"
    
    // Screenshot
    case requestScreenshot = "request_screenshot"
    case screenshotData = "screenshot_data"
    
    // WebRTC Signaling
    case rtcOffer = "rtc_offer"
    case rtcAnswer = "rtc_answer"
    case rtcCandidate = "rtc_candidate"
    
    // Errors
    case error = "error"
}

public struct PocketMessage: Codable, Identifiable {
    public let id: String
    public let version: Int
    public let timestamp: TimeInterval
    public let type: PocketMessageType
    public let payload: Data?
    
    public init(
        type: PocketMessageType,
        payload: Data? = nil,
        id: String = UUID().uuidString,
        version: Int = 1,
        timestamp: TimeInterval = Date().timeIntervalSince1970
    ) {
        self.id = id
        self.version = version
        self.timestamp = timestamp
        self.type = type
        self.payload = payload
    }
    
    // Helper to serialize typed payloads
    public static func make<T: Encodable>(type: PocketMessageType, data: T) -> PocketMessage? {
        guard let encoded = try? JSONEncoder().encode(data) else { return nil }
        return PocketMessage(type: type, payload: encoded)
    }
    
    // Helper to decode typed payload
    public func decodePayload<T: Decodable>(_ type: T.Type) -> T? {
        guard let payload = payload else { return nil }
        return try? JSONDecoder().decode(T.self, from: payload)
    }
}
