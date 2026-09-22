import SwiftUI

public struct WindowsManagerView: View {
    @ObservedObject private var connection = ConnectionManager.shared
    @State private var hoveredZone: String? = nil

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.pdBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 1. Header
                        headerView
                            .padding(.horizontal, 20)
                            .padding(.top, 10)

                        // 2. Physical Monitors with snap zones
                        monitorsSection
                            .padding(.horizontal, 20)

                        // 3. Quick Split 50/50 (if 2+ apps open)
                        if appList.count >= 2 {
                            quickSplitComboBanner
                                .padding(.horizontal, 20)
                        }

                        // 4. App list
                        appListSection
                            .padding(.horizontal, 20)

                        Spacer(minLength: 20)
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
            Text("Окна")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.pdPrimaryText)
            Spacer()
            Button(action: {
                Haptics.shared.click()
                connection.requestDisplays()
                connection.requestWindows()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.pdSecondaryText)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.pdElevatedCard))
            }
        }
    }

    // MARK: - Data
    private var displayList: [DisplayItem] {
        if !connection.displays.isEmpty {
            return connection.displays
        }
        return [
            DisplayItem(id: 6, name: "Экран 1", isPrimary: true, bounds: DisplayRect(x: 0, y: 0, width: 1920, height: 1080), workArea: DisplayRect(x: 0, y: 0, width: 1920, height: 1032)),
            DisplayItem(id: 5, name: "Экран 2", isPrimary: false, bounds: DisplayRect(x: -1680, y: 0, width: 1344, height: 840), workArea: DisplayRect(x: -1680, y: 0, width: 1344, height: 792))
        ]
    }

    private var appList: [DesktopWindow] {
        if !connection.openWindows.isEmpty {
            return connection.openWindows
        }
        return [
            DesktopWindow(id: "chrome", title: "Google Chrome", appName: "chrome"),
            DesktopWindow(id: "discord", title: "Discord", appName: "Discord"),
            DesktopWindow(id: "code", title: "VS Code", appName: "Code")
        ]
    }

    // MARK: - Monitors Section
    private var monitorsSection: some View {
        VStack(spacing: 10) {
            ForEach(displayList) { display in
                monitorCardView(display: display)
            }
        }
    }

    private func monitorCardView(display: DisplayItem) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Text(display.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.pdPrimaryText)
                if display.isPrimary {
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(.pdAccentBlue)
                }
                Spacer()
                Text("\(Int(display.bounds.width))×\(Int(display.bounds.height))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.pdTertiaryText)
            }

            // Snap zones: Left / Full / Right
            HStack(spacing: 6) {
                snapZoneTile(display: display, zone: "left", icon: "rectangle.leadinghalf.filled")
                snapZoneTile(display: display, zone: "full", icon: "rectangle.fill")
                snapZoneTile(display: display, zone: "right", icon: "rectangle.trailinghalf.filled")
            }
            .frame(height: 64)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.pdCardBackground))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.pdBorder, lineWidth: 0.5))
    }

    private func snapZoneTile(display: DisplayItem, zone: String, icon: String) -> some View {
        let key = "\(display.id)_\(zone)"
        let isHovered = hoveredZone == key

        return Image(systemName: icon)
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(isHovered ? .white : .pdAccentBlue)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovered ? Color.pdAccentBlue : Color.pdElevatedCard)
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

    // MARK: - Quick 50/50 Combo
    private var quickSplitComboBanner: some View {
        let first = appList[0]
        let second = appList[1]
        let targetDisplay = displayList.first?.id ?? 0

        return Button(action: {
            Haptics.shared.success()
            connection.sendWindowMove(windowId: first.id, displayId: targetDisplay, zone: "left")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                connection.sendWindowMove(windowId: second.id, displayId: targetDisplay, zone: "right")
            }
        }) {
            HStack(spacing: 10) {
                HStack(spacing: -5) {
                    BrandAppIconView(appName: first.appName, size: 26)
                    BrandAppIconView(appName: second.appName, size: 26)
                }

                Text("\(first.appName) + \(second.appName)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.pdPrimaryText)

                Spacer()

                Image(systemName: "rectangle.split.2x1.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.pdAccentBlue)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.pdCardBackground))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.pdBorder, lineWidth: 0.5))
        }
    }

    // MARK: - App List (compact single-row cards)
    private var appListSection: some View {
        VStack(spacing: 8) {
            ForEach(appList) { win in
                appRow(win: win)
            }
        }
    }

    private func appRow(win: DesktopWindow) -> some View {
        let primaryDisp = displayList.first?.id ?? 6

        return HStack(spacing: 10) {
            BrandAppIconView(appName: win.appName.isEmpty ? win.title : win.appName, size: 34)

            Text(win.appName.isEmpty ? win.title : win.appName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.pdPrimaryText)
                .lineLimit(1)

            Spacer(minLength: 4)

            // 3 compact snap buttons
            HStack(spacing: 4) {
                snapButton(icon: "rectangle.leadinghalf.filled") {
                    connection.sendWindowMove(windowId: win.id, displayId: primaryDisp, zone: "left")
                }
                snapButton(icon: "rectangle.fill") {
                    connection.sendWindowMove(windowId: win.id, displayId: primaryDisp, zone: "full")
                }
                snapButton(icon: "rectangle.trailinghalf.filled") {
                    connection.sendWindowMove(windowId: win.id, displayId: primaryDisp, zone: "right")
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.pdCardBackground))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.pdBorder, lineWidth: 0.5))
        .onDrag {
            Haptics.shared.click()
            return NSItemProvider(object: win.id as NSString)
        }
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func snapButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.shared.click()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.pdSecondaryText)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.pdElevatedCard))
        }
    }
}

public typealias SimplifiedDesktopView = WindowsManagerView