import Foundation
import CoreGraphics
import Combine

public protocol WebRTCManagerDelegate: AnyObject {
    func webRTCDataChannelDidOpen()
    func webRTCDataChannelDidClose()
    func webRTCDidReceiveData(_ data: Data)
}

public final class WebRTCManager: ObservableObject {
    public static let shared = WebRTCManager()
    
    public weak var delegate: WebRTCManagerDelegate?
    @Published public var isDataChannelOpen: Bool = false
    @Published public var isStreamingVideo: Bool = false
    @Published public var frameRate: Int = 60
    
    private init() {}
    
    public func startSession() {
        isDataChannelOpen = true
        isStreamingVideo = true
        delegate?.webRTCDataChannelDidOpen()
    }
    
    public func stopSession() {
        isDataChannelOpen = false
        isStreamingVideo = false
        delegate?.webRTCDataChannelDidClose()
    }
    
    public func sendDataPacket(_ data: Data) {
        guard isDataChannelOpen else { return }
        // In full WebRTC build, calls RTCDataChannel.sendData
        // For local loop/relay:
        delegate?.webRTCDidReceiveData(data)
    }
    
    public func sendInput(_ payload: MouseInputPayload) {
        guard let data = try? JSONEncoder().encode(payload) else { return }
        let message = PocketMessage(type: .mouseInput, payload: data)
        if let msgData = try? JSONEncoder().encode(message) {
            sendDataPacket(msgData)
        }
    }
    
    public func sendKeyboard(_ payload: KeyboardInputPayload) {
        guard let data = try? JSONEncoder().encode(payload) else { return }
        let message = PocketMessage(type: .keyboardInput, payload: data)
        if let msgData = try? JSONEncoder().encode(message) {
            sendDataPacket(msgData)
        }
    }
}
