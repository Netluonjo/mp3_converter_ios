import SwiftUI

public struct ZoomControlWidget: View {
    public let currentZoom: CGFloat
    public let maxZoom: CGFloat
    public let isFrontCamera: Bool
    public let onZoomSelected: (CGFloat) -> Void
    
    private let presets: [CGFloat] = [1.0, 2.0, 3.0, 5.0]
    
    public init(
        currentZoom: CGFloat,
        maxZoom: CGFloat,
        isFrontCamera: Bool,
        onZoomSelected: @escaping (CGFloat) -> Void
    ) {
        self.currentZoom = currentZoom
        self.maxZoom = maxZoom
        self.isFrontCamera = isFrontCamera
        self.onZoomSelected = onZoomSelected
    }
    
    public var body: some View {
        if isFrontCamera {
            EmptyView()
        } else {
            HStack(spacing: 4) {
                ForEach(presets.filter { $0 <= maxZoom }, id: \.self) { preset in
                    let isSelected = abs(currentZoom - preset) < 0.15
                    let displayLabel = "\(Int(preset))x"
                    
                    Button(action: {
                        let feedback = UIImpactFeedbackGenerator(style: .light)
                        feedback.impactOccurred()
                        onZoomSelected(preset)
                    }) {
                        Text(displayLabel)
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .monospaced))
                            .foregroundColor(isSelected ? .black : Color(white: 0.8))
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(isSelected ? Color.white : Color.clear)
                            )
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                    )
            )
        }
    }
}
