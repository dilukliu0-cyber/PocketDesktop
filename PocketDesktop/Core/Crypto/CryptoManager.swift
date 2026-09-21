import Foundation
import CryptoKit

public final class CryptoManager {
    public static let shared = CryptoManager()
    
    private init() {}
    
    // Generate device Curve25519 keypair for key agreement
    public func generateAgreementKeyPair() -> Curve25519.KeyAgreement.PrivateKey {
        return Curve25519.KeyAgreement.PrivateKey()
    }
    
    // Compute SHA-256 fingerprint formatted as readable hex (e.g. "A1:B2:C3...")
    public func computeFingerprint(for data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02X", $0) }.joined(separator: ":")
    }
    
    // Perform ECDH key exchange to derive AES-GCM symmetric session key
    public func deriveSessionKey(
        privateKey: Curve25519.KeyAgreement.PrivateKey,
        peerPublicKeyData: Data,
        salt: Data = "PocketDesktopSalt".data(using: .utf8)!
    ) throws -> SymmetricKey {
        let peerKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: peerPublicKeyData)
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: peerKey)
        return sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: salt,
            sharedInfo: Data(),
            outputByteCount: 32
        )
    }
    
    // Encrypt payload using AES-GCM
    public func encrypt(data: Data, key: SymmetricKey) throws -> Data {
        let sealed = try AES.GCM.seal(data, using: key)
        guard let combined = sealed.combined else {
            throw CryptoError.encryptionFailed
        }
        return combined
    }
    
    // Decrypt payload using AES-GCM
    public func decrypt(combinedData: Data, key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
}

public enum CryptoError: Error, LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case invalidPeerKey
    case signatureVerificationFailed
    
    public var errorDescription: String? {
        switch self {
        case .encryptionFailed: return "Failed to encrypt payload with AES-GCM."
        case .decryptionFailed: return "Failed to decrypt payload or integrity tag mismatch."
        case .invalidPeerKey: return "Peer public key format is invalid."
        case .signatureVerificationFailed: return "Cryptographic signature check failed."
        }
    }
}
