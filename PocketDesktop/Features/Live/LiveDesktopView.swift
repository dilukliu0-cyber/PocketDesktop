import SwiftUI

public struct LiveDesktopView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var connection = ConnectionManager.shared
    
    @State private var showingKeyboard = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar — monitor switcher
                topBarView
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                
                // Live Screen Display Area
                GeometryReader { geo in
                    ZStack {
                        Color.black
                        
                        if let img = connection.liveStreamImage {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(zoomScale)
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onEnded { val in
                                            handleScreenTouch(val.location, in: geo.size)
                                        }
                                )
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { val in
                                            zoomScale = max(1.0, min(3.0, lastZoomScale * val))
                                        }
                                        .onEnded { _ in
                                            lastZoomScale = zoomScale
                                        }
                                )
                        } else {
                            VStack(spacing: 10) {
                                ProgressView()
                                    .tint(.white.opacity(0.6))
                                Text("Подключение…")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.5))
                                Button("Запустить") {
                                    connection.startStream(displayId: currentDisplayId)
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color(white: 0.16))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Bottom Controls
                bottomBarControls
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
        }
        .sheet(isPresented: $showingKeyboard) {
            KeyboardView()
        }
        .onAppear {
            connection.requestDisplays()
            connection.startStream(displayId: currentDisplayId)
        }
        .onDisappear {
            connection.stopStream()
        }
        .onChange(of: connection.state) { newState in
            if newState == .connected && connection.isStreaming == false {
                connection.startStream(displayId: currentDisplayId)
            }
        }
    }
    
    private var currentDisplayId: Int {
        if connection.selectedDisplayId != 0 {
            return connection.selectedDisplayId
        }
        return connection.displays.first?.id ?? 6
    }
    
    private var displayList: [DisplayItem] {
        if !connection.displays.isEmpty {
            return connection.displays
        }
        return [
            DisplayItem(id: 6, name: "Экран 1", isPrimary: true),
            DisplayItem(id: 5, name: "Экран 2", isPrimary: false)
        ]
    }
    
    // MARK: - Top Bar (Monitor Selector)
    private var topBarView: some View {
        HStack(spacing: 6) {
            ForEach(displayList) { display in
                let isSelected = (display.id == connection.selectedDisplayId || (connection.selectedDisplayId == 0 && display.id == displayList.first?.id))
                Button(action: {
                    Haptics.shared.click()
                    connection.selectedDisplayId = display.id
                    connection.startStream(displayId: display.id)
                }) {
                    Text(display.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isSelected ? .black : .white.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? Color.white : Color(white: 0.14))
                        )
                }
            }
            
            Spacer()
            
            Button(action: {
                Haptics.shared.click()
                connection.startStream(displayId: currentDisplayId)
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color(white: 0.14)))
            }
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomBarControls: some View {
        HStack(spacing: 8) {
            Button(action: {
                Haptics.shared.click()
                connection.sendMouseClick(button: .left)
            }) {
                Text("ЛКМ")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.14)))
            }
            
            Button(action: {
                Haptics.shared.click()
                connection.sendMouseClick(button: .right)
            }) {
                Text("ПКМ")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.14)))
            }
            
            Button(action: {
                Haptics.shared.click()
                showingKeyboard = true
            }) {
                Image(systemName: "keyboard")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.pdAccentBlue))
            }
        }
    }
    
    // Touch on remote screen → Windows coordinates
    private func handleScreenTouch(_ location: CGPoint, in containerSize: CGSize) {
        guard containerSize.width > 0, containerSize.height > 0 else { return }
        Haptics.shared.click()
        
        let activeDisplay = connection.displays.first(where: { $0.id == currentDisplayId })
        let bounds = activeDisplay?.bounds ?? DisplayRect(x: 0, y: 0, width: 1920, height: 1080)
        
        let normX = max(0.0, min(1.0, Double(location.x / containerSize.width)))
        let normY = max(0.0, min(1.0, Double(location.y / containerSize.height)))
        
        let targetX = bounds.x + (normX * bounds.width)
        let targetY = bounds.y + (normY * bounds.height)
        
        connection.sendMouseSet(x: targetX, y: targetY)
        connection.sendMouseClick(button: .left)
    }
}

private struct ViewSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}