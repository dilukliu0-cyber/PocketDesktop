import SwiftUI

public struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var glowOpacity = 0.4
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.pdBackground
                .ignoresSafeArea()
            
            // Subtle ambient background glow
            Circle()
                .fill(Color.pdAccentBlue.opacity(0.15))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(y: -40)
            
            VStack(spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(Color.pdAccentGradient)
                        .frame(width: 108, height: 108)
                        .shadow(color: Color.pdAccentBlue.opacity(glowOpacity), radius: 24, x: 0, y: 12)
                    
                    Image(systemName: "macbook.and.iphone")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundColor(.white)
                }
                .scaleEffect(isAnimating ? 1.0 : 0.85)
                
                VStack(spacing: 8) {
                    Text("Pocket Desktop")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.pdPrimaryText)
                    
                    Text("Your computer. In your pocket.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.pdSecondaryText)
                }
                .opacity(isAnimating ? 1.0 : 0.0)
                .offset(y: isAnimating ? 0 : 10)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                isAnimating = true
                glowOpacity = 0.7
            }
        }
    }
}
