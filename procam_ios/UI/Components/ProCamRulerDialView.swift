import SwiftUI

public struct ProCamRulerDialView: View {
    @ObservedObject var cameraManager: CameraManager
    private let feedback = UIImpactFeedbackGenerator(style: .rigid)
    
    public init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            // Header
            HStack {
                Text("SHUTTER SPEED (SEC)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(ProCamColors.textSecondary)
                
                Spacer()
                
                let shutterText = cameraManager.uiState.isAutoShutter ? "AUTO" : cameraManager.uiState.formatShutterSpeed(cameraManager.uiState.currentExposureDurationSeconds)
                Text(shutterText)
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundColor(ProCamColors.red)
            }
            .padding(.horizontal, 8)
            
            // Ruler Marks
            rulerContent
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
    
    private var rulerContent: some View {
        let currentIndex = currentStopIndex
        
        return ZStack {
            // Center ProCam Red Needle Marker
            Rectangle()
                .fill(ProCamColors.red)
                .frame(width: 2.5, height: 32)
                .cornerRadius(1)
                .shadow(color: ProCamColors.red.opacity(0.6), radius: 3)
                .zIndex(3)
                .allowsHitTesting(false)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(0..<SHUTTER_STOPS.count, id: \.self) { idx in
                            let stop = SHUTTER_STOPS[idx]
                            let isCenter = idx == currentIndex
                            let offset = abs(idx - currentIndex)
                            let alpha = offset == 0 ? 1.0 : (offset == 1 ? 0.70 : (offset == 2 ? 0.40 : 0.15))
                            
                            VStack(spacing: 3) {
                                Rectangle()
                                    .fill(isCenter ? ProCamColors.red : (idx % 2 == 0 ? Color.white.opacity(0.8) : Color.white.opacity(0.35)))
                                    .frame(width: isCenter ? 2.5 : 1.5, height: isCenter ? 22 : (idx % 2 == 0 ? 16 : 10))
                                    .cornerRadius(1)
                                
                                Text(stop.label)
                                    .font(.system(size: isCenter ? 11 : 9, weight: isCenter ? .black : .bold, design: .monospaced))
                                    .foregroundColor(isCenter ? ProCamColors.red : Color.white.opacity(alpha))
                            }
                            .frame(width: 40)
                            .contentShape(Rectangle())
                            .id(idx)
                            .onTapGesture {
                                feedback.impactOccurred()
                                cameraManager.setShutterDuration(stop.seconds, isAuto: stop.isAuto)
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
                        let stop = SHUTTER_STOPS[currentIndex - 1]
                        cameraManager.setShutterDuration(stop.seconds, isAuto: stop.isAuto)
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
                    if currentIndex < SHUTTER_STOPS.count - 1 {
                        feedback.impactOccurred()
                        let stop = SHUTTER_STOPS[currentIndex + 1]
                        cameraManager.setShutterDuration(stop.seconds, isAuto: stop.isAuto)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(currentIndex < SHUTTER_STOPS.count - 1 ? Color(white: 0.7) : Color(white: 0.25))
                        .frame(width: 32, height: 40)
                }
            }
        }
        .frame(height: 48)
    }
    
    private var currentStopIndex: Int {
        if cameraManager.uiState.isAutoShutter { return 0 }
        let currentSec = cameraManager.uiState.currentExposureDurationSeconds
        var bestIndex = 1
        var minDiff = 10000.0
        for i in 1..<SHUTTER_STOPS.count {
            let diff = abs(SHUTTER_STOPS[i].seconds - currentSec)
            if diff < minDiff {
                minDiff = diff
                bestIndex = i
            }
        }
        return bestIndex
    }
}
