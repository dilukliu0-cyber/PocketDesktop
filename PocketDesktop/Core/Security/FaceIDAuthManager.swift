import Foundation
import LocalAuthentication
import SwiftUI

public final class FaceIDAuthManager: ObservableObject {
    public static let shared = FaceIDAuthManager()
    
    @Published public var isUnlocked: Bool = true
    @Published public var biometricType: LABiometryType = .none
    
    private init() {
        checkBiometricType()
    }
    
    public func checkBiometricType() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        } else {
            biometricType = .none
        }
    }
    
    public func authenticate(reason: String = "Unlock Pocket Desktop to access your computer", completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    self.isUnlocked = success
                    completion(success)
                }
            }
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            // Fallback to passcode
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    self.isUnlocked = success
                    completion(success)
                }
            }
        } else {
            // No security configured on device
            self.isUnlocked = true
            completion(true)
        }
    }
}
