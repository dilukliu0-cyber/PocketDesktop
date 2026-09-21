import XCTest
import CoreGraphics
import CryptoKit
@testable import PocketDesktop

final class PocketDesktopTests: XCTestCase {
    
    // MARK: - Protocol Framing Tests
    func testProtocolSerialization() throws {
        let sampleWindow = DesktopWindow(
            id: "test_win_1",
            title: "Test Editor",
            appName: "VS Code",
            isFocused: true
        )
        
        guard let message = PocketMessage.make(type: .windowsList, data: [sampleWindow]) else {
            XCTFail("Failed to encode pocket message")
            return
        }
        
        let jsonData = try JSONEncoder().encode(message)
        let decodedMessage = try JSONDecoder().decode(PocketMessage.self, from: jsonData)
        
        XCTAssertEqual(decodedMessage.type, .windowsList)
        let decodedWindows = decodedMessage.decodePayload([DesktopWindow].self)
        XCTAssertNotNil(decodedWindows)
        XCTAssertEqual(decodedWindows?.count, 1)
        XCTAssertEqual(decodedWindows?.first?.title, "Test Editor")
    }
    
    // MARK: - Cryptographic Tests
    func testCryptoKeyAgreementAndEncryption() throws {
        let crypto = CryptoManager.shared
        
        // Client & Server keypairs
        let clientKey = crypto.generateAgreementKeyPair()
        let serverKey = crypto.generateAgreementKeyPair()
        
        let clientPublic = clientKey.publicKey.rawRepresentation
        let serverPublic = serverKey.publicKey.rawRepresentation
        
        // Compute fingerprints
        let fingerprint = crypto.computeFingerprint(for: clientPublic)
        XCTAssertFalse(fingerprint.isEmpty)
        XCTAssertTrue(fingerprint.contains(":"))
        
        // Derive symmetric session keys
        let clientSessionKey = try crypto.deriveSessionKey(privateKey: clientKey, peerPublicKeyData: serverPublic)
        let serverSessionKey = try crypto.deriveSessionKey(privateKey: serverKey, peerPublicKeyData: clientPublic)
        
        // Test AES-GCM Encryption / Decryption
        let plaintext = "Sensitive Desktop Session Data".data(using: .utf8)!
        let ciphertext = try crypto.encrypt(data: plaintext, key: clientSessionKey)
        let decrypted = try crypto.decrypt(combinedData: ciphertext, key: serverSessionKey)
        
        XCTAssertEqual(plaintext, decrypted)
    }
    
    // MARK: - Touch Coordinate Mapping Tests
    func testCoordinateMapping() {
        let mapper = TouchCoordinateMapper(desktopSize: DesktopScreenDimension(width: 1920, height: 1080))
        
        // Scenario 1: Exact 16:9 view (no letterboxing)
        let viewSize16x9 = CGSize(width: 320, height: 180)
        let centerTouch = CGPoint(x: 160, y: 90)
        let mappedCenter = mapper.map(touchPoint: centerTouch, viewSize: viewSize16x9)
        
        XCTAssertNotNil(mappedCenter)
        XCTAssertEqual(mappedCenter?.x ?? 0, 960, accuracy: 1.0)
        XCTAssertEqual(mappedCenter?.y ?? 0, 540, accuracy: 1.0)
        
        // Scenario 2: Tall portrait view (letterboxing top and bottom)
        let portraitView = CGSize(width: 393, height: 852) // iPhone 15 Pro
        let topDeadZone = CGPoint(x: 196, y: 20) // Outside active desktop bounds
        let mappedOut = mapper.map(touchPoint: topDeadZone, viewSize: portraitView)
        XCTAssertNil(mappedOut, "Touches in letterboxed letterbox margins must be rejected")
    }
    
    // MARK: - Device Repository Tests
    func testDeviceRepositoryManagement() {
        let repo = DeviceRepository.shared
        let testDevice = PairedDevice(
            id: "unit-test-pc",
            name: "Test Rig",
            osName: "Windows 11",
            host: "127.0.0.1",
            publicKeyFingerprint: "11:22:33:44",
            pairingToken: "token123"
        )
        
        repo.addOrUpdateDevice(testDevice)
        XCTAssertTrue(repo.devices.contains(where: { $0.id == "unit-test-pc" }))
        
        repo.removeDevice(id: "unit-test-pc")
        XCTAssertFalse(repo.devices.contains(where: { $0.id == "unit-test-pc" }))
    }
}
