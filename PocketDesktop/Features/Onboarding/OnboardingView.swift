import SwiftUI

public struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingSetupGuide = false
    
    private let features = [
        (icon: "cursorarrow", title: "Управление", description: "Тачпад, клавиатура и жесты с телефона."),
        (icon: "display", title: "Стрим экрана", description: "Живая картинка рабочего стола ПК."),
        (icon: "folder", title: "Файлы и приложения", description: "Доступ к документам и запуск приложений."),
        (icon: "lock.shield", title: "Безопасность", description: "Защищённое парное подключение.")
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.pdBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer(minLength: 30)
                    
                    // Brand
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.pdCardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(Color.pdBorder, lineWidth: 1)
                                )
                                .frame(width: 84, height: 84)
                            
                            Image(systemName: "desktopcomputer.and.arrow.down")
                                .font(.system(size: 34))
                                .foregroundColor(.pdAccentBlue)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Pocket Desktop")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.pdPrimaryText)
                            Text("Your computer. In your pocket.")
                                .font(.system(size: 15))
                                .foregroundColor(.pdSecondaryText)
                        }
                    }
                    
                    Spacer(minLength: 36)
                    
                    // Features
                    VStack(spacing: 16) {
                        ForEach(features, id: \.title) { feature in
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.pdElevatedCard)
                                        .frame(width: 40, height: 40)
                                    Image(systemName: feature.icon)
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.pdAccentBlue)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(feature.title)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.pdPrimaryText)
                                    Text(feature.description)
                                        .font(.system(size: 13))
                                        .foregroundColor(.pdSecondaryText)
                                }
                                
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Actions
                    VStack(spacing: 10) {
                        PocketButton("Pair with QR Code", icon: "qrcode.viewfinder", style: .primary) {
                            appState.showPairingSheet = true
                        }
                        
                        Button(action: {
                            DemoDesktopService.shared.populateDemoState()
                            appState.hasCompletedOnboarding = true
                        }) {
                            Text("Explore Demo Mode")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.pdAccentBlue)
                        }
                        .padding(.top, 2)

                        Button(action: {
                            Haptics.shared.click()
                            showingSetupGuide = true
                        }) {
                            Text("Need help? View setup guide")
                                .font(.system(size: 13))
                                .foregroundColor(.pdSecondaryText)
                        }
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                }
            }
            .sheet(isPresented: $showingSetupGuide) {
                DesktopSetupGuideView()
            }
        }
    }
}

public struct DesktopSetupGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.pdBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Install Companion App")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.pdPrimaryText)
                            Text("Pocket Desktop needs a lightweight companion running on Windows or macOS.")
                                .font(.system(size: 15))
                                .foregroundColor(.pdSecondaryText)
                        }
                        
                        VStack(spacing: 16) {
                            stepRow(
                                num: "1",
                                title: "Download on your PC",
                                desc: "Visit getpocketdesktop.com on Windows or Mac and download the installer."
                            )
                            stepRow(
                                num: "2",
                                title: "Launch & Allow Firewall",
                                desc: "Open Pocket Desktop on your computer and grant local network access."
                            )
                            stepRow(
                                num: "3",
                                title: "Scan the Pairing QR",
                                desc: "A pairing QR code will appear on your desktop monitor. Scan it using this phone."
                            )
                        }
                        
                        GlassCard(cornerRadius: 16, padding: 14) {
                            HStack(spacing: 12) {
                                Image(systemName: "wifi")
                                    .font(.system(size: 20))
                                    .foregroundColor(.pdAccentBlue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Same Wi-Fi Network")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("Make sure your iPhone and PC are connected to the same local Wi-Fi router.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.pdSecondaryText)
                                }
                            }
                        }
                        
                        PocketButton("I'm Ready to Scan QR", icon: "qrcode.viewfinder", style: .primary) {
                            dismiss()
                            appState.showPairingSheet = true
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func stepRow(num: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(num)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.pdAccentBlue))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.pdPrimaryText)
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundColor(.pdSecondaryText)
            }
        }
    }
}