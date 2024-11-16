import Foundation
import AVFoundation
import Combine

@MainActor
final class AudioService: NSObject, ObservableObject {
    // Published properties for UI updates
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var base64Audio: String = ""

    // Private properties for recorder and player
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private let recordingSession = AVAudioSession.sharedInstance()
    private var recordingURL: URL?

    override init() {
        super.init()
        Task {
            await setupAudioSession()
        }
    }

    // MARK: - Audio Recording

    private func setupAudioSession() async {
        let permissionGranted = await requestMicrophonePermission()
        guard permissionGranted else {
            print("Microphone access denied.")
            return
        }

        do {
            try configureSession()
            try prepareRecorder()
        } catch {
            print("Audio session setup failed: \(error.localizedDescription)")
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            recordingSession.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func configureSession() throws {
        try recordingSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try recordingSession.setActive(true)
    }

    private func prepareRecorder() throws {
        let tempDir = FileManager.default.temporaryDirectory
        recordingURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("m4a")

        guard let url = recordingURL else {
            throw NSError(domain: "AudioService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid recording URL"])
        }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.delegate = self
    }

    func startRecording() {
        guard let recorder = audioRecorder, !recorder.isRecording else {
            print("Recorder is not ready or already recording.")
            return
        }

        do {
            try recordingSession.setActive(true)
            recorder.prepareToRecord()
            recorder.record()
            isRecording = true
            print("Recording started.")
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        guard let recorder = audioRecorder, recorder.isRecording else {
            print("No active recording to stop.")
            return
        }

        recorder.stop()
        isRecording = false
        print("Recording stopped.")

        Task {
            await convertAudioToBase64()
        }
    }

    private func convertAudioToBase64() async {
        guard let url = recordingURL else { return }

        do {
            let audioData = try await Data(contentsOf: url)
            let base64String = audioData.base64EncodedString()
            base64Audio = base64String
            print("Base64 Audio String Generated.")
        } catch {
            print("Failed to convert audio to Base64: \(error.localizedDescription)")
        }
    }

    // MARK: - Audio Playback

    /// Plays the recorded audio stored in `base64Audio`.
    func playAudio() {
        guard !base64Audio.isEmpty else {
            print("No Base64 audio to play.")
            return
        }

        Task {
            await playAudioAsync(fromBase64: base64Audio)
        }
    }

    /// Plays audio from the provided Base64-encoded string.
    /// - Parameter base64String: The Base64-encoded audio data.
    func playAudio(fromBase64 base64String: String) {
        Task {
            await playAudioAsync(fromBase64: base64String)
        }
    }

    private func playAudioAsync(fromBase64 base64String: String) async {
        guard let audioData = Data(base64Encoded: base64String) else {
            print("Failed to decode Base64 string.")
            return
        }
        do {
            try recordingSession.setActive(true)
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            print("Audio playback started.")
        } catch {
            print("Failed to play audio: \(error.localizedDescription)")
        }
    }

    func stopAudio() {
        guard let player = audioPlayer, player.isPlaying else { return }
        player.stop()
        isPlaying = false
        print("Audio playback stopped.")
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("Recording finished successfully.")
        } else {
            print("Recording failed.")
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        if flag {
            print("Playback finished successfully.")
        } else {
            print("Playback failed.")
        }
    }
}


