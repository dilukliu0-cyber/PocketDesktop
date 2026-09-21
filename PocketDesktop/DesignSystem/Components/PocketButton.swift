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
                        .scaleEffect(0.85)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                }
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(textColor)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 13)
            .padding(.horizontal, 18)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            Color.pdAccentBlue
        case .secondary:
            Color.pdCardBackground
        case .destructive:
            Color.pdOfflineRed.opacity(0.10)
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
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.pdBorder, lineWidth: 1)
        case .destructive:
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.pdOfflineRed.opacity(0.25), lineWidth: 1)
        case .tile:
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.pdBorder, lineWidth: 1)
        }
    }
}

public struct ScaleTouchButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: configuration.isPressed)
    }
}