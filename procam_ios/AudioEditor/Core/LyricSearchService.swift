import Foundation
import Combine

/// Model representing a lyric search result from LRCLIB API
public struct LyricSearchResult: Identifiable, Codable, Hashable {
    public let id: Int
    public var trackName: String
    public var artistName: String
    public let albumName: String?
    public let duration: Double?
    public let syncedLyrics: String?
    public let plainLyrics: String?
    
    enum CodingKeys: String, CodingKey {
        case id, trackName, name, artistName, albumName, duration, syncedLyrics, plainLyrics
    }
    
    public init(
        id: Int,
        trackName: String,
        artistName: String,
        albumName: String? = nil,
        duration: Double? = nil,
        syncedLyrics: String? = nil,
        plainLyrics: String? = nil
    ) {
        self.id = id
        self.trackName = trackName
        self.artistName = artistName
        self.albumName = albumName
        self.duration = duration
        self.syncedLyrics = syncedLyrics
        self.plainLyrics = plainLyrics
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        let rawTrack = try container.decodeIfPresent(String.self, forKey: .trackName) ??
                       (try container.decodeIfPresent(String.self, forKey: .name) ?? "Không rõ tên")
        self.trackName = rawTrack
        self.artistName = try container.decodeIfPresent(String.self, forKey: .artistName) ?? "Không rõ ca sĩ"
        self.albumName = try container.decodeIfPresent(String.self, forKey: .albumName)
        self.duration = try container.decodeIfPresent(Double.self, forKey: .duration)
        self.syncedLyrics = try container.decodeIfPresent(String.self, forKey: .syncedLyrics)
        self.plainLyrics = try container.decodeIfPresent(String.self, forKey: .plainLyrics)
    }
    
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
        if hasSyncedLyrics, let synced = syncedLyrics {
            return synced
        }
        if let plain = plainLyrics, !plain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return plain
        }
        let offlineMatches = OfflineLyricsStore.search(query: trackName)
        return offlineMatches.first?.resolvedLyrics ?? OfflineLyricsStore.xuongRongDangrangtoLRC
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
    
    /// Searches for synced lyrics with instant offline response followed by background network enrichment
    public func search(query: String) async -> [LyricSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            self.searchResults = OfflineLyricsStore.catalog
            self.hasAttemptedSearch = false
            return OfflineLyricsStore.catalog
        }
        
        self.errorMessage = nil
        self.hasAttemptedSearch = true
        
        // Tier 0: Clean query by stripping prefixes ("tìm bài hát", "bài hát", etc.)
        let cleaned = cleanQueryString(trimmed)
        let searchKeyword = cleaned.isEmpty ? trimmed : cleaned
        
        // Tier 1: Check instant offline catalog (0ms latency, zero delay)
        let offlineMatches = OfflineLyricsStore.search(query: searchKeyword)
        if !offlineMatches.isEmpty {
            self.searchResults = offlineMatches
            self.isSearching = false // Show offline matches immediately without blocking UI!
        } else {
            self.isSearching = true
        }
        
        // Tier 2: Search online network database with fast 3.5s timeout
        var networkResults = await executeNetworkSearch(query: searchKeyword)
        
        // Tier 3: If no network results, try folding Vietnamese accents
        if networkResults.isEmpty {
            let folded = searchKeyword.folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi-VN"))
            if folded != searchKeyword && !folded.isEmpty {
                networkResults = await executeNetworkSearch(query: folded)
            }
        }
        
        // Merge offline + online results without duplicates
        var combined = offlineMatches
        for netItem in networkResults {
            let isDuplicate = combined.contains { existing in
                let titleMatch = existing.trackName.caseInsensitiveCompare(netItem.trackName) == .orderedSame
                let artistMatch = existing.artistName.caseInsensitiveCompare(netItem.artistName) == .orderedSame
                return titleMatch && artistMatch
            }
            if !isDuplicate {
                combined.append(netItem)
            }
        }
        
        var finalResults = combined.isEmpty ? OfflineLyricsStore.catalog : combined
        finalResults.sort { a, b in
            if a.hasSyncedLyrics != b.hasSyncedLyrics {
                return a.hasSyncedLyrics && !b.hasSyncedLyrics
            }
            return false
        }
        self.searchResults = finalResults
        self.isSearching = false
        return finalResults
    }
    
    /// Low-level HTTP call to LRCLIB API with 3.5s timeout
    private func executeNetworkSearch(query: String) async -> [LyricSearchResult] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://lrclib.net/api/search?q=\(encoded)") else {
            return []
        }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 3.5
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
        let prefixPattern = "^(tìm\\s*kiếm|tim\\s*kiem|tìm\\s*lời\\s*bài\\s*hát|tim\\s*loi\\s*bai\\s*hat|tìm\\s*bài\\s*hát|tim\\s*bai\\s*hat|tìm|tim|lời\\s*bài\\s*hát|loi\\s*bai\\s*hat|bài\\s*hát|bai\\s*hat|nhạc|nhac|ca\\s*khúc|ca\\s*khuc|bài|bai|lyrics?\\s+of|lyrics?|song)\\s+"
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
