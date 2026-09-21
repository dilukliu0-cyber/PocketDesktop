import SwiftUI

public struct SimplifiedDesktopView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var connection = ConnectionManager.shared
    
    @State private var showingLiveView = false
    @State private var showingTrackpad = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Top PC Status Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(connection.currentDevice?.name ?? "My PC")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.pdPrimaryText)
                            
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(connection.state == .connected ? Color.pdOnlineGreen : Color.pdWarningAmber)
                                    .frame(width: 7, height: 7)
                                Text(connection.state.rawValue)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.pdSecondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        // Live View button
                        Button(action: {
                            Haptics.shared.click()
                            showingLiveView = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "display")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Live View")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.pdAccentGradient)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // SECTION 1: OPEN WINDOWS
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Open Windows")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.pdPrimaryText)
                            Spacer()
                            Text("\(connection.openWindows.count) Active")
                                .font(.system(size: 13))
                                .foregroundColor(.pdSecondaryText)
                        }
                        .padding(.horizontal, 20)
                        
                        if connection.openWindows.isEmpty {
                            GlassCard(cornerRadius: 18, padding: 24) {
                                VStack(spacing: 10) {
                                    Image(systemName: "macwindow.on.rectangle")
                                        .font(.system(size: 36))
                                        .foregroundColor(.pdSecondaryText)
                                    Text("No Open Windows")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Launch an app below to get started.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.pdSecondaryText)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, 20)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(connection.openWindows) { win in
                                    windowCard(win)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // SECTION 2: RUNNING APPS
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Running Apps")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.pdPrimaryText)
                            Spacer()
                            Button("All Apps") {
                                appState.activeToolSheet = .apps
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.pdAccentBlue)
                        }
                        .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(connection.runningApps.filter { $0.isRunning }) { app in
                                    runningAppPill(app)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // SECTION 3: FAVORITES & SHORTCUTS
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Favorites")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.pdPrimaryText)
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 12) {
                            favoriteTile(title: "Trackpad Mode", icon: "hand.draw.fill", color: .pdAccentBlue) {
                                showingTrackpad = true
                            }
                            favoriteTile(title: "Quick Actions", icon: "bolt.fill", color: .pdAccentViolet) {
                                appState.activeToolSheet = .quickActions
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color.pdBackground.ignoresSafeArea())
            .fullScreenCover(isPresented: $showingLiveView) {
                LiveDesktopView()
            }
            .sheet(isPresented: $showingTrackpad) {
                TrackpadView()
            }
        }
    }
    
    private func windowCard(_ win: DesktopWindow) -> some View {
        GlassCard(cornerRadius: 20, padding: 16, isElevated: win.isFocused) {
            VStack(alignment: .leading, spacing: 12) {
                // Window Header
                HStack(spacing: 10) {
                    Image(systemName: win.appIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.pdAccentBlue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(win.appName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.pdPrimaryText)
                        Text(win.title)
                            .font(.system(size: 13))
                            .foregroundColor(.pdSecondaryText)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if win.isFocused {
                        Text("Focused")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.pdOnlineGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.pdOnlineGreen.opacity(0.12)))
                    }
                }
                
                // Window Simulated Live Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.pdElevatedCard)
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.pdBorder, lineWidth: 1)
                        )
                    
                    VStack(spacing: 8) {
                        Image(systemName: win.appIcon)
                            .font(.system(size: 32))
                            .foregroundColor(.pdSecondaryText.opacity(0.6))
                        Text(win.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.pdSecondaryText)
                            .lineLimit(1)
                            .padding(.horizontal, 16)
                    }
                }
                
                // Action Buttons: Focus, Minimize, Close
                HStack(spacing: 12) {
                    Button(action: {
                        connection.performWindowAction(windowId: win.id, action: .focus)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                            Text("Focus")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.pdAccentBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.pdAccentBlue.opacity(0.12)))
                    }
                    
                    Button(action: {
                        connection.performWindowAction(windowId: win.id, action: .minimize)
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.pdPrimaryText)
                            .frame(width: 44, height: 32)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.pdElevatedCard))
                    }
                    
                    Button(action: {
                        connection.performWindowAction(windowId: win.id, action: .close)
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.pdOfflineRed)
                            .frame(width: 44, height: 32)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.pdOfflineRed.opacity(0.12)))
                    }
                }
            }
        }
    }
    
    private func runningAppPill(_ app: DesktopApp) -> some View {
        Button(action: {
            connection.launchApp(app)
        }) {
            HStack(spacing: 8) {
                Image(systemName: app.systemIconName)
                    .font(.system(size: 14))
                    .foregroundColor(.pdAccentBlue)
                Text(app.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.pdPrimaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.pdCardBackground)
                    .overlay(Capsule().stroke(Color.pdBorder, lineWidth: 1))
            )
        }
    }
    
    private func favoriteTile(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.shared.click()
            action()
        }) {
            GlassCard(cornerRadius: 16, padding: 14) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: icon).foregroundColor(color))
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.pdPrimaryText)
                    Spacer()
                }
            }
        }
        .buttonStyle(ScaleTouchButtonStyle())
    }
}
