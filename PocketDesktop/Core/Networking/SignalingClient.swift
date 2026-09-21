import Foundation
import Combine

public protocol SignalingClientDelegate: AnyObject {
    func signalingDidConnect()
    func signalingDidDisconnect(error: Error?)
    func signalingDidReceiveMessage(_ message: PocketMessage)
}

public final class SignalingClient: NSObject, URLSessionWebSocketDelegate {
    public weak var delegate: SignalingClientDelegate?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var pingTimer: Timer?
    private var isConnected = false
    
    private let queue = DispatchQueue(label: "com.pocketdesktop.signaling", qos: .userInitiated)
    
    public override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 30.0
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
    }
    
    public func connect(host: String, port: Int) {
        disconnect()
        
        let urlString = "ws://\(host):\(port)/ws"
        guard let url = URL(string: urlString) else { return }
        
        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()
        
        listenForMessages()
        startPingTimer()
    }
    
    public func disconnect() {
        stopPingTimer()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
    }
    
    public func send(message: PocketMessage) {
        guard let data = try? JSONEncoder().encode(message),
              let string = String(data: data, encoding: .utf8) else { return }
        
        let wsMessage = URLSessionWebSocketTask.Message.string(string)
        webSocketTask?.send(wsMessage) { [weak self] error in
            if let error = error {
                self?.delegate?.signalingDidDisconnect(error: error)
            }
        }
    }
    
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let wsMessage):
                self.handleWebSocketMessage(wsMessage)
                self.listenForMessages() // Keep listening loop active
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.delegate?.signalingDidDisconnect(error: error)
                }
            }
        }
    }
    
    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) {
        let rawData: Data?
        switch message {
        case .string(let text):
            rawData = text.data(using: .utf8)
        case .data(let data):
            rawData = data
        @unknown default:
            rawData = nil
        }
        
        guard let data = rawData,
              let pocketMessage = try? JSONDecoder().decode(PocketMessage.self, from: data) else {
            return
        }
        
        DispatchQueue.main.async {
            self.delegate?.signalingDidReceiveMessage(pocketMessage)
        }
    }
    
    private func startPingTimer() {
        stopPingTimer()
        DispatchQueue.main.async {
            self.pingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
                let pingMsg = PocketMessage(type: .ping)
                LatencyMonitor.shared.recordPingSent(id: pingMsg.id)
                self?.send(message: pingMsg)
            }
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    // URLSessionWebSocketDelegate
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
        DispatchQueue.main.async {
            self.delegate?.signalingDidConnect()
        }
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
        DispatchQueue.main.async {
            self.delegate?.signalingDidDisconnect(error: nil)
        }
    }
}
