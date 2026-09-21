import SwiftUI

public struct LiveDesktopView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var connection = ConnectionManager.shared
    
    @State private var showingKeyboard = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var streamImageSize: CGSize = .zero
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Bar
                    topBarView
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.black)
                    
                    // Live Screen Display Area
                    GeometryReader { geo in
                        ZStack {
                            Color.black
                            
                            if let img = connection.liveStreamImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .scaleEffect(zoomScale)
                                    .background(GeometryReader { imgGeo in
                                        Color.clear.preference(
                                            key: ViewSizeKey.self,
                                            value: imgGeo.size
                                        )
                                    })
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
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .tint(.white.opacity(0.7))
                                    Text("Подключение к экрану ПК…")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                    Button("Запустить стрим") {
                                        connection.startStream(displayId: currentDisplayId)
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 9)
                                    .background(Color(white: 0.16))
                                    .cornerRadius(9)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    // Bottom Controls Bar
                    bottomBarControls
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.black)
                }
            }
            .navigationBarHidden(true)
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
            // Restart stream if connection was lost and restored
            .onChange(of: connection.state) { newState in
                if newState == .connected && connection.isStreaming == false {
                    connection.startStream(displayId: currentDisplayId)
                }
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
    
    // Top Bar with Close, Title, and Monitor Selector
    private var topBarView: some View {
        HStack(spacing: 12) {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color(white: 0.16)))
            }
            
            Spacer()
            
            // Monitor Switcher Pills
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
                            .foregroundColor(isSelected ? .black : .white.opacity(0.65))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelected ? Color.white : Color(white: 0.16))
                            )
                    }
                }
            }
        }
    }
    
    // Bottom Controls (Left Click, Right Click, Keyboard, Refresh)
    private var bottomBarControls: some View {
        HStack(spacing: 10) {
            Button(action: {
                Haptics.shared.click()
                connection.sendMouseClick(button: .left)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 13))
                    Text("ЛКМ")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.16)))
            }
            
            Button(action: {
                Haptics.shared.click()
                connection.sendMouseClick(button: .right)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 13))
                    Text("ПКМ")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.16)))
            }
            
            Button(action: {
                Haptics.shared.click()
                showingKeyboard = true
            }) {
                Image(systemName: "keyboard")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.pdAccentBlue))
            }
            
            Button(action: {
                Haptics.shared.click()
                connection.startStream(displayId: currentDisplayId)
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(10)
                    .background(Circle().fill(Color(white: 0.16)))
            }
        }
    }
    
    // Touch on remote screen: translate to Windows coordinates and click
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