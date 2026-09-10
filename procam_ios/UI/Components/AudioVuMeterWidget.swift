import SwiftUI

public struct AudioVuMeterWidget: View {
    public let decibelLevel: Float
    
    private let totalSegments: Int = 16
    private let greenSegments: Int = 10
    private let yellowSegments: Int = 4
    private let redSegments: Int = 2
    
    public init(decibelLevel: Float) {
        self.decibelLevel = decibelLevel
    }
    
    public var body: some View {
        let activeCountL = Int(max(0.1, min(1.0, decibelLevel)) * Float(totalSegments))
        let activeCountR = Int(max(0.1, min(1.0, decibelLevel * 0.9 + 0.05)) * Float(totalSegments))
        
        VStack(spacing: 8) {
            // Mic icon
            Image(systemName: "mic.fill")
                .font(.system(size: 11))
                .foregroundColor(.white)
            
            // Stereo vertical bars
            HStack(spacing: 4) {
                // Channel L
                barColumn(activeCount: activeCountL)
                // Channel R
                barColumn(activeCount: activeCountR)
            }
            .frame(maxHeight: .infinity)
            
            // L and R labels
            HStack(spacing: 6) {
                Text("L")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(ProCamColors.textSecondary)
                Text("R")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(ProCamColors.textSecondary)
            }
        }
        .frame(width: 36, height: 180)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.7))
        )
    }
    
    private func barColumn(activeCount: Int) -> some View {
        VStack(spacing: 2) {
            ForEach((0..<totalSegments).reversed(), id: \.self) { i in
                let isLit = i < activeCount
                let segmentColor: Color = {
                    if i >= greenSegments + yellowSegments {
                        return ProCamColors.red
                    } else if i >= greenSegments {
                        return Color(red: 1.0, green: 0.8, blue: 0.0)
                    } else {
                        return ProCamColors.green
                    }
                }()
                
                RoundedRectangle(cornerRadius: 1)
                    .fill(isLit ? segmentColor : Color(white: 0.33).opacity(0.3))
                    .frame(width: 6, height: 4)
            }
        }
    }
}
