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
                
                VStack(spacing: 12) {
                    // 1. TOP HEADER: PocketDesktop ● ПК подключен [⚙️]
                    headerView
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    // 2. MEDIA CONTROL BAR
                    mediaControlBar
                        .padding(.horizontal, 20)
                    
                    // 3. BIG TRACKPAD SURFACE (60-70% height)
                    trackpadSurfaceView
                        .padding(.horizontal, 20)
                    
                    // 4. BOTTOM 3 ACTION BUTTONS: [ Клавиатура ] [ Стрим ] [ Окна ]
                    bottomNavigationButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
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
    
    // MARK: - 1. Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("PocketDesktop")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.pdPrimaryText)
            }
            
            Spacer()
            
            // Connection Status Dot & Label
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(statusColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(statusColor.opacity(0.12)))
            
            // Settings Button
            Button(action: {
                Haptics.shared.click()
                showingSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.pdSecondaryText)
                    .padding(8)
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
        case .connected: return "ПК подключен"
        case .connecting, .authenticating: return "Подключение..."
        case .reconnecting: return "Переподключение"
        default: return "Отключен"
        }
    }
    
    // MARK: - 2. Media Control Bar
    private var mediaControlBar: some View {
        VStack(spacing: 8) {
            // Transport buttons: << -10s, Play/Pause, Stop, >> +10s
            HStack(spacing: 20) {
                // Rewind 10s
                Button(action: {
                    connection.performMediaCommand(.rewind10)
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.pdPrimaryText)
                }
                
                Spacer()
                
                // Play / Pause Toggle
                Button(action: {
                    connection.performMediaCommand(.playPause)
                }) {
                    Image(systemName: connection.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 38))
                        .foregroundColor(.pdAccentBlue)
                }
                
                Spacer()
                
                // Stop Button
                Button(action: {
                    connection.performMediaCommand(.stop)
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.pdSecondaryText)
                }
                
                Spacer()
                
                // Forward 10s
                Button(action: {
                    connection.performMediaCommand(.forward10)
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.pdPrimaryText)
                }
            }
            .padding(.horizontal, 12)
            
            // Scrubber Slider
            HStack(spacing: 8) {
                Text("01:14")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.pdSecondaryText)
                
                Slider(value: $connection.mediaProgress, in: 0...1)
                    .tint(.pdAccentBlue)
                
                Text("04:30")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.pdSecondaryText)
            }
            
            // Speed Pills: 1x, 1.25x, 1.5x, 2x
            HStack(spacing: 10) {
                ForEach(speedOptions, id: \.self) { speed in
                    let isSelected = selectedSpeed == speed
                    Button(action: {
                        Haptics.shared.select()
                        selectedSpeed = speed
                        connection.performMediaCommand(.setRate, rate: speed)
                    }) {
                        Text("\(String(format: "%g", speed))x")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(isSelected ? .white : .pdSecondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelected ? Color.pdAccentBlue : Color.pdElevatedCard)
                            )
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.pdCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.pdBorder, lineWidth: 1)
        )
    }
    
    // MARK: - 3. Massive Trackpad Surface
    private var trackpadSurfaceView: some View {
        GeometryReader { _ in
            ZStack {
                // Background Trackpad Tile
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.pdElevatedCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.pdBorder, lineWidth: 1)
                    )
                
                // Trackpad Label & Gestures Info
                VStack(spacing: 8) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 42))
                        .foregroundColor(.pdSecondaryText.opacity(0.35))
                    
                    Text("Тачпад")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.pdPrimaryText.opacity(0.6))
                    
                    Text("1 палец: курсор • Тап: ЛКМ")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.pdSecondaryText.opacity(0.7))
                    
                    Text("2 пальца: скролл / ПКМ • Удержание: Drag")
                        .font(.system(size: 11))
                        .foregroundColor(.pdSecondaryText.opacity(0.6))
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
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - 4. Bottom 3 Big Navigation Buttons
    private var bottomNavigationButtons: some View {
        HStack(spacing: 12) {
            // [ Клавиатура ]
            Button(action: {
                Haptics.shared.click()
                showingKeyboard = true
            }) {
                VStack(spacing: 6) {
                    Image(systemName: "keyboard.fill")
                        .font(.system(size: 20))
                    Text("Клавиатура")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.pdPrimaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.pdCardBackground))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pdBorder, lineWidth: 1))
            }
            
            // [ Стрим ]
            Button(action: {
                Haptics.shared.click()
                showingStream = true
            }) {
                VStack(spacing: 6) {
                    Image(systemName: "display")
                        .font(.system(size: 20))
                    Text("Стрим")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.pdAccentBlue))
            }
            
            // [ Окна ]
            Button(action: {
                Haptics.shared.click()
                showingWindows = true
            }) {
                VStack(spacing: 6) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 20))
                    Text("Окна")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.pdPrimaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.pdCardBackground))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pdBorder, lineWidth: 1))
            }
        }
    }
}
