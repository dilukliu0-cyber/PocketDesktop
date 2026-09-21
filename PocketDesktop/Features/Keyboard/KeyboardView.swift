import SwiftUI

public struct KeyboardView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFieldFocused: Bool
    
    @State private var inputBuffer: String = ""
    @State private var activeModifiers: KeyboardModifierFlags = []
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.pdBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Info
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Remote Keyboard")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.pdPrimaryText)
                            Text("Encrypted input stream • No history stored")
                                .font(.system(size: 12))
                                .foregroundColor(.pdSecondaryText)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Hidden text field to summon system keyboard
                    TextField("Tap to type on computer...", text: $inputBuffer)
                        .focused($isFieldFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.pdElevatedCard))
                        .padding(.horizontal, 20)
                        .onChange(of: inputBuffer) { _, newVal in
                            if !newVal.isEmpty {
                                transmitText(newVal)
                                inputBuffer = "" // Do not retain keystroke history
                            }
                        }
                    
                    Spacer()
                    
                    // Desktop Modifiers & Quick Action Toolbars
                    VStack(spacing: 8) {
                        // Row 1: Esc, Tab, Ctrl, Alt, Shift, Win/Cmd, Arrows
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                keyButton(label: "Esc") { sendSpecialKey("Escape") }
                                keyButton(label: "Tab") { sendSpecialKey("Tab") }
                                modifierToggle(label: "Ctrl", flag: .ctrl)
                                modifierToggle(label: "Alt", flag: .alt)
                                modifierToggle(label: "Shift", flag: .shift)
                                modifierToggle(label: "Win/Cmd", flag: .meta)
                                
                                Divider().frame(height: 24)
                                
                                keyButton(icon: "arrow.left") { sendSpecialKey("ArrowLeft") }
                                keyButton(icon: "arrow.up") { sendSpecialKey("ArrowUp") }
                                keyButton(icon: "arrow.down") { sendSpecialKey("ArrowDown") }
                                keyButton(icon: "arrow.right") { sendSpecialKey("ArrowRight") }
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        // Row 2: Copy, Paste, Undo, Redo, Select All
                        HStack(spacing: 8) {
                            shortcutButton(label: "Copy", icon: "doc.on.doc") { sendShortcut("copy") }
                            shortcutButton(label: "Paste", icon: "doc.on.clipboard") { sendShortcut("paste") }
                            shortcutButton(label: "Undo", icon: "arrow.uturn.backward") { sendShortcut("undo") }
                            shortcutButton(label: "Redo", icon: "arrow.uturn.forward") { sendShortcut("redo") }
                            shortcutButton(label: "Select All", icon: "selection.pin.in.out") { sendShortcut("selectAll") }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 12)
                    .background(Color.pdCardBackground)
                    .overlay(Divider().background(Color.pdBorder), alignment: .top)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFieldFocused = true
                }
            }
        }
    }
    
    private func keyButton(label: String? = nil, icon: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.shared.click()
            action()
        }) {
            HStack {
                if let icon = icon { Image(systemName: icon) }
                if let label = label { Text(label) }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.pdPrimaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.pdElevatedCard))
        }
    }
    
    private func modifierToggle(label: String, flag: KeyboardModifierFlags) -> some View {
        let isActive = activeModifiers.contains(flag)
        return Button(action: {
            Haptics.shared.select()
            if isActive {
                activeModifiers.remove(flag)
            } else {
                activeModifiers.insert(flag)
            }
        }) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isActive ? .white : .pdPrimaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10).fill(isActive ? Color.pdAccentBlue : Color.pdElevatedCard))
        }
    }
    
    private func shortcutButton(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.shared.click()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.pdPrimaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.pdElevatedCard))
        }
    }
    
    private func transmitText(_ text: String) {
        WebRTCManager.shared.sendKeyboard(KeyboardInputPayload(
            action: .text,
            text: text,
            modifiers: activeModifiers
        ))
    }
    
    private func sendSpecialKey(_ key: String) {
        WebRTCManager.shared.sendKeyboard(KeyboardInputPayload(
            action: .keyPress,
            keyCode: key,
            modifiers: activeModifiers
        ))
    }
    
    private func sendShortcut(_ shortcut: String) {
        WebRTCManager.shared.sendKeyboard(KeyboardInputPayload(
            action: .shortcut,
            modifiers: activeModifiers,
            shortcut: shortcut
        ))
    }
}
