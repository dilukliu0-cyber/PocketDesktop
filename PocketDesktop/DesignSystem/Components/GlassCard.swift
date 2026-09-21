import SwiftUI

public struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat
    var padding: CGFloat
    var fill: Color?
    
    public init(
        cornerRadius: CGFloat = 18,
        padding: CGFloat = 16,
        isElevated: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.fill = isElevated ? Color.pdElevatedCard : Color.pdCardBackground
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill ?? Color.pdCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.pdBorder, lineWidth: 1)
                    )
            )
    }
}