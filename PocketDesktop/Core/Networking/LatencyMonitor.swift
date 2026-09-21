import Foundation
import Combine

public final class LatencyMonitor: ObservableObject {
    public static let shared = LatencyMonitor()
    
    @Published public private(set) var currentLatencyMs: Int? = 12
    @Published public private(set) var currentGrade: LatencyGrade = .excellent
    
    private var pingTimestamps: [String: TimeInterval] = [:]
    private var recentSamples: [Double] = [12.0]
    
    private init() {}
    
    public func recordPingSent(id: String) {
        pingTimestamps[id] = Date().timeIntervalSince1970
    }
    
    public func recordPongReceived(id: String) {
        guard let sentTime = pingTimestamps.removeValue(forKey: id) else { return }
        let roundTripMs = (Date().timeIntervalSince1970 - sentTime) * 1000.0
        addSample(ms: roundTripMs)
    }
    
    public func updateManualLatency(ms: Int) {
        addSample(ms: Double(ms))
    }
    
    private func addSample(ms: Double) {
        recentSamples.append(ms)
        if recentSamples.count > 10 {
            recentSamples.removeFirst()
        }
        
        let avg = recentSamples.reduce(0, +) / Double(recentSamples.count)
        let rounded = Int(avg)
        self.currentLatencyMs = rounded
        
        if rounded < 30 {
            self.currentGrade = .excellent
        } else if rounded < 100 {
            self.currentGrade = .good
        } else {
            self.currentGrade = .slow
        }
    }
    
    public func markOffline() {
        self.currentLatencyMs = nil
        self.currentGrade = .offline
        self.recentSamples.removeAll()
    }
}
