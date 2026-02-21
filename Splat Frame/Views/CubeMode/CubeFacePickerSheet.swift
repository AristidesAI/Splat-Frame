import SwiftUI
import PhotosUI
import AVFoundation

struct CubeFacePickerSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFace: CubeFace?
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Centered dismiss button at top
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrowtriangle.down.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 12)
                .padding(.bottom, 4)

                List {
                    ForEach(CubeFace.allCases) { face in
                        HStack {
                            Image(systemName: face.systemImage)
                                .frame(width: 30)

                            Text(face.displayName)

                            Spacer()

                            if appState.faceContent[face] != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)

                                Button("Clear", role: .destructive) {
                                    appState.faceContent[face] = nil
                                    appState.cubeController.clearFace(face)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedFace = face
                            showPhotoPicker = true
                        }
                    }
                }
            }
            .navigationTitle("Cube Faces")
            .navigationBarTitleDisplayMode(.inline)
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedPhotoItem,
                matching: .any(of: [.images, .videos])
            )
            .onChange(of: selectedPhotoItem) { _, item in
                guard let item, let face = selectedFace else { return }
                // Dismiss immediately — content loads in the background
                dismiss()
                Task {
                    await loadContent(from: item, for: face)
                }
                selectedPhotoItem = nil
            }
        }
    }

    private func loadContent(from item: PhotosPickerItem, for face: CubeFace) async {
        // Try loading as image first
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            appState.faceContent[face] = .photo(image)
            appState.cubeController.setImage(image, on: face)
            return
        }

        // Try loading as video
        if let movie = try? await item.loadTransferable(type: VideoFileTransferable.self) {
            let player = AVPlayer(url: movie.url)
            appState.faceContent[face] = .video(movie.url)
            appState.cubeController.setVideo(player, on: face)

            // Loop video
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { _ in
                player.seek(to: .zero)
                player.play()
            }
        }
    }
}

/// Transferable wrapper for video files from PhotosPicker.
struct VideoFileTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let tempDir = FileManager.default.temporaryDirectory
            let filename = received.file.lastPathComponent
            let destination = tempDir.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: received.file, to: destination)
            return VideoFileTransferable(url: destination)
        }
    }
}
