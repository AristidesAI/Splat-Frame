import SwiftUI
import AVFoundation
import ReplayKit

struct MainTabView: View {
    @State private var appState = AppState()
    @State private var cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    @State private var uiHidden = false

    var body: some View {
        Group {
            if cameraAuthorized {
                mainContent
            } else {
                PermissionRequestView {
                    cameraAuthorized = true
                }
            }
        }
        .onChange(of: cameraAuthorized) { _, authorized in
            if authorized {
                appState.headTracker.start()
                if appState.gyroEnabled {
                    appState.deviceMotion.start()
                }
            }
        }
        .onChange(of: appState.gyroEnabled) { _, enabled in
            if enabled {
                appState.deviceMotion.start()
            } else {
                appState.deviceMotion.stop()
            }
        }
        .onChange(of: appState.wobbleEnabled) { _, value in
            appState.cubeController.wobbleEnabled = value
        }
        .onChange(of: appState.inertiaEnabled) { _, value in
            appState.cubeController.inertiaEnabled = value
        }
        .onChange(of: appState.bounceEnabled) { _, value in
            appState.cubeController.bounceEnabled = value
            if !value {
                appState.motionEffects.reset()
            }
        }
        .onChange(of: appState.lineWobbleEnabled) { _, value in
            appState.cubeController.lineWobbleEnabled = value
        }
        .onChange(of: appState.lineInertiaEnabled) { _, value in
            appState.cubeController.lineInertiaEnabled = value
        }
        .onChange(of: appState.lineBounceEnabled) { _, value in
            appState.cubeController.lineBounceEnabled = value
        }
        .onAppear {
            if cameraAuthorized {
                appState.headTracker.start()
                if appState.gyroEnabled {
                    appState.deviceMotion.start()
                }
            }
        }
        .environment(appState)
    }

    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            TabView(selection: $appState.selectedTab) {
                Tab("Camera", systemImage: "cube", value: AppState.Tab.cube) {
                    CubeModeView(uiHidden: $uiHidden)
                }

                Tab("Settings", systemImage: "gearshape", value: AppState.Tab.settings) {
                    SettingsView()
                }
            }
            .toolbar(uiHidden ? .hidden : .visible, for: .tabBar)
            .animation(.easeInOut(duration: 0.35), value: uiHidden)

            // Launch spinner overlay — fades out once ARKit starts tracking
            LaunchOverlay(isReady: appState.headTracker.isTracking)
        }
    }
}

// MARK: - Cube Mode View

struct CubeModeView: View {
    @Environment(AppState.self) private var appState
    @Binding var uiHidden: Bool
    @State private var showFacePicker = false
    @State private var pinchStartScale: CGFloat = 1.0
    @State private var showDoubleTapHint = false
    @State private var lastTapTime: Date = .distantPast

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CubeSceneView(controller: appState.cubeController)
                .ignoresSafeArea()
                .gesture(pinchGesture)
                .onTapGesture {
                    handleTap()
                }

            // Live face contour overlay from ARKit face mesh
            if appState.showSilhouette && !uiHidden {
                HeadTrackingOverlay(headTracker: appState.headTracker)
            }

            // All UI controls — hidden/shown together
            if !uiHidden {
                GlassEffectContainer(spacing: 12) {
                    overlayControls
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.35)))
            }

            // "Double tap to show interface" hint
            if showDoubleTapHint {
                Text("Double tap to show interface")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .glassEffect(.regular, in: .capsule)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .sheet(isPresented: $showFacePicker) {
            CubeFacePickerSheet()
                .presentationDetents([.medium])
        }
        .sheet(isPresented: Binding(
            get: { appState.recordingPreviewVC != nil },
            set: { if !$0 { appState.recordingPreviewVC = nil } }
        )) {
            if let previewVC = appState.recordingPreviewVC {
                RecordingPreviewSheet(previewController: previewVC)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            pinchStartScale = appState.zoomScale
            appState.cubeController.setRoomShape(isRectangleMode: appState.isRectangleMode)
            appState.cubeController.setZoomScale(Float(appState.zoomScale))
        }
    }

    // MARK: - Overlay Controls

    @ViewBuilder
    private var overlayControls: some View {
        VStack {
            // Top bar — hide button left, tracking indicator center, recording right
            ZStack {
                // Centered face tracking indicator
                CalibrationOverlay(headTracker: appState.headTracker)

                HStack {
                    // Hide UI button — top left
                    Button {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            uiHidden = true
                        }
                    } label: {
                        Image(systemName: "eye.slash")
                            .font(.callout)
                            .padding(12)
                    }
                    .glassEffect(.regular.interactive())

                    Spacer()

                    // Recording stop button — top right (only when recording)
                    if appState.isRecording {
                        Button {
                            stopRecording()
                        } label: {
                            Image(systemName: "record.circle.fill")
                                .font(.callout)
                                .foregroundStyle(.red)
                                .padding(12)
                        }
                        .glassEffect(.regular.interactive())
                        .transition(.opacity.combined(with: .scale(scale: 0.8)).animation(.easeInOut(duration: 0.3)))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()

            // Bottom toolbar
            HStack(spacing: 12) {
                // Shape toggle
                Button {
                    appState.isRectangleMode.toggle()
                    appState.cubeController.setRoomShape(isRectangleMode: appState.isRectangleMode)
                } label: {
                    Image(systemName: appState.isRectangleMode ? "rectangle.portrait" : "cube.transparent")
                        .font(.callout)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .glassEffect(.regular.interactive())

                // Reset button
                Button {
                    appState.cubeController.resetView()
                    appState.headTracker.resetOrigin()
                    appState.deviceMotion.resetReference()
                    appState.zoomScale = 0.6
                    pinchStartScale = 0.6
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle")
                        .font(.callout)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .glassEffect(.regular.interactive())

                // Faces button
                Button {
                    showFacePicker = true
                } label: {
                    Label("Faces", systemImage: "photo.on.rectangle")
                        .font(.callout)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .glassEffect(.regular.interactive())

                // Silhouette toggle
                Button {
                    appState.showSilhouette.toggle()
                } label: {
                    Image(systemName: "face.dashed")
                        .font(.callout)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .glassEffect(.regular.interactive())
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - Tap Handling

    private func handleTap() {
        let now = Date()
        let interval = now.timeIntervalSince(lastTapTime)
        lastTapTime = now

        if interval < 0.35 {
            // Double tap — show UI
            withAnimation(.easeInOut(duration: 0.35)) {
                uiHidden = false
                showDoubleTapHint = false
            }
        } else {
            // Schedule single-tap hint (only if UI is hidden)
            let tapTime = now
            Task {
                try? await Task.sleep(for: .milliseconds(380))
                // Only fire if no second tap has occurred
                guard lastTapTime == tapTime, uiHidden else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    showDoubleTapHint = true
                }
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.easeOut(duration: 0.5)) {
                    showDoubleTapHint = false
                }
            }
        }
    }

    // MARK: - Recording

    private func stopRecording() {
        let recorder = RPScreenRecorder.shared()
        recorder.stopRecording { previewVC, error in
            withAnimation(.easeOut(duration: 0.3)) {
                appState.isRecording = false
            }
            guard let previewVC else { return }
            appState.recordingPreviewVC = previewVC
        }
    }

    // MARK: - Pinch

    private var pinchGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let newScale = clampScale(pinchStartScale * value.magnification)
                appState.zoomScale = newScale
                appState.cubeController.setZoomScale(Float(newScale))
            }
            .onEnded { _ in
                pinchStartScale = appState.zoomScale
            }
    }

    private func clampScale(_ value: CGFloat) -> CGFloat {
        min(4.0, max(0.3, value))
    }
}
