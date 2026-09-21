import Foundation

// MARK: - Remote Input Protocols

public enum MouseButton: String, Codable {
    case left
    case right
    case middle
}

public enum MouseActionType: String, Codable {
    case move
    case click
    case doubleClick
    case rightClick
    case down
    case up
    case scroll
    case drag
}

public struct MouseInputPayload: Codable {
    public let action: MouseActionType
    public let x: Double?              // Normalized 0.0 ... 1.0 or pixel coordinates
    public let y: Double?
    public let deltaX: Double?
    public let deltaY: Double?
    public let button: MouseButton?
    public let scrollDeltaY: Double?
    
    public init(
        action: MouseActionType,
        x: Double? = nil,
        y: Double? = nil,
        deltaX: Double? = nil,
        deltaY: Double? = nil,
        button: MouseButton? = nil,
        scrollDeltaY: Double? = nil
    ) {
        self.action = action
        self.x = x
        self.y = y
        self.deltaX = deltaX
        self.deltaY = deltaY
        self.button = button
        self.scrollDeltaY = scrollDeltaY
    }
}

public struct KeyboardModifierFlags: OptionSet, Codable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let ctrl  = KeyboardModifierFlags(rawValue: 1 << 0)
    public static let alt   = KeyboardModifierFlags(rawValue: 1 << 1)
    public static let shift = KeyboardModifierFlags(rawValue: 1 << 2)
    public static let meta  = KeyboardModifierFlags(rawValue: 1 << 3) // Cmd / Win
}

public enum KeyboardActionType: String, Codable {
    case text
    case keyPress
    case shortcut
}

public struct KeyboardInputPayload: Codable {
    public let action: KeyboardActionType
    public let text: String?
    public let key: String?
    public let keyCode: String?         // "Escape", "Tab", "ArrowUp", "ArrowDown", etc.
    public let modifiers: KeyboardModifierFlags
    public let shortcut: String?        // "copy", "paste", "undo", "redo", "selectAll"
    
    public init(
        action: KeyboardActionType,
        text: String? = nil,
        key: String? = nil,
        keyCode: String? = nil,
        modifiers: KeyboardModifierFlags = [],
        shortcut: String? = nil
    ) {
        self.action = action
        self.text = text
        self.key = key ?? keyCode
        self.keyCode = keyCode ?? key
        self.modifiers = modifiers
        self.shortcut = shortcut
    }
}

public enum MediaCommandType: String, Codable {
    case playPause = "play_pause"
    case stop = "stop"
    case next = "next"
    case previous = "previous"
    case forward10 = "forward_10"
    case rewind10 = "rewind_10"
    case volumeUp = "volume_up"
    case volumeDown = "volume_down"
    case setVolume = "set_volume"
    case muteToggle = "mute_toggle"
    case setRate = "set_rate"
}

public struct MediaControlPayload: Codable {
    public let command: MediaCommandType
    public let volumeLevel: Float? // 0.0 ... 1.0
    public let rate: Float?
    
    public init(command: MediaCommandType, volumeLevel: Float? = nil, rate: Float? = nil) {
        self.command = command
        self.volumeLevel = volumeLevel
        self.rate = rate
    }
}

public struct MediaStatusPayload: Codable {
    public let title: String?
    public let artist: String?
    public let isPlaying: Bool
    public let duration: Double?
    public let position: Double?
    public let rate: Float?
    
    public init(
        title: String? = nil,
        artist: String? = nil,
        isPlaying: Bool = false,
        duration: Double? = nil,
        position: Double? = nil,
        rate: Float? = 1.0
    ) {
        self.title = title
        self.artist = artist
        self.isPlaying = isPlaying
        self.duration = duration
        self.position = position
        self.rate = rate
    }
}

public enum SystemCommandType: String, Codable {
    case lock = "lock"
    case sleep = "sleep"
    case showDesktop = "show_desktop"
    case altTab = "alt_tab"
    case screenshot = "screenshot"
}

public struct SystemCommandPayload: Codable {
    public let command: SystemCommandType
    
    public init(command: SystemCommandType) {
        self.command = command
    }
}
