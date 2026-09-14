import SwiftUI

/// Styling and color constants for the MP3 Converter & Audio Editor
public struct AudioEditorTheme {
    // Primary vibrant coral red from the screenshot
    public static let accentRed = Color(red: 255/255, green: 75/255, blue: 75/255)
    public static let playheadRed = Color(red: 255/255, green: 59/255, blue: 48/255)
    
    // Waveform colors
    public static let playedWaveform = Color(red: 255/255, green: 110/255, blue: 110/255)
    public static let unplayedWaveform = Color(red: 229/255, green: 229/255, blue: 234/255)
    
    // Backgrounds
    public static let pillBackground = Color(UIColor.secondarySystemBackground)
    public static let pillSelectedDark = Color(red: 28/255, green: 28/255, blue: 30/255)
    
    // Card & surfaces
    public static let surfaceCard = Color(UIColor.secondarySystemBackground)
    public static let borderSubtle = Color(UIColor.separator)
}
