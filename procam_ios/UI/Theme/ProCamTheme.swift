import SwiftUI

// MARK: - DSLR ProCam Color Palette (Direct replica of Android ProCam Theme)
public struct ProCamColors {
    public static let dslrBlack = Color(red: 10/255, green: 10/255, blue: 12/255)         // #0A0A0C
    public static let dslrDarkGrey = Color(red: 20/255, green: 20/255, blue: 24/255)      // #141418
    public static let dslrSurface = Color(red: 32/255, green: 32/255, blue: 38/255)       // #202026
    public static let dslrBorder = Color(red: 46/255, green: 46/255, blue: 54/255)        // #2E2E36
    
    // Brand Highlights
    public static let amber = Color(red: 255/255, green: 179/255, blue: 0/255)            // #FFB300
    public static let amberDim = Color(red: 255/255, green: 179/255, blue: 0/255).opacity(0.4)
    public static let halideGold = Color(red: 255/255, green: 184/255, blue: 0/255)       // #FFB800
    public static let red = Color(red: 255/255, green: 59/255, blue: 48/255)              // #FF3B30
    public static let green = Color(red: 52/255, green: 199/255, blue: 89/255)            // #34C759
    
    // Focus Peaking Colors
    public static let peakingGreen = Color(red: 0/255, green: 230/255, blue: 118/255)      // #00E676
    public static let peakingRed = Color(red: 255/255, green: 23/255, blue: 68/255)        // #FF1744
    public static let peakingCyan = Color(red: 0/255, green: 229/255, blue: 255/255)       // #00E5FF
    
    // Typography Colors
    public static let textPrimary = Color.white
    public static let textSecondary = Color(red: 158/255, green: 158/255, blue: 167/255)  // #9E9EA7
    public static let textMuted = Color(red: 90/255, green: 90/255, blue: 98/255)         // #5A5A62
}
