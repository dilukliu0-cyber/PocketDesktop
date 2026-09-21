import SwiftUI

public struct DeviceSwitcherView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var repo = DeviceRepository.shared
    @ObservedObject private var connection = ConnectionManager.shared
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Devices")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.pdPrimaryText)
                        Text("Select a computer to control or add another device.")
                            .font(.system(size: 15))
                            .foregroundColor(.pdSecondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    VStack(spacing: 12) {
                        ForEach(repo.devices) { device in
                            deviceRow(device)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    PocketButton("Add New Computer", icon: "plus.circle.fill", style: .secondary) {
                        dismiss()
                        appState.showPairingSheet = true
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .padding(.bottom, 24)
            }
            .background(Color.pdBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func deviceRow(_ device: PairedDevice) -> some View {
        let isSelected = repo.activeDeviceId == device.id
        
        return Button(action: {
            Haptics.shared.select()
            repo.activeDeviceId = device.id
            connection.connect(to: device)
            dismiss()
        }) {
            GlassCard(cornerRadius: 18, padding: 16, isElevated: isSelected) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.pdAccentBlue.opacity(0.15) : Color.pdElevatedCard)
                            .frame(width: 46, height: 46)
                        
                        Image(systemName: device.osName.contains("Mac") ? "desktopcomputer" : "pc")
                            .font(.system(size: 22))
                            .foregroundColor(isSelected ? .pdAccentBlue : .pdSecondaryText)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(device.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.pdPrimaryText)
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(device.isOnline ? Color.pdOnlineGreen : Color.pdOfflineRed)
                                .frame(width: 6, height: 6)
                            Text(device.isOnline ? "Online" : "Offline")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.pdSecondaryText)
                            Text("• \(device.osName)")
                                .font(.system(size: 12))
                                .foregroundColor(.pdSecondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.pdAccentBlue)
                            .font(.system(size: 22))
                    }
                }
            }
        }
        .buttonStyle(ScaleTouchButtonStyle())
    }
}
