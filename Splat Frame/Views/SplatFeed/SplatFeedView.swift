import SwiftUI

struct SplatFeedView: View {
    @Environment(AppState.self) private var appState
    @State private var feedService = SplatFeedService()
    @State private var selectedItem: SplatFeedItem?

    var body: some View {
        NavigationStack {
            Group {
                if feedService.isLoading && feedService.items.isEmpty {
                    ProgressView("Loading feed...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = feedService.error, feedService.items.isEmpty {
                    ContentUnavailableView {
                        Label("Could not load feed", systemImage: "wifi.slash")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            Task { await feedService.refresh() }
                        }
                    }
                } else {
                    // Single-item Instagram/Twitter-style vertical paging scroll
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 0) {
                            ForEach(feedService.items) { item in
                                SplatFeedItemView(item: item) {
                                    selectedItem = item
                                }
                                .containerRelativeFrame(.vertical)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .refreshable {
                        await feedService.refresh()
                    }
                }
            }
            .background(.black)
            .navigationDestination(item: $selectedItem) { item in
                SplatFeedDetailView(
                    item: item,
                    feedService: feedService,
                    headTracker: appState.headTracker
                )
            }
            .task {
                if feedService.items.isEmpty {
                    await feedService.refresh()
                }
            }
        }
    }
}
