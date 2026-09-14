import SwiftUI

/// Main playback control buttons matching Image 1:
/// - x1 speed multiplier
/// - 10-second rewind
/// - Red circular Play/Pause button
/// - 10-second forward
/// - Loop/repeat toggle
public struct AudioControlButtonsView: View {
    public let isPlaying: Bool
    public let playbackRate: Float
    public let isLooping: Bool
    
    public let onTogglePlayPause: () -> Void
    public let onSkipBackward: () -> Void
    public let onSkipForward: () -> Void
    public let onCycleSpeed: () -> Void
    public let onToggleLoop: () -> Void
    
    public init(
        isPlaying: Bool,
        playbackRate: Float,
        isLooping: Bool,
        onTogglePlayPause: @escaping () -> Void,
        onSkipBackward: @escaping () -> Void,
        onSkipForward: @escaping () -> Void,
        onCycleSpeed: @escaping () -> Void,
        onToggleLoop: @escaping () -> Void
    ) {
        self.isPlaying = isPlaying
        self.playbackRate = playbackRate
        self.isLooping = isLooping
        self.onTogglePlayPause = onTogglePlayPause
        self.onSkipBackward = onSkipBackward
        self.onSkipForward = onSkipForward
        self.onCycleSpeed = onCycleSpeed
        self.onToggleLoop = onToggleLoop
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Speed button: x1
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onCycleSpeed()
            }) {
                Text(formattedSpeed(playbackRate))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(UIColor.label))
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // 10s Rewind button
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onSkipBackward()
            }) {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(Color(UIColor.label))
                    .frame(width: 48, height: 48)
            }
            
            Spacer()
            
            // Primary Red Play/Pause Button
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onTogglePlayPause()
            }) {
                ZStack {
                    Circle()
                        .fill(AudioEditorTheme.accentRed)
                        .frame(width: 68, height: 68)
                        .shadow(color: AudioEditorTheme.accentRed.opacity(0.35), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: isPlaying ? 0 : 2)
                }
            }
            
            Spacer()
            
            // 10s Forward button
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onSkipForward()
            }) {
                Image(systemName: "goforward.10")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(Color(UIColor.label))
                    .frame(width: 48, height: 48)
            }
            
            Spacer()
            
            // Loop / repeat button
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onToggleLoop()
            }) {
                Image(systemName: "repeat")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(isLooping ? AudioEditorTheme.accentRed : Color(UIColor.label))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 28)
    }
    
    private func formattedSpeed(_ rate: Float) -> String {
        if rate == Float(Int(rate)) {
            return "x\(Int(rate))"
        } else {
            return "x\(String(format: "%.1f", rate))"
        }
    }
}
