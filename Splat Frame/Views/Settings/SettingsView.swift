import SwiftUI
import ReplayKit

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var smoothingAlpha: Float = 0.25
    @State private var movementScale: Float = 1.5
    @State private var gyroSensitivity: Float = 0.03

    var body: some View {
        @Bindable var state = appState
        NavigationStack {
            List {
                // MARK: Head Tracking
                Section("Head Tracking") {
                    Button("Reset Calibration") {
                        appState.headTracker.resetOrigin()
                        appState.deviceMotion.resetReference()
                    }

                    HStack {
                        Text("Status")
                        Spacer()
                        Text(appState.headTracker.isTracking ? "Active" : "Inactive")
                            .foregroundStyle(appState.headTracker.isTracking ? .green : .secondary)
                    }

                    VStack(alignment: .leading) {
                        Text("Smoothing: \(smoothingAlpha, specifier: "%.2f")")
                        Slider(value: $smoothingAlpha, in: 0.1...0.5, step: 0.05)
                            .onChange(of: smoothingAlpha) { _, value in
                                appState.headTracker.smoothingAlpha = value
                            }
                    }

                    VStack(alignment: .leading) {
                        Text("Sensitivity: \(movementScale, specifier: "%.1f")x")
                        Slider(value: $movementScale, in: 0.5...3.0, step: 0.1)
                            .onChange(of: movementScale) { _, value in
                                appState.cubeController.movementScale = value
                            }
                    }
                }

                // MARK: Gyroscope
                Section("Phone Motion") {
                    Toggle("Gyroscope Tracking", isOn: $state.gyroEnabled)

                    if appState.gyroEnabled {
                        HStack {
                            Text("Status")
                            Spacer()
                            Text(appState.deviceMotion.isActive ? "Active" : "Inactive")
                                .foregroundStyle(appState.deviceMotion.isActive ? .green : .secondary)
                        }

                        VStack(alignment: .leading) {
                            Text("Sensitivity: \(gyroSensitivity, specifier: "%.3f")")
                            Slider(value: $gyroSensitivity, in: 0.01...0.08, step: 0.005)
                                .onChange(of: gyroSensitivity) { _, value in
                                    appState.deviceMotion.sensitivity = value
                                }
                        }
                    }
                }

                // MARK: Screen Recording
                Section("Recording") {
                    Button {
                        toggleRecording()
                    } label: {
                        Label(
                            appState.isRecording ? "Stop Recording" : "Start Screen Recording",
                            systemImage: appState.isRecording ? "record.circle.fill" : "record.circle"
                        )
                        .foregroundStyle(appState.isRecording ? .red : .primary)
                    }
                }

                // MARK: Effects
                Section {
                    Toggle("Wobble / Jello", isOn: $state.wobbleEnabled)
                    Toggle("Inertia / Slide", isOn: $state.inertiaEnabled)
                    Toggle("Bounce", isOn: $state.bounceEnabled)
                } header: {
                    Text("Motion Effects")
                } footer: {
                    Text("Gyroscope-driven effects applied to the cube. These layer on top of head tracking.")
                }

                // MARK: Line Effects
                Section {
                    Toggle("Wobble / Jello", isOn: $state.lineWobbleEnabled)
                    Toggle("Inertia / Slide", isOn: $state.lineInertiaEnabled)
                    Toggle("Bounce", isOn: $state.lineBounceEnabled)
                } header: {
                    Text("Line Effects")
                } footer: {
                    Text("Physics effects on the wireframe edges. Walls stay stable while lines deform like jello.")
                }

                // MARK: Device Info
                Section("Device") {
                    HStack {
                        Text("Sensors")
                        Spacer()
                        HStack(spacing: 8) {
                            Label("Face", systemImage: appState.headTracker.isSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(appState.headTracker.isSupported ? .green : .red)
                            Label("Gyro", systemImage: appState.deviceMotion.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(appState.deviceMotion.isAvailable ? .green : .red)
                        }
                        .font(.caption)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func toggleRecording() {
        let recorder = RPScreenRecorder.shared()
        if appState.isRecording {
            recorder.stopRecording { previewVC, error in
                appState.isRecording = false
                guard let previewVC else { return }
                previewVC.previewControllerDelegate = RecordingDismissDelegate.shared
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    previewVC.modalPresentationStyle = .fullScreen
                    rootVC.present(previewVC, animated: true)
                }
            }
        } else {
            recorder.isMicrophoneEnabled = false
            recorder.startRecording { error in
                if error == nil {
                    appState.isRecording = true
                }
            }
        }
    }
}
