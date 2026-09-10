import SwiftUI

public struct ProCamSettingsModalView: View {
    @ObservedObject var cameraManager: CameraManager
    public let onDismiss: () -> Void
    
    public init(cameraManager: CameraManager, onDismiss: @escaping () -> Void) {
        self.cameraManager = cameraManager
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            // Dark Backdrop
            Color.black.opacity(0.65)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onDismiss()
                }
            
            // Modal Card
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("CAMERA SETTINGS")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(1.0)
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ProCamColors.textSecondary)
                            .padding(6)
                    }
                }
                
                Divider()
                    .background(ProCamColors.dslrBorder)
                
                // 1. Focus Peaking
                toggleRow(
                    title: "Focus Peaking",
                    subtitle: "Highlight in-focus edges with colored contours",
                    isOn: Binding(
                        get: { cameraManager.uiState.isFocusPeakingEnabled },
                        set: { _ in cameraManager.toggleFocusPeaking() }
                    )
                )
                
                // 2. Zebra Stripes
                toggleRow(
                    title: "Zebra Highlight Warning",
                    subtitle: "Diagonal stripes overlay on overexposed areas",
                    isOn: Binding(
                        get: { cameraManager.uiState.isZebraEnabled },
                        set: { _ in cameraManager.toggleZebra() }
                    )
                )
                
                // 3. Viewfinder Grid
                actionRow(
                    title: "Viewfinder Grid",
                    value: cameraManager.uiState.gridType.title
                ) {
                    cameraManager.cycleGridType()
                }
                
                // 4. Tiltmeter / Horizon
                toggleRow(
                    title: "Tiltmeter / Horizon Level",
                    subtitle: "Sensor-guided artificial horizon indicator",
                    isOn: Binding(
                        get: { cameraManager.uiState.isTiltMeterEnabled },
                        set: { _ in cameraManager.toggleTiltMeter() }
                    )
                )
                
                // 5. Live Histogram
                toggleRow(
                    title: "Live Luminance Histogram",
                    subtitle: "Real-time exposure distribution graph",
                    isOn: Binding(
                        get: { cameraManager.uiState.isHistogramEnabled },
                        set: { _ in cameraManager.toggleHistogram() }
                    )
                )
                
                // 6. Aspect Ratio
                actionRow(
                    title: "Aspect Ratio",
                    value: cameraManager.uiState.aspectRatio.label
                ) {
                    cameraManager.cycleAspectRatio()
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ProCamColors.dslrDarkGrey)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(ProCamColors.dslrBorder, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }
    
    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(ProCamColors.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: ProCamColors.amber))
        }
    }
    
    private func actionRow(title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            let feedback = UIImpactFeedbackGenerator(style: .light)
            feedback.impactOccurred()
            action()
        }) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(ProCamColors.amber)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(ProCamColors.dslrSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(ProCamColors.dslrBorder, lineWidth: 1)
                            )
                    )
            }
        }
    }
}
