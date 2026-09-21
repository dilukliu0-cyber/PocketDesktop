import SwiftUI

public struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16
    var isElevated: Bool = false
    
    public init(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 16,
        isElevated: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.isElevated = isElevated
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isElevated ? Color.pdElevatedCard : Color.pdCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.pdBorder, lineWidth: 1)
                    )
                    .shadow(
                        color: Color.black.opacity(isElevated ? 0.15 : 0.06),
                        radius: isElevated ? 16 : 8,
                        x: 0,
                        y: isElevated ? 8 : 4
                    )
            )
    }
}
