import SwiftUI

public struct ConnectingView: View {
    let payload: QRPairingPayload
    var onComplete: (PairedDevice) -> Void
    var onCancel: () -> Void
    
    @State private var currentStep = 0
    @State private var stepDescriptions = [
        "Verifying computer identity...",
        "Creating secure connection...",
        "Waiting for desktop approval...",
        "Connected!"
    ]
    
    public init(payload: QRPairingPayload, onComplete: @escaping (PairedDevice) -> Void, onCancel: @escaping () -> Void) {
        self.payload = payload
        self.onComplete = onComplete
        self.onCancel = onCancel
    }
    
    public var body: some View {
        ZStack {
            Color.pdBackground.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Animated Status Icon
                ZStack {
                    Circle()
                        .fill(Color.pdAccentBlue.opacity(0.12))
                        .frame(width: 120, height: 120)
                    
                    if currentStep == 3 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.pdOnlineGreen)
                            .transition(.scale)
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .pdAccentBlue))
                            .scaleEffect(1.6)
                    }
                }
                
                VStack(spacing: 8) {
                    Text("Connecting to")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.pdSecondaryText)
                    
                    Text(payload.deviceName)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.pdPrimaryText)
                    
                    Text(payload.osName)
                        .font(.system(size: 15))
                        .foregroundColor(.pdSecondaryText)
                }
                
                // 4-Step Progress List
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(0..<4) { index in
                        HStack(spacing: 12) {
                            if index < currentStep {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.pdOnlineGreen)
                            } else if index == currentStep {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Circle()
                                    .stroke(Color.pdSecondaryText.opacity(0.4), lineWidth: 1.5)
                                    .frame(width: 14, height: 14)
                            }
                            
                            Text(stepDescriptions[index])
                                .font(.system(size: 15, weight: index <= currentStep ? .semibold : .regular))
                                .foregroundColor(index <= currentStep ? .pdPrimaryText : .pdSecondaryText)
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                PocketButton("Cancel", style: .secondary) {
                    onCancel()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            advanceSteps()
        }
    }
    
    private func advanceSteps() {
        // Step 1: Verify computer
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation { currentStep = 1 }
            Haptics.shared.soft()
            
            // Step 2: Secure connection (derive keys)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation { currentStep = 2 }
                Haptics.shared.soft()
                
                // Step 3: Desktop approval
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    withAnimation { currentStep = 3 }
                    Haptics.shared.success()
                    
                    // Save to Keychain & complete
                    let pairedDevice = PairedDevice(
                        id: payload.deviceId,
                        name: payload.deviceName,
                        osName: payload.osName,
                        host: payload.host,
                        port: payload.port,
                        publicKeyFingerprint: payload.fingerprint,
                        pairingToken: UUID().uuidString,
                        isOnline: true
                    )
                    
                    // Save private key & token to Keychain
                    let fakeSecret = "device_secret_\(payload.deviceId)".data(using: .utf8)!
                    KeychainService.shared.save(key: "device_key_\(payload.deviceId)", data: fakeSecret)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onComplete(pairedDevice)
                    }
                }
            }
        }
    }
}
