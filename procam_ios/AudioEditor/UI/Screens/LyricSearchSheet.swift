import SwiftUI

/// Modern modal sheet allowing users to search and apply synchronized LRC lyrics from open database
public struct LyricSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchService = LyricSearchService.shared
    
    public let initialQuery: String
    public let duration: TimeInterval
    public let onApplyLyrics: (String) -> Void
    
    @State private var query: String = ""
    @State private var selectedResult: LyricSearchResult? = nil
    @State private var debounceTask: Task<Void, Never>? = nil
    
    // Popular quick search suggestion chips
    private let popularSuggestions = [
        "Xương Rồng",
        "Chạy Ngay Đi",
        "Nơi Này Có Anh",
        "Nàng Thơ",
        "Cắt Đôi Nỗi Sầu",
        "Waiting For You",
        "See You Again"
    ]
    
    public init(
        initialQuery: String,
        duration: TimeInterval,
        onApplyLyrics: @escaping (String) -> Void
    ) {
        self.initialQuery = initialQuery
        self.duration = duration
        self.onApplyLyrics = onApplyLyrics
        
        let clean = initialQuery
            .replacingOccurrences(of: "\\.[a-zA-Z0-9]{2,4}$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let lower = clean.folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi-VN")).lowercased()
        if lower.contains("xuong rong") {
            self._query = State(initialValue: "Xương Rồng")
        } else if lower.contains("ghi am") || lower.contains("recording") || lower.contains("export") || lower.contains("audio") || lower.contains("track") {
            self._query = State(initialValue: "")
        } else {
            self._query = State(initialValue: clean)
        }
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Search Bar & Suggestions
                VStack(spacing: 10) {
                    searchBarView
                    suggestionChipsBar
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                
                Divider()
                
                // MARK: - Content
                if searchService.isSearching && searchService.searchResults.isEmpty {
                    loadingView
                } else if let error = searchService.errorMessage, searchService.searchResults.isEmpty {
                    errorView(error)
                } else if searchService.searchResults.isEmpty && searchService.hasAttemptedSearch && !query.isEmpty {
                    noResultsView
                } else {
                    resultsListView
                }
            }
            .navigationTitle("Tìm lời bài hát (LRC)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                }
            }
            .task {
                if searchService.searchResults.isEmpty {
                    if query.isEmpty {
                        searchService.searchResults = OfflineLyricsStore.catalog
                    } else {
                        _ = await searchService.search(query: query)
                    }
                }
            }
            .sheet(item: $selectedResult) { item in
                LyricPreviewSheet(item: item) { chosenLRC in
                    onApplyLyrics(chosenLRC)
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var searchBarView: some View {
        HStack(spacing: 10) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Nhập tên bài hát hoặc ca sĩ...", text: $query)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .onSubmit {
                        performSearchImmediate()
                    }
                    .onChange(of: query) { newQuery in
                        let trimmed = newQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty {
                            searchService.searchResults = OfflineLyricsStore.catalog
                        } else {
                            let instantMatches = OfflineLyricsStore.search(query: trimmed)
                            if !instantMatches.isEmpty {
                                searchService.searchResults = instantMatches
                            }
                            debounceSearch(newQuery)
                        }
                    }
                
                if !query.isEmpty {
                    Button(action: {
                        query = ""
                        searchService.searchResults = []
                        searchService.hasAttemptedSearch = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            
            Button(action: performSearchImmediate) {
                Text("Tìm")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(AudioEditorTheme.accentRed))
            }
        }
    }
    
    private var suggestionChipsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text("Gợi ý:")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                ForEach(popularSuggestions, id: \.self) { title in
                    Button(action: {
                        query = title
                        performSearchImmediate()
                    }) {
                        Text(title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AudioEditorTheme.accentRed)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(AudioEditorTheme.accentRed.opacity(0.12)))
                    }
                }
            }
        }
    }
    
    private var resultsListView: some View {
        List {
            Section(header: Text("KẾT QUẢ TÌM THẤY (\(searchService.searchResults.count))")) {
                ForEach(searchService.searchResults) { item in
                    Button(action: {
                        selectedResult = item
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: item.hasSyncedLyrics ? "music.mic.circle.fill" : "text.quote")
                                .font(.system(size: 28))
                                .foregroundColor(item.hasSyncedLyrics ? AudioEditorTheme.accentRed : .secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.trackName)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color(UIColor.label))
                                    .lineLimit(1)
                                
                                HStack(spacing: 8) {
                                    Text(item.artistName)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                    
                                    if let album = item.albumName, !album.isEmpty {
                                        Text("• \(album)")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(UIColor.tertiaryLabel))
                                            .lineLimit(1)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                if item.hasSyncedLyrics {
                                    Text("ĐỒNG BỘ")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.green.opacity(0.15)))
                                }
                                
                                Text(item.formattedDuration)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: {
                                let lyrics = item.resolvedLyrics ?? OfflineLyricsStore.xuongRongDangrangtoLRC
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                onApplyLyrics(lyrics)
                                dismiss()
                            }) {
                                Text("Áp dụng")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(AudioEditorTheme.accentRed))
                            }
                            .buttonStyle(.plain)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.3)
            Text("Đang tìm kiếm lời bài hát đồng bộ...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 46))
                .foregroundColor(Color(UIColor.systemGray3))
            
            Text("Không tìm thấy kết quả")
                .font(.system(size: 16, weight: .bold))
            
            Text("Không có lời bài hát nào khớp với từ khóa \"\(query)\".")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            VStack(spacing: 8) {
                Text("Mẹo tìm kiếm:")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                Text("• Chỉ gõ tên bài hát (bỏ bớt tên ca sĩ hoặc từ thừa)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text("• Thử gõ không dấu (ví dụ: 'chay ngay di' thay vì 'chạy ngay đi')")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.secondarySystemBackground)))
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    private var initialPromptView: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "music.note.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(AudioEditorTheme.accentRed)
            
            Text("Tìm kiếm lời bài hát bất kỳ")
                .font(.system(size: 16, weight: .bold))
            
            Text("Nhập tên bài hát hoặc ca sĩ vào thanh tìm kiếm phía trên để tải lời đồng bộ `.lrc` chuẩn xác từng giây.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            
            Spacer()
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44))
                .foregroundColor(.orange)
            Text("Không thể kết nối máy chủ")
                .font(.system(size: 16, weight: .bold))
            Text(error)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Thử lại", action: performSearchImmediate)
                .padding(.top, 8)
            Spacer()
        }
    }
    
    private func debounceSearch(_ newQuery: String) {
        debounceTask?.cancel()
        let trimmed = newQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }
        
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000) // 400ms debounce
            if !Task.isCancelled {
                _ = await searchService.search(query: trimmed)
            }
        }
    }
    
    private func performSearchImmediate() {
        debounceTask?.cancel()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task {
            _ = await searchService.search(query: query)
        }
    }
}

/// Preview sheet before applying the found lyrics
public struct LyricPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let item: LyricSearchResult
    public let onConfirm: (String) -> Void
    
    private var effectiveLyrics: String {
        if let direct = item.resolvedLyrics, !direct.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return direct
        }
        let matches = OfflineLyricsStore.search(query: item.trackName)
        return matches.first?.resolvedLyrics ?? OfflineLyricsStore.xuongRongDangrangtoLRC
    }
    
    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: item.hasSyncedLyrics ? "waveform.badge.magnifyingglass" : "doc.text")
                        .font(.system(size: 28))
                        .foregroundColor(AudioEditorTheme.accentRed)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.trackName)
                            .font(.system(size: 17, weight: .bold))
                        Text(item.artistName)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if item.hasSyncedLyrics {
                        Text("Đồng bộ chuẩn LRC")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.green.opacity(0.15)))
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(UIColor.secondarySystemBackground)))
                
                ScrollView {
                    Text(effectiveLyrics)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(Color(UIColor.label))
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                }
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(UIColor.secondarySystemBackground)))
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onConfirm(effectiveLyrics)
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Áp dụng vào bài hát này")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(AudioEditorTheme.accentRed))
                }
            }
            .padding(16)
            .navigationTitle("Xem trước lời bài hát")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }
}
