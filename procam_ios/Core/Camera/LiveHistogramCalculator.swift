import Foundation
import CoreVideo

public struct HistogramData {
    public var lumaBins: [Float] = [Float](repeating: 0.0, count: 256)
    public var maxBinCount: Float = 1.0
    
    public init(lumaBins: [Float] = [Float](repeating: 0.0, count: 256), maxBinCount: Float = 1.0) {
        self.lumaBins = lumaBins
        self.maxBinCount = maxBinCount
    }
}

public class LiveHistogramCalculator {
    public static func calculateFromPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> HistogramData {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else {
            return HistogramData()
        }
        
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        
        var rawBins = [Int](repeating: 0, count: 256)
        let sampleStep = 8 // Sample 1 in 64 pixels for real-time 60fps performance
        var maxCount = 0
        
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        for row in stride(from: 0, to: height, by: sampleStep) {
            let rowOffset = row * bytesPerRow
            for col in stride(from: 0, to: width, by: sampleStep) {
                let y = Int(buffer[rowOffset + col])
                rawBins[y] += 1
                if rawBins[y] > maxCount {
                    maxCount = rawBins[y]
                }
            }
        }
        
        var normalizedBins = [Float](repeating: 0.0, count: 256)
        let safeMax = max(Float(maxCount), 1.0)
        for i in 0..<256 {
            normalizedBins[i] = Float(rawBins[i]) / safeMax
        }
        
        return HistogramData(lumaBins: normalizedBins, maxBinCount: safeMax)
    }
    
    /// Generates stylized realistic sample data if pixel buffer is in simulator
    public static func simulatedHistogram() -> HistogramData {
        var bins = [Float](repeating: 0.0, count: 256)
        for i in 0..<256 {
            let x = Float(i)
            // Gaussian bell curve centered around midtones (128)
            let val = exp(-pow(x - 128.0, 2) / (2 * pow(45.0, 2))) * 0.85 + Float.random(in: 0.01...0.06)
            bins[i] = min(val, 1.0)
        }
        return HistogramData(lumaBins: bins, maxBinCount: 1.0)
    }
}
