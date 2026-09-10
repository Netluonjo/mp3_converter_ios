import SwiftUI

public struct HalideDrumDialView: View {
    @ObservedObject var cameraManager: CameraManager
    public let isEvMode: Bool
    
    private let feedback = UIImpactFeedbackGenerator(style: .rigid)
    
    public init(cameraManager: CameraManager, isEvMode: Bool = true) {
        self.cameraManager = cameraManager
        self.isEvMode = isEvMode
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            if isEvMode {
                evHeaderAndPresets
                evDrumWheel
            } else {
                isoHeaderAndPresets
                isoDrumWheel
            }
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
    
    // MARK: - EV Header & Quick Pills
    private var evHeaderAndPresets: some View {
        HStack {
            HStack(spacing: 6) {
                Text("EXPOSURE EV")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(ProCamColors.textSecondary)
                
                Text(cameraManager.uiState.formatEv(cameraManager.uiState.currentEv))
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundColor(abs(cameraManager.uiState.currentEv) < 0.05 ? ProCamColors.green : ProCamColors.halideGold)
            }
            
            Spacer()
            
            // Quick preset pills: 0.0, +1.0, +2.0, +3.0
            HStack(spacing: 5) {
                ForEach([0.0, 1.0, 2.0, 3.0], id: \.self) { val in
                    let fVal = Float(val)
                    let isSelected = abs(cameraManager.uiState.currentEv - fVal) < 0.05
                    Button(action: {
                        feedback.impactOccurred()
                        cameraManager.setEv(fVal)
                    }) {
                        Text(fVal == 0 ? "0.0" : String(format: "+%.0f", fVal))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isSelected ? ProCamColors.halideGold : ProCamColors.dslrSurface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(isSelected ? ProCamColors.halideGold : Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(isSelected ? .black : .white)
                    }
                }
            }
        }
    }
    
    // MARK: - ISO Header & Quick Pills
    private var isoHeaderAndPresets: some View {
        HStack {
            HStack(spacing: 6) {
                Text("MANUAL ISO")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(ProCamColors.textSecondary)
                
                Text(cameraManager.uiState.isAutoIso ? "AUTO" : "\(cameraManager.uiState.currentIso)")
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundColor(cameraManager.uiState.isAutoIso ? ProCamColors.green : ProCamColors.halideGold)
            }
            
            Spacer()
            
            // Quick preset pills: AUTO, 100, 400, 1600
            HStack(spacing: 5) {
                presetPill(title: "AUTO", isSelected: cameraManager.uiState.isAutoIso) {
                    cameraManager.setIso(100, isAuto: true)
                }
                presetPill(title: "100", isSelected: !cameraManager.uiState.isAutoIso && cameraManager.uiState.currentIso == 100) {
                    cameraManager.setIso(100, isAuto: false)
                }
                presetPill(title: "400", isSelected: !cameraManager.uiState.isAutoIso && cameraManager.uiState.currentIso == 400) {
                    cameraManager.setIso(400, isAuto: false)
                }
                presetPill(title: "1600", isSelected: !cameraManager.uiState.isAutoIso && cameraManager.uiState.currentIso == 1600) {
                    cameraManager.setIso(1600, isAuto: false)
                }
            }
        }
    }
    
    private func presetPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
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
                        .fill(isSelected ? ProCamColors.halideGold : ProCamColors.dslrSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isSelected ? ProCamColors.halideGold : Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
        }
    }
    
    // MARK: - EV Drum Wheel
    private var evDrumWheel: some View {
        let currentIndex = currentEvStopIndex
        
        return ZStack {
            // Center needle
            Rectangle()
                .fill(ProCamColors.halideGold)
                .frame(width: 2.5, height: 34)
                .cornerRadius(1)
                .zIndex(3)
            
            HStack(spacing: 16) {
                ForEach(0..<HALIDE_EV_VALUES.count, id: \.self) { idx in
                    let stop = HALIDE_EV_VALUES[idx]
                    let isCenter = idx == currentIndex
                    let offset = abs(idx - currentIndex)
                    let alpha = offset == 0 ? 1.0 : (offset == 1 ? 0.70 : (offset == 2 ? 0.40 : 0.15))
                    
                    VStack(spacing: 3) {
                        Rectangle()
                            .fill(isCenter ? ProCamColors.halideGold : (stop.value.truncatingRemainder(dividingBy: 1.0) == 0 ? Color.white.opacity(0.8) : Color.white.opacity(0.35)))
                            .frame(width: isCenter ? 2.5 : 1.5, height: isCenter ? 20 : (stop.value.truncatingRemainder(dividingBy: 1.0) == 0 ? 15 : 9))
                            .cornerRadius(1)
                        
                        Text(stop.label)
                            .font(.system(size: isCenter ? 12 : 10, weight: isCenter ? .black : .bold, design: .monospaced))
                            .foregroundColor(isCenter ? (abs(stop.value) < 0.05 ? ProCamColors.green : ProCamColors.halideGold) : Color.white.opacity(alpha))
                    }
                    .frame(width: 38)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        feedback.impactOccurred()
                        cameraManager.setEv(stop.value)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // Left / Right nudge
            HStack {
                Button(action: {
                    if currentIndex > 0 {
                        feedback.impactOccurred()
                        cameraManager.setEv(HALIDE_EV_VALUES[currentIndex - 1].value)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(currentIndex > 0 ? Color(white: 0.7) : Color(white: 0.25))
                        .frame(width: 32, height: 40)
                }
                
                Spacer()
                
                Button(action: {
                    if currentIndex < HALIDE_EV_VALUES.count - 1 {
                        feedback.impactOccurred()
                        cameraManager.setEv(HALIDE_EV_VALUES[currentIndex + 1].value)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(currentIndex < HALIDE_EV_VALUES.count - 1 ? Color(white: 0.7) : Color(white: 0.25))
                        .frame(width: 32, height: 40)
                }
            }
        }
        .frame(height: 48)
    }
    
    // MARK: - ISO Drum Wheel
    private var isoDrumWheel: some View {
        let currentIndex = currentIsoStopIndex
        
        return ZStack {
            // Center needle
            Rectangle()
                .fill(ProCamColors.halideGold)
                .frame(width: 2.5, height: 34)
                .cornerRadius(1)
                .zIndex(3)
            
            HStack(spacing: 16) {
                ForEach(0..<HALIDE_ISO_VALUES.count, id: \.self) { idx in
                    let stop = HALIDE_ISO_VALUES[idx]
                    let isCenter = idx == currentIndex
                    let offset = abs(idx - currentIndex)
                    let alpha = offset == 0 ? 1.0 : (offset == 1 ? 0.70 : (offset == 2 ? 0.40 : 0.15))
                    
                    VStack(spacing: 3) {
                        Rectangle()
                            .fill(isCenter ? ProCamColors.halideGold : (idx == 0 || [100, 200, 400, 800, 1600, 3200].contains(stop.value) ? Color.white.opacity(0.8) : Color.white.opacity(0.35)))
                            .frame(width: isCenter ? 2.5 : 1.5, height: isCenter ? 20 : (idx == 0 || [100, 200, 400, 800, 1600, 3200].contains(stop.value) ? 15 : 9))
                            .cornerRadius(1)
                        
                        Text(stop.label)
                            .font(.system(size: isCenter ? 11 : 9, weight: isCenter ? .black : .bold, design: .monospaced))
                            .foregroundColor(isCenter ? (stop.value == -1 ? ProCamColors.green : ProCamColors.halideGold) : Color.white.opacity(alpha))
                    }
                    .frame(width: 38)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        feedback.impactOccurred()
                        if stop.value == -1 {
                            cameraManager.setIso(100, isAuto: true)
                        } else {
                            cameraManager.setIso(stop.value, isAuto: false)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // Left / Right nudge
            HStack {
                Button(action: {
                    if currentIndex > 0 {
                        feedback.impactOccurred()
                        let prev = HALIDE_ISO_VALUES[currentIndex - 1]
                        cameraManager.setIso(prev.value == -1 ? 100 : prev.value, isAuto: prev.value == -1)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(currentIndex > 0 ? Color(white: 0.7) : Color(white: 0.25))
                        .frame(width: 32, height: 40)
                }
                
                Spacer()
                
                Button(action: {
                    if currentIndex < HALIDE_ISO_VALUES.count - 1 {
                        feedback.impactOccurred()
                        let next = HALIDE_ISO_VALUES[currentIndex + 1]
                        cameraManager.setIso(next.value == -1 ? 100 : next.value, isAuto: next.value == -1)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(currentIndex < HALIDE_ISO_VALUES.count - 1 ? Color(white: 0.7) : Color(white: 0.25))
                        .frame(width: 32, height: 40)
                }
            }
        }
        .frame(height: 48)
    }
    
    private var currentEvStopIndex: Int {
        let current = cameraManager.uiState.currentEv
        var best = 6 // default 0.0
        var minDiff: Float = 100.0
        for i in 0..<HALIDE_EV_VALUES.count {
            let diff = abs(HALIDE_EV_VALUES[i].value - current)
            if diff < minDiff {
                minDiff = diff
                best = i
            }
        }
        return best
    }
    
    private var currentIsoStopIndex: Int {
        if cameraManager.uiState.isAutoIso { return 0 }
        let current = cameraManager.uiState.currentIso
        var best = 4 // default 100
        var minDiff = 100000
        for i in 1..<HALIDE_ISO_VALUES.count {
            let diff = abs(HALIDE_ISO_VALUES[i].value - current)
            if diff < minDiff {
                minDiff = diff
                best = i
            }
        }
        return best
    }
}
