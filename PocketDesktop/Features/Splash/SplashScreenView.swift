import SwiftUI

public struct SplashScreenView: View {
    @State private var isAnimating = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.pdBackground
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.pdCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.pdBorder, lineWidth: 1)
                        )
                        .frame(width: 96, height: 96)
                    
                    Image(systemName: "macbook.and.iphone")
                        .font(.system(size: 40, weight: .regular))
                        .foregroundColor(.pdAccentBlue)
                }
                .scaleEffect(isAnimating ? 1.0 : 0.86)
                
                VStack(spacing: 4) {
                    Text("Pocket Desktop")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.pdPrimaryText)
                    
                    Text("Your computer. In your pocket.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.pdSecondaryText)
                }
                .opacity(isAnimating ? 1.0 : 0.0)
                .offset(y: isAnimating ? 0 : 6)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
}