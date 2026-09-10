import SwiftUI
import AVFoundation

public struct CameraPreviewView: View {
    @ObservedObject var cameraManager: CameraManager
    
    public init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
    }
    
    public var body: some View {
        ZStack {
            CameraPreviewRepresentable(cameraManager: cameraManager)
            
            #if targetEnvironment(simulator)
            SimulatedCameraViewfinder(cameraManager: cameraManager)
            #else
            if !cameraManager.isCameraAvailable {
                SimulatedCameraViewfinder(cameraManager: cameraManager)
            }
            #endif
        }
    }
}

public struct CameraPreviewRepresentable: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager
    
    public func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.cameraManager = cameraManager
        view.videoPreviewLayer.session = cameraManager.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.setupGestures()
        return view
    }
    
    public func updateUIView(_ uiView: PreviewUIView, context: Context) {
        if let connection = uiView.videoPreviewLayer.connection {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
    }
}

public class PreviewUIView: UIView {
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    weak var cameraManager: CameraManager?
    private var focusBoxView: UIView?
    private var baseZoomFactor: CGFloat = 1.0
    
    override public class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinchGesture)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        showFocusBox(at: location)
        
        let devicePoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: location)
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
        
        cameraManager?.tapToFocus(at: devicePoint, screenPoint: location)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let manager = cameraManager else { return }
        
        if gesture.state == .began {
            baseZoomFactor = manager.uiState.currentZoomFactor
        } else if gesture.state == .changed {
            let newScale = baseZoomFactor * gesture.scale
            manager.setZoomFactor(newScale)
        }
    }
    
    private func showFocusBox(at point: CGPoint) {
        focusBoxView?.removeFromSuperview()
        
        let boxSize: CGFloat = 72
        let box = UIView(frame: CGRect(x: point.x - boxSize / 2, y: point.y - boxSize / 2, width: boxSize, height: boxSize))
        box.layer.borderColor = UIColor(red: 1.0, green: 0.72, blue: 0.0, alpha: 0.9).cgColor
        box.layer.borderWidth = 1.5
        box.layer.cornerRadius = 4
        box.backgroundColor = .clear
        box.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        
        addSubview(box)
        focusBoxView = box
        
        UIView.animate(withDuration: 0.25, animations: {
            box.transform = CGAffineTransform.identity
        }) { _ in
            UIView.animate(withDuration: 0.4, delay: 1.5, options: .curveEaseOut, animations: {
                box.alpha = 0.0
            }) { _ in
                box.removeFromSuperview()
            }
        }
    }
}

// MARK: - Simulated Viewfinder for Simulator or fallback
public struct SimulatedCameraViewfinder: View {
    @ObservedObject var cameraManager: CameraManager
    @State private var focusTapLocation: CGPoint? = nil
    
    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background DSLR lens scene
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.10, green: 0.12, blue: 0.16),
                        Color(red: 0.05, green: 0.06, blue: 0.08),
                        Color(red: 0.08, green: 0.09, blue: 0.13)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Optical elements in viewfinder
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    .frame(width: geo.size.width * 0.75, height: geo.size.width * 0.75)
                
                Circle()
                    .stroke(ProCamColors.amber.opacity(0.12), lineWidth: 1)
                    .frame(width: geo.size.width * 0.35, height: geo.size.width * 0.35)
                
                // Center ProCam Optical Mark
                VStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 42, weight: .ultraLight))
                        .foregroundColor(ProCamColors.amber.opacity(0.5))
                    
                    Text("PROCAM SENSOR ACTIVE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.6))
                        .tracking(1.5)
                    
                    Text(String(format: "%.1fx ZOOM • ISO %d • %@s",
                                cameraManager.uiState.currentZoomRatio,
                                cameraManager.uiState.currentIso,
                                cameraManager.uiState.isAutoShutter ? "AUTO" : cameraManager.uiState.formatShutterSpeed(cameraManager.uiState.currentExposureDurationSeconds)))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(ProCamColors.amber.opacity(0.8))
                }
                .scaleEffect(cameraManager.uiState.currentZoomRatio)
                
                // Tap to focus reticle
                if let tap = focusTapLocation {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(ProCamColors.amber, lineWidth: 1.5)
                        .frame(width: 64, height: 64)
                        .position(tap)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                let feedback = UIImpactFeedbackGenerator(style: .light)
                feedback.impactOccurred()
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    focusTapLocation = location
                }
                let devX = location.x / geo.size.width
                let devY = location.y / geo.size.height
                cameraManager.tapToFocus(at: CGPoint(x: devX, y: devY), screenPoint: location)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        if focusTapLocation == location {
                            focusTapLocation = nil
                        }
                    }
                }
            }
        }
    }
}
