import Foundation

// MARK: - Simplified Desktop Models

public struct DesktopWindow: Codable, Identifiable, Equatable {
    public let id: String
    public let title: String
    public let appName: String
    public let appIcon: String
    public let thumbnailBase64: String?
    public var isFocused: Bool
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        appName: String,
        appIcon: String = "app.window.fill",
        thumbnailBase64: String? = nil,
        isFocused: Bool = false
    ) {
        self.id = id
        self.title = title
        self.appName = appName
        self.appIcon = appIcon
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
