import SwiftUI

public struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingSetupGuide = false
    
    private let features = [
        (icon: "cursorarrow.rays", title: "Control your computer", description: "Mobile-first trackpad, keyboard, and instant gestures."),
        (icon: "safari.fill", title: "Browse without fighting a desktop UI", description: "Remote tabs and web controller tailored for your phone."),
        (icon: "folder.fill", title: "Open files and apps", description: "Direct access to documents, downloads, and app launcher."),
        (icon: "lock.shield.fill", title: "Secure device-to-device", description: "End-to-end encryption with authenticated pairing.")
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.pdBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer(minLength: 20)
                    
                    // App Branding Header
                    VStack(spacing: 8) {
                        Image(systemName: "desktopcomputer.and.arrow.down")
                            .font(.system(size: 46, weight: .semibold))
                            .foregroundStyle(Color.pdAccentGradient)
                            .padding(.bottom, 6)
                        
                        Text("Pocket Desktop")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.pdPrimaryText)
                        
                        Text("Your computer. In your pocket.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.pdSecondaryText)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 28)
                    
                    // 4 Core Value Propositions
                    VStack(spacing: 18) {
                        ForEach(features, id: \.title) { feature in
                            HStack(alignment: .top, spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.pdElevatedCard)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: feature.icon)
                                        .font(.system(size: 19, weight: .semibold))
                                        .foregroundColor(.pdAccentBlue)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(feature.title)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.pdPrimaryText)
                                    Text(feature.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.pdSecondaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    Spacer(minLength: 32)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        PocketButton("Set up my computer", icon: "desktopcomputer", style: .primary) {
                            showingSetupGuide = true
                        }
                        
                        PocketButton("Pair with QR Code", icon: "qrcode.viewfinder", style: .secondary) {
                            appState.showPairingSheet = true
                        }
                        
                        Button(action: {
                            DemoDesktopService.shared.populateDemoState()
                            appState.hasCompletedOnboarding = true
                        }) {
                            Text("Explore Demo Mode")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.pdAccentBlue)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Install Companion App")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
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
                    
                    GlassCard(cornerRadius: 18) {
                        HStack(spacing: 12) {
                            Image(systemName: "wifi")
                                .font(.system(size: 24))
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
                    
                    Spacer(minLength: 20)
                    
                    PocketButton("I'm Ready to Scan QR", icon: "qrcode.viewfinder", style: .primary) {
                        dismiss()
                        appState.showPairingSheet = true
                    }
                }
                .padding(24)
            }
            .background(Color.pdBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func stepRow(num: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(num)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.pdAccentBlue))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.pdPrimaryText)
                Text(desc)
                    .font(.system(size: 14))
                    .foregroundColor(.pdSecondaryText)
            }
        }
    }
}
