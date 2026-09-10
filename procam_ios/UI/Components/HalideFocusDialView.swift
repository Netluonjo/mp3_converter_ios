import SwiftUI

public struct HalideFocusDialView: View {
    @ObservedObject var cameraManager: CameraManager
    private let feedback = UIImpactFeedbackGenerator(style: .rigid)
    
    public init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Header & Presets
            focusHeaderAndPresets
            
            // Focus Ruler Dial
            focusRulerWheel
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
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
    
    // MARK: - Header & Quick Focus Presets
    private var focusHeaderAndPresets: some View {
        HStack {
            HStack(spacing: 6) {
                Text("MANUAL FOCUS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(ProCamColors.textSecondary)
                
                let distText = cameraManager.uiState.isAutoFocus ? "AUTO" : cameraManager.uiState.formatFocusDistance(cameraManager.uiState.currentLensPosition)
                Text(distText)
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .foregroundColor(ProCamColors.amber)
            }
            
            Spacer()
            
            // Quick preset pills: AUTO, MACRO, 0.5m, 1.0m, ∞
            HStack(spacing: 5) {
                focusPresetButton(title: "AUTO", isSelected: cameraManager.uiState.isAutoFocus) {
                    cameraManager.setFocusPosition(0.0, isAuto: true)
                }
                focusPresetButton(title: "MACRO", isSelected: !cameraManager.uiState.isAutoFocus && cameraManager.uiState.currentLensPosition >= 0.90) {
                    cameraManager.setFocusPosition(1.0, isAuto: false)
                }
                focusPresetButton(title: "0.5m", isSelected: !cameraManager.uiState.isAutoFocus && abs(cameraManager.uiState.currentLensPosition - 0.40) < 0.08) {
                    cameraManager.setFocusPosition(0.40, isAuto: false)
                }
                focusPresetButton(title: "1.0m", isSelected: !cameraManager.uiState.isAutoFocus && abs(cameraManager.uiState.currentLensPosition - 0.25) < 0.06) {
                    cameraManager.setFocusPosition(0.25, isAuto: false)
                }
                focusPresetButton(title: "∞", isSelected: !cameraManager.uiState.isAutoFocus && cameraManager.uiState.currentLensPosition <= 0.05) {
                    cameraManager.setFocusPosition(0.0, isAuto: false)
                }
            }
        }
    }
    
    private func focusPresetButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            feedback.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? ProCamColors.amber : ProCamColors.dslrSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isSelected ? ProCamColors.amber : Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
        }
    }
    
    // MARK: - Focus Ruler Wheel
    private var focusRulerWheel: some View {
        let currentIndex = currentStopIndex
        
        return ZStack {
            // Center Indicator Needle
            Rectangle()
                .fill(ProCamColors.amber)
                .frame(width: 2.5, height: 36)
                .cornerRadius(1)
                .zIndex(3)
            
            // Scrollable / Tappable Graduated Marks
            HStack(spacing: 20) {
                ForEach(0..<HALIDE_FOCUS_VALUES.count, id: \.self) { idx in
                    let stop = HALIDE_FOCUS_VALUES[idx]
                    let isCenter = idx == currentIndex
                    let offset = abs(idx - currentIndex)
                    let alpha = offset == 0 ? 1.0 : (offset == 1 ? 0.65 : (offset == 2 ? 0.35 : 0.15))
                    
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(isCenter ? ProCamColors.amber : Color.white.opacity(0.35))
                            .frame(width: isCenter ? 2.5 : 1.2, height: isCenter ? 20 : 12)
                            .cornerRadius(1)
                        
                        Text(stop.label)
                            .font(.system(size: isCenter ? 12 : 10, weight: isCenter ? .black : .bold, design: .monospaced))
                            .foregroundColor(isCenter ? ProCamColors.amber : Color.white.opacity(alpha))
                    }
                    .frame(width: 44)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        feedback.impactOccurred()
                        cameraManager.setFocusPosition(stop.lensPosition, isAuto: stop.isAuto)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // Left Nudge (‹)
            HStack {
                Button(action: {
                    if currentIndex > 0 {
                        feedback.impactOccurred()
                        let stop = HALIDE_FOCUS_VALUES[currentIndex - 1]
                        cameraManager.setFocusPosition(stop.lensPosition, isAuto: stop.isAuto)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(currentIndex > 0 ? Color(white: 0.7) : Color(white: 0.25))
                        .frame(width: 32, height: 40)
                }
                
                Spacer()
                
                // Right Nudge (›)
                Button(action: {
                    if currentIndex < HALIDE_FOCUS_VALUES.count - 1 {
                        feedback.impactOccurred()
                        let stop = HALIDE_FOCUS_VALUES[currentIndex + 1]
                        cameraManager.setFocusPosition(stop.lensPosition, isAuto: stop.isAuto)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(currentIndex < HALIDE_FOCUS_VALUES.count - 1 ? Color(white: 0.7) : Color(white: 0.25))
                        .frame(width: 32, height: 40)
                }
            }
        }
        .frame(height: 48)
    }
    
    private var currentStopIndex: Int {
        if cameraManager.uiState.isAutoFocus { return 0 }
        let currentPos = cameraManager.uiState.currentLensPosition
        var bestIndex = 1
        var minDiff: Float = 100.0
        for i in 1..<HALIDE_FOCUS_VALUES.count {
            let diff = abs(HALIDE_FOCUS_VALUES[i].lensPosition - currentPos)
            if diff < minDiff {
                minDiff = diff
                bestIndex = i
            }
        }
        return bestIndex
    }
}
