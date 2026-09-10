import SwiftUI

public struct OverlaysView: View {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var motionManager: MotionSensorManager
    
    public init(cameraManager: CameraManager, motionManager: MotionSensorManager) {
        self.cameraManager = cameraManager
        self.motionManager = motionManager
    }
    
    public var body: some View {
        ZStack {
            // 1. Composition Grid
            if cameraManager.uiState.gridType != .none {
                gridCanvas
            }
            
            // 2. Artificial Horizon / Tiltmeter Level (Center of Viewfinder)
            if cameraManager.uiState.isTiltMeterEnabled {
                tiltMeterOverlay
            }
            
            // 3. Tap to Focus Reticle Ring + Sun AE Metering Icon
            if let focusPoint = cameraManager.focusReticlePoint {
                focusReticleView(at: focusPoint)
            }
            
            // 4. Stereo Audio VU Meter (Left edge in Video Mode)
            if cameraManager.uiState.selectedMode == .video {
                HStack {
                    AudioVuMeterWidget(decibelLevel: cameraManager.uiState.audioDecibelLevel)
                        .padding(.leading, 12)
                    Spacer()
                }
                
                // Video Recording Indicator Badge (Bottom Left)
                if cameraManager.uiState.isRecordingVideo {
                    VStack {
                        Spacer()
                        HStack {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(ProCamColors.red)
                                    .frame(width: 8, height: 8)
                                
                                let minutes = cameraManager.uiState.videoRecordingSeconds / 60
                                let seconds = cameraManager.uiState.videoRecordingSeconds % 60
                                Text(String(format: "REC %02d:%02d", minutes, seconds))
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.6)))
                            .padding(.leading, 14)
                            .padding(.bottom, 12)
                            
                            Spacer()
                        }
                    }
                }
            }
            
            // 5. Live Luminance Histogram Overlay (Bottom-Right)
            if cameraManager.uiState.isHistogramEnabled {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        liveHistogramView
                            .padding(.trailing, 12)
                            .padding(.bottom, 12)
                    }
                }
            }
            
            // 6. ProCam Quick Zoom Preset Widget (Bottom-Center)
            VStack {
                Spacer()
                ZoomControlWidget(
                    currentZoom: cameraManager.uiState.currentZoomRatio,
                    maxZoom: cameraManager.uiState.maxZoomRatio,
                    isFrontCamera: cameraManager.uiState.isFrontCamera
                ) { zoom in
                    cameraManager.setZoomRatio(zoom)
                }
                .padding(.bottom, 12)
            }
        }
    }
    
    // MARK: - Composition Grid Canvas
    private var gridCanvas: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            Path { path in
                switch cameraManager.uiState.gridType {
                case .ruleOfThirds:
                    let col1 = w / 3.0
                    let col2 = 2.0 * w / 3.0
                    let row1 = h / 3.0
                    let row2 = 2.0 * h / 3.0
                    
                    path.move(to: CGPoint(x: col1, y: 0))
                    path.addLine(to: CGPoint(x: col1, y: h))
                    path.move(to: CGPoint(x: col2, y: 0))
                    path.addLine(to: CGPoint(x: col2, y: h))
                    
                    path.move(to: CGPoint(x: 0, y: row1))
                    path.addLine(to: CGPoint(x: w, y: row1))
                    path.move(to: CGPoint(x: 0, y: row2))
                    path.addLine(to: CGPoint(x: w, y: row2))
                    
                case .goldenRatio:
                    let phi: CGFloat = 0.618
                    let col1 = w * (1.0 - phi)
                    let col2 = w * phi
                    let row1 = h * (1.0 - phi)
                    let row2 = h * phi
                    
                    path.move(to: CGPoint(x: col1, y: 0))
                    path.addLine(to: CGPoint(x: col1, y: h))
                    path.move(to: CGPoint(x: col2, y: 0))
                    path.addLine(to: CGPoint(x: col2, y: h))
                    
                    path.move(to: CGPoint(x: 0, y: row1))
                    path.addLine(to: CGPoint(x: w, y: row1))
                    path.move(to: CGPoint(x: 0, y: row2))
                    path.addLine(to: CGPoint(x: w, y: row2))
                    
                case .crosshair:
                    let cx = w / 2.0
                    let cy = h / 2.0
                    let arm: CGFloat = 40.0
                    
                    path.move(to: CGPoint(x: cx - arm, y: cy))
                    path.addLine(to: CGPoint(x: cx + arm, y: cy))
                    path.move(to: CGPoint(x: cx, y: cy - arm))
                    path.addLine(to: CGPoint(x: cx, y: cy + arm))
                    path.addEllipse(in: CGRect(x: cx - 25, y: cy - 25, width: 50, height: 50))
                    
                case .none:
                    break
                }
            }
            .stroke(Color.white.opacity(0.35), lineWidth: 1.2)
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Tiltmeter / Artificial Horizon Level
    private var tiltMeterOverlay: some View {
        GeometryReader { geo in
            let isLevel = motionManager.isLevel
            let strokeColor = isLevel ? ProCamColors.peakingGreen : Color.white.opacity(0.65)
            let strokeW: CGFloat = isLevel ? 3.0 : 1.8
            let wingLength: CGFloat = 55.0
            let gap: CGFloat = 28.0
            let cx = geo.size.width / 2.0
            let cy = geo.size.height / 2.0
            
            ZStack {
                // Left Wing
                Rectangle()
                    .fill(strokeColor)
                    .frame(width: wingLength, height: strokeW)
                    .position(x: cx - gap - wingLength / 2.0, y: cy)
                
                // Right Wing
                Rectangle()
                    .fill(strokeColor)
                    .frame(width: wingLength, height: strokeW)
                    .position(x: cx + gap + wingLength / 2.0, y: cy)
                
                // Center Dot
                Circle()
                    .fill(strokeColor)
                    .frame(width: isLevel ? 6 : 4, height: isLevel ? 6 : 4)
                    .position(x: cx, y: cy)
            }
            .rotationEffect(.degrees(motionManager.rollDegrees))
            .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.8), value: motionManager.rollDegrees)
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Tap to Focus Reticle + Sun AE Icon
    private func focusReticleView(at point: CGPoint) -> some View {
        ZStack {
            // Dashed yellow focus circle
            Circle()
                .stroke(ProCamColors.amber, style: StrokeStyle(lineWidth: 2.5, dash: [10, 6]))
                .frame(width: 80, height: 80)
            
            // Sun AE metering icon to the right
            Circle()
                .fill(ProCamColors.amber)
                .frame(width: 12, height: 12)
                .offset(x: 52)
        }
        .position(point)
        .transition(.opacity.combined(with: .scale(scale: 1.15)))
        .allowsHitTesting(false)
    }
    
    // MARK: - Live Luminance Histogram (256 Bins Gradient Curve)
    private var liveHistogramView: some View {
        let bins = cameraManager.histogramData.lumaBins
        
        return ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.35), lineWidth: 0.5)
                )
            
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let stepX = w / 256.0
                
                Path { path in
                    path.move(to: CGPoint(x: 0, y: h))
                    for i in 0..<min(256, bins.count) {
                        let x = CGFloat(i) * stepX
                        let normalizedY = (1.0 - CGFloat(max(0.0, min(1.0, bins[i])))) * h
                        path.addLine(to: CGPoint(x: x, y: normalizedY))
                    }
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.85), Color.white.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .frame(width: 88, height: 44)
        .allowsHitTesting(false)
    }
}
