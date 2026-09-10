import SwiftUI

public struct CameraTopBarView: View {
    @ObservedObject var cameraManager: CameraManager
    private let feedback = UIImpactFeedbackGenerator(style: .light)
    
    public init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // --- 1. Primary Top Status Bar ---
            HStack {
                // Flash Mode Button [⚡ Auto / On / Off / Torch]
                Button(action: {
                    feedback.impactOccurred()
                    cameraManager.toggleFlash()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: flashIconName)
                            .font(.system(size: 13, weight: .semibold))
                        Text(cameraManager.uiState.flashMode.label)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    }
                    .foregroundColor(cameraManager.uiState.flashMode != .off ? ProCamColors.amber : Color(white: 0.55))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.clear))
                }
                
                Spacer()
                
                // Center Format Badges: [RAW]  [TIFF]  [SBRT]  [AEB]
                HStack(spacing: 8) {
                    topBarPillButton(label: "RAW", isActive: cameraManager.uiState.isRawEnabled) {
                        cameraManager.toggleRaw()
                    }
                    topBarPillButton(label: "TIFF", isActive: cameraManager.uiState.isTiffEnabled) {
                        cameraManager.toggleTiff()
                    }
                    topBarPillButton(label: "SBRT", isActive: cameraManager.uiState.isSbrtEnabled) {
                        cameraManager.toggleSbrt()
                    }
                    topBarPillButton(label: "AEB", isActive: cameraManager.uiState.isAebEnabled) {
                        cameraManager.toggleAeb()
                    }
                }
                
                Spacer()
                
                // Right SET Button (Iconic ProCam Settings Pill)
                Button(action: {
                    feedback.impactOccurred()
                    cameraManager.toggleSetMenu()
                }) {
                    Text("SET")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(cameraManager.uiState.isSetMenuOpen ? ProCamColors.amber : Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(cameraManager.uiState.isSetMenuOpen ? ProCamColors.amber : Color(white: 0.28), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(Color.black)
            
            // --- 2. Sub-header Info Strip ---
            HStack {
                // Camera Switch Icon
                Button(action: {
                    feedback.impactOccurred()
                    cameraManager.switchCamera()
                }) {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(white: 0.8))
                }
                
                Spacer()
                
                // Center Info: 48MP | Auto/Manual | Auto/WB-M
                HStack(spacing: 12) {
                    Text(cameraManager.uiState.sensorMegapixels)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    let isAutoExp = cameraManager.uiState.isAutoIso && cameraManager.uiState.isAutoShutter
                    Text(isAutoExp ? "Auto" : "Manual")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(isAutoExp ? ProCamColors.green : ProCamColors.amber)
                    
                    let isAutoWb = cameraManager.uiState.isAutoWb
                    Text(isAutoWb ? "Auto" : "WB-M")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(isAutoWb ? ProCamColors.green : ProCamColors.amber)
                }
                
                Spacer()
                
                // Battery and Free Storage Indicators
                HStack(spacing: 4) {
                    Image(systemName: "battery.100")
                        .font(.system(size: 12))
                        .foregroundColor(ProCamColors.green)
                    
                    Text("\(cameraManager.uiState.freeStorageGb)GB")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color(white: 0.55))
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 30)
            .background(Color(red: 10/255, green: 10/255, blue: 12/255).opacity(0.9))
        }
    }
    
    private func topBarPillButton(label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            feedback.impactOccurred()
            action()
        }) {
            Text(label)
                .font(.system(size: 11, weight: isActive ? .bold : .medium, design: .monospaced))
                .foregroundColor(isActive ? ProCamColors.amber : Color(white: 0.55))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isActive ? ProCamColors.amber.opacity(0.25) : Color.clear)
                )
        }
    }
    
    private var flashIconName: String {
        switch cameraManager.uiState.flashMode {
        case .off: return "bolt.slash.fill"
        case .auto: return "bolt.badge.a.fill"
        case .on: return "bolt.fill"
        case .torch: return "flashlight.on.fill"
        }
    }
}
