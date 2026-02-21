import SwiftUI
import AVFoundation
import Photos

struct PermissionRequestView: View {
    var onGranted: () -> Void

    @State private var cameraStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "camera.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.7))

                Text("Welcome to Splat Frame")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("Splat Frame uses the front camera to track your head and create a 3D window effect. Photo library access lets you place your photos on the cube faces.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 24)

                if cameraStatus == .denied || cameraStatus == .restricted {
                    Text("Camera access was denied. Please enable it in Settings.")
                        .foregroundStyle(.red.opacity(0.9))
                        .multilineTextAlignment(.center)

                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.glassProminent)
                } else {
                    Button("Get Started") {
                        requestAllPermissions()
                    }
                    .buttonStyle(.glassProminent)
                    .padding(.top, 8)
                }

                Spacer()
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }

    private func requestAllPermissions() {
        // Request camera first, then photo library
        AVCaptureDevice.requestAccess(for: .video) { cameraGranted in
            // Also request photo library access for cube face content
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in
                Task { @MainActor in
                    cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
                    if cameraGranted {
                        onGranted()
                    }
                }
            }
        }
    }
}
