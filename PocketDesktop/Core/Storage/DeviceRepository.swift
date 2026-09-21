import Foundation
import Combine

public final class DeviceRepository: ObservableObject {
    public static let shared = DeviceRepository()
    
    private let devicesKey = "com.pocketdesktop.paired_devices"
    private let activeDeviceKey = "com.pocketdesktop.active_device_id"
    
    @Published public private(set) var devices: [PairedDevice] = []
    @Published public var activeDeviceId: String? {
        didSet {
            UserDefaults.standard.set(activeDeviceId, forKey: activeDeviceKey)
        }
    }
    
    public var activeDevice: PairedDevice? {
        guard let id = activeDeviceId else { return devices.first }
        return devices.first(where: { $0.id == id }) ?? devices.first
    }
    
    private init() {
        loadDevices()
        self.activeDeviceId = UserDefaults.standard.string(forKey: activeDeviceKey)
        if activeDeviceId == nil, let first = devices.first {
            self.activeDeviceId = first.id
        }
    }
    
    public func loadDevices() {
        guard let data = UserDefaults.standard.data(forKey: devicesKey),
              let decoded = try? JSONDecoder().decode([PairedDevice].self, from: data) else {
            self.devices = []
            return
        }
        self.devices = decoded
    }
    
    public func saveDevices() {
        if let encoded = try? JSONEncoder().encode(devices) {
            UserDefaults.standard.set(encoded, forKey: devicesKey)
        }
    }
    
    public func addOrUpdateDevice(_ device: PairedDevice) {
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index] = device
        } else {
            devices.append(device)
        }
        saveDevices()
        if activeDeviceId == nil {
            activeDeviceId = device.id
        }
    }
    
    public func updateDeviceSettings(deviceId: String, settings: DeviceUserSettings) {
        if let index = devices.firstIndex(where: { $0.id == deviceId }) {
            devices[index].userSettings = settings
            saveDevices()
        }
    }
    
    public func removeDevice(id: String) {
        devices.removeAll(where: { $0.id == id })
        saveDevices()
        // Also remove private key from keychain
        KeychainService.shared.delete(key: "device_key_\(id)")
        
        if activeDeviceId == id {
            activeDeviceId = devices.first?.id
        }
    }
    
    public func clearAllDevices() {
        for device in devices {
            KeychainService.shared.delete(key: "device_key_\(device.id)")
        }
        devices.removeAll()
        activeDeviceId = nil
        saveDevices()
    }
}
