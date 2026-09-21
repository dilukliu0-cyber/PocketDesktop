import SwiftUI

@main
struct PocketDesktopApp: App {
    @StateObject private var appState = AppState()
    @ObservedObject private var connection = ConnectionManager.shared
    @ObservedObject private var repo = DeviceRepository.shared
    
    @State private var showingToolsSheet = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if appState.showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                } else if !appState.hasCompletedOnboarding && repo.devices.isEmpty {
                    OnboardingView()
                        .environmentObject(appState)
                } else if appState.isBiometricsLocked {
                    biometricLockView
                } else {
                    mainAppInterface
                }
            }
            .privacyBlurProtected(
                isEnabled: repo.activeDevice?.userSettings.hidePreviewInAppSwitcher ?? true
            )
            .sheet(isPresented: $appState.showPairingSheet) {
                PairDeviceView()
                    .environmentObject(appState)
            }
            .sheet(item: $appState.activePairingPayload) { payload in
                ConnectingView(
                    payload: payload,
                    onComplete: { newDevice in
                        repo.addOrUpdateDevice(newDevice)
                        connection.connect(to: newDevice)
                        appState.hasCompletedOnboarding = true
                        appState.activePairingPayload = nil
                    },
                    onCancel: {
                        appState.activePairingPayload = nil
                    }
                )
            }
            .sheet(item: $appState.activeToolSheet) { sheet in
                switch sheet {
                case .keyboard:
                    KeyboardView()
                case .files:
                    FilesView()
                case .apps:
                    AppLauncherView()
                case .quickActions:
                    QuickActionsView()
                        .environmentObject(appState)
                case .screenshot:
                    ScreenshotPreviewView()
                case .settings:
                    SettingsView()
                        .environmentObject(appState)
                case .deviceSwitcher:
                    DeviceSwitcherView()
                        .environmentObject(appState)
                }
            }
            .sheet(isPresented: $showingToolsSheet) {
                ToolsSheetView()
                    .environmentObject(appState)
            }
        }
    }
    
    // Main 3-Screen Navigation View matching User Mockup
    private var mainAppInterface: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .environmentObject(appState)
                .tabItem {
                    Label("Главная", systemImage: "hand.draw.fill")
                }
                .tag(AppTab.home)
            
            LiveDesktopView()
                .tabItem {
                    Label("Стрим", systemImage: "display")
                }
                .tag(AppTab.stream)
            
            WindowsManagerView()
                .tabItem {
                    Label("Окна", systemImage: "macwindow.on.rectangle")
                }
                .tag(AppTab.windows)
        }
        .tint(Color.pdAccentBlue)
    }
    
    // Biometric Unlock View
    private var biometricLockView: some View {
        ZStack {
            Color.pdBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "faceid")
                    .font(.system(size: 64))
                    .foregroundColor(.pdAccentBlue)
                
                VStack(spacing: 8) {
                    Text("Pocket Desktop Locked")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.pdPrimaryText)
                    Text("Authenticate with Face ID to access your computer.")
                        .font(.system(size: 14))
                        .foregroundColor(.pdSecondaryText)
                }
                
                Spacer()
                
                PocketButton("Unlock with Face ID", icon: "faceid", style: .primary) {
                    appState.checkSecurityLock()
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
    }
}
