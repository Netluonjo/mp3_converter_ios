import SwiftUI

public struct HalideWbDialView: View {
    @ObservedObject var cameraManager: CameraManager
    private let feedback = UIImpactFeedbackGenerator(style: .rigid)
    
    public init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Header & Presets
            wbHeaderAndPresets
            
            // Kelvin Ruler Dial
            wbRulerWheel
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
    
    // MARK: - Header & Quick Kelvin Presets
    private var wbHeaderAndPresets: some View {
        HStack {
            HStack(spacing: 6) {
                Text("WHITE BALANCE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(ProCamColors.textSecondary)
                
                let wbText = cameraManager.uiState.isAutoWb ? "AUTO" : "\(cameraManager.uiState.currentKelvin)K"
                Text(wbText)
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .foregroundColor(ProCamColors.amber)
            }
            
            Spacer()
            
            // Quick preset pills: AUTO, INCAN (3000K), FLUOR (4000K), DAY (5500K), SHADE (7500K)
            HStack(spacing: 5) {
                wbPresetButton(title: "AUTO", isSelected: cameraManager.uiState.isAutoWb) {
                    cameraManager.setKelvin(5500, isAuto: true)
                }
                wbPresetButton(title: "INCAN", isSelected: !cameraManager.uiState.isAutoWb && cameraManager.uiState.currentKelvin == 3200) {
                    cameraManager.setKelvin(3200, isAuto: false)
                }
                wbPresetButton(title: "FLUOR", isSelected: !cameraManager.uiState.isAutoWb && cameraManager.uiState.currentKelvin == 4000) {
                    cameraManager.setKelvin(4000, isAuto: false)
                }
                wbPresetButton(title: "DAY", isSelected: !cameraManager.uiState.isAutoWb && cameraManager.uiState.currentKelvin == 5500) {
                    cameraManager.setKelvin(5500, isAuto: false)
                }
                wbPresetButton(title: "SHADE", isSelected: !cameraManager.uiState.isAutoWb && cameraManager.uiState.currentKelvin == 7500) {
                    cameraManager.setKelvin(7500, isAuto: false)
                }
            }
        }
    }
    
    private func wbPresetButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
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
    
    // MARK: - White Balance Ruler Wheel
    private var wbRulerWheel: some View {
        let currentIndex = currentStopIndex
        
        return ZStack {
            // Center Indicator Needle
            Rectangle()
                .fill(ProCamColors.amber)
                .frame(width: 2.5, height: 36)
                .cornerRadius(1)
                .zIndex(3)
                .allowsHitTesting(false)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(0..<HALIDE_WB_VALUES.count, id: \.self) { idx in
                            let stop = HALIDE_WB_VALUES[idx]
                            let isCenter = idx == currentIndex
                            let offset = abs(idx - currentIndex)
                            let alpha = offset == 0 ? 1.0 : (offset == 1 ? 0.65 : (offset == 2 ? 0.35 : 0.15))
                            
                            VStack(spacing: 3) {
                                Rectangle()
                                    .fill(isCenter ? ProCamColors.amber : Color.white.opacity(0.35))
                                    .frame(width: isCenter ? 2.5 : 1.2, height: isCenter ? 18 : 10)
                                    .cornerRadius(1)
                                
                                Text(stop.label)
                                    .font(.system(size: isCenter ? 11 : 9, weight: isCenter ? .black : .bold, design: .monospaced))
                                    .foregroundColor(isCenter ? ProCamColors.amber : Color.white.opacity(alpha))
                                
                                // Color Temperature dot
                                Circle()
                                    .fill(stop.indicatorColor.opacity(alpha))
                                    .frame(width: isCenter ? 5 : 4, height: isCenter ? 5 : 4)
                            }
                            .frame(width: 44)
                            .contentShape(Rectangle())
                            .id(idx)
                            .onTapGesture {
                                feedback.impactOccurred()
                                cameraManager.setKelvin(stop.isAuto ? 5500 : stop.kelvin, isAuto: stop.isAuto)
                                withAnimation {
                                    proxy.scrollTo(idx, anchor: .center)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 140)
                }
                .onAppear {
                    proxy.scrollTo(currentIndex, anchor: .center)
                }
                .onChange(of: currentIndex) { newIdx in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        proxy.scrollTo(newIdx, anchor: .center)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // Left Nudge (‹)
            HStack {
                Button(action: {
                    if currentIndex > 0 {
                        feedback.impactOccurred()
                        let stop = HALIDE_WB_VALUES[currentIndex - 1]
                        cameraManager.setKelvin(stop.isAuto ? 5500 : stop.kelvin, isAuto: stop.isAuto)
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
                    if currentIndex < HALIDE_WB_VALUES.count - 1 {
                        feedback.impactOccurred()
                        let stop = HALIDE_WB_VALUES[currentIndex + 1]
                        cameraManager.setKelvin(stop.isAuto ? 5500 : stop.kelvin, isAuto: stop.isAuto)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(currentIndex < HALIDE_WB_VALUES.count - 1 ? Color(white: 0.7) : Color(white: 0.25))
                        .frame(width: 32, height: 40)
                }
            }
        }
        .frame(height: 52)
    }
    
    private var currentStopIndex: Int {
        if cameraManager.uiState.isAutoWb { return 0 }
        let currentK = cameraManager.uiState.currentKelvin
        var bestIndex = 1
        var minDiff = 100000
        for i in 1..<HALIDE_WB_VALUES.count {
            let diff = abs(HALIDE_WB_VALUES[i].kelvin - currentK)
            if diff < minDiff {
                minDiff = diff
                bestIndex = i
            }
        }
        return bestIndex
    }
}
