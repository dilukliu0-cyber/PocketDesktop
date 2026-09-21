import SwiftUI

public struct AppLauncherView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var connection = ConnectionManager.shared
    
    @State private var searchQuery = ""
    
    public init() {}
    
    private var filteredApps: [DesktopApp] {
        if searchQuery.isEmpty {
            return connection.runningApps
        }
        return connection.runningApps.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Search Bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.pdSecondaryText)
                        TextField("Search apps on PC...", text: $searchQuery)
                            .textFieldStyle(.plain)
                        if !searchQuery.isEmpty {
                            Button(action: { searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.pdSecondaryText)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.pdElevatedCard)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pdBorder, lineWidth: 1))
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // App Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                        ForEach(filteredApps) { app in
                            appGridItem(app)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 24)
            }
            .background(Color.pdBackground.ignoresSafeArea())
            .navigationTitle("Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func appGridItem(_ app: DesktopApp) -> some View {
        Button(action: {
            connection.launchApp(app)
            dismiss()
        }) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.pdElevatedCard)
                        .frame(width: 72, height: 72)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.pdBorder, lineWidth: 1)
                        )
                        .overlay(
                            Image(systemName: app.systemIconName)
                                .font(.system(size: 32))
                                .foregroundColor(.pdAccentBlue)
                        )
                    
                    if app.isRunning {
                        Circle()
                            .fill(Color.pdOnlineGreen)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(Color.pdCardBackground, lineWidth: 2))
                            .offset(x: 2, y: -2)
                    }
                }
                
                Text(app.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.pdPrimaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 34, alignment: .top)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ScaleTouchButtonStyle())
        .contextMenu {
            Button(action: {
                Haptics.shared.success()
            }) {
                Label(app.isFavorite ? "Remove from Favorites" : "Add to Favorites", systemImage: app.isFavorite ? "star.slash" : "star.fill")
            }
            
            Button(action: {
                connection.launchApp(app)
            }) {
                Label("Launch / Focus", systemImage: "arrow.up.forward.app")
            }
        }
    }
}
