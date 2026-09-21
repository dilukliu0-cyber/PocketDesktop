import SwiftUI

public struct WindowsManagerView: View {
    @ObservedObject private var connection = ConnectionManager.shared
    @State private var hoveredZone: String? = nil
    @State private var selectedDisplayId: Int = 6 // Primary
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.pdBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Header
                        headerView
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        
                        // 2. Physical Monitors with 50/50 Split Zones
                        monitorsSection
                            .padding(.horizontal, 20)
                        
                        // 3. Quick Split 50/50 Combo Button (if Chrome & Discord or any 2 apps open)
                        if appList.count >= 2 {
                            quickSplitComboBanner
                                .padding(.horizontal, 20)
                        }
                        
                        // 4. LITERAL APP ICONS (Chrome, Discord, etc.)
                        appIconsGridSection
                            .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                connection.requestDisplays()
                connection.requestWindows()
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Управление окнами")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.pdPrimaryText)
                Text("Перетащите иконку приложения на экран или нажмите кнопку")
                    .font(.system(size: 13))
                    .foregroundColor(.pdSecondaryText)
            }
            Spacer()
            Button(action: {
                Haptics.shared.click()
                connection.requestDisplays()
                connection.requestWindows()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.pdPrimaryText)
                    .padding(10)
                    .background(Circle().fill(Color.pdElevatedCard))
            }
        }
    }
    
    // MARK: - Displays List
    private var displayList: [DisplayItem] {
        if !connection.displays.isEmpty {
            return connection.displays
        }
        return [
            DisplayItem(id: 6, name: "Экран 1", isPrimary: true, bounds: DisplayRect(x: 0, y: 0, width: 1920, height: 1080), workArea: DisplayRect(x: 0, y: 0, width: 1920, height: 1032)),
            DisplayItem(id: 5, name: "Экран 2", isPrimary: false, bounds: DisplayRect(x: -1680, y: 0, width: 1344, height: 840), workArea: DisplayRect(x: -1680, y: 0, width: 1344, height: 792))
        ]
    }
    
    // Fallback known apps if windows list is currently refreshing
    private var appList: [DesktopWindow] {
        if !connection.openWindows.isEmpty {
            return connection.openWindows
        }
        return [
            DesktopWindow(id: "chrome", title: "Google Chrome", appName: "chrome"),
            DesktopWindow(id: "discord", title: "Discord", appName: "Discord"),
            DesktopWindow(id: "code", title: "VS Code", appName: "Code"),
            DesktopWindow(id: "explorer", title: "Проводник", appName: "explorer")
        ]
    }
    
    // MARK: - Monitors Section with 50/50 Halves Drop Targets
    private var monitorsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Мониторы для расстановки")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.pdPrimaryText)
            
            ForEach(displayList) { display in
                monitorCardView(display: display)
            }
        }
    }
    
    private func monitorCardView(display: DisplayItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: display.isPrimary ? "display.2" : "display")
                    .foregroundColor(display.isPrimary ? .pdAccentBlue : .pdSecondaryText)
                Text(display.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.pdPrimaryText)
                if display.isPrimary {
                    Text("Основной")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.pdAccentBlue.opacity(0.2)))
                        .foregroundColor(.pdAccentBlue)
                }
                Spacer()
                Text("\(Int(display.bounds.width))×\(Int(display.bounds.height))")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.pdSecondaryText)
            }
            
            // Visual monitor representation split into Left 50% and Right 50%
            HStack(spacing: 8) {
                // Left 50%
                snapZoneTile(display: display, zone: "left", label: "Левая 50%", icon: "rectangle.leadinghalf.filled")
                
                // Full 100%
                snapZoneTile(display: display, zone: "full", label: "100%", icon: "rectangle.fill")
                
                // Right 50%
                snapZoneTile(display: display, zone: "right", label: "Правая 50%", icon: "rectangle.trailinghalf.filled")
            }
            .frame(height: 95)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.pdCardBackground))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.pdBorder, lineWidth: 1))
    }
    
    private func snapZoneTile(display: DisplayItem, zone: String, label: String, icon: String) -> some View {
        let key = "\(display.id)_\(zone)"
        let isHovered = hoveredZone == key
        
        return VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isHovered ? .white : .pdAccentBlue)
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isHovered ? .white : .pdPrimaryText)
            Text("Перетащите сюда")
                .font(.system(size: 9))
                .foregroundColor(isHovered ? .white.opacity(0.8) : .pdSecondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovered ? Color.pdAccentBlue : Color.pdElevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? Color.white : Color.pdBorder, lineWidth: isHovered ? 2 : 1)
        )
        .onDrop(of: ["public.text", "public.plain-text"], isTargeted: Binding(
            get: { hoveredZone == key },
            set: { targeted in hoveredZone = targeted ? key : nil }
        )) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: String.self) { winId, _ in
                if let id = winId {
                    DispatchQueue.main.async {
                        Haptics.shared.success()
                        connection.sendWindowMove(windowId: id, displayId: display.id, zone: zone)
                    }
                }
            }
            return true
        }
    }
    
    // MARK: - Quick 50/50 Combo Banner
    private var quickSplitComboBanner: some View {
        let first = appList[0]
        let second = appList[1]
        let targetDisplay = displayList.first?.id ?? 6
        
        return Button(action: {
            Haptics.shared.success()
            // Snap first app to Left 50%
            connection.sendWindowMove(windowId: first.id, displayId: targetDisplay, zone: "left")
            // Snap second app to Right 50%
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                connection.sendWindowMove(windowId: second.id, displayId: targetDisplay, zone: "right")
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.split.2x1.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Сплит 50 / 50 в 1 клик")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text("\(first.appName) слева ◧ + \(second.appName) справа ◨ на Экране 1")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(14)
            .background(Color.pdAccentGradient)
            .cornerRadius(16)
        }
    }
    
    // MARK: - LITERAL APP ICONS GRID
    private var appIconsGridSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Иконки открытых приложений")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.pdPrimaryText)
                Spacer()
                Text("\(appList.count) шт.")
                    .font(.system(size: 13))
                    .foregroundColor(.pdSecondaryText)
            }
            
            // Grid of Big Colorful App Icons
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(appList) { win in
                    appIconCard(win: win)
                }
            }
        }
    }
    
    // Big App Icon Card
    private func appIconCard(win: DesktopWindow) -> some View {
        let meta = appMetadata(win.appName)
        let primaryDisp = displayList.first?.id ?? 6
        let secondaryDisp = displayList.count > 1 ? displayList[1].id : primaryDisp
        
        return VStack(spacing: 10) {
            // Big App Icon
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(meta.color)
                    .frame(width: 64, height: 64)
                    .shadow(color: meta.color.opacity(0.35), radius: 8, x: 0, y: 4)
                
                Image(systemName: meta.icon)
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            .padding(.top, 6)
            
            // App Name
            Text(win.appName.isEmpty ? win.title : win.appName)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.pdPrimaryText)
                .lineLimit(1)
            
            Divider().background(Color.pdBorder)
            
            // "Квадрат на половинку" Quick Buttons for Screen 1
            VStack(spacing: 6) {
                Text("Экран 1:")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.pdSecondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 6) {
                    // Left 50%
                    Button(action: {
                        Haptics.shared.click()
                        connection.sendWindowMove(windowId: win.id, displayId: primaryDisp, zone: "left")
                    }) {
                        HStack(spacing: 2) {
                            Image(systemName: "rectangle.leadinghalf.filled")
                            Text("50%")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.pdPrimaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.pdElevatedCard))
                    }
                    
                    // Full 100%
                    Button(action: {
                        Haptics.shared.click()
                        connection.sendWindowMove(windowId: win.id, displayId: primaryDisp, zone: "full")
                    }) {
                        Image(systemName: "rectangle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.pdPrimaryText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.pdElevatedCard))
                    }
                    
                    // Right 50%
                    Button(action: {
                        Haptics.shared.click()
                        connection.sendWindowMove(windowId: win.id, displayId: primaryDisp, zone: "right")
                    }) {
                        HStack(spacing: 2) {
                            Text("50%")
                            Image(systemName: "rectangle.trailinghalf.filled")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.pdPrimaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.pdElevatedCard))
                    }
                }
                
                // If there's a 2nd screen, provide Screen 2 buttons
                if displayList.count > 1 {
                    HStack(spacing: 6) {
                        Button(action: {
                            Haptics.shared.click()
                            connection.sendWindowMove(windowId: win.id, displayId: secondaryDisp, zone: "left")
                        }) {
                            Text("Экран 2 ◧")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.pdSecondaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.pdElevatedCard))
                        }
                        
                        Button(action: {
                            Haptics.shared.click()
                            connection.sendWindowMove(windowId: win.id, displayId: secondaryDisp, zone: "right")
                        }) {
                            Text("Экран 2 ◨")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.pdSecondaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.pdElevatedCard))
                        }
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
        // DRAG & DROP SUPPORT: Drag this app icon directly onto Screen 1 or Screen 2!
        .onDrag {
            Haptics.shared.click()
            return NSItemProvider(object: win.id as NSString)
        }
    }
    
    // Metadata helper with vivid, official brand colors for apps
    private func appMetadata(_ appName: String) -> (icon: String, color: Color) {
        let lower = appName.lowercased()
        if lower.contains("discord") {
            return ("bubble.left.and.bubble.right.fill", Color(red: 0.35, green: 0.40, blue: 0.95)) // Discord Blurple
        } else if lower.contains("chrome") {
            return ("globe.americas.fill", Color(red: 0.92, green: 0.26, blue: 0.21)) // Chrome Red
        } else if lower.contains("telegram") {
            return ("paperplane.fill", Color(red: 0.16, green: 0.67, blue: 0.93)) // Telegram Blue
        } else if lower.contains("code") {
            return ("chevron.left.forwardslash.chevron.right", Color(red: 0.0, green: 0.48, blue: 0.80)) // VS Code
        } else if lower.contains("spotify") || lower.contains("music") {
            return ("music.note", Color(red: 0.11, green: 0.73, blue: 0.33)) // Spotify Green
        } else if lower.contains("explorer") {
            return ("folder.fill", Color(red: 0.98, green: 0.66, blue: 0.0)) // Explorer Folder
        }
        return ("app.window.fill", Color.pdAccentBlue)
    }
}

public typealias SimplifiedDesktopView = WindowsManagerView
