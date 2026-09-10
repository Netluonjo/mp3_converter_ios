import SwiftUI

public struct LockControlView: View {
    @ObservedObject var cameraManager: CameraManager
    private let feedback = UIImpactFeedbackGenerator(style: .medium)
    
    public init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            // AE/AF Lock Button
            Button(action: {
                feedback.impactOccurred()
                cameraManager.toggleAeAfLock()
            }) {
                Text(cameraManager.uiState.isAeAfLocked ? "AE/AF LOCKED" : "LOCK AE/AF")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(cameraManager.uiState.isAeAfLocked ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(cameraManager.uiState.isAeAfLocked ? ProCamColors.amber : ProCamColors.dslrSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(cameraManager.uiState.isAeAfLocked ? ProCamColors.amber : ProCamColors.dslrBorder, lineWidth: 1)
                            )
                    )
            }
            
            // WB Lock Button
            Button(action: {
                feedback.impactOccurred()
                cameraManager.toggleWbLock()
            }) {
                Text(cameraManager.uiState.isWbLocked ? "WB LOCKED" : "LOCK WB")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(cameraManager.uiState.isWbLocked ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(cameraManager.uiState.isWbLocked ? ProCamColors.amber : ProCamColors.dslrSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(cameraManager.uiState.isWbLocked ? ProCamColors.amber : ProCamColors.dslrBorder, lineWidth: 1)
                            )
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(ProCamColors.dslrDarkGrey.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(ProCamColors.dslrBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal, 12)
    }
}
