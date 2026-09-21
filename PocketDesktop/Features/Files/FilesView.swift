import SwiftUI

public struct FilesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var connection = ConnectionManager.shared
    
    @State private var activeFolder = "Desktop"
    @State private var fileToDelete: FileItem?
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    
    private let rootFolders = ["Desktop", "Documents", "Downloads", "Pictures"]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Root Folders Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(rootFolders, id: \.self) { folder in
                            folderChip(folder)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(Color.pdCardBackground)
                .overlay(Divider().background(Color.pdBorder), alignment: .bottom)
                
                // Files List
                List {
                    ForEach(connection.currentFiles) { item in
                        fileRow(item)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    fileToDelete = item
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    downloadAndShare(item)
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .tint(.pdAccentBlue)
                            }
                    }
                }
                .listStyle(.plain)
            }
            .background(Color.pdBackground.ignoresSafeArea())
            .navigationTitle("Files")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showingNewFolderAlert = true }) {
                            Label("New Folder", systemImage: "folder.badge.plus")
                        }
                        Button(action: {
                            // Refresh files
                            connection.sendMessage(.getFiles)
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.pdPrimaryText)
                    }
                }
            }
            .alert("Delete File?", isPresented: $showingDeleteAlert, presenting: fileToDelete) { item in
                Button("Delete", role: .destructive) {
                    connection.performFileAction(FileActionPayload(action: .delete, path: item.path))
                }
                Button("Cancel", role: .cancel) {}
            } message: { item in
                Text("Are you sure you want to delete '\(item.name)' on your PC? This action cannot be undone.")
            }
            .alert("New Folder", isPresented: $showingNewFolderAlert) {
                TextField("Folder Name", text: $newFolderName)
                Button("Create") {
                    if !newFolderName.isEmpty {
                        connection.performFileAction(FileActionPayload(action: .createFolder, path: "\(activeFolder)\\\(newFolderName)"))
                        newFolderName = ""
                    }
                }
                Button("Cancel", role: .cancel) { newFolderName = "" }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = shareURL {
                    ShareActivitySheet(activityItems: [url])
                }
            }
        }
    }
    
    private func folderChip(_ folder: String) -> some View {
        let isSelected = activeFolder == folder
        return Button(action: {
            Haptics.shared.select()
            activeFolder = folder
            connection.sendMessage(.getFiles)
        }) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "folder.fill" : "folder")
                    .font(.system(size: 13))
                Text(folder)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
            }
            .foregroundColor(isSelected ? .white : .pdPrimaryText)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.pdAccentBlue : Color.pdElevatedCard)
            )
        }
    }
    
    private func fileRow(_ item: FileItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.pdElevatedCard)
                    .frame(width: 42, height: 42)
                
                Image(systemName: fileIcon(for: item))
                    .font(.system(size: 20))
                    .foregroundColor(item.isDirectory ? .pdAccentBlue : .pdSecondaryText)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.pdPrimaryText)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(item.formattedSize)
                    Text("•")
                    Text(item.modifiedDate.formatted(date: .abbreviated, time: .omitted))
                }
                .font(.system(size: 12))
                .foregroundColor(.pdSecondaryText)
            }
            
            Spacer()
            
            Button(action: {
                downloadAndShare(item)
            }) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.pdAccentBlue)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
    
    private func fileIcon(for item: FileItem) -> String {
        if item.isDirectory { return "folder.fill" }
        switch item.fileExtension.lowercased() {
        case "pdf": return "doc.richtext.fill"
        case "png", "jpg", "jpeg": return "photo.fill"
        case "mp3", "wav": return "music.note"
        case "mp4", "mov": return "film.fill"
        case "xlsx", "csv": return "tablecells.fill"
        default: return "doc.fill"
        }
    }
    
    private func downloadAndShare(_ item: FileItem) {
        Haptics.shared.click()
        // Save demo/downloaded file to app sandbox
        let sampleData = "Pocket Desktop remote file content: \(item.name)".data(using: .utf8)!
        if let localURL = try? FileSandboxService.shared.saveDownloadedFile(name: item.name, data: sampleData) {
            self.shareURL = localURL
            self.showingShareSheet = true
        }
    }
}

public struct ShareActivitySheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
