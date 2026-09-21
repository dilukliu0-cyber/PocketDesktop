import SwiftUI

public struct ConnectionErrorView: View {
    @ObservedObject private var connection = ConnectionManager.shared
    var onRetry: () -> Void
    var onSwitchDevice: () -> Void
    
    public init(onRetry: @escaping () -> Void, onSwitchDevice: @escaping () -> Void) {
        self.onRetry = onRetry
        self.onSwitchDevice = onSwitchDevice
    }
    
    public var body: some View {
        ZStack {
            Color.pdBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.pdOfflineRed.opacity(0.12))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 46))
                        .foregroundColor(.pdOfflineRed)
                }
                
                VStack(spacing: 8) {
                    Text(connection.currentDevice?.name ?? "Computer")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.pdPrimaryText)
                    
                    Text("Offline")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.pdOfflineRed)
                    
                    Text("Last seen \(connection.currentDevice?.lastSeen.formatted(date: .omitted, time: .shortened) ?? "recently")")
                        .font(.system(size: 14))
                        .foregroundColor(.pdSecondaryText)
                }
                
                GlassCard(cornerRadius: 18, padding: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Troubleshooting Checklist:")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.pdPrimaryText)
                        
                        bulletPoint("Ensure Pocket Desktop is running on your PC")
                        bulletPoint("Confirm your iPhone and PC are on the same Wi-Fi")
                        bulletPoint("Check that Windows Firewall allows local port 8443")
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                VStack(spacing: 12) {
                    PocketButton("Retry Connection", icon: "arrow.clockwise", style: .primary) {
                        onRetry()
                    }
                    
                    PocketButton("Switch Device", icon: "laptopcomputer.and.iphone", style: .secondary) {
                        onSwitchDevice()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.pdAccentBlue)
                .fontWeight(.bold)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.pdSecondaryText)
        }
    }
}
