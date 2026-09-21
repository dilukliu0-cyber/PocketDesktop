import SwiftUI

public struct DeviceCard: View {
    let device: PairedDevice?
    let connectionState: ConnectionState
    let latencyMs: Int?
    var onSwitchDevice: () -> Void
    var onStartRemote: () -> Void
    
    public init(
        device: PairedDevice?,
        connectionState: ConnectionState,
        latencyMs: Int?,
        onSwitchDevice: @escaping () -> Void,
        onStartRemote: @escaping () -> Void
    ) {
        self.device = device
        self.connectionState = connectionState
        self.latencyMs = latencyMs
        self.onSwitchDevice = onSwitchDevice
        self.onStartRemote = onStartRemote
    }
    
    public var body: some View {
        GlassCard(cornerRadius: 24, padding: 20, isElevated: true) {
            VStack(alignment: .leading, spacing: 18) {
                // Device Header Row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)
                            Text(connectionState.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(statusColor)
                        }
                        
                        Text(device?.name ?? "No PC Connected")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.pdPrimaryText)
                        
                        Text(device?.osName ?? "Tap to pair a computer")
                            .font(.system(size: 14))
                            .foregroundColor(.pdSecondaryText)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        Haptics.shared.click()
                        onSwitchDevice()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.pdSecondaryText)
                            .padding(10)
                            .background(Circle().fill(Color.pdElevatedCard))
                    }
                }
                
                Divider()
                    .background(Color.pdBorder)
                
                // Telemetry Row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connection")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.pdSecondaryText)
                        HStack(spacing: 6) {
                            Image(systemName: "wifi")
                                .font(.system(size: 12))
                                .foregroundColor(.pdAccentBlue)
                            Text(device != nil ? "Local Wi-Fi" : "--")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.pdPrimaryText)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text("Ping")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.pdSecondaryText)
                        LatencyBadge(latencyMs: latencyMs, showLabel: false)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Status")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.pdSecondaryText)
                        Text(device?.isOnline == true ? "Online" : "Offline")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(device?.isOnline == true ? .pdOnlineGreen : .pdSecondaryText)
                    }
                }
                
                // Big Action Button
                PocketButton("Start Remote Control", icon: "play.circle.fill", style: .primary) {
                    onStartRemote()
                }
                .disabled(connectionState != .connected)
            }
        }
    }
    
    private var statusColor: Color {
        switch connectionState {
        case .connected: return .pdOnlineGreen
        case .connecting, .authenticating, .reconnecting: return .pdWarningAmber
        case .disconnected, .offline: return .pdOfflineRed
        case .paused: return .pdAccentBlue
        }
    }
}
