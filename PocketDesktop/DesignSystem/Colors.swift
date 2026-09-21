import SwiftUI

// MARK: - Color Palette
// Restrained, Apple-like neutrals with a single calm indigo accent.
// No neon, no heavy gradients — clean, quiet, professional.

extension Color {
    static let pocketBackground = Color("Background", bundle: nil).opacity(1)
    
    // Adaptive theme colors
    static let pdBackground = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.055, green: 0.055, blue: 0.067, alpha: 1.0)  // #0E0E11
            : UIColor(red: 0.965, green: 0.965, blue: 0.973, alpha: 1.0) // #F6F6F8
    })
    
    static let pdCardBackground = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.090, green: 0.090, blue: 0.106, alpha: 1.0) // #17171B
            : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    })
    
    static let pdElevatedCard = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.133, green: 0.133, blue: 0.153, alpha: 1.0) // #222228
            : UIColor(red: 0.933, green: 0.937, blue: 0.945, alpha: 1.0) // #EEEF F1
    })
    
    static let pdBorder = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.09)
            : UIColor.black.withAlphaComponent(0.07)
    })
    
    static let pdPrimaryText = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1.0)
            : UIColor(red: 0.10, green: 0.105, blue: 0.125, alpha: 1.0)
    })
    
    static let pdSecondaryText = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.58, green: 0.58, blue: 0.63, alpha: 1.0)
            : UIColor(red: 0.52, green: 0.53, blue: 0.56, alpha: 1.0)
    })
    
    static let pdTertiaryText = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.40, green: 0.40, blue: 0.44, alpha: 1.0)
            : UIColor(red: 0.70, green: 0.71, blue: 0.73, alpha: 1.0)
    })
    
    // Brand Accent — single calm indigo, shared across light & dark
    static let pdAccentBlue = Color(red: 0.235, green: 0.392, blue: 0.961) // #3C64F5
    static let pdAccentBluePressed = Color(red: 0.180, green: 0.320, blue: 0.850)
    
    // Soft accent tints (usable for subtle backgrounds)
    static let pdAccentTint = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.235, green: 0.392, blue: 0.961, alpha: 0.22)
            : UIColor(red: 0.235, green: 0.392, blue: 0.961, alpha: 0.10)
    })
    
    // Status colors — calm system palette
    static let pdOnlineGreen = Color(red: 0.20, green: 0.78, blue: 0.38) // #34C759
    static let pdWarningAmber = Color(red: 1.0, green: 0.62, blue: 0.04) // #FF9F0A
    static let pdOfflineRed = Color(red: 1.0, green: 0.23, blue: 0.19)   // #FF3B30
    
    // Reserved for rare multi-color moments (kept quiet)
    static let pdAccentViolet = Color(red: 0.40, green: 0.34, blue: 0.80) // #675CE8
    
    // Soft gradient preset (used only sparingly, e.g. splash mark)
    static let pdAccentGradient = LinearGradient(
        colors: [Color(red: 0.235, green: 0.392, blue: 0.961),
                 Color(red: 0.365, green: 0.300, blue: 0.940)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}