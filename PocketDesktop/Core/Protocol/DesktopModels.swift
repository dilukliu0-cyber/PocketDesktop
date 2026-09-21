import Foundation

// MARK: - Physical Displays & Geometry

public struct DisplayRect: Codable, Equatable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double
    
    public init(x: Double = 0, y: Double = 0, width: Double = 1920, height: Double = 1080) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct DisplayItem: Codable, Identifiable, Equatable {
    public let id: Int
    public let name: String
    public let isPrimary: Bool
    public let bounds: DisplayRect
    public let workArea: DisplayRect
    
    public init(
        id: Int,
        name: String,
        isPrimary: Bool = false,
        bounds: DisplayRect = DisplayRect(),
        workArea: DisplayRect = DisplayRect()
    ) {
        self.id = id
        self.name = name
        self.isPrimary = isPrimary
        self.bounds = bounds
        self.workArea = workArea
    }
}

// MARK: - Simplified Desktop Models

public struct DesktopWindow: Codable, Identifiable, Equatable {
    public let id: String
    public let hwnd: Int?
    public let pid: Int?
    public let title: String
    public let appName: String
    public var appIcon: String?
    public var displayId: Int?
    public var bounds: DisplayRect?
    public let thumbnailBase64: String?
    public var isFocused: Bool?
    
    public init(
        id: String = UUID().uuidString,
        hwnd: Int? = nil,
        pid: Int? = nil,
        title: String,
        appName: String,
        appIcon: String? = "app.window.fill",
        displayId: Int? = nil,
        bounds: DisplayRect? = nil,
        thumbnailBase64: String? = nil,
        isFocused: Bool = false
    ) {
        self.id = id
        self.hwnd = hwnd
        self.pid = pid
        self.title = title
        self.appName = appName
        self.appIcon = appIcon
        self.displayId = displayId
        self.bounds = bounds
        self.thumbnailBase64 = thumbnailBase64
        self.isFocused = isFocused
    }
}

public enum WindowActionType: String, Codable {
    case focus = "focus"
    case minimize = "minimize"
    case maximize = "maximize"
    case close = "close"
}

public struct WindowActionPayload: Codable {
    public let windowId: String
    public let action: WindowActionType
    
    public init(windowId: String, action: WindowActionType) {
        self.windowId = windowId
        self.action = action
    }
}

public struct WindowMovePayload: Codable {
    public let windowId: String
    public let displayId: Int
    public let zone: String // "left", "right", "full"
    
    public init(windowId: String, displayId: Int, zone: String) {
        self.windowId = windowId
        self.displayId = displayId
        self.zone = zone
    }
}

// MARK: - Live Stream Models

public struct StreamControlPayload: Codable {
    public let displayId: Int?
    public let fps: Int?
    public let quality: Int?
    
    public init(displayId: Int? = nil, fps: Int? = 20, quality: Int? = 65) {
        self.displayId = displayId
        self.fps = fps
        self.quality = quality
    }
}

public struct StreamFramePayload: Codable {
    public let displayId: Int?
    public let frameBase64: String?
    public let data: String?
    public let width: Int?
    public let height: Int?
    public let timestamp: Double?
    
    public init(displayId: Int? = nil, frameBase64: String? = nil, data: String? = nil, width: Int? = nil, height: Int? = nil, timestamp: Double? = nil) {
        self.displayId = displayId
        self.frameBase64 = frameBase64
        self.data = data
        self.width = width
        self.height = height
        self.timestamp = timestamp
    }
}

// MARK: - App Launcher Models

public struct DesktopApp: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let systemIconName: String
    public var isRunning: Bool
    public var isFavorite: Bool
    public let executablePath: String
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        systemIconName: String,
        isRunning: Bool = false,
        isFavorite: Bool = false,
        executablePath: String = ""
    ) {
        self.id = id
        self.name = name
        self.systemIconName = systemIconName
        self.isRunning = isRunning
        self.isFavorite = isFavorite
        self.executablePath = executablePath
    }
}

// MARK: - Simplified Browser Models

public struct BrowserTab: Codable, Identifiable, Equatable {
    public let id: String
    public var title: String
    public var url: String
    public var previewBase64: String?
    public var isActive: Bool
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        url: String,
        previewBase64: String? = nil,
        isActive: Bool = false
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.previewBase64 = previewBase64
        self.isActive = isActive
    }
}

public enum BrowserActionType: String, Codable {
    case navigate = "navigate"
    case switchTab = "switch_tab"
    case closeTab = "close_tab"
    case newTab = "new_tab"
    case back = "back"
    case forward = "forward"
    case refresh = "refresh"
}

public struct BrowserActionPayload: Codable {
    public let action: BrowserActionType
    public let tabId: String?
    public let url: String?
    
    public init(action: BrowserActionType, tabId: String? = nil, url: String? = nil) {
        self.action = action
        self.tabId = tabId
        self.url = url
    }
}

// MARK: - Remote Files Models

public struct FileItem: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let path: String
    public let isDirectory: Bool
    public let sizeBytes: Int64
    public let modifiedDate: Date
    public let fileExtension: String
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        path: String,
        isDirectory: Bool,
        sizeBytes: Int64 = 0,
        modifiedDate: Date = Date(),
        fileExtension: String = ""
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.sizeBytes = sizeBytes
        self.modifiedDate = modifiedDate
        self.fileExtension = fileExtension
    }
    
    public var formattedSize: String {
        if isDirectory { return "--" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: sizeBytes)
    }
}

public enum FileActionType: String, Codable {
    case download = "download"
    case delete = "delete"
    case rename = "rename"
    case createFolder = "create_folder"
    case upload = "upload"
}

public struct FileActionPayload: Codable {
    public let action: FileActionType
    public let path: String
    public let destinationName: String?
    public let newName: String?
    
    public init(
        action: FileActionType,
        path: String,
        destinationName: String? = nil,
        newName: String? = nil
    ) {
        self.action = action
        self.path = path
        self.destinationName = destinationName
        self.newName = newName
    }
}
