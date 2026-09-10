import SwiftUI

public struct ShutterControlView: View {
    @ObservedObject var cameraManager: CameraManager
    private let haptic = UIImpactFeedbackGenerator(style: .heavy)
    private let lightFeedback = UIImpactFeedbackGenerator(style: .light)
    
    public init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            // 1. Gallery Thumbnail
            galleryButton
                .frame(maxWidth: .infinity)
            
            // 2. Mode Expand Drawer Chevron (^)
            modeDrawerToggleButton
                .frame(maxWidth: .infinity)
            
            // 3. Iconic DSLR Shutter Button
            mainShutterButton
                .frame(maxWidth: .infinity)
            
            // 4. Timer Cycle Button (⏲)
            timerCycleButton
                .frame(maxWidth: .infinity)
            
            // 5. Lens / Zoom Switcher Badge
            zoomBadgeButton
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .frame(height: 96)
        .background(Color.black)
    }
    
    // MARK: - 1. Gallery Thumbnail Button
    private var galleryButton: some View {
        Button(action: {
            if let url = URL(string: "photos-redirect://") {
                UIApplication.shared.open(url)
            }
        }) {
            ZStack {
                if let image = cameraManager.uiState.lastCapturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 46, height: 46)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(white: 0.28), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ProCamColors.dslrDarkGrey)
                        .frame(width: 46, height: 46)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(white: 0.28), lineWidth: 1)
                        )
                        .overlay(
                            Image(systemName: "photo.on.rectangle.angled")
                                .foregroundColor(Color(white: 0.6))
                                .font(.system(size: 20))
                        )
                }
            }
        }
    }
    
    // MARK: - 2. Mode Drawer Toggle Chevron Button
    private var modeDrawerToggleButton: some View {
        Button(action: {
            lightFeedback.impactOccurred()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                cameraManager.toggleModeDrawer()
            }
        }) {
            Circle()
                .fill(Color.clear)
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: "chevron.up")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(cameraManager.uiState.isModeDrawerExpanded ? ProCamColors.amber : Color(white: 0.8))
                        .rotationEffect(.degrees(cameraManager.uiState.isModeDrawerExpanded ? 180 : 0))
                )
        }
    }
    
    // MARK: - 3. ProCam DSLR Shutter Button
    private var mainShutterButton: some View {
        let isVideo = cameraManager.uiState.selectedMode == .video
        let isRecording = cameraManager.uiState.isRecordingVideo
        
        return Button(action: {
            haptic.impactOccurred()
            cameraManager.onShutterPressed()
        }) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.white, lineWidth: 3.5)
                    .frame(width: 74, height: 74)
                
                // Inner button morph
                if isVideo && isRecording {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(ProCamColors.red)
                        .frame(width: 26, height: 26)
                } else {
                    Circle()
                        .fill(isVideo ? ProCamColors.red : Color.white)
                        .frame(width: 60, height: 60)
                }
            }
        }
        .buttonStyle(ShutterPressStyle())
    }
    
    // MARK: - 4. Timer Cycle Button
    private var timerCycleButton: some View {
        Button(action: {
            lightFeedback.impactOccurred()
            cameraManager.cycleTimer()
        }) {
            Circle()
                .fill(Color.clear)
                .frame(width: 38, height: 38)
                .overlay(
                    Group {
                        if cameraManager.uiState.timerSeconds > 0 {
                            Circle()
                                .fill(ProCamColors.amber)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Text("\(cameraManager.uiState.timerSeconds)s")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.black)
                                )
                        } else {
                            Image(systemName: "timer")
                                .font(.system(size: 20))
                                .foregroundColor(Color(white: 0.6))
                        }
                    }
                )
        }
    }
    
    // MARK: - 5. Lens / Zoom Switcher Badge Button
    private var zoomBadgeButton: some View {
        let zoomText: String = {
            if cameraManager.uiState.isFrontCamera {
                return "Front"
            } else if cameraManager.uiState.currentZoomRatio.truncatingRemainder(dividingBy: 1.0) == 0 {
                return "\(Int(cameraManager.uiState.currentZoomRatio))x"
            } else {
                return String(format: "%.1fx", cameraManager.uiState.currentZoomRatio)
            }
        }()
        
        return Button(action: {
            lightFeedback.impactOccurred()
            if cameraManager.uiState.isFrontCamera {
                cameraManager.switchCamera()
            } else {
                // Cycle 1x -> 2x -> 3x -> 5x -> 1x
                let current = cameraManager.uiState.currentZoomRatio
                let next: CGFloat = {
                    if current < 1.9 { return 2.0 }
                    if current < 2.9 { return 3.0 }
                    if current < 4.9 { return 5.0 }
                    return 1.0
                }()
                cameraManager.setZoomRatio(next)
            }
        }) {
            Circle()
                .fill(ProCamColors.dslrDarkGrey)
                .frame(width: 46, height: 46)
                .overlay(
                    Circle().stroke(Color(white: 0.28), lineWidth: 1)
                )
                .overlay(
                    Text(zoomText)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(!cameraManager.uiState.isFrontCamera && cameraManager.uiState.currentZoomRatio > 1.0 ? ProCamColors.amber : Color.white)
                )
        }
    }
}

public struct ShutterPressStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
