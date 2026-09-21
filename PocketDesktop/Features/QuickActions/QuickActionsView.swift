import SwiftUI

public struct QuickActionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var connection = ConnectionManager.shared
    
    @State private var volume: Float = 0.65
    @State private var isPlaying = true
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quick Actions")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.pdPrimaryText)
                        Text("Connected to \(connection.currentDevice?.name ?? "Alex’s PC")")
                            .font(.system(size: 14))
                            .foregroundColor(.pdSecondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // SECTION 1: MEDIA & VOLUME
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Media & Volume")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.pdSecondaryText)
                            .padding(.horizontal, 20)
                        
                        GlassCard(cornerRadius: 20, padding: 18) {
                            VStack(spacing: 16) {
                                // Volume Slider
                                HStack(spacing: 14) {
                                    Image(systemName: "speaker.fill")
                                        .foregroundColor(.pdSecondaryText)
                                    Slider(value: $volume, in: 0...1) { _ in
                                        connection.performMediaCommand(.setVolume, volume: volume)
                                    }
                                    .tint(.pdAccentBlue)
                                    Image(systemName: "speaker.wave.3.fill")
                                        .foregroundColor(.pdSecondaryText)
                                }
                                
                                Divider().background(Color.pdBorder)
                                
                                // Playback Controls
                                HStack(spacing: 32) {
                                    Button(action: {
                                        connection.performMediaCommand(.previous)
                                    }) {
                                        Image(systemName: "backward.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.pdPrimaryText)
                                    }
                                    
                                    Button(action: {
                                        isPlaying.toggle()
                                        connection.performMediaCommand(.playPause)
                                    }) {
                                        Circle()
                                            .fill(Color.pdAccentBlue)
                                            .frame(width: 54, height: 54)
                                            .overlay(
                                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.white)
                                            )
                                    }
                                    
                                    Button(action: {
                                        connection.performMediaCommand(.next)
                                    }) {
                                        Image(systemName: "forward.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.pdPrimaryText)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // SECTION 2: COMPUTER COMMANDS
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Computer")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.pdSecondaryText)
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            actionTile(icon: "keyboard", title: "Keyboard") {
                                appState.activeToolSheet = .keyboard
                            }
                            actionTile(icon: "folder.fill", title: "Files") {
                                appState.activeToolSheet = .files
                            }
                            actionTile(icon: "camera.fill", title: "Screenshot") {
                                connection.sendMessage(.requestScreenshot)
                                appState.activeToolSheet = .screenshot
                            }
                            actionTile(icon: "lock.fill", title: "Lock PC") {
                                connection.performSystemCommand(.lock)
                            }
                            actionTile(icon: "moon.fill", title: "Sleep") {
                                connection.performSystemCommand(.sleep)
                            }
                            actionTile(icon: "square.grid.2x2.fill", title: "Apps") {
                                appState.activeToolSheet = .apps
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // SECTION 3: PRODUCTIVITY
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Productivity")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.pdSecondaryText)
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            actionTile(icon: "menubar.dock.rectangle", title: "Show Desktop") {
                                connection.performSystemCommand(.showDesktop)
                            }
                            actionTile(icon: "rectangle.2.swap", title: "Alt + Tab") {
                                connection.performSystemCommand(.altTab)
                            }
                            actionTile(icon: "doc.on.doc", title: "Copy") {
                                WebRTCManager.shared.sendKeyboard(KeyboardInputPayload(action: .shortcut, shortcut: "copy"))
                            }
                            actionTile(icon: "doc.on.clipboard", title: "Paste") {
                                WebRTCManager.shared.sendKeyboard(KeyboardInputPayload(action: .shortcut, shortcut: "paste"))
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color.pdBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func actionTile(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.shared.click()
            action()
        }) {
            GlassCard(cornerRadius: 16, padding: 14) {
                VStack(spacing: 8) {
                    Circle()
                        .fill(Color.pdElevatedCard)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.pdAccentBlue)
                        )
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.pdPrimaryText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(ScaleTouchButtonStyle())
    }
}
