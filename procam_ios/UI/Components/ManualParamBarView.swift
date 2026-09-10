import SwiftUI

public struct ManualParamBarView: View {
    @ObservedObject var cameraManager: CameraManager
    private let feedback = UIImpactFeedbackGenerator(style: .light)
    
    public init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
    }
    
    public var body: some View {
        let state = cameraManager.uiState
        
        let isoText = state.isAutoIso ? "AUTO" : "\(state.currentIso)"
        let secText = state.isAutoShutter ? "AUTO" : state.formatShutterSpeed(state.currentExposureDurationSeconds)
        let evText = state.formatEv(state.currentEv)
        let afText = state.isAutoFocus ? "AUTO" : state.formatFocusDistance(state.currentLensPosition)
        let awbText = state.isAutoWb ? "AUTO" : "\(state.currentKelvin)K"
        let lockText: String = {
            if state.isAeAfLocked && state.isWbLocked { return "ALL-L" }
            if state.isAeAfLocked { return "AE-L" }
            if state.isWbLocked { return "WB-L" }
            return "OFF"
        }()
        
        let items: [(ManualParameter, String, String)] = [
            (.iso, "ISO", isoText),
            (.sec, "SEC", secText),
            (.ev, "EV", evText),
            (.af, "AF", afText),
            (.awb, "AWB", awbText),
            (.lock, "E/F", lockText)
        ]
        
        HStack(spacing: 0) {
            ForEach(0..<items.count, id: \.self) { index in
                let item = items[index]
                let isSelected = state.activeManualParam == item.0
                
                Button(action: {
                    feedback.impactOccurred()
                    cameraManager.setActiveParam(item.0)
                }) {
                    VStack(spacing: 2) {
                        Text(item.1)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(isSelected ? ProCamColors.amber : ProCamColors.textSecondary)
                        
                        Text(item.2)
                            .font(.system(size: 11, weight: isSelected ? .heavy : .medium, design: .monospaced))
                            .foregroundColor(isSelected ? Color.white : Color(white: 0.8))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        // Active bottom amber highlight indicator
                        Rectangle()
                            .fill(isSelected ? ProCamColors.amber : Color.clear)
                            .frame(height: 2)
                            .padding(.top, 1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                
                // Vertical divider
                if index < items.count - 1 {
                    Rectangle()
                        .fill(Color(white: 0.17))
                        .frame(width: 0.5, height: 24)
                }
            }
        }
        .frame(height: 48)
        .background(Color.black)
    }
}
