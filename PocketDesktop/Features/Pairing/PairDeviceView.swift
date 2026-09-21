import SwiftUI

public struct PairDeviceView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    @State private var showingScanner = false
    @State private var showingManualCode = false
    @State private var manualPin = ""
    @State private var manualHost = "192.168.1."
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.pdBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color.pdAccentBlue.opacity(0.12))
                            .frame(width: 110, height: 110)
                        
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 54, weight: .medium))
                            .foregroundColor(.pdAccentBlue)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Connect a computer")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.pdPrimaryText)
                        
                        Text("Scan the QR code shown on your desktop screen to link this iPhone securely.")
                            .font(.system(size: 15))
                            .foregroundColor(.pdSecondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        PocketButton("Scan QR Code", icon: "camera.fill", style: .primary) {
                            showingScanner = true
                        }
                        
                        PocketButton("Enter Pairing Code", icon: "keyboard", style: .secondary) {
                            showingManualCode = true
                        }
                        
                        Button(action: {
                            DemoDesktopService.shared.populateDemoState()
                            appState.showPairingSheet = false
                            appState.hasCompletedOnboarding = true
                        }) {
                            Text("Use Sample Demo PC")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.pdSecondaryText)
                        }
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showingScanner) {
                QRScannerView { qrString in
                    showingScanner = false
                    appState.handleScannedQR(qrString)
                }
            }
            .sheet(isPresented: $showingManualCode) {
                manualCodeSheet
            }
        }
    }
    
    private var manualCodeSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Enter Pairing Code")
                    .font(.system(size: 22, weight: .bold))
                
                Text("Enter the IP address and 6-digit code displayed in Pocket Desktop on your PC.")
                    .font(.system(size: 14))
                    .foregroundColor(.pdSecondaryText)
                    .multilineTextAlignment(.center)
                
                TextField("IP Address (e.g. 192.168.1.50)", text: $manualHost)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                
                TextField("6-Digit Code", text: $manualPin)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                
                PocketButton("Connect", style: .primary) {
                    showingManualCode = false
                    // Simulate pairing with IP
                    let mockPayload = QRPairingPayload(
                        deviceId: UUID().uuidString,
                        deviceName: "Work PC",
                        osName: "Windows 11",
                        host: manualHost,
                        port: 8443,
                        fingerprint: "AA:BB:CC:DD:11:22:33:44",
                        pin: manualPin
                    )
                    if let data = try? JSONEncoder().encode(mockPayload),
                       let str = String(data: data, encoding: .utf8) {
                        appState.handleScannedQR(str)
                    }
                }
                
                Spacer()
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showingManualCode = false }
                }
            }
        }
    }
}
