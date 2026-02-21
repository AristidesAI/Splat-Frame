import SwiftUI

struct SplatFeedDetailView: View {
    let item: SplatFeedItem
    let feedService: SplatFeedService
    let headTracker: HeadTrackingService

    @State private var localURL: URL?
    @State private var isDownloading = false
    @State private var downloadError: String?
    @State private var showPlayer = false

    var body: some View {
        Group {
            if showPlayer, let localURL {
                SplatPlayerView(fileURL: localURL, headTracker: headTracker)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 24) {
                    // Thumbnail preview
                    if let thumbnailURL = item.thumbnailURL {
                        AsyncImage(url: thumbnailURL) { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Text(item.title)
                        .font(.title2.bold())

                    if isDownloading {
                        ProgressView("Downloading...")
                    } else if let downloadError {
                        Text(downloadError)
                            .foregroundStyle(.red)
                        Button("Retry") {
                            Task { await download() }
                        }
                        .buttonStyle(.borderedProminent)
                    } else if localURL != nil {
                        Button {
                            showPlayer = true
                        } label: {
                            Label("View in 3D", systemImage: "play.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    } else {
                        Button {
                            Task { await download() }
                        } label: {
                            Label("Download & View", systemImage: "arrow.down.circle")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Check if already downloaded
            localURL = feedService.localFileURL(for: item)
        }
    }

    private func download() async {
        isDownloading = true
        downloadError = nil
        do {
            localURL = try await feedService.downloadSplat(item: item)
            showPlayer = true
        } catch {
            downloadError = error.localizedDescription
        }
        isDownloading = false
    }
}
