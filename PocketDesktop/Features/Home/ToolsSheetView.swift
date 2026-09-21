import SwiftUI

public struct ToolsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tools & Utilities")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.pdPrimaryText)
                        Text("Control input, browse files, and trigger shortcuts.")
                            .font(.system(size: 15))
                            .foregroundColor(.pdSecondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        toolCard(title: "Keyboard", subtitle: "System modifiers", icon: "keyboard.fill", color: .pdAccentBlue) {
                            appState.activeToolSheet = .keyboard
                        }
                        
                        toolCard(title: "Files", subtitle: "Allowed folders", icon: "folder.fill", color: .pdWarningAmber) {
                            appState.activeToolSheet = .files
                        }
                        
                        toolCard(title: "Apps", subtitle: "App Launcher", icon: "square.grid.2x2.fill", color: .pdAccentViolet) {
                            appState.activeToolSheet = .apps
                        }
                        
                        toolCard(title: "Quick Actions", subtitle: "Volume & media", icon: "bolt.fill", color: .pdOnlineGreen) {
                            appState.activeToolSheet = .quickActions
                        }
                        
                        toolCard(title: "Screenshot", subtitle: "Capture & share", icon: "camera.fill", color: .pdAccentBlue) {
                            ConnectionManager.shared.sendMessage(.requestScreenshot)
                            appState.activeToolSheet = .screenshot
                        }
                        
                        toolCard(title: "Settings", subtitle: "Preferences & security", icon: "gearshape.fill", color: .pdSecondaryText) {
                            appState.activeToolSheet = .settings
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 24)
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
    
    private func toolCard(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.shared.click()
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                action()
            }
        }) {
            GlassCard(cornerRadius: 18, padding: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(color)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.pdPrimaryText)
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.pdSecondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(ScaleTouchButtonStyle())
    }
}
