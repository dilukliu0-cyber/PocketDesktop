import Foundation

public struct DevicePermissions: Codable, Equatable {
    public var remoteControl: Bool = true
    public var files: Bool = true
    public var clipboard: Bool = true
    public var browser: Bool = true
    public var audio: Bool = true
    
    public init(
        remoteControl: Bool = true,
        files: Bool = true,
        clipboard: Bool = true,
        browser: Bool = true,
        audio: Bool = true
    ) {
        self.remoteControl = remoteControl
        self.files = files
        self.clipboard = clipboard
        self.browser = browser
        self.audio = audio
    }
}

public struct DeviceUserSettings: Codable, Equatable {
    public var autoConnect: Bool = true
    public var hapticFeedback: Bool = true
    public var naturalScrolling: Bool = true
    public var streamingQuality: StreamingQuality = .high
    public var requireFaceID: Bool = false
    public var hidePreviewInAppSwitcher: Bool = true
    public var trackpadSensitivity: Double = 1.0 // 0.5 to 2.0
    public var tapToClick: Bool = true
    
    public init() {}
}

public enum StreamingQuality: String, Codable, CaseIterable {
    case low = "Low (Battery Saver)"
    case balanced = "Balanced"
    case high = "High (60 FPS)"
    case ultra = "Ultra (Native)"
}

public struct PairedDevice: Codable, Identifiable, Equatable {
    public let id: String                 // Unique device UUID
    public var name: String               // e.g. "Alex’s PC"
    public var osName: String             // e.g. "Windows 11 Pro" or "macOS Sonoma"
    public var host: String               // IP or hostname
    public var port: Int                  // Signaling port (e.g. 8443)
    public var publicKeyFingerprint: String // SHA-256 hex string of computer identity
    public var pairingToken: String       // Authenticated session token
    public var permissions: DevicePermissions
    public var userSettings: DeviceUserSettings
    public var lastSeen: Date
    public var isOnline: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        osName: String,
        host: String,
        port: Int = 8443,
        publicKeyFingerprint: String,
        pairingToken: String,
        permissions: DevicePermissions = DevicePermissions(),
        userSettings: DeviceUserSettings = DeviceUserSettings(),
        lastSeen: Date = Date(),
        isOnline: Bool = false
    ) {
        self.id = id
        self.name = name
        self.osName = osName
        self.host = host
        self.port = port
        self.publicKeyFingerprint = publicKeyFingerprint
        self.pairingToken = pairingToken
        self.permissions = permissions
        self.userSettings = userSettings
        self.lastSeen = lastSeen
        self.isOnline = isOnline
    }
}

// QR Code payload decoded during pairing
public struct QRPairingPayload: Codable {
    public let version: Int
    public let deviceId: String
    public let deviceName: String
    public let osName: String
    public let host: String
    public let port: Int
    public let fingerprint: String
    public let pin: String
    
    public init(
        version: Int = 1,
        deviceId: String,
        deviceName: String,
        osName: String,
        host: String,
        port: Int,
        fingerprint: String,
        pin: String
    ) {
        self.version = version
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.osName = osName
        self.host = host
        self.port = port
        self.fingerprint = fingerprint
        self.pin = pin
    }
}
