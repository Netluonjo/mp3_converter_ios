import SwiftUI

public struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var motionManager = MotionSensorManager()
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Fullscreen Background
            ProCamColors.dslrBlack
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // 1. Camera Top Bar (2 tiers: primary status + sub-header info strip)
                CameraTopBarView(cameraManager: cameraManager)
                
                // 2. Viewfinder with Aspect Ratio & Overlays
                ZStack {
                    GeometryReader { geo in
                        CameraPreviewView(cameraManager: cameraManager)
                            .aspectRatio(cameraManager.uiState.aspectRatio.multiplier, contentMode: .fit)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { value in
                                        let screenPoint = value.location
                                        let deviceX = screenPoint.x / geo.size.width
                                        let deviceY = screenPoint.y / geo.size.height
                                        cameraManager.tapToFocus(at: CGPoint(x: deviceX, y: deviceY), screenPoint: screenPoint)
                                    }
                            )
                    }
                    
                    // Live Overlays (Grid, Tiltmeter, Reticle, Histogram, VU meter, REC badge, Zoom widget)
                    OverlaysView(cameraManager: cameraManager, motionManager: motionManager)
                    
                    // Shutter Flash Feedback
                    if cameraManager.uiState.isShutterFlashing {
                        Color.white
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                
                // 3. ProCam 6-Column Parameter Strip [ ISO ] [ SEC ] [ EV ] [ AF ] [ AWB ] [ E/F ]
                ManualParamBarView(cameraManager: cameraManager)
                
                // 4. Manual Control Dial (Halide ISO/EV Drum, Focus Dial, WB Dial, Ruler Dial, or Lock panel)
                activeControlDial
                    .padding(.vertical, 4)
                    .background(Color.black)
                
                // 5. Expandable Shooting Mode Drawer
                ModeSelectorView(
                    cameraManager: cameraManager,
                    isExpanded: cameraManager.uiState.isModeDrawerExpanded
                ) { mode in
                    cameraManager.setShootingMode(mode)
                    withAnimation {
                        cameraManager.uiState.isModeDrawerExpanded = false
                    }
                }
                
                // 6. Iconic Bottom Shutter & Controls Row
                ShutterControlView(cameraManager: cameraManager)
            }
            
            // 7. ProCam Settings Modal Dialog (When tapping SET)
            if cameraManager.uiState.isSetMenuOpen {
                ProCamSettingsModalView(cameraManager: cameraManager) {
                    cameraManager.toggleSetMenu()
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .statusBar(hidden: true)
    }
    
    // MARK: - Active Dial Selector
    @ViewBuilder
    private var activeControlDial: some View {
        switch cameraManager.uiState.activeManualParam {
        case .iso:
            HalideDrumDialView(cameraManager: cameraManager, isEvMode: false)
        case .ev:
            HalideDrumDialView(cameraManager: cameraManager, isEvMode: true)
        case .af:
            HalideFocusDialView(cameraManager: cameraManager)
        case .awb:
            HalideWbDialView(cameraManager: cameraManager)
        case .lock:
            LockControlView(cameraManager: cameraManager)
        case .sec, .none:
            ProCamRulerDialView(cameraManager: cameraManager)
        }
    }
}
