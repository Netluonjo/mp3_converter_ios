import Foundation
import Speech
import AVFoundation

/// Service for converting spoken audio files to timestamped LRC lyrics using native Apple Speech
@MainActor
public final class SpeechRecognitionService: ObservableObject {
    public static let shared = SpeechRecognitionService()
    
    @Published public var isTranscribing: Bool = false
    @Published public var progressText: String = ""
    @Published public var errorMessage: String? = nil
    
    private var speechRecognizer: SFSpeechRecognizer?
    
    private init() {
        // Default to Vietnamese if available, fallback to current device locale
        let viLocale = Locale(identifier: "vi-VN")
        if SFSpeechRecognizer.supportedLocales().contains(viLocale) {
            speechRecognizer = SFSpeechRecognizer(locale: viLocale)
        } else {
            speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        }
    }
    
    /// Requests speech recognition permission
    public func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    /// Transcribes an audio file into synchronized LRC formatted text
    public func transcribeAudio(url: URL, duration: TimeInterval) async throws -> String {
        self.isTranscribing = true
        self.errorMessage = nil
        self.progressText = "Đang xin quyền nhận diện giọng nói..."
        
        let authorized = await requestAuthorization()
        guard authorized else {
            self.isTranscribing = false
            throw NSError(
                domain: "SpeechRecognitionService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Chưa được cấp quyền nhận diện giọng nói trong Cài đặt."]
            )
        }
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            self.isTranscribing = false
            throw NSError(
                domain: "SpeechRecognitionService",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Bộ nhận diện giọng nói hiện không khả dụng."]
            )
        }
        
        self.progressText = "Đang phân tích âm thanh bằng AI..."
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            request.addsPunctuation = true
            
            recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    if let error = error {
                        self?.isTranscribing = false
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let result = result, result.isFinal else { return }
                    
                    self?.progressText = "Đang chia mốc thời gian (LRC)..."
                    let lrcString = self?.formatTranscriptionToLRC(result.bestTranscription, audioDuration: duration) ?? ""
                    
                    self?.isTranscribing = false
                    continuation.resume(returning: lrcString)
                }
            }
        }
    }
    
    /// Groups word segments into readable sentences and generates timestamped LRC lines
    private func formatTranscriptionToLRC(_ transcription: SFTranscription, audioDuration: TimeInterval) -> String {
        let segments = transcription.segments
        guard !segments.isEmpty else {
            return transcription.formattedString
        }
        
        var lines: [String] = []
        var currentLineWords: [String] = []
        var lineStartTime: TimeInterval = segments[0].timestamp
        
        for (index, segment) in segments.enumerated() {
            currentLineWords.append(segment.substring)
            
            // Break into new line if pause between words is > 1.2s or word count reaches 8
            let isLast = (index == segments.count - 1)
            var shouldBreak = false
            
            if !isLast {
                let nextSegment = segments[index + 1]
                let pauseDuration = nextSegment.timestamp - (segment.timestamp + segment.duration)
                if pauseDuration > 1.2 || currentLineWords.count >= 8 {
                    shouldBreak = true
                }
            } else {
                shouldBreak = true
            }
            
            if shouldBreak {
                let text = currentLineWords.joined(separator: " ")
                let mins = Int(lineStartTime) / 60
                let secs = Int(lineStartTime) % 60
                let hundredths = Int((lineStartTime - Double(Int(lineStartTime))) * 100)
                let lrcLine = String(format: "[%02d:%02d.%02d]%@", mins, secs, hundredths, text)
                lines.append(lrcLine)
                
                currentLineWords.removeAll()
                if !isLast {
                    lineStartTime = segments[index + 1].timestamp
                }
            }
        }
        
        return lines.joined(separator: "\n")
    }
}
