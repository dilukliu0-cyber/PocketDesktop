import SwiftUI

public struct BrowserView: View {
    @ObservedObject private var connection = ConnectionManager.shared
    
    @State private var searchInput: String = ""
    @State private var showingTabsSheet = false
    @State private var isBookmarked = false
    
    private var activeTab: BrowserTab? {
        connection.browserTabs.first(where: { $0.isActive }) ?? connection.browserTabs.first
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.pdBackground.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Top Address / Search Bar
                    HStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.pdSecondaryText)
                            
                            TextField("Search or enter address...", text: $searchInput)
                                .textFieldStyle(.plain)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .onSubmit {
                                    handleSearchSubmit()
                                }
                            
                            if !searchInput.isEmpty {
                                Button(action: { searchInput = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.pdSecondaryText)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.pdElevatedCard)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pdBorder, lineWidth: 1))
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Horizontal Tabs Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(connection.browserTabs) { tab in
                                tabChip(tab)
                            }
                            
                            Button(action: {
                                connection.performBrowserAction(BrowserActionPayload(action: .newTab, url: "https://google.com"))
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.pdAccentBlue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(Color.pdElevatedCard))
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Main Web Page Preview Card
                    GlassCard(cornerRadius: 24, padding: 18, isElevated: true) {
                        VStack(alignment: .leading, spacing: 14) {
                            // Page Details
                            VStack(alignment: .leading, spacing: 4) {
                                Text(activeTab?.title ?? "Remote Browser")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.pdPrimaryText)
                                    .lineLimit(1)
                                
                                Text(activeTab?.url ?? "about:blank")
                                    .font(.system(size: 13))
                                    .foregroundColor(.pdAccentBlue)
                                    .lineLimit(1)
                            }
                            
                            // Visual Web Page Canvas
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(uiColor: .tertiarySystemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.pdBorder, lineWidth: 1)
                                    )
                                
                                VStack(spacing: 12) {
                                    Image(systemName: "safari")
                                        .font(.system(size: 48))
                                        .foregroundColor(.pdAccentBlue.opacity(0.8))
                                    
                                    Text("Desktop Session Active")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.pdPrimaryText)
                                    
                                    Text("Webpage rendered remotely in desktop browser")
                                        .font(.system(size: 12))
                                        .foregroundColor(.pdSecondaryText)
                                }
                            }
                            .frame(maxHeight: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Bottom Navigation Toolbar
                    HStack {
                        toolbarItem(icon: "chevron.backward") {
                            connection.performBrowserAction(BrowserActionPayload(action: .back))
                        }
                        Spacer()
                        toolbarItem(icon: "chevron.forward") {
                            connection.performBrowserAction(BrowserActionPayload(action: .forward))
                        }
                        Spacer()
                        toolbarItem(icon: "arrow.clockwise") {
                            connection.performBrowserAction(BrowserActionPayload(action: .refresh))
                        }
                        Spacer()
                        toolbarItem(icon: "square.on.square") {
                            showingTabsSheet = true
                        }
                        Spacer()
                        toolbarItem(icon: isBookmarked ? "bookmark.fill" : "bookmark") {
                            isBookmarked.toggle()
                            Haptics.shared.click()
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.pdCardBackground)
                    .overlay(Divider().background(Color.pdBorder), alignment: .top)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingTabsSheet) {
                BrowserTabsView()
            }
        }
    }
    
    private func tabChip(_ tab: BrowserTab) -> some View {
        Button(action: {
            connection.performBrowserAction(BrowserActionPayload(action: .switchTab, tabId: tab.id))
        }) {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 11))
                Text(tab.title)
                    .font(.system(size: 13, weight: tab.isActive ? .bold : .medium))
                    .lineLimit(1)
            }
            .foregroundColor(tab.isActive ? .white : .pdPrimaryText)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(tab.isActive ? Color.pdAccentBlue : Color.pdElevatedCard)
            )
        }
    }
    
    private func toolbarItem(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.shared.click()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.pdPrimaryText)
                .frame(width: 44, height: 44)
        }
    }
    
    private func handleSearchSubmit() {
        guard !searchInput.isEmpty else { return }
        var targetUrl = searchInput
        if !targetUrl.lowercased().starts(with: "http://") && !targetUrl.lowercased().starts(with: "https://") {
            if targetUrl.contains(".") && !targetUrl.contains(" ") {
                targetUrl = "https://" + targetUrl
            } else {
                targetUrl = "https://www.google.com/search?q=" + targetUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            }
        }
        connection.performBrowserAction(BrowserActionPayload(action: .navigate, url: targetUrl))
        searchInput = ""
    }
}
