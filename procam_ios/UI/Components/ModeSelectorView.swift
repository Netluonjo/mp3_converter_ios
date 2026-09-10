import SwiftUI

public struct ModeSelectorView: View {
    @ObservedObject var cameraManager: CameraManager
    public let isExpanded: Bool
    public let onModeSelected: (ShootingMode) -> Void
    
    private let feedback = UIImpactFeedbackGenerator(style: .light)
    
    public init(
        cameraManager: CameraManager,
        isExpanded: Bool,
        onModeSelected: @escaping (ShootingMode) -> Void
    ) {
        self.cameraManager = cameraManager
        self.isExpanded = isExpanded
        self.onModeSelected = onModeSelected
    }
    
    public var body: some View {
        if isExpanded {
            VStack(spacing: 6) {
                // Primary Shooting Modes Row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ShootingMode.allCases) { mode in
                            let isSelected = mode == cameraManager.uiState.selectedMode
                            
                            Button(action: {
                                feedback.impactOccurred()
                                onModeSelected(mode)
                            }) {
                                Text(mode.title)
                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .monospaced))
                                    .foregroundColor(isSelected ? ProCamColors.amber : ProCamColors.textMuted)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isSelected ? ProCamColors.amber.opacity(0.2) : Color.clear)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                }
                
                // Sub-mode options for Slow Shutter
                if cameraManager.uiState.selectedMode == .slowShutter {
                    HStack(spacing: 12) {
                        ForEach(SlowShutterMode.allCases) { subMode in
                            let isSubSelected = cameraManager.uiState.slowShutterMode == subMode
                            Button(action: {
                                feedback.impactOccurred()
                                cameraManager.uiState.slowShutterMode = subMode
                            }) {
                                Text(subMode.title)
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(isSubSelected ? .black : ProCamColors.amber)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(isSubSelected ? ProCamColors.amber : ProCamColors.dslrSurface)
                                    )
                            }
                        }
                    }
                    .padding(.bottom, 4)
                }
            }
            .background(Color(red: 10/255, green: 10/255, blue: 12/255).opacity(0.92))
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
