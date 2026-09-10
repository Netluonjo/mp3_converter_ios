import Foundation
import UIKit
import CoreGraphics

public class FrameStackingEngine {
    private var accumulatedImage: UIImage?
    private var frameCount: Int = 0
    private let lock = NSLock()
    
    public init() {}
    
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        accumulatedImage = nil
        frameCount = 0
    }
    
    public func processFrame(newFrame: UIImage, mode: SlowShutterMode) -> UIImage? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let currentAcc = accumulatedImage else {
            accumulatedImage = newFrame
            frameCount = 1
            return newFrame
        }
        
        guard let cg1 = currentAcc.cgImage, let cg2 = newFrame.cgImage else {
            return currentAcc
        }
        
        let width = cg1.width
        let height = cg1.height
        
        guard cg2.width == width && cg2.height == height else {
            return currentAcc
        }
        
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var rawData1 = [UInt8](repeating: 0, count: bytesPerRow * height)
        var rawData2 = [UInt8](repeating: 0, count: bytesPerRow * height)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        guard let ctx1 = CGContext(data: &rawData1, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo),
              let ctx2 = CGContext(data: &rawData2, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            return currentAcc
        }
        
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        ctx1.draw(cg1, in: rect)
        ctx2.draw(cg2, in: rect)
        
        switch mode {
        case .lightTrails:
            // Maximum luminance blend: keep brightest pixels for headlights, light painting, star trails
            for i in stride(from: 0, to: rawData1.count, by: 4) {
                rawData1[i] = max(rawData1[i], rawData2[i])         // R
                rawData1[i + 1] = max(rawData1[i + 1], rawData2[i + 1]) // G
                rawData1[i + 2] = max(rawData1[i + 2], rawData2[i + 2]) // B
            }
            
        case .motionBlur:
            // Running weighted average to create silky smooth waterfalls and clouds
            frameCount += 1
            let alpha = 1.0 / min(Double(frameCount), 30.0)
            let invAlpha = 1.0 - alpha
            
            for i in stride(from: 0, to: rawData1.count, by: 4) {
                let r1 = Double(rawData1[i])
                let g1 = Double(rawData1[i + 1])
                let b1 = Double(rawData1[i + 2])
                
                let r2 = Double(rawData2[i])
                let g2 = Double(rawData2[i + 1])
                let b2 = Double(rawData2[i + 2])
                
                rawData1[i] = UInt8(clamping: Int(r1 * invAlpha + r2 * alpha))
                rawData1[i + 1] = UInt8(clamping: Int(g1 * invAlpha + g2 * alpha))
                rawData1[i + 2] = UInt8(clamping: Int(b1 * invAlpha + b2 * alpha))
            }
        }
        
        if let outCgImage = ctx1.makeImage() {
            let blendedImage = UIImage(cgImage: outCgImage, scale: newFrame.scale, orientation: newFrame.imageOrientation)
            accumulatedImage = blendedImage
            return blendedImage
        }
        
        return currentAcc
    }
    
    public func getResult() -> UIImage? {
        lock.lock()
        defer { lock.unlock() }
        return accumulatedImage
    }
}
