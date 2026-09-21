import Foundation
import SwiftUI

public final class DemoDesktopService {
    public static let shared = DemoDesktopService()
    
    private init() {}
    
    public var sampleDevice: PairedDevice {
        PairedDevice(
            id: "demo-device-alex-pc",
            name: "Alex’s PC",
            osName: "Windows 11 Pro",
            host: "192.168.1.145",
            port: 8443,
            publicKeyFingerprint: "7A:B3:9F:44:12:88:C1:DE:60:E5:31:02:49:FF:88:9C",
            pairingToken: "demo_token_secret_12345",
            isOnline: true
        )
    }
    
    public var sampleWindows: [DesktopWindow] {
        [
            DesktopWindow(
                id: "win_1",
                title: "YouTube — Google Chrome",
                appName: "Google Chrome",
                appIcon: "globe",
                isFocused: true
            ),
            DesktopWindow(
                id: "win_2",
                title: "Pocket Desktop — VS Code",
                appName: "VS Code",
                appIcon: "chevron.left.forwardslash.chevron.right",
                isFocused: false
            ),
            DesktopWindow(
                id: "win_3",
                title: "Liked Songs — Spotify",
                appName: "Spotify",
                appIcon: "music.note",
                isFocused: false
            )
        ]
    }
    
    public var sampleApps: [DesktopApp] {
        [
            DesktopApp(id: "app_chrome", name: "Google Chrome", systemIconName: "globe", isRunning: true, isFavorite: true),
            DesktopApp(id: "app_spotify", name: "Spotify", systemIconName: "music.note", isRunning: true, isFavorite: true),
            DesktopApp(id: "app_vscode", name: "VS Code", systemIconName: "chevron.left.forwardslash.chevron.right", isRunning: true, isFavorite: true),
            DesktopApp(id: "app_discord", name: "Discord", systemIconName: "bubble.left.and.bubble.right.fill", isRunning: false, isFavorite: false),
            DesktopApp(id: "app_steam", name: "Steam", systemIconName: "gamecontroller.fill", isRunning: false, isFavorite: false),
            DesktopApp(id: "app_files", name: "Files Explorer", systemIconName: "folder.fill", isRunning: true, isFavorite: false)
        ]
    }
    
    public var sampleBrowserTabs: [BrowserTab] {
        [
            BrowserTab(id: "tab_1", title: "Google Search", url: "https://google.com", isActive: true),
            BrowserTab(id: "tab_2", title: "YouTube — Trending", url: "https://youtube.com", isActive: false),
            BrowserTab(id: "tab_3", title: "Pocket Desktop Workspace — Notion", url: "https://notion.so", isActive: false)
        ]
    }
    
    public var sampleFiles: [FileItem] {
        [
            FileItem(id: "f_1", name: "Documents", path: "C:\\Users\\Alex\\Documents", isDirectory: true),
            FileItem(id: "f_2", name: "Downloads", path: "C:\\Users\\Alex\\Downloads", isDirectory: true),
            FileItem(id: "f_3", name: "Pictures", path: "C:\\Users\\Alex\\Pictures", isDirectory: true),
            FileItem(id: "f_4", name: "Project_Roadmap_Q4.pdf", path: "C:\\Users\\Alex\\Desktop\\Project_Roadmap_Q4.pdf", isDirectory: false, sizeBytes: 2450000, fileExtension: "pdf"),
            FileItem(id: "f_5", name: "Desktop_Screenshot.png", path: "C:\\Users\\Alex\\Desktop\\Desktop_Screenshot.png", isDirectory: false, sizeBytes: 1200000, fileExtension: "png"),
            FileItem(id: "f_6", name: "Budget_2026.xlsx", path: "C:\\Users\\Alex\\Desktop\\Budget_2026.xlsx", isDirectory: false, sizeBytes: 340000, fileExtension: "xlsx")
        ]
    }
    
    public func populateDemoState() {
        let conn = ConnectionManager.shared
        conn.isDemoMode = true
        conn.currentDevice = sampleDevice
        conn.state = .connected
        conn.openWindows = sampleWindows
        conn.runningApps = sampleApps
        conn.browserTabs = sampleBrowserTabs
        conn.currentFiles = sampleFiles
        LatencyMonitor.shared.updateManualLatency(ms: 12)
        
        // Save demo device into repository if empty
        if DeviceRepository.shared.devices.isEmpty {
            DeviceRepository.shared.addOrUpdateDevice(sampleDevice)
        }
    }
}
