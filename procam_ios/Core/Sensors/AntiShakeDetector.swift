import Foundation
import CoreMotion
import Combine

public class AntiShakeDetector: ObservableObject {
    private let motionManager = CMMotionManager()
    
    @Published public var isSteady: Bool = true
    
    private var steadyFramesCount: Int = 0
    private let requiredSteadyFrames: Int = 15 // ~300ms at 50Hz
    
    private let accelThreshold: Double = 0.25 // m/s^2 or g equivalent
    private let gyroThreshold: Double = 0.15  // rad/s
    
    private var currentAccelEnergy: Double = 0.0
    private var currentGyroEnergy: Double = 0.0
    
    public init() {
        start()
    }
    
    deinit {
        stop()
    }
    
    public func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0 // 50 Hz
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            
            // Linear acceleration (user acceleration without gravity)
            let ax = motion.userAcceleration.x * 9.81
            let ay = motion.userAcceleration.y * 9.81
            let az = motion.userAcceleration.z * 9.81
            self.currentAccelEnergy = sqrt(ax * ax + ay * ay + az * az)
            
            // Gyroscope rotation rate
            let rx = motion.rotationRate.x
            let ry = motion.rotationRate.y
            let rz = motion.rotationRate.z
            self.currentGyroEnergy = sqrt(rx * rx + ry * ry + rz * rz)
            
            let isNowCalm = (self.currentAccelEnergy < self.accelThreshold) && (self.currentGyroEnergy < self.gyroThreshold)
            if isNowCalm {
                self.steadyFramesCount += 1
                if self.steadyFramesCount >= self.requiredSteadyFrames {
                    self.isSteady = true
                }
            } else {
                self.steadyFramesCount = 0
                self.isSteady = false
            }
        }
    }
    
    public func stop() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }
}
