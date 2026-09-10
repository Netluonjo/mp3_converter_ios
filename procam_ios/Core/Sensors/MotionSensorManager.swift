import Foundation
import CoreMotion
import Combine

public class MotionSensorManager: ObservableObject {
    @Published public var rollDegrees: Double = 0.0
    @Published public var pitchDegrees: Double = 0.0
    @Published public var isLevel: Bool = false
    
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    
    public init() {
        queue.qualityOfService = .userInteractive
        startDeviceMotion()
    }
    
    deinit {
        stopDeviceMotion()
    }
    
    public func startDeviceMotion() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0 // 30 Hz for smooth horizon
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else { return }
            
            // Gravity vector components
            let roll = atan2(motion.gravity.x, motion.gravity.y) * 180.0 / .pi
            let pitch = atan2(motion.gravity.z, sqrt(motion.gravity.x * motion.gravity.x + motion.gravity.y * motion.gravity.y)) * 180.0 / .pi
            
            // Normalize roll relative to portrait/landscape
            var normalizedRoll = roll + 90.0
            if normalizedRoll > 180.0 {
                normalizedRoll -= 360.0
            }
            
            let levelThreshold = 1.0 // Within 1 degree is considered level
            let level = abs(normalizedRoll) < levelThreshold
            
            DispatchQueue.main.async {
                self.rollDegrees = normalizedRoll
                self.pitchDegrees = pitch
                self.isLevel = level
            }
        }
    }
    
    public func stopDeviceMotion() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }
}
