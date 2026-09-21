import SwiftUI

public struct BrowserTabsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var connection = ConnectionManager.shared
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text("Open Tabs")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.pdPrimaryText)
                        Spacer()
                        Button(action: {
                            connection.performBrowserAction(BrowserActionPayload(action: .newTab, url: "https://google.com"))
                            dismiss()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                Text("New Tab")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.pdAccentGradient)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    VStack(spacing: 14) {
                        ForEach(connection.browserTabs) { tab in
                            tabCard(tab)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 24)
            }
            .background(Color.pdBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func tabCard(_ tab: BrowserTab) -> some View {
        GlassCard(cornerRadius: 18, padding: 16, isElevated: tab.isActive) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(tab.isActive ? Color.pdAccentBlue.opacity(0.15) : Color.pdElevatedCard)
                        .frame(width: 44, height: 44)
                    Image(systemName: "globe")
                        .font(.system(size: 20))
                        .foregroundColor(tab.isActive ? .pdAccentBlue : .pdSecondaryText)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(tab.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.pdPrimaryText)
                        .lineLimit(1)
                    
                    Text(tab.url)
                        .font(.system(size: 13))
                        .foregroundColor(.pdSecondaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button(action: {
                    connection.performBrowserAction(BrowserActionPayload(action: .closeTab, tabId: tab.id))
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.pdSecondaryText.opacity(0.7))
                }
            }
        }
        .onTapGesture {
            connection.performBrowserAction(BrowserActionPayload(action: .switchTab, tabId: tab.id))
            dismiss()
        }
    }
}
