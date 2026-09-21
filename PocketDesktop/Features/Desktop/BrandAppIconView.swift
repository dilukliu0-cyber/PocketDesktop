import SwiftUI

// MARK: - LITERAL BRAND APP ICONS
// Beautiful, pixel-perfect, highly recognizable vector icons for Discord, Chrome, Telegram, etc.

public struct BrandAppIconView: View {
    public let appName: String
    public let size: CGFloat
    
    public init(appName: String, size: CGFloat = 64) {
        self.appName = appName
        self.size = size
    }
    
    public var body: some View {
        let lower = appName.lowercased()
        
        Group {
            if lower.contains("discord") {
                discordIcon
            } else if lower.contains("chrome") {
                chromeIcon
            } else if lower.contains("telegram") {
                telegramIcon
            } else if lower.contains("code") || lower.contains("visual studio") {
                vscodeIcon
            } else if lower.contains("spotify") {
                spotifyIcon
            } else if lower.contains("steam") {
                steamIcon
            } else if lower.contains("explorer") || lower.contains("проводник") {
                explorerIcon
            } else {
                genericAppIcon
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.26, style: .continuous))
        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - 1. Google Chrome Icon (Iconic 3-color pinwheel + blue center)
    private var chromeIcon: some View {
        ZStack {
            Color.white
            
            // Outer Tri-Color Ring
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                // Red segment (Top)
                Circle()
                    .fill(Color(red: 0.91, green: 0.26, blue: 0.21)) // #EA4335
                
                // Yellow segment (Right / Bottom-Right)
                Path { path in
                    path.move(to: CGPoint(x: w/2, y: h/2))
                    path.addArc(center: CGPoint(x: w/2, y: h/2), radius: w/2, startAngle: .degrees(-30), endAngle: .degrees(90), clockwise: false)
                    path.closeSubpath()
                }
                .fill(Color(red: 0.98, green: 0.74, blue: 0.02)) // #FBBC05
                
                // Green segment (Bottom-Left / Left)
                Path { path in
                    path.move(to: CGPoint(x: w/2, y: h/2))
                    path.addArc(center: CGPoint(x: w/2, y: h/2), radius: w/2, startAngle: .degrees(90), endAngle: .degrees(210), clockwise: false)
                    path.closeSubpath()
                }
                .fill(Color(red: 0.20, green: 0.66, blue: 0.33)) // #34A853)
                
                // Red segment overlay (Top-Left)
                Path { path in
                    path.move(to: CGPoint(x: w/2, y: h/2))
                    path.addArc(center: CGPoint(x: w/2, y: h/2), radius: w/2, startAngle: .degrees(210), endAngle: .degrees(330), clockwise: false)
                    path.closeSubpath()
                }
                .fill(Color(red: 0.91, green: 0.26, blue: 0.21)) // #EA4335
            }
            
            // White ring separating the center
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.50, height: size * 0.50)
            
            // Google Blue center core
            Circle()
                .fill(Color(red: 0.26, green: 0.52, blue: 0.96)) // #4285F4
                .frame(width: size * 0.38, height: size * 0.38)
        }
    }
    
    // MARK: - 2. Discord Icon (Official Blurple + Clyde Face)
    private var discordIcon: some View {
        ZStack {
            // Discord Blurple Background
            Color(red: 0.35, green: 0.40, blue: 0.95) // #5865F2
            
            // Clyde Mascot Silhouette
            VStack(spacing: 0) {
                ZStack {
                    // Controller Base Shape
                    RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                        .fill(Color.white)
                        .frame(width: size * 0.64, height: size * 0.44)
                    
                    // Eyes (Cutouts in Blurple)
                    HStack(spacing: size * 0.18) {
                        Circle()
                            .fill(Color(red: 0.35, green: 0.40, blue: 0.95))
                            .frame(width: size * 0.11, height: size * 0.11)
                        
                        Circle()
                            .fill(Color(red: 0.35, green: 0.40, blue: 0.95))
                            .frame(width: size * 0.11, height: size * 0.11)
                    }
                }
            }
        }
    }
    
    // MARK: - 3. Telegram Icon (Sky Blue Circle + White Paper Airplane)
    private var telegramIcon: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.16, green: 0.67, blue: 0.93), Color(red: 0.11, green: 0.54, blue: 0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            Image(systemName: "paperplane.fill")
                .font(.system(size: size * 0.48, weight: .bold))
                .foregroundColor(.white)
                .offset(x: -size * 0.03, y: size * 0.02)
        }
    }
    
    // MARK: - 4. Visual Studio Code Icon (VS Code Blue + Ribbon Chevrons)
    private var vscodeIcon: some View {
        ZStack {
            Color(red: 0.0, green: 0.48, blue: 0.80) // #007ACC
            
            HStack(spacing: 3) {
                Image(systemName: "chevron.left")
                    .font(.system(size: size * 0.34, weight: .bold))
                Image(systemName: "chevron.right")
                    .font(.system(size: size * 0.34, weight: .bold))
            }
            .foregroundColor(.white)
        }
    }
    
    // MARK: - 5. Spotify Icon (Spotify Green + 3 Waves)
    private var spotifyIcon: some View {
        ZStack {
            Color(red: 0.11, green: 0.73, blue: 0.33) // #1DB954
            
            VStack(spacing: 3) {
                Capsule()
                    .fill(Color.white)
                    .frame(width: size * 0.48, height: size * 0.07)
                Capsule()
                    .fill(Color.white)
                    .frame(width: size * 0.40, height: size * 0.07)
                Capsule()
                    .fill(Color.white)
                    .frame(width: size * 0.32, height: size * 0.07)
            }
            .rotationEffect(.degrees(-15))
        }
    }
    
    // MARK: - 6. Steam Icon (Steam Navy Gradient + Piston Crank)
    private var steamIcon: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.15, blue: 0.22), Color(red: 0.07, green: 0.09, blue: 0.13)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Circle()
                .stroke(Color.white.opacity(0.85), lineWidth: size * 0.07)
                .frame(width: size * 0.42, height: size * 0.42)
            
            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: size * 0.16, height: size * 0.16)
        }
    }
    
    // MARK: - 7. Windows Explorer / Files
    private var explorerIcon: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.98, green: 0.72, blue: 0.12), Color(red: 0.92, green: 0.58, blue: 0.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            Image(systemName: "folder.fill")
                .font(.system(size: size * 0.52))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Generic App Icon
    private var genericAppIcon: some View {
        ZStack {
            Color.pdAccentBlue
            
            Image(systemName: "macwindow")
                .font(.system(size: size * 0.46, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}
