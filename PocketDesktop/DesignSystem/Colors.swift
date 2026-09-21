import SwiftUI

// MARK: - Color Palette
// Inspired by modern, calm, Apple-native graphite and subtle neon accents
extension Color {
    static let pocketBackground = Color("Background", bundle: nil).opacity(1)
    
    // Adaptive theme colors
    static let pdBackground = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1.0) // Charcoal #121217
            : UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1.0) // Off-white #F8F8FA
    })
    
    static let pdCardBackground = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0) // #1F1F26
            : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95)
    })
    
    static let pdElevatedCard = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.16, green: 0.16, blue: 0.20, alpha: 1.0)
            : UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1.0)
    })
    
    static let pdBorder = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.black.withAlphaComponent(0.06)
    })
    
    static let pdPrimaryText = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? .white : UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
    })
    
    static let pdSecondaryText = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.systemGray : UIColor.systemGray2
    })
    
    // Brand Accents
    static let pdAccentBlue = Color(red: 0.23, green: 0.51, blue: 0.96) // #3B82F6
    static let pdAccentViolet = Color(red: 0.55, green: 0.36, blue: 0.96) // #8B5CF6
    static let pdOnlineGreen = Color(red: 0.13, green: 0.77, blue: 0.45) // #22C55E
    static let pdWarningAmber = Color(red: 0.96, green: 0.62, blue: 0.13) // #F59E0B
    static let pdOfflineRed = Color(red: 0.94, green: 0.27, blue: 0.27) // #EF4444
    
    // Gradient presets
    static let pdAccentGradient = LinearGradient(
        colors: [pdAccentBlue, pdAccentViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
