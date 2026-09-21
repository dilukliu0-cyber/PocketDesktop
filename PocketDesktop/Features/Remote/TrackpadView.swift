import SwiftUI

public struct TrackpadView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var connection = ConnectionManager.shared
    
    @State private var showingSettings = false
    @State private var showingKeyboard = false
    @State private var sensitivity: Double = 1.0
    @State private var naturalScrolling: Bool = true
    @State private var tapToClick: Bool = true
    @State private var hapticClicks: Bool = true
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.pdBackground.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Header Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Trackpad")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.pdPrimaryText)
                            Text(connection.currentDevice?.name ?? "Alex's PC")
                                .font(.system(size: 13))
                                .foregroundColor(.pdSecondaryText)
                        }
                        
                        Spacer()
                        
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.pdPrimaryText)
                                .padding(10)
                                .background(Circle().fill(Color.pdElevatedCard))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // MacBook-Style Large Touch Surface
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.pdElevatedCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.pdBorder, lineWidth: 1)
                            )
                        
                        VStack(spacing: 12) {
                            Image(systemName: "hand.draw")
                                .font(.system(size: 40))
                                .foregroundColor(.pdSecondaryText.opacity(0.4))
                            
                            Text("Swipe  •  Tap  •  Pinch  •  Scroll")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.pdSecondaryText.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 20)
                    .gesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { val in
                                let deltaX = val.translation.width * sensitivity
                                let deltaY = val.translation.height * sensitivity
                                WebRTCManager.shared.sendInput(MouseInputPayload(
                                    action: .move,
                                    deltaX: deltaX,
                                    deltaY: deltaY
                                ))
                            }
                    )
                    .onTapGesture {
                        if tapToClick {
                            if hapticClicks { Haptics.shared.click() }
                            WebRTCManager.shared.sendInput(MouseInputPayload(action: .click, button: .left))
                        }
                    }
                    
                    // Bottom Controls Row: Left Click, Right Click, Keyboard
                    HStack(spacing: 14) {
                        Button(action: {
                            if hapticClicks { Haptics.shared.click() }
                            WebRTCManager.shared.sendInput(MouseInputPayload(action: .click, button: .left))
                        }) {
                            Text("Left Click")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.pdPrimaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.pdCardBackground))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pdBorder, lineWidth: 1))
                        }
                        
                        Button(action: {
                            if hapticClicks { Haptics.shared.click() }
                            WebRTCManager.shared.sendInput(MouseInputPayload(action: .rightClick, button: .right))
                        }) {
                            Text("Right Click")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.pdPrimaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.pdCardBackground))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pdBorder, lineWidth: 1))
                        }
                        
                        Button(action: { showingKeyboard = true }) {
                            Image(systemName: "keyboard.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 58, height: 54)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.pdAccentGradient))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showingSettings) {
                trackpadSettingsSheet
            }
            .sheet(isPresented: $showingKeyboard) {
                KeyboardView()
            }
        }
    }
    
    private var trackpadSettingsSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Tracking Speed")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Slider(value: $sensitivity, in: 0.5...2.5, step: 0.1)
                        Text("Sensitivity: \(String(format: "%.1fx", sensitivity))")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Gestures")) {
                    Toggle("Natural Scrolling", isOn: $naturalScrolling)
                    Toggle("Tap to Click", isOn: $tapToClick)
                    Toggle("Haptic Feedback", isOn: $hapticClicks)
                }
            }
            .navigationTitle("Trackpad Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showingSettings = false }
                }
            }
        }
    }
}
