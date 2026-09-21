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
                        // 1. Header
                        headerView
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                        // 2. Physical Monitors with 50/50 Split Zones
                        monitorsSection
                            .padding(.horizontal, 20)

                        // 3. Quick Split 50/50 Combo Button (if 2+ apps open)
                        if appList.count >= 2 {
                            quickSplitComboBanner
                                .padding(.horizontal, 20)
                        }

                        // 4. App icons grid (Chrome, Discord, etc.)
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
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.pdPrimaryText)
                Text("Расставьте приложения по экранам")
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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.pdPrimaryText)
                    .frame(width: 34, height: 34)
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
            Text("Мониторы")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.pdSecondaryText)

            ForEach(displayList) { display in
                monitorCardView(display: display)
            }
        }
    }

    private func monitorCardView(display: DisplayItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: display.isPrimary ? "display.2" : "display")
                    .font(.system(size: 14))
                    .foregroundColor(display.isPrimary ? .pdAccentBlue : .pdSecondaryText)
                Text(display.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.pdPrimaryText)
                if display.isPrimary {
                    Text("Основной")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.pdAccentTint))
                        .foregroundColor(.pdAccentBlue)
                }
                Spacer()
                Text("\(Int(display.bounds.width))×\(Int(display.bounds.height))")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.pdTertiaryText)
            }

            // Visual monitor representation split into Left 50% / Full / Right 50%
            HStack(spacing: 8) {
                snapZoneTile(display: display, zone: "left", label: "Слева", icon: "rectangle.leadinghalf.filled")
                snapZoneTile(display: display, zone: "full", label: "Полный", icon: "rectangle.fill")
                snapZoneTile(display: display, zone: "right", label: "Справа", icon: "rectangle.trailinghalf.filled")
            }
            .frame(height: 88)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.pdCardBackground))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.pdBorder, lineWidth: 1))
    }

    private func snapZoneTile(display: DisplayItem, zone: String, label: String, icon: String) -> some View {
        let key = "\(display.id)_\(zone)"
        let isHovered = hoveredZone == key

        return VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(isHovered ? .white : .pdAccentBlue)
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isHovered ? .white : .pdPrimaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
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

    // MARK: - Quick 50/50 Combo Banner
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
            HStack(spacing: 12) {
                HStack(spacing: -6) {
                    BrandAppIconView(appName: first.appName, size: 30)
                    BrandAppIconView(appName: second.appName, size: 30)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Слева и справа одной кнопкой")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.pdPrimaryText)
                    Text("\(first.appName) + \(second.appName)")
                        .font(.system(size: 12))
                        .foregroundColor(.pdSecondaryText)
                }

                Spacer()

                Image(systemName: "rectangle.split.2x1.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.pdAccentBlue)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.pdCardBackground))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.pdBorder, lineWidth: 1))
        }
    }

    // MARK: - App Icons Grid
    private var appIconsGridSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Открытые приложения")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.pdSecondaryText)
                Spacer()
                Text("\(appList.count) шт.")
                    .font(.system(size: 12))
                    .foregroundColor(.pdTertiaryText)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(appList) { win in
                    appIconCard(win: win)
                }
            }
        }
    }

    private func appIconCard(win: DesktopWindow) -> some View {
        let primaryDisp = displayList.first?.id ?? 6
        let secondaryDisp = displayList.count > 1 ? displayList[1].id : primaryDisp

        return VStack(spacing: 0) {
            // App row
            HStack(spacing: 10) {
                BrandAppIconView(appName: win.appName.isEmpty ? win.title : win.appName, size: 40)
                VStack(alignment: .leading, spacing: 1) {
                    Text(win.appName.isEmpty ? win.title : win.appName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.pdPrimaryText)
                        .lineLimit(1)
                    Text("Перетащите на монитор")
                        .font(.system(size: 10))
                        .foregroundColor(.pdTertiaryText)
                }
                Spacer(minLength: 4)
            }
            .padding(.bottom, 10)

            Divider()
                .overlay(Color.pdBorder)

            // Placement buttons
            VStack(spacing: 8) {
                // Screen 1 row
                HStack(spacing: 6) {
                    placementButton(icon: "rectangle.leadinghalf.filled", title: "50%", large: true) {
                        connection.sendWindowMove(windowId: win.id, displayId: primaryDisp, zone: "left")
                    }
                    placementButton(icon: "rectangle.fill", title: nil, large: false) {
                        connection.sendWindowMove(windowId: win.id, displayId: primaryDisp, zone: "full")
                    }
                    placementButton(icon: "rectangle.trailinghalf.filled", title: "50%", large: false) {
                        connection.sendWindowMove(windowId: win.id, displayId: primaryDisp, zone: "right")
                    }
                }

                // Screen 2 row
                if displayList.count > 1 {
                    HStack(spacing: 6) {
                        placementButton(icon: "rectangle.leadinghalf.filled", title: "Экран 2", large: true) {
                            connection.sendWindowMove(windowId: win.id, displayId: secondaryDisp, zone: "left")
                        }
                        placementButton(icon: "rectangle.trailinghalf.filled", title: "Экран 2", large: true) {
                            connection.sendWindowMove(windowId: win.id, displayId: secondaryDisp, zone: "right")
                        }
                    }
                }
            }
            .padding(.top, 10)
        }
        .padding(12)
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
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func placementButton(
        icon: String,
        title: String?,
        large: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            Haptics.shared.click()
            action()
        }) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                if let title = title {
                    Text(title)
                        .font(.system(size: 10, weight: .semibold))
                }
            }
            .foregroundColor(.pdSecondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.pdElevatedCard))
        }
    }
}

public typealias SimplifiedDesktopView = WindowsManagerView