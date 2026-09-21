import SwiftUI

public struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var connection = ConnectionManager.shared
    @ObservedObject private var latency = LatencyMonitor.shared
    
    @State private var showingDeviceSwitcher = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Top App Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pocket Desktop")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.pdPrimaryText)
                            Text("Your computer in your pocket")
                                .font(.system(size: 14))
                                .foregroundColor(.pdSecondaryText)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingDeviceSwitcher = true
                        }) {
                            Image(systemName: "laptopcomputer.and.iphone")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.pdPrimaryText)
                                .padding(10)
                                .background(Circle().fill(Color.pdElevatedCard))
                                .overlay(Circle().stroke(Color.pdBorder, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // Main Device Card
                    DeviceCard(
                        device: connection.currentDevice,
                        connectionState: connection.state,
                        latencyMs: latency.currentLatencyMs,
                        onSwitchDevice: { showingDeviceSwitcher = true },
                        onStartRemote: { appState.selectedTab = .desktop }
                    )
                    .padding(.horizontal, 20)
                    
                    // Quick Action Tiles [ Desktop ] [ Browser ] [ Files ] [ Keyboard ]
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.pdPrimaryText)
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            quickTile(title: "Desktop", icon: "macwindow", color: .pdAccentBlue) {
                                appState.selectedTab = .desktop
                            }
                            quickTile(title: "Browser", icon: "safari.fill", color: .pdAccentViolet) {
                                appState.selectedTab = .browser
                            }
                            quickTile(title: "Files", icon: "folder.fill", color: .pdWarningAmber) {
                                appState.activeToolSheet = .files
                            }
                            quickTile(title: "Keyboard", icon: "keyboard.fill", color: .pdOnlineGreen) {
                                appState.activeToolSheet = .keyboard
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Recent Apps Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Apps")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.pdPrimaryText)
                            Spacer()
                            Button(action: {
                                appState.activeToolSheet = .apps
                            }) {
                                Text("See All")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.pdAccentBlue)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(connection.runningApps.prefix(4)) { app in
                                    recentAppCard(app)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color.pdBackground.ignoresSafeArea())
            .sheet(isPresented: $showingDeviceSwitcher) {
                DeviceSwitcherView()
            }
        }
    }
    
    private func quickTile(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.shared.click()
            action()
        }) {
            GlassCard(cornerRadius: 18, padding: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(color)
                        )
                    
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.pdPrimaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(ScaleTouchButtonStyle())
    }
    
    private func recentAppCard(_ app: DesktopApp) -> some View {
        Button(action: {
            connection.launchApp(app)
        }) {
            GlassCard(cornerRadius: 18, padding: 14) {
                VStack(spacing: 8) {
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(Color.pdElevatedCard)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: app.systemIconName)
                                    .font(.system(size: 22))
                                    .foregroundColor(.pdAccentBlue)
                            )
                        
                        if app.isRunning {
                            Circle()
                                .fill(Color.pdOnlineGreen)
                                .frame(width: 10, height: 10)
                                .overlay(Circle().stroke(Color.pdCardBackground, lineWidth: 2))
                        }
                    }
                    
                    Text(app.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.pdPrimaryText)
                        .lineLimit(1)
                }
                .frame(width: 90)
            }
        }
        .buttonStyle(ScaleTouchButtonStyle())
    }
}
