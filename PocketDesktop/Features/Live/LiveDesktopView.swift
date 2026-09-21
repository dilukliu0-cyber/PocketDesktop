import SwiftUI

public struct LiveDesktopView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var connection = ConnectionManager.shared
    @ObservedObject private var latency = LatencyMonitor.shared
    
    @State private var overlayVisible = true
    @State private var overlayTimer: Timer?
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @State private var lastPanOffset: CGSize = .zero
    @State private var showingKeyboard = false
    @State private var showingTrackpad = false
    
    private let mapper = TouchCoordinateMapper(desktopSize: DesktopScreenDimension(width: 1920, height: 1080))
    
    public init() {}
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Desktop Screen Stream / Surface
                remoteDesktopSurface(proxy: proxy)
                    .scaleEffect(zoomScale)
                    .offset(panOffset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { val in
                                zoomScale = max(1.0, min(3.5, lastZoomScale * val))
                                resetOverlayTimer()
                            }
                            .onEnded { _ in
                                lastZoomScale = zoomScale
                            }
                    )
                    .gesture(
                        DragGesture(minimumDistance: 4)
                            .onChanged { val in
                                handleDragGesture(val, viewSize: proxy.size)
                                resetOverlayTimer()
                            }
                    )
                    .onTapGesture(count: 2) {
                        handleDoubleTap(viewSize: proxy.size)
                        resetOverlayTimer()
                    }
                    .onTapGesture(count: 1) {
                        handleSingleTap(viewSize: proxy.size)
                        resetOverlayTimer()
                    }
                
                // Floating Auto-Hiding Controls Overlay
                if overlayVisible {
                    overlayControls
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .statusBar(hidden: !overlayVisible)
        .onAppear {
            startOverlayTimer()
        }
        .onDisappear {
            overlayTimer?.invalidate()
        }
        .sheet(isPresented: $showingKeyboard) {
            KeyboardView()
        }
        .sheet(isPresented: $showingTrackpad) {
            TrackpadView()
        }
    }
    
    // Remote Display Surface Canvas
    private func remoteDesktopSurface(proxy: GeometryProxy) -> some View {
        ZStack {
            // Simulated desktop workspace canvas
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color(red: 0.10, green: 0.13, blue: 0.20), Color(red: 0.05, green: 0.07, blue: 0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .overlay(
                    VStack {
                        // Desktop Taskbar Preview
                        Spacer()
                        HStack(spacing: 12) {
                            Image(systemName: "square.grid.2x2.fill")
                                .foregroundColor(.pdAccentBlue)
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text(Date().formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                    }
                )
                .overlay(
                    // Active Window Representation in Stream
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            VStack(spacing: 4) {
                                HStack {
                                    Circle().fill(.red).frame(width: 8, height: 8)
                                    Circle().fill(.yellow).frame(width: 8, height: 8)
                                    Circle().fill(.green).frame(width: 8, height: 8)
                                    Spacer()
                                    Text(connection.openWindows.first?.title ?? "Pocket Desktop Stream")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .padding(.top, 6)
                                
                                Spacer()
                                Image(systemName: "macbook.and.iphone")
                                    .font(.system(size: 38))
                                    .foregroundColor(.white.opacity(0.3))
                                Spacer()
                            }
                        )
                        .frame(width: proxy.size.width * 0.75, height: proxy.size.height * 0.45)
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Top & Bottom Overlay HUD
    private var overlayControls: some View {
        VStack {
            // Top Bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.85))
                }
                
                Spacer()
                
                // Latency & Host badge
                HStack(spacing: 8) {
                    Circle().fill(Color.pdOnlineGreen).frame(width: 7, height: 7)
                    Text(connection.currentDevice?.name ?? "Alex's PC")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text("•")
                        .foregroundColor(.white.opacity(0.5))
                    Text("\(latency.currentLatencyMs ?? 12) ms")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(.ultraThinMaterial))
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        zoomScale = 1.0
                        panOffset = .zero
                    }
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Spacer()
            
            // Bottom Action Bar
            HStack(spacing: 16) {
                overlayButton(icon: "keyboard", label: "Keyboard") {
                    showingKeyboard = true
                }
                overlayButton(icon: "hand.draw", label: "Trackpad") {
                    showingTrackpad = true
                }
                overlayButton(icon: "camera.fill", label: "Screenshot") {
                    connection.sendMessage(.requestScreenshot)
                    appState.activeToolSheet = .screenshot
                }
                overlayButton(icon: "power", label: "Disconnect", isDestructive: true) {
                    connection.disconnect()
                    dismiss()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
            )
            .padding(.bottom, 24)
        }
    }
    
    private func overlayButton(icon: String, label: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.shared.click()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isDestructive ? .pdOfflineRed : .white)
            .frame(width: 62)
        }
    }
    
    private func startOverlayTimer() {
        overlayTimer?.invalidate()
        overlayTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                overlayVisible = false
            }
        }
    }
    
    private func resetOverlayTimer() {
        withAnimation(.easeIn(duration: 0.2)) {
            overlayVisible = true
        }
        startOverlayTimer()
    }
    
    private func handleSingleTap(viewSize: CGSize) {
        Haptics.shared.click()
        WebRTCManager.shared.sendInput(MouseInputPayload(action: .click, button: .left))
    }
    
    private func handleDoubleTap(viewSize: CGSize) {
        Haptics.shared.click()
        WebRTCManager.shared.sendInput(MouseInputPayload(action: .doubleClick, button: .left))
    }
    
    private func handleDragGesture(_ val: DragGesture.Value, viewSize: CGSize) {
        let deltaX = Double(val.translation.width)
        let deltaY = Double(val.translation.height)
        WebRTCManager.shared.sendInput(MouseInputPayload(
            action: .move,
            deltaX: deltaX,
            deltaY: deltaY
        ))
    }
}
