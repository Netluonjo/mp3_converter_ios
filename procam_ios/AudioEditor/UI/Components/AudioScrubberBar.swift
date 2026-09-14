import SwiftUI

/// Scrubber bar matching the screenshot with coral-red track, round thumb, and elapsed/remaining timestamps
public struct AudioScrubberBar: View {
    public let currentTime: TimeInterval
    public let duration: TimeInterval
    public let onSeek: (TimeInterval) -> Void
    
    @State private var isDragging: Bool = false
    @State private var dragProgress: Double = 0.0
    
    public init(
        currentTime: TimeInterval,
        duration: TimeInterval,
        onSeek: @escaping (TimeInterval) -> Void
    ) {
        self.currentTime = currentTime
        self.duration = duration
        self.onSeek = onSeek
    }
    
    private var displayProgress: Double {
        if isDragging { return dragProgress }
        guard duration > 0 else { return 0.0 }
        return min(1.0, max(0.0, currentTime / duration))
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let thumbX = CGFloat(displayProgress) * width
                
                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: 3)
                    
                    // Active progress track
                    Capsule()
                        .fill(AudioEditorTheme.accentRed)
                        .frame(width: max(0, thumbX), height: 3)
                    
                    // Thumb dot
                    Circle()
                        .fill(AudioEditorTheme.accentRed)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                        .position(x: min(max(7, thumbX), width - 7), y: geometry.size.height / 2)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let progress = max(0.0, min(1.0, Double(value.location.x / width)))
                            dragProgress = progress
                        }
                        .onEnded { value in
                            let progress = max(0.0, min(1.0, Double(value.location.x / width)))
                            isDragging = false
                            onSeek(progress * duration)
                        }
                )
            }
            .frame(height: 20)
            
            // Timestamp labels
            HStack {
                Text(formatTime(isDragging ? dragProgress * duration : currentTime))
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                Spacer()
                
                Text(formatTime(duration))
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
        }
        .padding(.horizontal, 24)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let total = Int(max(0, time))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
