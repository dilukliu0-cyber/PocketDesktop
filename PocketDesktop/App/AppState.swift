import SwiftUI
import Combine

public enum AppTab: String, CaseIterable {
    case home = "Главная"
    case stream = "Стрим"
    case windows = "Окна"
    
    var icon: String {
        switch self {
        case .home: return "hand.draw.fill"
        case .stream: return "display"
        case .windows: return "macwindow.on.rectangle"
        }
    }
}

public enum ActiveToolSheet: Identifiable {
    case keyboard
    case files
    case apps
    case quickActions
    case screenshot
    case settings
    case deviceSwitcher
    
    public var id: String {
        switch self {
        case .keyboard: return "keyboard"
        case .files: return "files"
        case .apps: return "apps"
        case .quickActions: return "quickActions"
        case .screenshot: return "screenshot"
        case .settings: return "settings"
        case .deviceSwitcher: return "deviceSwitcher"
        }
    }
}

public final class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") public var hasCompletedOnboarding: Bool = false
    
    @Published public var selectedTab: AppTab = .home
    @Published public var showSplash: Bool = true
    @Published public var showPairingSheet: Bool = false
    @Published public var activePairingPayload: QRPairingPayload?
    @Published public var activeToolSheet: ActiveToolSheet?
    @Published public var isBiometricsLocked: Bool = false
    
    public init() {
        // Automatically hide splash after 1.4s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeInOut(duration: 0.35)) {
                self.showSplash = false
            }
        }
        
        checkSecurityLock()
    }
    
    public func checkSecurityLock() {
        if let device = DeviceRepository.shared.activeDevice, device.userSettings.requireFaceID {
            self.isBiometricsLocked = true
            FaceIDAuthManager.shared.authenticate { [weak self] success in
                if success {
                    self?.isBiometricsLocked = false
                }
            }
        }
    }
    
    public func handleScannedQR(_ qrString: String) {
        if let data = qrString.data(using: .utf8),
           let payload = try? JSONDecoder().decode(QRPairingPayload.self, from: data) {
            self.activePairingPayload = payload
            self.showPairingSheet = false
        }
    }
}
