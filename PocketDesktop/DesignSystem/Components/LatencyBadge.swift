import SwiftUI

public enum LatencyGrade: String {
    case excellent = "Excellent"
    case good = "Good"
    case slow = "Slow connection"
    case offline = "Offline"
    
    var color: Color {
        switch self {
        case .excellent: return .pdOnlineGreen
        case .good: return .pdAccentBlue
        case .slow: return .pdWarningAmber
        case .offline: return .pdOfflineRed
        }
    }
}

public struct LatencyBadge: View {
    let latencyMs: Int?
    var showLabel: Bool = true
    
    private var grade: LatencyGrade {
        guard let ms = latencyMs else { return .offline }
        if ms < 30 { return .excellent }
        if ms < 100 { return .good }
        return .slow
    }
    
    public init(latencyMs: Int?, showLabel: Bool = true) {
        self.latencyMs = latencyMs
        self.showLabel = showLabel
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(grade.color)
                .frame(width: 7, height: 7)
                .shadow(color: grade.color.opacity(0.6), radius: 3)
            
            if let ms = latencyMs {
                Text("\(ms) ms")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.pdPrimaryText)
                
                if showLabel {
                    Text("• \(grade.rawValue)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.pdSecondaryText)
                }
            } else {
                Text(LatencyGrade.offline.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.pdSecondaryText)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.pdCardBackground)
                .overlay(Capsule().stroke(Color.pdBorder, lineWidth: 1))
        )
    }
}
