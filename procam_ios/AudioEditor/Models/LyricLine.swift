import Foundation

/// Represents a single synchronized line of lyric with start and end timestamps.
public struct LyricLine: Identifiable, Codable, Hashable {
    public let id: UUID
    public var startTime: TimeInterval
    public var endTime: TimeInterval
    public var text: String
    
    public init(
        id: UUID = UUID(),
        startTime: TimeInterval,
        endTime: TimeInterval,
        text: String
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
    }
    
    /// Formatted timestamp string e.g. "00:04"
    public var formattedStartTime: String {
        let total = Int(max(0, startTime))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

/// Robust parser and exporter for LRC and plain text lyric files.
public struct LyricParser {
    
    /// Standard demo LRC text matching the 21-second demo audio
    public static let demoLRC = """
    [00:00.00]Xin chào! Chào mừng đến với Audio Editor.
    [00:04.20]Đây là bản ghi âm thử nghiệm chất lượng cao 44.1kHz.
    [00:08.50]Bạn có thể cắt ghép nhạc và tỉa âm thanh trực quan.
    [00:12.80]Trích xuất âm thanh từ video và đổi định dạng dễ dàng.
    [00:17.00]Tăng âm lượng, chỉnh hiệu ứng và xuất file tức thì!
    """
    
    /// Parses LRC content or fallback plain text into structured `[LyricLine]`
    public static func parse(text: String, duration: TimeInterval) -> [LyricLine] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        let lines = trimmed.components(separatedBy: .newlines)
        var parsedLrcEntries: [(time: TimeInterval, text: String)] = []
        
        // Regex to match tags like [00:04.20] or [01:15:30] or [00:05]
        let pattern = "\\[(\\d{1,2}):(\\d{2})(?:[.:](\\d{1,3}))?\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return parsePlainText(lines: lines, duration: duration)
        }
        
        for line in lines {
            let lineRange = NSRange(location: 0, length: (line as NSString).length)
            let matches = regex.matches(in: line, options: [], range: lineRange)
            
            if !matches.isEmpty {
                // Remove all timestamp tags to get raw lyric text
                var cleanText = line
                for match in matches.reversed() {
                    if let range = Range(match.range, in: cleanText) {
                        cleanText.removeSubrange(range)
                    }
                }
                cleanText = cleanText.trimmingCharacters(in: .whitespaces)
                
                // Extract time for each tag in this line
                for match in matches {
                    let nsLine = line as NSString
                    let minStr = nsLine.substring(with: match.range(at: 1))
                    let secStr = nsLine.substring(with: match.range(at: 2))
                    var frac: Double = 0.0
                    
                    if match.numberOfRanges > 3 && match.range(at: 3).location != NSNotFound {
                        let fracStr = nsLine.substring(with: match.range(at: 3))
                        if let val = Double("0." + fracStr) {
                            frac = val
                        }
                    }
                    
                    let minutes = Double(minStr) ?? 0.0
                    let seconds = Double(secStr) ?? 0.0
                    let time = (minutes * 60.0) + seconds + frac
                    parsedLrcEntries.append((time: time, text: cleanText))
                }
            }
        }
        
        // If LRC tags were found, sort and assign end times
        if !parsedLrcEntries.isEmpty {
            parsedLrcEntries.sort { $0.time < $1.time }
            var result: [LyricLine] = []
            
            for i in 0..<parsedLrcEntries.count {
                let current = parsedLrcEntries[i]
                let nextTime: TimeInterval
                if i + 1 < parsedLrcEntries.count {
                    nextTime = parsedLrcEntries[i + 1].time
                } else {
                    nextTime = max(current.time + 4.0, duration)
                }
                
                result.append(
                    LyricLine(
                        startTime: current.time,
                        endTime: max(current.time + 0.5, nextTime),
                        text: current.text
                    )
                )
            }
            return result
        }
        
        // Fallback: If no LRC tags were found, parse as plain text
        return parsePlainText(lines: lines, duration: duration)
    }
    
    /// Parses plain text without timestamps by distributing lines evenly across track duration
    private static func parsePlainText(lines: [String], duration: TimeInterval) -> [LyricLine] {
        let validLines = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !validLines.isEmpty else { return [] }
        
        let validDuration = max(1.0, duration)
        let step = validDuration / Double(validLines.count)
        
        return validLines.enumerated().map { index, text in
            let start = Double(index) * step
            let end = (index == validLines.count - 1) ? validDuration : Double(index + 1) * step
            return LyricLine(
                startTime: start,
                endTime: end,
                text: text
            )
        }
    }
    
    /// Exports `[LyricLine]` back into standard `.lrc` format
    public static func exportToLRC(lines: [LyricLine]) -> String {
        return lines.map { line in
            let total = Int(line.startTime)
            let mins = total / 60
            let secs = total % 60
            let hundredths = Int((line.startTime - Double(total)) * 100)
            return String(format: "[%02d:%02d.%02d]%@", mins, secs, hundredths, line.text)
        }.joined(separator: "\n")
    }
}
