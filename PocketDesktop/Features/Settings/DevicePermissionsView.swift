import SwiftUI

public struct DevicePermissionsView: View {
    let permissions: DevicePermissions
    
    public init(permissions: DevicePermissions = DevicePermissions()) {
        self.permissions = permissions
    }
    
    public var body: some View {
        List {
            Section(header: Text("Granted Desktop Permissions"), footer: Text("Permissions are set on your desktop computer and cannot be elevated from this device.")) {
                permissionRow(title: "Remote Control & Input", icon: "cursorarrow.rays", isGranted: permissions.remoteControl)
                permissionRow(title: "Files & Documents Access", icon: "folder.fill", isGranted: permissions.files)
                permissionRow(title: "Clipboard Sync", icon: "doc.on.clipboard", isGranted: permissions.clipboard)
                permissionRow(title: "Browser Session Controller", icon: "safari.fill", isGranted: permissions.browser)
                permissionRow(title: "Audio Streaming", icon: "speaker.wave.2.fill", isGranted: permissions.audio)
            }
        }
        .navigationTitle("Device Permissions")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func permissionRow(title: String, icon: String, isGranted: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isGranted ? .pdAccentBlue : .pdSecondaryText)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 15))
            
            Spacer()
            
            if isGranted {
                Text("Allowed")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.pdOnlineGreen)
            } else {
                Text("Denied")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.pdOfflineRed)
            }
        }
    }
}
