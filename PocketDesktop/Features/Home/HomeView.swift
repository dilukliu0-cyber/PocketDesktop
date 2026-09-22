import SwiftUI

public struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var connection = ConnectionManager.shared
    
    // Trackpad gesture state
    @State private var lastDragLocation: CGPoint? = nil
    @State private var isDraggingMouse: Bool = false
    @State private var sensitivity: Double = 1.35
    
    // Navigation sheets
    @State private var showingSettings = false
    @State private var showingKeyboard = false
    @State private var showingWindows = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1. COMPACT HEADER
                headerView
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                
                // 2. QUICK APPS ROW
                quickAppsRow
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                
                // 3. TRACKPAD — fills all remaining space
                trackpadSurfaceView
                    .padding(.horizontal, 16)
                
                // 4. KEYBOARD BUTTON
                keyboardButton
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
            }
            .background(Color.pdBackground.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showingKeyboard) {
                KeyboardView()
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
    
    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(connection.currentDevice?.name ?? "Pocket Desktop")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.pdPrimaryText)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    Text(statusText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(statusColor)
                }
            }
            
            Spacer()
            
            Button(action: {
                Haptics.shared.click()
                showingSettings = true
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.pdSecondaryText)
                    .frame(width: 34, height: 34)
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
    
    // MARK: - Quick Apps Row
    private var quickAppsRow: some View {
        let apps: [DesktopWindow] = connection.openWindows.isEmpty ? [
            DesktopWindow(id: "chrome", title: "Google Chrome", appName: "chrome"),
            DesktopWindow(id: "discord", title: "Discord", appName: "Discord")
        ] : connection.openWindows
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(apps) { win in
                    Button(action: {
                        Haptics.shared.click()
                        showingWindows = true
                    }) {
                        HStack(spacing: 6) {
                            BrandAppIconView(appName: win.appName, size: 20)
                            Text(win.appName.isEmpty ? win.title : win.appName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.pdPrimaryText)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.pdCardBackground))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.pdBorder, lineWidth: 0.5))
                    }
                }
            }
        }
    }
    
    // MARK: - Trackpad Surface (fills remaining space)
    private var trackpadSurfaceView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.pdCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.pdBorder, lineWidth: 0.5)
                )
            
            Text("Тачпад")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.pdTertiaryText.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    // MARK: - Keyboard Button
    private var keyboardButton: some View {
        Button(action: {
            Haptics.shared.click()
            showingKeyboard = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "keyboard")
                    .font(.system(size: 15))
                Text("Клавиатура")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.pdPrimaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.pdCardBackground))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pdBorder, lineWidth: 0.5))
        }
    }
}