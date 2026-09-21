import SwiftUI
import AVFoundation

public struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    var onScanned: (String) -> Void
    
    @State private var torchOn = false
    @State private var hasPermission = true
    
    public init(onScanned: @escaping (String) -> Void) {
        self.onScanned = onScanned
    }
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            #if targetEnvironment(simulator)
            VStack(spacing: 20) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 64))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Camera not available in iOS Simulator")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                PocketButton("Simulate QR Scan (Alex's PC)", style: .primary) {
                    let sampleQR = QRPairingPayload(
                        deviceId: "alex-pc-id",
                        deviceName: "Alex’s PC",
                        osName: "Windows 11 Pro",
                        host: "192.168.1.145",
                        port: 8443,
                        fingerprint: "7A:B3:9F:44:12:88:C1:DE:60:E5:31:02:49:FF:88:9C",
                        pin: "849201"
                    )
                    if let data = try? JSONEncoder().encode(sampleQR),
                       let str = String(data: data, encoding: .utf8) {
                        onScanned(str)
                    }
                }
                .padding(.horizontal, 32)
            }
            #else
            CameraScannerRepresentable(onFoundCode: onScanned)
                .ignoresSafeArea()
            #endif
            
            // Viewfinder Overlay
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // Target bounding box
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.pdAccentBlue, lineWidth: 3)
                        .frame(width: 260, height: 260)
                        .shadow(color: Color.pdAccentBlue.opacity(0.5), radius: 12)
                    
                    Text("Align QR code within frame")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .offset(y: 155)
                }
                
                Spacer()
                
                #if !targetEnvironment(simulator)
                PocketButton("Simulate QR (Demo PC)", style: .secondary) {
                    let sampleQR = QRPairingPayload(
                        deviceId: "alex-pc-id",
                        deviceName: "Alex’s PC",
                        osName: "Windows 11 Pro",
                        host: "192.168.1.145",
                        port: 8443,
                        fingerprint: "7A:B3:9F:44:12:88:C1:DE:60:E5:31:02:49:FF:88:9C",
                        pin: "849201"
                    )
                    if let data = try? JSONEncoder().encode(sampleQR),
                       let str = String(data: data, encoding: .utf8) {
                        onScanned(str)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
                #endif
            }
        }
    }
}

#if !targetEnvironment(simulator)
struct CameraScannerRepresentable: UIViewControllerRepresentable {
    var onFoundCode: (String) -> Void
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.onCodeDetected = onFoundCode
        return vc
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeDetected: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        captureSession = session
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else { return }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            captureSession?.stopRunning()
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            onCodeDetected?(stringValue)
        }
    }
}
#endif
