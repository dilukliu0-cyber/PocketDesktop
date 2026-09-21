import SwiftUI

public struct PrivacyBlurOverlayModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    let isEnabled: Bool
    
    public func body(content: Content) -> some View {
        ZStack {
            content
            
            if isEnabled && scenePhase != .active {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.pdAccentBlue)
                            Text("Pocket Desktop Protected")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    )
                    .transition(.opacity)
            }
        }
    }
}

public extension View {
    func privacyBlurProtected(isEnabled: Bool = true) -> some View {
        self.modifier(PrivacyBlurOverlayModifier(isEnabled: isEnabled))
    }
}
