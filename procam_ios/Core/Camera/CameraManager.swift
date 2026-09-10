import Foundation
import AVFoundation
import UIKit
import Photos
import AudioToolbox
import Combine
import CoreMedia

public class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {
    
    // MARK: - Published State
    @Published public var uiState = CameraUiState()
    @Published public var session = AVCaptureSession()
    @Published public var histogramData = HistogramData()
    @Published public var focusReticlePoint: CGPoint? = nil
    
    // MARK: - Sub-Systems
    public let antiShakeDetector = AntiShakeDetector()
    public let frameStackingEngine = FrameStackingEngine()
    public let audioMeterManager = AudioMeterManager()
    
    // MARK: - Private Capture Properties
    private let sessionQueue = DispatchQueue(label: "com.sondeptrai.procam.sessionQueue")
    private var currentDevice: AVCaptureDevice?
    private var photoOutput = AVCapturePhotoOutput()
    private var movieFileOutput = AVCaptureMovieFileOutput()
    private var videoDataOutput = AVCaptureVideoDataOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var audioDeviceInput: AVCaptureDeviceInput?
    
    private var recordingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    public override init() {
        super.init()
        checkPermissions()
        bindSubsystems()
        histogramData = LiveHistogramCalculator.simulatedHistogram()
    }
    
    private func bindSubsystems() {
        antiShakeDetector.$isSteady
            .receive(on: DispatchQueue.main)
            .sink { [weak self] steady in
                self?.uiState.isSteadyForCapture = steady
            }
            .store(in: &cancellables)
        
        audioMeterManager.$decibelLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.uiState.audioDecibelLevel = level
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Permissions & Setup
    private func checkPermissions() {
        #if targetEnvironment(simulator)
        DispatchQueue.main.async {
            self.uiState.isInitialized = true
            self.uiState.maxZoomRatio = 10.0
        }
        #else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupSession()
                } else {
                    DispatchQueue.main.async {
                        self?.uiState.isInitialized = true
                    }
                }
            }
        default:
            print("Camera access denied.")
            DispatchQueue.main.async {
                self.uiState.isInitialized = true
            }
        }
        #endif
    }
    
    public var isCameraAvailable: Bool {
        return currentDevice != nil && session.isRunning
    }
    
    public func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning && self.currentDevice != nil {
                self.session.startRunning()
            }
        }
    }
    
    public func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    public func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            
            // Default to Back Wide Camera
            guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                print("Back camera unavailable (Simulator or restricted device)")
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.uiState.isInitialized = true
                    self.uiState.maxZoomRatio = 10.0
                }
                return
            }
            
            self.currentDevice = backCamera
            
            do {
                let videoInput = try AVCaptureDeviceInput(device: backCamera)
                if self.session.canAddInput(videoInput) {
                    self.session.addInput(videoInput)
                    self.videoDeviceInput = videoInput
                }
                
                // Photo Output
                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                    if #available(iOS 16.0, *) {
                        if let maxDim = backCamera.activeFormat.supportedMaxPhotoDimensions.max(by: { $0.width * $0.height < $1.width * $1.height }) {
                            self.photoOutput.maxPhotoDimensions = maxDim
                        }
                    } else {
                        self.photoOutput.isHighResolutionCaptureEnabled = true
                    }
                    if self.photoOutput.isAppleProRAWSupported {
                        self.photoOutput.isAppleProRAWEnabled = true
                    }
                }
                
                // Movie File Output
                if self.session.canAddOutput(self.movieFileOutput) {
                    self.session.addOutput(self.movieFileOutput)
                }
                
                // Video Data Output for Live Histogram & Peaking
                if self.session.canAddOutput(self.videoDataOutput) {
                    self.session.addOutput(self.videoDataOutput)
                    self.videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
                    let sampleQueue = DispatchQueue(label: "com.sondeptrai.procam.videoDataQueue")
                    self.videoDataOutput.setSampleBufferDelegate(self, queue: sampleQueue)
                }
                
                self.session.commitConfiguration()
                self.session.startRunning()
                
                DispatchQueue.main.async {
                    self.uiState.isInitialized = true
                    self.uiState.maxZoomRatio = min(backCamera.activeFormat.videoMaxZoomFactor, 10.0)
                    self.readHardwareProperties()
                }
            } catch {
                print("Failed to initialize camera session: \(error)")
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.uiState.isInitialized = true
                }
            }
        }
    }
    
    private func readHardwareProperties() {
        guard let device = currentDevice else { return }
        uiState.currentIso = Int(device.iso)
        uiState.currentExposureDurationSeconds = device.exposureDuration.seconds
        uiState.currentEv = device.exposureTargetBias
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate (Live Histogram)
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard uiState.isHistogramEnabled,
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let calculated = LiveHistogramCalculator.calculateFromPixelBuffer(imageBuffer)
        DispatchQueue.main.async {
            self.histogramData = calculated
        }
    }
    
    // MARK: - Manual Controls (ISO, Shutter, Focus, WB, EV, Zoom)
    public func setEv(_ ev: Float) {
        uiState.currentEv = ev
        uiState.isAutoIso = true
        uiState.isAutoShutter = true
        
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.currentDevice else { return }
            do {
                try device.lockForConfiguration()
                let clampedBias = min(max(ev, device.minExposureTargetBias), device.maxExposureTargetBias)
                device.setExposureTargetBias(clampedBias, completionHandler: nil)
                device.unlockForConfiguration()
            } catch {
                print("Error setting EV: \(error)")
            }
        }
    }
    
    public func setIso(_ iso: Int, isAuto: Bool) {
        uiState.isAutoIso = isAuto
        if !isAuto { uiState.currentIso = iso }
        
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.currentDevice else { return }
            do {
                try device.lockForConfiguration()
                if isAuto {
                    if device.isExposureModeSupported(.continuousAutoExposure) {
                        device.exposureMode = .continuousAutoExposure
                    }
                } else if device.isExposureModeSupported(.custom) {
                    let clampedIso = min(max(Float(iso), device.activeFormat.minISO), device.activeFormat.maxISO)
                    device.setExposureModeCustom(duration: AVCaptureDevice.currentExposureDuration, iso: clampedIso, completionHandler: nil)
                }
                device.unlockForConfiguration()
            } catch {
                print("Error setting ISO: \(error)")
            }
        }
    }
    
    public func setShutterDuration(_ seconds: Double, isAuto: Bool) {
        uiState.isAutoShutter = isAuto
        uiState.currentExposureDurationSeconds = seconds
        
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.currentDevice else { return }
            do {
                try device.lockForConfiguration()
                if isAuto {
                    if device.isExposureModeSupported(.continuousAutoExposure) {
                        device.exposureMode = .continuousAutoExposure
                    }
                } else if device.isExposureModeSupported(.custom) {
                    let minSec = CMTimeGetSeconds(device.activeFormat.minExposureDuration)
                    let maxSec = CMTimeGetSeconds(device.activeFormat.maxExposureDuration)
                    let clampedSeconds = min(max(seconds, minSec), maxSec)
                    let durationTime = CMTime(seconds: clampedSeconds, preferredTimescale: 1000000)
                    device.setExposureModeCustom(duration: durationTime, iso: AVCaptureDevice.currentISO, completionHandler: nil)
                }
                device.unlockForConfiguration()
            } catch {
                print("Error setting Shutter speed: \(error)")
            }
        }
    }
    
    public func setFocusPosition(_ position: Float, isAuto: Bool) {
        uiState.isAutoFocus = isAuto
        uiState.currentLensPosition = position
        
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.currentDevice else { return }
            do {
                try device.lockForConfiguration()
                if isAuto {
                    if device.isFocusModeSupported(.continuousAutoFocus) {
                        device.focusMode = .continuousAutoFocus
                    }
                } else {
                    if device.isLockingFocusWithCustomLensPositionSupported && device.isFocusModeSupported(.locked) {
                        let clampedPos = min(max(position, 0.0), 1.0)
                        device.setFocusModeLocked(lensPosition: clampedPos, completionHandler: nil)
                    }
                }
                device.unlockForConfiguration()
            } catch {
                print("Error setting Focus: \(error)")
            }
        }
    }
    
    public func setKelvin(_ kelvin: Int, isAuto: Bool) {
        uiState.isAutoWb = isAuto
        uiState.currentKelvin = kelvin
        
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.currentDevice else { return }
            do {
                try device.lockForConfiguration()
                if isAuto {
                    if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                        device.whiteBalanceMode = .continuousAutoWhiteBalance
                    }
                } else if device.isWhiteBalanceModeSupported(.locked) {
                    let tempAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(
                        temperature: Float(kelvin),
                        tint: 0.0
                    )
                    var gains = device.deviceWhiteBalanceGains(for: tempAndTint)
                    let maxGain = device.maxWhiteBalanceGain
                    gains.redGain = min(max(gains.redGain, 1.0), maxGain)
                    gains.greenGain = min(max(gains.greenGain, 1.0), maxGain)
                    gains.blueGain = min(max(gains.blueGain, 1.0), maxGain)
                    
                    device.setWhiteBalanceModeLocked(with: gains, completionHandler: nil)
                }
                device.unlockForConfiguration()
            } catch {
                print("Error setting White Balance: \(error)")
            }
        }
    }
    
    public func setZoomRatio(_ ratio: CGFloat) {
        let clamped = min(max(ratio, 1.0), self.uiState.maxZoomRatio)
        self.uiState.currentZoomRatio = clamped
        
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.currentDevice else { return }
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = clamped
                device.unlockForConfiguration()
            } catch {
                print("Error setting zoom: \(error)")
            }
        }
    }
    
    public func setZoomFactor(_ factor: CGFloat) {
        setZoomRatio(factor)
    }
    
    // MARK: - Tap to Focus (Point of Interest)
    public func tapToFocus(at devicePoint: CGPoint, screenPoint: CGPoint = .zero) {
        if screenPoint != .zero {
            DispatchQueue.main.async {
                self.focusReticlePoint = screenPoint
            }
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.currentDevice else { return }
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = .autoFocus
                }
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = .continuousAutoExposure
                }
                device.unlockForConfiguration()
                
                DispatchQueue.main.async {
                    self.uiState.isAutoFocus = true
                }
            } catch {
                print("Error setting tap-to-focus: \(error)")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            if self?.focusReticlePoint == screenPoint {
                self?.focusReticlePoint = nil
            }
        }
    }
    
    // MARK: - Switch Camera
    public func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            
            if let currentInput = self.videoDeviceInput {
                self.session.removeInput(currentInput)
            }
            
            let newPosition: AVCaptureDevice.Position = self.uiState.isFrontCamera ? .back : .front
            let deviceType: AVCaptureDevice.DeviceType = newPosition == .front ? .builtInTrueDepthCamera : .builtInWideAngleCamera
            let newDevice = AVCaptureDevice.default(deviceType, for: .video, position: newPosition)
                ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition)
            
            if let device = newDevice, let newInput = try? AVCaptureDeviceInput(device: device), self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.videoDeviceInput = newInput
                self.currentDevice = device
            }
            
            self.session.commitConfiguration()
            
            DispatchQueue.main.async {
                self.uiState.isFrontCamera.toggle()
                self.readHardwareProperties()
            }
        }
    }
    
    // MARK: - Shutter Actions (Photo / Video / Anti-Shake / Slow Shutter / Burst)
    public func onShutterPressed() {
        if uiState.selectedMode == .video {
            toggleVideoRecording()
            return
        }
        
        // Timer handling
        if uiState.timerSeconds > 0 {
            let seconds = uiState.timerSeconds
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(seconds)) { [weak self] in
                self?.executeCapture()
            }
        } else {
            executeCapture()
        }
    }
    
    private func executeCapture() {
        // Anti-Shake check
        if uiState.selectedMode == .antiShake {
            if !uiState.isSteadyForCapture {
                // Wait until steady or capture after 1.5s timeout
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.executeCapture()
                }
                return
            }
        }
        
        // Play shutter audio
        AudioServicesPlaySystemSound(1108)
        
        // Visual shutter flash feedback
        DispatchQueue.main.async {
            self.uiState.isShutterFlashing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.uiState.isShutterFlashing = false
        }
        
        // Fallback for Simulator or when camera is not running
        if currentDevice == nil || !session.isRunning {
            let simImage = generateSimulatedPhoto()
            DispatchQueue.main.async {
                self.uiState.lastCapturedImage = simImage
            }
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            var photoSettings: AVCapturePhotoSettings
            
            let defaultCodec: AVVideoCodecType = self.photoOutput.availablePhotoCodecTypes.contains(.hevc) ? .hevc : .jpeg
            
            if self.uiState.isRawEnabled,
               let rawFormat = self.photoOutput.availableRawPhotoPixelFormatTypes.first(where: { AVCapturePhotoOutput.isAppleProRAWPixelFormat($0) || AVCapturePhotoOutput.isBayerRAWPixelFormat($0) }) {
                photoSettings = AVCapturePhotoSettings(rawPixelFormatType: rawFormat, processedFormat: [AVVideoCodecKey: defaultCodec])
            } else {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: defaultCodec])
            }
            
            if !self.uiState.isRawEnabled && self.photoOutput.isStillImageStabilizationSupported {
                photoSettings.isAutoStillImageStabilizationEnabled = true
            }
            
            let targetFlash: AVCaptureDevice.FlashMode = {
                switch self.uiState.flashMode {
                case .on: return .on
                case .auto: return .auto
                case .off, .torch: return .off
                }
            }()
            if self.photoOutput.supportedFlashModes.contains(targetFlash) {
                photoSettings.flashMode = targetFlash
            }
            
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            print("Failed to process photo: \(String(describing: error))")
            return
        }
        
        DispatchQueue.main.async {
            self.uiState.lastCapturedImage = image
        }
        
        // Handle Slow Shutter computational stacking if mode is SLOW SHUTTER
        if uiState.selectedMode == .slowShutter {
            _ = frameStackingEngine.processFrame(newFrame: image, mode: uiState.slowShutterMode)
        }
        
        // Save to Photos library
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: data, options: nil)
                } completionHandler: { success, _ in
                    if success {
                        print("Photo successfully saved to Photos library!")
                    }
                }
            }
        }
    }
    
    // MARK: - Video Recording
    private func toggleVideoRecording() {
        if uiState.isRecordingVideo {
            stopVideoRecording()
        } else {
            startVideoRecording()
        }
    }
    
    private func startVideoRecording() {
        if currentDevice == nil || !session.isRunning {
            DispatchQueue.main.async {
                self.uiState.isRecordingVideo = true
                self.uiState.videoRecordingSeconds = 0
                self.recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    self?.uiState.videoRecordingSeconds += 1
                }
            }
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self, !self.movieFileOutput.isRecording else { return }
            
            let tempDir = FileManager.default.temporaryDirectory
            let outputUrl = tempDir.appendingPathComponent("procam_\(UUID().uuidString).mov")
            
            self.movieFileOutput.startRecording(to: outputUrl, recordingDelegate: self)
            
            DispatchQueue.main.async {
                self.uiState.isRecordingVideo = true
                self.uiState.videoRecordingSeconds = 0
                self.audioMeterManager.startMonitoring()
                
                self.recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    self?.uiState.videoRecordingSeconds += 1
                }
            }
        }
    }
    
    private func stopVideoRecording() {
        if currentDevice == nil || !session.isRunning {
            DispatchQueue.main.async {
                self.uiState.isRecordingVideo = false
                self.recordingTimer?.invalidate()
                self.recordingTimer = nil
            }
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self, self.movieFileOutput.isRecording else { return }
            self.movieFileOutput.stopRecording()
            
            DispatchQueue.main.async {
                self.uiState.isRecordingVideo = false
                self.recordingTimer?.invalidate()
                self.recordingTimer = nil
                self.audioMeterManager.stopMonitoring()
            }
        }
    }
    
    private func generateSimulatedPhoto() -> UIImage {
        let size = CGSize(width: 1920, height: 1080)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let colors = [UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0).cgColor,
                          UIColor(red: 0.15, green: 0.18, blue: 0.25, alpha: 1.0).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!
            ctx.cgContext.drawLinearGradient(gradient, start: CGPoint.zero, end: CGPoint(x: size.width, y: size.height), options: [])
            
            let text = "PROCAM RAW CAPTURE"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 36, weight: .bold),
                .foregroundColor: UIColor(red: 1.0, green: 0.72, blue: 0.0, alpha: 0.85)
            ]
            let textSize = text.size(withAttributes: attrs)
            text.draw(at: CGPoint(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2), withAttributes: attrs)
        }
    }
    
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        guard error == nil else {
            print("Video recording error: \(String(describing: error))")
            return
        }
        
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
        } completionHandler: { success, _ in
            if success {
                print("Video successfully saved to Photos library!")
            }
        }
    }
    
    // MARK: - Top Bar & UI Toggles
    public func toggleFlash() {
        let nextIndex = (uiState.flashMode.rawValue + 1) % FlashMode.allCases.count
        uiState.flashMode = FlashMode(rawValue: nextIndex) ?? .off
    }
    
    public func toggleRaw() {
        uiState.isRawEnabled.toggle()
    }
    
    public func toggleTiff() {
        uiState.isTiffEnabled.toggle()
    }
    
    public func toggleSbrt() {
        uiState.isSbrtEnabled.toggle()
    }
    
    public func toggleAeb() {
        uiState.isAebEnabled.toggle()
    }
    
    public func toggleSetMenu() {
        uiState.isSetMenuOpen.toggle()
    }
    
    public func toggleModeDrawer() {
        uiState.isModeDrawerExpanded.toggle()
    }
    
    public func cycleTimer() {
        switch uiState.timerSeconds {
        case 0: uiState.timerSeconds = 3
        case 3: uiState.timerSeconds = 10
        default: uiState.timerSeconds = 0
        }
    }
    
    public func toggleAeAfLock() {
        uiState.isAeAfLocked.toggle()
    }
    
    public func toggleWbLock() {
        uiState.isWbLocked.toggle()
    }
    
    public func toggleFocusPeaking() {
        uiState.isFocusPeakingEnabled.toggle()
    }
    
    public func toggleZebra() {
        uiState.isZebraEnabled.toggle()
    }
    
    public func cycleGridType() {
        switch uiState.gridType {
        case .none: uiState.gridType = .ruleOfThirds
        case .ruleOfThirds: uiState.gridType = .goldenRatio
        case .goldenRatio: uiState.gridType = .crosshair
        case .crosshair: uiState.gridType = .none
        }
    }
    
    public func cycleAspectRatio() {
        switch uiState.aspectRatio {
        case .ratio16_9: uiState.aspectRatio = .ratio4_3
        case .ratio4_3: uiState.aspectRatio = .ratio1_1
        case .ratio1_1: uiState.aspectRatio = .ratio16_9
        }
    }
    
    public func toggleTiltMeter() {
        uiState.isTiltMeterEnabled.toggle()
    }
    
    public func toggleHistogram() {
        uiState.isHistogramEnabled.toggle()
    }
    
    public func setActiveParam(_ param: ManualParameter) {
        if uiState.activeManualParam == param {
            uiState.activeManualParam = .none
        } else {
            uiState.activeManualParam = param
        }
    }
    
    public func setShootingMode(_ mode: ShootingMode) {
        uiState.selectedMode = mode
        if mode == .video {
            audioMeterManager.startMonitoring()
        } else {
            audioMeterManager.stopMonitoring()
        }
    }
}
