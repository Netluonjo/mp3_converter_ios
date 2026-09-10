import SwiftUI
import AVFoundation

public struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager
    
    public init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
    }
    
    public func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.cameraManager = cameraManager
        view.videoPreviewLayer.session = cameraManager.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.setupGestures()
        return view
    }
    
    public func updateUIView(_ uiView: PreviewUIView, context: Context) {
        // Update layer connection if needed
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
        // Tap to focus
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
        
        // Pinch to zoom
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinchGesture)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        showFocusBox(at: location)
        
        // Convert point to device coordinates (0.0 to 1.0)
        let devicePoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: location)
        
        // Trigger haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
        
        // Focus and meter lens at tapped position
        cameraManager?.tapToFocus(at: devicePoint)
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
        box.layer.borderColor = UIColor(red: 1.0, green: 0.72, blue: 0.0, alpha: 0.9).cgColor // Halide yellow
        box.layer.borderWidth = 1.5
        box.layer.cornerRadius = 4
        box.backgroundColor = .clear
        box.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        
        addSubview(box)
        focusBoxView = box
        
        // Animate pulse
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
