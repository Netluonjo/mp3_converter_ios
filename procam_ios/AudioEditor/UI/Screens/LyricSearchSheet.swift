import SwiftUI

/// Modern modal sheet allowing users to search and apply synchronized LRC lyrics from open database
public struct LyricSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchService = LyricSearchService.shared
    
    public let initialQuery: String
    public let duration: TimeInterval
    public let onApplyLyrics: (String) -> Void
    
    @State private var query: String
    @State private var selectedResult: LyricSearchResult? = nil
    @State private var showPreviewSheet: Bool = false
    
    public init(
        initialQuery: String,
        duration: TimeInterval,
        onApplyLyrics: @escaping (String) -> Void
    ) {
        self.initialQuery = initialQuery
        self.duration = duration
        self.onApplyLyrics = onApplyLyrics
        
        // Clean up common file tags like "Ghi âm 1.m4a" -> "Ghi âm 1"
        let clean = initialQuery
            .replacingOccurrences(of: "\\.[a-zA-Z0-9]{2,4}$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "_", with: " ")
        self._query = State(initialValue: clean)
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Search Bar
                searchBarView
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                
                Divider()
                
                // MARK: - Content
                if searchService.isSearching {
                    loadingView
                } else if let error = searchService.errorMessage {
                    errorView(error)
                } else if searchService.searchResults.isEmpty {
                    emptyStateView
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
                if !query.trimmingCharacters(in: .whitespaces).isEmpty && searchService.searchResults.isEmpty {
                    _ = await searchService.search(query: query)
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
                        performSearch()
                    }
                
                if !query.isEmpty {
                    Button(action: { query = "" }) {
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
            
            Button(action: performSearch) {
                Text("Tìm")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(AudioEditorTheme.accentRed))
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
                            // Icon indicating synced or plain
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
    
    private var errorView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundColor(.orange)
            Text("Không thể tải kết quả")
                .font(.system(size: 16, weight: .bold))
            Text(error)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Thử lại", action: performSearch)
                .padding(.top, 8)
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "music.note.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(Color(UIColor.systemGray3))
            
            Text("Nhập tên bài hát để tìm lời")
                .font(.system(size: 16, weight: .bold))
            
            Text("Kho dữ liệu chứa hàng triệu lời bài hát chuẩn `.lrc` có mốc thời gian đồng bộ chuẩn xác với nhạc.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Suggested quick searches
            VStack(spacing: 8) {
                Text("Gợi ý tìm nhanh:")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    suggestionPill("See You Again")
                    suggestionPill("Hello")
                    suggestionPill("Shape of You")
                }
            }
            .padding(.top, 16)
            
            Spacer()
        }
    }
    
    private func suggestionPill(_ title: String) -> some View {
        Button(action: {
            query = title
            performSearch()
        }) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AudioEditorTheme.accentRed)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(AudioEditorTheme.accentRed.opacity(0.12)))
        }
    }
    
    private func performSearch() {
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
    
    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                // Header track summary
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
                
                // Lyrics Scroll Preview
                ScrollView {
                    Text(item.resolvedLyrics ?? "Không có nội dung lời bài hát.")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(Color(UIColor.label))
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                }
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(UIColor.secondarySystemBackground)))
                
                // Apply Button
                Button(action: {
                    if let lyrics = item.resolvedLyrics {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onConfirm(lyrics)
                        dismiss()
                    }
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
