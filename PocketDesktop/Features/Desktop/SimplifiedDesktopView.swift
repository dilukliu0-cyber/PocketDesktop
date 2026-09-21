import SwiftUI

public struct WindowsManagerView: View {
    @ObservedObject private var connection = ConnectionManager.shared
    @State private var hoveredZone: String? = nil
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.pdBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header info
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Управление окнами")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.pdPrimaryText)
                                Text("Перетащите окно в зону монитора или используйте кнопки")
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
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        // PHYSICAL MONITORS SECTION
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Физические мониторы (\(displayList.count))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.pdPrimaryText)
                                .padding(.horizontal, 20)
                            
                            ForEach(displayList) { display in
                                monitorDropTargetView(display: display)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // OPEN WINDOWS SECTION
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Открытые приложения (\(connection.openWindows.count))")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.pdPrimaryText)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            if connection.openWindows.isEmpty {
                                emptyWindowsView
                                    .padding(.horizontal, 20)
                            } else {
                                ForEach(connection.openWindows) { win in
                                    windowCard(win: win)
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 32)
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
    
    // Fallback if displays not yet populated
    private var displayList: [DisplayItem] {
        if !connection.displays.isEmpty {
            return connection.displays
        }
        // Default detected dual displays if waiting for network packet
        return [
            DisplayItem(id: 6, name: "Экран 1", isPrimary: true, bounds: DisplayRect(x: 0, y: 0, width: 1920, height: 1080), workArea: DisplayRect(x: 0, y: 0, width: 1920, height: 1032)),
            DisplayItem(id: 5, name: "Экран 2", isPrimary: false, bounds: DisplayRect(x: -1680, y: 0, width: 1344, height: 840), workArea: DisplayRect(x: -1680, y: 0, width: 1344, height: 792))
        ]
    }
    
    // Physical Monitor Canvas with 3 Snap Zones (Left 50%, Full 100%, Right 50%)
    private func monitorDropTargetView(display: DisplayItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.pdSecondaryText)
            }
            
            // 3 Snap Target Zones inside monitor
            HStack(spacing: 8) {
                // Zone Left 50%
                snapDropZone(display: display, zone: "left", label: "Левая 50%", icon: "rectangle.leadinghalf.filled")
                
                // Zone Full 100%
                snapDropZone(display: display, zone: "full", label: "Весь экран", icon: "rectangle.fill")
                
                // Zone Right 50%
                snapDropZone(display: display, zone: "right", label: "Правая 50%", icon: "rectangle.trailinghalf.filled")
            }
            .frame(height: 90)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.pdCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.pdBorder, lineWidth: 1)
        )
    }
    
    // Interactive snap drop zone button & drop target
    private func snapDropZone(display: DisplayItem, zone: String, label: String, icon: String) -> some View {
        let key = "\(display.id)_\(zone)"
        let isHovered = hoveredZone == key
        
        return Button(action: {
            // If user taps, snap first focused window
            if let first = connection.openWindows.first {
                connection.sendWindowMove(windowId: first.id, displayId: display.id, zone: zone)
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isHovered ? .white : .pdAccentBlue)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isHovered ? .white : .pdPrimaryText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHovered ? Color.pdAccentBlue.opacity(0.8) : Color.pdElevatedCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isHovered ? Color.white : Color.pdBorder.opacity(0.7), lineWidth: isHovered ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .onDrop(of: ["public.text", "public.plain-text"], isTargeted: Binding(
            get: { hoveredZone == key },
            set: { targeted in
                hoveredZone = targeted ? key : nil
            }
        )) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: String.self) { stringVal, _ in
                if let winId = stringVal {
                    DispatchQueue.main.async {
                        connection.sendWindowMove(windowId: winId, displayId: display.id, zone: zone)
                    }
                }
            }
            return true
        }
    }
    
    // Window Card with draggable support & quick action snap buttons
    private func windowCard(win: DesktopWindow) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // App Icon
                Image(systemName: iconForApp(win.appName))
                    .font(.system(size: 22))
                    .foregroundColor(.pdAccentBlue)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.pdElevatedCard))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(win.title.isEmpty ? win.appName : win.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.pdPrimaryText)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(win.appName)
                            .font(.system(size: 12))
                            .foregroundColor(.pdSecondaryText)
                        
                        if let dId = win.displayId {
                            Text("Экран \(dId)")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.pdElevatedCard))
                                .foregroundColor(.pdSecondaryText)
                        }
                    }
                }
                
                Spacer()
                
                // Focus & Close Buttons
                HStack(spacing: 6) {
                    Button(action: {
                        connection.performWindowAction(windowId: win.id, action: .focus)
                    }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.pdSecondaryText)
                            .padding(8)
                            .background(Circle().fill(Color.pdElevatedCard))
                    }
                    
                    Button(action: {
                        connection.performWindowAction(windowId: win.id, action: .close)
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.pdWarningAmber)
                            .padding(8)
                            .background(Circle().fill(Color.pdElevatedCard))
                    }
                }
            }
            
            Divider().background(Color.pdBorder)
            
            // Quick Snap Buttons for each display
            VStack(spacing: 8) {
                ForEach(displayList) { display in
                    HStack(spacing: 8) {
                        Text(display.name)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.pdSecondaryText)
                            .frame(width: 60, alignment: .leading)
                        
                        Button(action: {
                            connection.sendWindowMove(windowId: win.id, displayId: display.id, zone: "left")
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "rectangle.leadinghalf.filled")
                                Text("50% Лево")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.pdPrimaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.pdElevatedCard))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.pdBorder, lineWidth: 1))
                        }
                        
                        Button(action: {
                            connection.sendWindowMove(windowId: win.id, displayId: display.id, zone: "full")
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "rectangle.fill")
                                Text("100%")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.pdPrimaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.pdElevatedCard))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.pdBorder, lineWidth: 1))
                        }
                        
                        Button(action: {
                            connection.sendWindowMove(windowId: win.id, displayId: display.id, zone: "right")
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "rectangle.trailinghalf.filled")
                                Text("50% Право")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.pdPrimaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.pdElevatedCard))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.pdBorder, lineWidth: 1))
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.pdCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.pdBorder, lineWidth: 1)
        )
        .onDrag {
            Haptics.shared.click()
            return NSItemProvider(object: win.id as NSString)
        }
    }
    
    private var emptyWindowsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "macwindow.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.pdSecondaryText.opacity(0.6))
            Text("Нет обнаруженных окон")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.pdPrimaryText)
            Text("Откройте приложения на ПК (Discord, Chrome, проводник) и нажмите Обновить")
                .font(.system(size: 13))
                .foregroundColor(.pdSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.pdCardBackground))
    }
    
    private func iconForApp(_ appName: String) -> String {
        let lower = appName.lowercased()
        if lower.contains("chrome") || lower.contains("edge") || lower.contains("brave") || lower.contains("firefox") {
            return "globe"
        } else if lower.contains("discord") || lower.contains("telegram") || lower.contains("slack") {
            return "bubble.left.and.bubble.right.fill"
        } else if lower.contains("code") || lower.contains("terminal") || lower.contains("powershell") {
            return "chevron.left.forwardslash.chevron.right"
        } else if lower.contains("music") || lower.contains("spotify") {
            return "music.note"
        } else if lower.contains("explorer") {
            return "folder.fill"
        }
        return "app.window.fill"
    }
}

public typealias SimplifiedDesktopView = WindowsManagerView
