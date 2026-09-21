import SwiftUI

public struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var connection = ConnectionManager.shared
    
    // Trackpad gesture state
    @State private var lastDragLocation: CGPoint? = nil
    @State private var isDraggingMouse: Bool = false
    @State private var sensitivity: Double = 1.35
    
    // Media speed pills
    @State private var selectedSpeed: Float = 1.0
    private let speedOptions: [Float] = [1.0, 1.25, 1.5, 2.0]
    
    // Navigation sheets
    @State private var showingSettings = false
    @State private var showingKeyboard = false
    @State private var showingStream = false
    @State private var showingWindows = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.pdBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 1. HEADER
                        headerView
                        
                        // 2. MEDIA CONTROL BAR
                        mediaControlBar
                        
                        // 3. TRACKPAD SURFACE
                        trackpadSurfaceView
                            .frame(height: 340)
                        
                        // 4. QUICK APPS ROW
                        quickAppsRow
                        
                        // 5. BOTTOM ACTION BUTTONS
                        bottomNavigationButtons
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showingKeyboard) {
                KeyboardView()
            }
            .fullScreenCover(isPresented: $showingStream) {
                LiveDesktopView()
            }
            .sheet(isPresented: $showingWindows) {
                WindowsManagerView()
            }
            .onAppear {
                connection.requestDisplays()
                connection.requestWindows()
            }
        }
    }
    
    // MARK: - 1. Header
    private var headerView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(connection.currentDevice?.name ?? "Pocket Desktop")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.pdPrimaryText)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    Text(statusText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(statusColor)
                }
            }
            
            Spacer()
            
            Button(action: {
                Haptics.shared.click()
                showingSettings = true
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.pdSecondaryText)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.pdElevatedCard))
            }
        }
    }
    
    private var statusColor: Color {
        switch connection.state {
        case .connected: return .pdOnlineGreen
        case .connecting, .authenticating, .reconnecting: return .pdWarningAmber
        default: return .pdSecondaryText
        }
    }
    
    private var statusText: String {
        switch connection.state {
        case .connected: return "Подключено"
        case .connecting, .authenticating: return "Подключение…"
        case .reconnecting: return "Переподключение"
        default: return "Отключено"
        }
    }
    
    // MARK: - 2. Media Control Bar
    private var mediaControlBar: some View {
        VStack(spacing: 10) {
            // Transport buttons
            HStack(spacing: 0) {
                Button(action: { connection.performMediaCommand(.rewind10) }) {
                    controlIcon("gobackward.10", size: 16)
                        .frame(maxWidth: .infinity)
                }
                
                Button(action: { connection.performMediaCommand(.playPause) }) {
                    Image(systemName: connection.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.pdAccentBlue)
                        .frame(maxWidth: .infinity)
                }
                
                Button(action: { connection.performMediaCommand(.stop) }) {
                    controlIcon("stop.fill", size: 18)
                        .frame(maxWidth: .infinity)
                }
                
                Button(action: { connection.performMediaCommand(.forward10) }) {
                    controlIcon("goforward.10", size: 16)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Scrubber
            HStack(spacing: 8) {
                Text("01:14")
                    .monospacedDigit()
                    .font(.system(size: 11))
                    .foregroundColor(.pdTertiaryText)
                
                Slider(value: $connection.mediaProgress, in: 0...1)
                    .tint(.pdAccentBlue)
                
                Text("04:30")
                    .monospacedDigit()
                    .font(.system(size: 11))
                    .foregroundColor(.pdTertiaryText)
            }
            
            // Speed pills
            HStack(spacing: 8) {
                ForEach(speedOptions, id: \.self) { speed in
                    let isSelected = selectedSpeed == speed
                    Button(action: {
                        Haptics.shared.select()
                        selectedSpeed = speed
                        connection.performMediaCommand(.setRate, rate: speed)
                    }) {
                        Text("\(String(format: "%g", speed))×")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isSelected ? .white : .pdSecondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelected ? Color.pdAccentBlue : Color.pdElevatedCard)
                            )
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.pdCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.pdBorder, lineWidth: 1)
                )
        )
    }
    
    private func controlIcon(_ name: String, size: CGFloat) -> some View {
        Image(systemName: name)
            .font(.system(size: size, weight: .medium))
            .foregroundColor(.pdPrimaryText)
            .frame(height: 36)
            .contentShape(Rectangle())
    }
    
    // MARK: - 3. Trackpad Surface
    private var trackpadSurfaceView: some View {
        GeometryReader { _ in
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.pdCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.pdBorder, lineWidth: 1)
                    )
                
                VStack(spacing: 10) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 36))
                        .foregroundColor(.pdTertiaryText)
                    
                    VStack(spacing: 4) {
                        Text("Тачпад")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.pdSecondaryText)
                        Text("1 палец — курсор и ЛКМ • 2 пальца — скролл и ПКМ")
                            .font(.system(size: 12))
                            .foregroundColor(.pdTertiaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                }
            }
            .contentShape(Rectangle())
            // 1. Mouse Drag & Movement Gesture (differential delta tracking)
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { val in
                        if let last = lastDragLocation {
                            let rawDx = Double(val.location.x - last.x)
                            let rawDy = Double(val.location.y - last.y)
                            
                            // Apply sensitivity and acceleration
                            let speed = hypot(rawDx, rawDy)
                            let accel = max(1.0, min(2.5, speed * 0.1))
                            let dx = rawDx * sensitivity * accel
                            let dy = rawDy * sensitivity * accel
                            
                            connection.sendMouseMove(dx: dx, dy: dy)
                        }
                        lastDragLocation = val.location
                    }
                    .onEnded { _ in
                        lastDragLocation = nil
                        if isDraggingMouse {
                            connection.sendMouseUp(button: .left)
                            isDraggingMouse = false
                        }
                    }
            )
            // 2. Tap for Left Click
            .onTapGesture(count: 1) {
                Haptics.shared.click()
                connection.sendMouseClick(button: .left)
            }
            // 3. Double Tap for Double Click
            .onTapGesture(count: 2) {
                Haptics.shared.click()
                connection.sendMouseClick(button: .left, double: true)
            }
            // 4. Long Press for Mouse Drag Start
            .onLongPressGesture(minimumDuration: 0.35) {
                Haptics.shared.warning()
                isDraggingMouse = true
                connection.sendMouseDown(button: .left)
            }
        }
    }
    
    // MARK: - Quick Open Apps Row
    private var quickAppsRow: some View {
        let apps: [DesktopWindow] = connection.openWindows.isEmpty ? [
            DesktopWindow(id: "chrome", title: "Google Chrome", appName: "chrome"),
            DesktopWindow(id: "discord", title: "Discord", appName: "Discord")
        ] : connection.openWindows
        
        return VStack(alignment: .leading, spacing: 10) {
            Text("Приложения")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.pdSecondaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(apps) { win in
                        Button(action: {
                            Haptics.shared.click()
                            showingWindows = true
                        }) {
                            HStack(spacing: 8) {
                                BrandAppIconView(appName: win.appName, size: 22)
                                Text(win.appName.isEmpty ? win.title : win.appName)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.pdPrimaryText)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.pdCardBackground))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pdBorder, lineWidth: 1))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 4. Bottom 3 Navigation Buttons
    private var bottomNavigationButtons: some View {
        HStack(spacing: 10) {
            // [ Клавиатура ]
            Button(action: {
                Haptics.shared.click()
                showingKeyboard = true
            }) {
                VStack(spacing: 5) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 18))
                    Text("Клавиатура")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.pdPrimaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.pdCardBackground))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pdBorder, lineWidth: 1))
            }
            
            // [ Стрим ]
            Button(action: {
                Haptics.shared.click()
                showingStream = true
            }) {
                VStack(spacing: 5) {
                    Image(systemName: "display")
                        .font(.system(size: 18))
                    Text("Стрим")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.pdAccentBlue))
            }
            
            // [ Окна ]
            Button(action: {
                Haptics.shared.click()
                showingWindows = true
            }) {
                VStack(spacing: 5) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 18))
                    Text("Окна")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.pdPrimaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.pdCardBackground))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pdBorder, lineWidth: 1))
            }
        }
    }
}