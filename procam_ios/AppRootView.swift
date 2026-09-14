import SwiftUI

/// Root navigation container that hosts MP3 Converter - Audio Editor as default,
/// while providing quick switching to ProCam camera view.
public struct AppRootView: View {
    @State private var currentAppMode: AppMode = .audioEditor
    
    public enum AppMode {
        case audioEditor
        case proCam
    }
    
    public init() {}
    
    public var body: some View {
        ZStack {
            switch currentAppMode {
            case .audioEditor:
                AudioEditorMainView(
                    onSwitchToProCam: {
                        withAnimation(.spring()) {
                            currentAppMode = .proCam
                        }
                    }
                )
                .transition(.opacity)
                
            case .proCam:
                ZStack(alignment: .topLeading) {
                    CameraView()
                        .preferredColorScheme(.dark)
                    
                    // Return button to Audio Editor
                    Button(action: {
                        withAnimation(.spring()) {
                            currentAppMode = .audioEditor
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "waveform")
                            Text("Audio Editor")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(AudioEditorTheme.accentRed))
                        .shadow(radius: 4)
                    }
                    .padding(.top, 50)
                    .padding(.leading, 16)
                }
                .transition(.opacity)
            }
        }
    }
}
