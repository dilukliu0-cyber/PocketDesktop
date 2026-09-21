import SwiftUI
import UIKit

public struct ScreenshotPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var connection = ConnectionManager.shared
    
    @State private var showingShareSheet = false
    @State private var saveStatusMessage: String?
    
    public init() {}
    
    private var screenshotImage: UIImage {
        if let img = connection.lastScreenshotImage {
            return img
        }
        // Fallback placeholder screenshot
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 450))
        return renderer.image { ctx in
            UIColor(red: 0.1, green: 0.12, blue: 0.18, alpha: 1.0).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 800, height: 450))
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.pdBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Screenshot Image Preview
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.black)
                            .shadow(color: Color.black.opacity(0.3), radius: 16)
                        
                        Image(uiImage: screenshotImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    if let msg = saveStatusMessage {
                        Text(msg)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.pdOnlineGreen)
                            .transition(.opacity)
                    }
                    
                    Spacer()
                    
                    // 3 Actions: Save to Photos, Share, Copy
                    HStack(spacing: 12) {
                        actionButton(icon: "square.and.arrow.down", label: "Save") {
                            UIImageWriteToSavedPhotosAlbum(screenshotImage, nil, nil, nil)
                            Haptics.shared.success()
                            withAnimation {
                                saveStatusMessage = "Saved to Photo Library!"
                            }
                        }
                        
                        actionButton(icon: "square.and.arrow.up", label: "Share") {
                            showingShareSheet = true
                        }
                        
                        actionButton(icon: "doc.on.doc", label: "Copy") {
                            UIPasteboard.general.image = screenshotImage
                            Haptics.shared.success()
                            withAnimation {
                                saveStatusMessage = "Copied to Clipboard!"
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Desktop Screenshot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareActivitySheet(activityItems: [screenshotImage])
            }
        }
    }
    
    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.shared.click()
            action()
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.pdPrimaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.pdCardBackground))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.pdBorder, lineWidth: 1))
        }
        .buttonStyle(ScaleTouchButtonStyle())
    }
}
