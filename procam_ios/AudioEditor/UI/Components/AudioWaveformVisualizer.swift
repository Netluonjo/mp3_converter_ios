import SwiftUI

/// Pixel-perfect interactive waveform visualizer matching the user's screenshot
/// Features:
/// - Fixed center vertical red playhead with top and bottom red circular pins
/// - Symmetrical amplitude bars with rounded caps
/// - Coral-red bars for elapsed audio, light gray for upcoming audio
/// - Horizontal drag gesture for interactive scrubbing with haptic feedback
public struct AudioWaveformVisualizer: View {
    public let samples: [Float]
    public let progress: Double // 0.0 ... 1.0
    public let onSeek: (Double) -> Void
    
    @State private var dragOffset: CGFloat = 0.0
    @State private var isDragging: Bool = false
    
    // Bar configuration
    private let barWidth: CGFloat = 3.5
    private let barSpacing: CGFloat = 3.0
    private let maxBarHeight: CGFloat = 160.0
    private let minBarHeight: CGFloat = 6.0
    
    public init(
        samples: [Float],
        progress: Double,
        onSeek: @escaping (Double) -> Void
    ) {
        self.samples = samples.isEmpty ? AudioTrack.placeholderSamples(count: 65) : samples
        self.progress = progress
        self.onSeek = onSeek
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let totalHeight = geometry.size.height
            let centerX = totalWidth / 2.0
            
            // Total content width based on sample count
            let step = barWidth + barSpacing
            let waveformContentWidth = CGFloat(samples.count) * step
            
            // Calculate horizontal offset so the current playhead progress is centered at centerX
            let currentX = CGFloat(progress) * waveformContentWidth
            let scrollOffset = centerX - currentX + dragOffset
            
            ZStack {
                // Waveform bars
                HStack(alignment: .center, spacing: barSpacing) {
                    ForEach(0..<samples.count, id: \.self) { index in
                        let sampleProgress = Double(index) / Double(max(1, samples.count - 1))
                        let isPlayed = sampleProgress <= (isDragging ? effectiveProgress(totalContentWidth: waveformContentWidth, centerX: centerX) : progress)
                        
                        let rawAmp = CGFloat(samples[index])
                        let barHeight = max(minBarHeight, rawAmp * maxBarHeight)
                        
                        RoundedRectangle(cornerRadius: barWidth / 2)
                            .fill(isPlayed ? AudioEditorTheme.playedWaveform : AudioEditorTheme.unplayedWaveform)
                            .frame(width: barWidth, height: barHeight)
                    }
                }
                .frame(width: waveformContentWidth, height: totalHeight)
                .offset(x: scrollOffset - (waveformContentWidth / 2.0) + (totalWidth / 2.0))
                
                // Center vertical red playhead with top and bottom pin dots
                VStack(spacing: 0) {
                    // Top pin dot
                    Circle()
                        .fill(AudioEditorTheme.playheadRed)
                        .frame(width: 8, height: 8)
                    
                    // Vertical needle line
                    Rectangle()
                        .fill(AudioEditorTheme.playheadRed)
                        .frame(width: 2)
                    
                    // Bottom pin dot
                    Circle()
                        .fill(AudioEditorTheme.playheadRed)
                        .frame(width: 8, height: 8)
                }
                .frame(height: maxBarHeight + 36)
                .position(x: centerX, y: totalHeight / 2.0)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let finalProgress = effectiveProgress(totalContentWidth: waveformContentWidth, centerX: centerX)
                        dragOffset = 0.0
                        isDragging = false
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onSeek(finalProgress)
                    }
            )
        }
        .frame(height: 200)
    }
    
    private func effectiveProgress(totalContentWidth: CGFloat, centerX: CGFloat) -> Double {
        guard totalContentWidth > 0 else { return 0.0 }
        let currentX = CGFloat(progress) * totalContentWidth
        let newX = currentX - dragOffset
        let clamped = max(0.0, min(totalContentWidth, newX))
        return Double(clamped / totalContentWidth)
    }
}
