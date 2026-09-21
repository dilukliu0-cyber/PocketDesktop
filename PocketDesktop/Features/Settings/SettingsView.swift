import SwiftUI

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var repo = DeviceRepository.shared
    @ObservedObject private var connection = ConnectionManager.shared
    
    @State private var showingForgetAlert = false
    
    public init() {}
    
    private var activeDevice: PairedDevice? {
        repo.activeDevice
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // ACTIVE DEVICE SECTION
                if let device = activeDevice {
                    Section(header: Text("Connected Computer")) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.pdAccentBlue.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "desktopcomputer")
                                    .font(.system(size: 20))
                                    .foregroundColor(.pdAccentBlue)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(device.name)
                                    .font(.system(size: 16, weight: .bold))
                                Text(device.osName)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Circle()
                                .fill(device.isOnline ? Color.pdOnlineGreen : Color.pdOfflineRed)
                                .frame(width: 8, height: 8)
                        }
                        
                        NavigationLink {
                            DevicePermissionsView(permissions: device.permissions)
                        } label: {
                            Label("View Computer Permissions", systemImage: "hand.raised.fill")
                        }
                    }
                    
                    // PREFERENCES SECTION
                    Section(header: Text("Device Preferences")) {
                        Toggle("Auto Connect on Launch", isOn: Binding(
                            get: { device.userSettings.autoConnect },
                            set: { val in
                                var updated = device.userSettings
                                updated.autoConnect = val
                                repo.updateDeviceSettings(deviceId: device.id, settings: updated)
                            }
                        ))
                        
                        Toggle("Haptic Feedback", isOn: Binding(
                            get: { device.userSettings.hapticFeedback },
                            set: { val in
                                var updated = device.userSettings
                                updated.hapticFeedback = val
                                Haptics.shared.isEnabled = val
                                repo.updateDeviceSettings(deviceId: device.id, settings: updated)
                            }
                        ))
                        
                        Toggle("Natural Scrolling", isOn: Binding(
                            get: { device.userSettings.naturalScrolling },
                            set: { val in
                                var updated = device.userSettings
                                updated.naturalScrolling = val
                                repo.updateDeviceSettings(deviceId: device.id, settings: updated)
                            }
                        ))
                        
                        Picker("Streaming Quality", selection: Binding(
                            get: { device.userSettings.streamingQuality },
                            set: { val in
                                var updated = device.userSettings
                                updated.streamingQuality = val
                                repo.updateDeviceSettings(deviceId: device.id, settings: updated)
                            }
                        )) {
                            ForEach(StreamingQuality.allCases, id: \.self) { quality in
                                Text(quality.rawValue).tag(quality)
                            }
                        }
                    }
                    
                    // SECURITY & PRIVACY SECTION
                    Section(header: Text("Security & Privacy")) {
                        Toggle("Require Face ID to Open", isOn: Binding(
                            get: { device.userSettings.requireFaceID },
                            set: { val in
                                var updated = device.userSettings
                                updated.requireFaceID = val
                                repo.updateDeviceSettings(deviceId: device.id, settings: updated)
                            }
                        ))
                        
                        Toggle("Hide Preview in App Switcher", isOn: Binding(
                            get: { device.userSettings.hidePreviewInAppSwitcher },
                            set: { val in
                                var updated = device.userSettings
                                updated.hidePreviewInAppSwitcher = val
                                repo.updateDeviceSettings(deviceId: device.id, settings: updated)
                            }
                        ))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Identity Fingerprint")
                                .font(.system(size: 13, weight: .medium))
                            Text(device.publicKeyFingerprint)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    
                    // FORGET COMPUTER
                    Section {
                        Button(role: .destructive, action: {
                            showingForgetAlert = true
                        }) {
                            HStack {
                                Spacer()
                                Text("Forget This Computer")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                } else {
                    Section {
                        Text("No computer paired.")
                            .foregroundColor(.secondary)
                        Button("Pair a Computer") {
                            dismiss()
                            appState.showPairingSheet = true
                        }
                    }
                }
                
                // DEMO MODE SECTION (Section 33: Clearly isolated)
                Section(header: Text("Developer Environment")) {
                    Toggle("Demo Mode (Decoupled)", isOn: $connection.isDemoMode)
                        .onChange(of: connection.isDemoMode) { _, enabled in
                            if enabled {
                                DemoDesktopService.shared.populateDemoState()
                            } else {
                                connection.disconnect()
                            }
                        }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Forget Computer?", isPresented: $showingForgetAlert) {
                Button("Forget", role: .destructive) {
                    if let id = activeDevice?.id {
                        connection.disconnect()
                        repo.removeDevice(id: id)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will securely erase the identity keys from your Keychain. You will need to scan the pairing QR code again to reconnect.")
            }
        }
    }
}
