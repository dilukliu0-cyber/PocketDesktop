import SwiftUI

public enum PocketButtonStyle {
    case primary
    case secondary
    case destructive
    case tile
}

public struct PocketButton: View {
    let title: String
    var icon: String? = nil
    var style: PocketButtonStyle = .primary
    var fullWidth: Bool = true
    var isLoading: Bool = false
    let action: () -> Void
    
    public init(
        _ title: String,
        icon: String? = nil,
        style: PocketButtonStyle = .primary,
        fullWidth: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.fullWidth = fullWidth
        self.isLoading = isLoading
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            Haptics.shared.click()
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.9)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(textColor)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(borderView)
        }
        .buttonStyle(ScaleTouchButtonStyle())
        .disabled(isLoading)
    }
    
    private var textColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .pdPrimaryText
        case .destructive: return .pdOfflineRed
        case .tile: return .pdPrimaryText
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            Color.pdAccentGradient
        case .secondary:
            Color.pdCardBackground
        case .destructive:
            Color.pdOfflineRed.opacity(0.12)
        case .tile:
            Color.pdElevatedCard
        }
    }
    
    @ViewBuilder
    private var borderView: some View {
        switch style {
        case .primary:
            EmptyView()
        case .secondary:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.pdBorder, lineWidth: 1)
        case .destructive:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.pdOfflineRed.opacity(0.3), lineWidth: 1)
        case .tile:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.pdBorder, lineWidth: 1)
        }
    }
}

public struct ScaleTouchButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
