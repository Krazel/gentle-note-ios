import AVFoundation
import Foundation
import SwiftUI
import UIKit

enum MediaPermissionState: String {
    case notRequested = "Not Requested"
    case allowed = "Allowed"
    case denied = "Off"
    var title: String { rawValue.gentleLocalized }
}

enum MediaPermissions {
    static func camera() -> MediaPermissionState { state(for: .video) }
    static func microphone() -> MediaPermissionState { state(for: .audio) }

    static func requestCamera() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }

    static func requestCameraAndMicrophone() async -> Bool {
        let camera = await AVCaptureDevice.requestAccess(for: .video)
        guard camera else { return false }
        return await AVCaptureDevice.requestAccess(for: .audio)
    }

    static func requestMicrophone() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .audio)
    }

    private static func state(for type: AVMediaType) -> MediaPermissionState {
        switch AVCaptureDevice.authorizationStatus(for: type) {
        case .authorized: .allowed
        case .notDetermined: .notRequested
        default: .denied
        }
    }
}

final class VideoRecorder: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    @Published var isReady = false
    @Published var isRecording = false
    @Published var elapsed: TimeInterval = 0
    @Published var finishedURL: URL?
    @Published var errorMessage: String?

    let session = AVCaptureSession()
    private let output = AVCaptureMovieFileOutput()
    private let queue = DispatchQueue(label: "com.krazel.gentlenote.camera")
    private var timer: Timer?

    func configure() {
        queue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .hd1280x720
            defer { self.session.commitConfiguration() }
            do {
                guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                           for: .video,
                                                           position: .front),
                      let microphone = AVCaptureDevice.default(for: .audio) else {
                    throw NSError(domain: "GentleNote.Camera", code: 1,
                                  userInfo: [NSLocalizedDescriptionKey: "Camera or microphone is unavailable.".gentleLocalized])
                }
                for input in self.session.inputs { self.session.removeInput(input) }
                let cameraInput = try AVCaptureDeviceInput(device: camera)
                let microphoneInput = try AVCaptureDeviceInput(device: microphone)
                guard self.session.canAddInput(cameraInput), self.session.canAddInput(microphoneInput) else {
                    throw NSError(domain: "GentleNote.Camera", code: 2,
                                  userInfo: [NSLocalizedDescriptionKey: "Camera inputs could not be prepared.".gentleLocalized])
                }
                self.session.addInput(cameraInput)
                self.session.addInput(microphoneInput)
                if self.session.canAddOutput(self.output) { self.session.addOutput(self.output) }
                self.output.movieFragmentInterval = .invalid
                DispatchQueue.main.async { self.isReady = true }
                self.session.startRunning()
            } catch {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
            }
        }
    }

    func start() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mov")
        try? FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete],
                                               ofItemAtPath: FileManager.default.temporaryDirectory.path)
        finishedURL = nil
        output.startRecording(to: url, recordingDelegate: self)
        isRecording = true
        elapsed = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.elapsed += 1 }
        }
    }

    func stop() {
        output.stopRecording()
        timer?.invalidate()
        isRecording = false
    }

    func flipCamera() {
        guard !isRecording else { return }
        queue.async { [weak self] in
            guard let self,
                  let current = self.session.inputs.compactMap({ $0 as? AVCaptureDeviceInput })
                    .first(where: { $0.device.hasMediaType(.video) }) else { return }
            let position: AVCaptureDevice.Position = current.device.position == .front ? .back : .front
            guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                           for: .video,
                                                           position: position),
                  let newInput = try? AVCaptureDeviceInput(device: newCamera) else { return }
            self.session.beginConfiguration()
            self.session.removeInput(current)
            if self.session.canAddInput(newInput) { self.session.addInput(newInput) }
            else { self.session.addInput(current) }
            self.session.commitConfiguration()
        }
    }

    func stopSession() {
        timer?.invalidate()
        queue.async { [weak self] in self?.session.stopRunning() }
    }

    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        DispatchQueue.main.async {
            if let error { self.errorMessage = error.localizedDescription }
            else { self.finishedURL = outputFileURL }
            self.isRecording = false
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.layerView.videoGravity = .resizeAspectFill
        view.layerView.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.layerView.session = session
    }
}

struct PhotoCapturePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onImage: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: PhotoCapturePicker

        init(parent: PhotoCapturePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImage(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var layerView: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

@MainActor
final class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var elapsed: TimeInterval = 0
    @Published var level: Float = 0
    @Published var finishedURL: URL?
    @Published var errorMessage: String?

    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    func start() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .spokenAudio, options: [])
            try session.setActive(true)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.delegate = self
            recorder.isMeteringEnabled = true
            recorder.record()
            self.recorder = recorder
            isRecording = true
            isPaused = false
            finishedURL = nil
            elapsed = 0
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.recorder?.updateMeters()
                    self.elapsed = self.recorder?.currentTime ?? 0
                    let power = self.recorder?.averagePower(forChannel: 0) ?? -60
                    self.level = max(0.05, min(1, (power + 60) / 60))
                }
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func pauseOrResume() {
        guard let recorder else { return }
        if recorder.isRecording { recorder.pause(); isPaused = true }
        else { recorder.record(); isPaused = false }
    }

    func stop() {
        recorder?.stop()
        timer?.invalidate()
        finishedURL = recorder?.url
        isRecording = false
        isPaused = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
