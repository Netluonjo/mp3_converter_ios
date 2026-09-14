import SwiftUI

/// Dual-handle trimmer overlay allowing the user to visually set Start Time and End Time
public struct WaveformTrimmerOverlay: View {
    @Binding public var startProgress: Double // 0.0 ... 1.0
    @Binding public var endProgress: Double   // 0.0 ... 1.0
    public let duration: TimeInterval
    
    @State private var draggingStart = false
    @State private var draggingEnd = false
    
    public init(
        startProgress: Binding<Double>,
        endProgress: Binding<Double>,
        duration: TimeInterval
    ) {
        self._startProgress = startProgress
        self._endProgress = endProgress
        self.duration = duration
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let startX = CGFloat(startProgress) * width
            let endX = CGFloat(endProgress) * width
            
            ZStack(alignment: .leading) {
                // Dimmed area before Start Time
                Rectangle()
                    .fill(Color.black.opacity(0.35))
                    .frame(width: max(0, startX), height: height)
                
                // Active trimmed window with border
                Rectangle()
                    .stroke(AudioEditorTheme.accentRed, lineWidth: 2)
                    .background(AudioEditorTheme.accentRed.opacity(0.08))
                    .frame(width: max(20, endX - startX), height: height)
                    .offset(x: startX)
                
                // Dimmed area after End Time
                Rectangle()
                    .fill(Color.black.opacity(0.35))
                    .frame(width: max(0, width - endX), height: height)
                    .offset(x: endX)
                
                // Left Start Handle
                TrimHandleView(timeString: formatTime(startProgress * duration), isStart: true)
                    .position(x: startX, y: height / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { val in
                                let newProgress = max(0.0, min(Double(val.location.x / width), endProgress - 0.05))
                                startProgress = newProgress
                            }
                    )
                
                // Right End Handle
                TrimHandleView(timeString: formatTime(endProgress * duration), isStart: false)
                    .position(x: endX, y: height / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { val in
                                let newProgress = min(1.0, max(Double(val.location.x / width), startProgress + 0.05))
                                endProgress = newProgress
                            }
                    )
            }
        }
        .frame(height: 120)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let total = Int(max(0, time))
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}

private struct TrimHandleView: View {
    let timeString: String
    let isStart: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            Text(timeString)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.black.opacity(0.8)))
            
            RoundedRectangle(cornerRadius: 3)
                .fill(AudioEditorTheme.accentRed)
                .frame(width: 14, height: 70)
                .overlay(
                    Image(systemName: isStart ? "chevron.right" : "chevron.left")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.white)
                )
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
        }
    }
}
