import UIKit

public final class Haptics {
    public static let shared = Haptics()
    
    public var isEnabled: Bool = true
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()
    
    private init() {
        prepare()
    }
    
    public func prepare() {
        lightImpact.prepare()
        mediumImpact.prepare()
        softImpact.prepare()
        selection.prepare()
        notification.prepare()
    }
    
    public func click() {
        guard isEnabled else { return }
        lightImpact.impactOccurred()
    }
    
    public func soft() {
        guard isEnabled else { return }
        softImpact.impactOccurred()
    }
    
    public func select() {
        guard isEnabled else { return }
        selection.selectionChanged()
    }
    
    public func medium() {
        guard isEnabled else { return }
        mediumImpact.impactOccurred()
    }
    
    public func success() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
    }
    
    public func warning() {
        guard isEnabled else { return }
        notification.notificationOccurred(.warning)
    }
    
    public func error() {
        guard isEnabled else { return }
        notification.notificationOccurred(.error)
    }
}
