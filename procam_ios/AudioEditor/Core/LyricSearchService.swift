import Foundation
import Combine

/// Model representing a lyric search result from LRCLIB API
public struct LyricSearchResult: Identifiable, Codable, Hashable {
    public let id: Int
    public let trackName: String
    public let artistName: String
    public let albumName: String?
    public let duration: Double?
    public let syncedLyrics: String?
    public let plainLyrics: String?
    
    public var hasSyncedLyrics: Bool {
        guard let synced = syncedLyrics else { return false }
        return !synced.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var formattedDuration: String {
        guard let dur = duration, dur > 0 else { return "--:--" }
        let total = Int(dur)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    public var resolvedLyrics: String? {
        return (hasSyncedLyrics ? syncedLyrics : plainLyrics)
    }
}

/// Service connecting to LRCLIB (open-source synced lyrics database) with smart fallbacks
@MainActor
public final class LyricSearchService: ObservableObject {
    public static let shared = LyricSearchService()
    
    @Published public var isSearching: Bool = false
    @Published public var searchResults: [LyricSearchResult] = []
    @Published public var errorMessage: String? = nil
    @Published public var hasAttemptedSearch: Bool = false
    
    private init() {}
    
    /// Searches for synced lyrics with multi-tier smart fallback (clean query -> parts -> unaccented)
    public func search(query: String) async -> [LyricSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            self.searchResults = []
            self.hasAttemptedSearch = false
            return []
        }
        
        self.isSearching = true
        self.errorMessage = nil
        self.hasAttemptedSearch = true
        
        // Tier 1: Clean query by stripping file extensions and tags like (Official MV), [Lyrics]
        let cleaned = cleanQueryString(trimmed)
        var results = await executeNetworkSearch(query: cleaned)
        
        // Tier 2: If no results and query contains "-", search individual segments (e.g. "Son Tung - Chay Ngay Di")
        if results.isEmpty && cleaned.contains("-") {
            let parts = cleaned.components(separatedBy: "-")
            for part in parts {
                let partClean = part.trimmingCharacters(in: .whitespacesAndNewlines)
                if partClean.count >= 3 {
                    results = await executeNetworkSearch(query: partClean)
                    if !results.isEmpty { break }
                }
            }
        }
        
        // Tier 3: If no results, try folding Vietnamese accents (diacritics insensitive)
        if results.isEmpty {
            let folded = cleaned.folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi-VN"))
            if folded != cleaned {
                results = await executeNetworkSearch(query: folded)
            }
        }
        
        // Prioritize results that have synced LRC timestamps
        let sorted = results.sorted { lhs, rhs in
            if lhs.hasSyncedLyrics != rhs.hasSyncedLyrics {
                return lhs.hasSyncedLyrics && !rhs.hasSyncedLyrics
            }
            return false
        }
        
        self.searchResults = sorted
        self.isSearching = false
        return sorted
    }
    
    /// Low-level HTTP call to LRCLIB API
    private func executeNetworkSearch(query: String) async -> [LyricSearchResult] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://lrclib.net/api/search?q=\(encoded)") else {
            return []
        }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 8.0
            request.setValue("ProCam-AudioEditor/1.0 (https://procam.app)", forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return []
            }
            
            let decoded = try JSONDecoder().decode([LyricSearchResult].self, from: data)
            return decoded
        } catch {
            return []
        }
    }
    
    /// Cleans up raw recording/file names into clean searchable song names
    public func cleanQueryString(_ raw: String) -> String {
        var str = raw
        // Remove quotes
        str = str.replacingOccurrences(of: "[\"']", with: "", options: .regularExpression)
        // Remove file extensions
        str = str.replacingOccurrences(of: "\\.[a-zA-Z0-9]{2,4}$", with: "", options: .regularExpression)
        // Remove bracketed info [MV], (Lyrics), (Audio)
        str = str.replacingOccurrences(of: "\\[[^\\]]*\\]|\\([^\\)]*\\)", with: "", options: .regularExpression)
        // Remove underscores
        str = str.replacingOccurrences(of: "_", with: " ")
        
        // Remove common Vietnamese & English song prefixes that prevent exact title matching
        let prefixPattern = "^(lời\\s*bài\\s*hát|loi\\s*bai\\s*hat|bài\\s*hát|bai\\s*hat|nhạc|nhac|ca\\s*khúc|ca\\s*khuc|bài|bai|lyrics?\\s+of|lyrics?|song)\\s+"
        str = str.replacingOccurrences(of: prefixPattern, with: "", options: [.regularExpression, .caseInsensitive])
        
        return str.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Auto-fetch best matched LRC lyrics for a given track title and audio duration
    public func autoFetchBestMatch(trackTitle: String, duration: TimeInterval) async -> String? {
        let results = await search(query: trackTitle)
        if let exactSynced = results.first(where: { $0.hasSyncedLyrics }) {
            return exactSynced.syncedLyrics
        }
        return results.first?.resolvedLyrics
    }
}
