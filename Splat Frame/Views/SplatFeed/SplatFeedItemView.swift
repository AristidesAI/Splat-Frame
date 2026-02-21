import SwiftUI

struct SplatFeedItemView: View {
    let item: SplatFeedItem
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Color.black

                // Full-bleed thumbnail
                if let thumbnailURL = item.thumbnailURL {
                    AsyncImage(url: thumbnailURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            placeholderContent
                        case .empty:
                            ProgressView()
                                .tint(.white)
                        @unknown default:
                            placeholderContent
                        }
                    }
                } else {
                    placeholderContent
                }
            }
            .clipped()
        }
        .buttonStyle(.plain)
    }

    private var placeholderContent: some View {
        ZStack {
            Color.black
            Image(systemName: "cube.transparent")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
        }
    }
}
