import Foundation
import AVFoundation
import Combine

final class SpeechToBase64Service: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var base64Audio: String = ""
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingSession: AVAudioSession = AVAudioSession.sharedInstance()
    private var recordingURL: URL?
    
    override init() {
        super.init()
        setupRecorder()
    }
    
    private func setupRecorder() {
        // Request permission to access the microphone
        recordingSession.requestRecordPermission { [unowned self] allowed in
            DispatchQueue.main.async {
                if allowed {
                    self.configureSession()
                } else {
                    print("Microphone access denied.")
                }
            }
        }
    }
    
    private func configureSession() {
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try recordingSession.setActive(true)
            prepareRecorder()
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    private func prepareRecorder() {
        let tempDir = FileManager.default.temporaryDirectory
        recordingURL = tempDir.appendingPathComponent(UUID().uuidString + ".m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        guard let url = recordingURL else { return }
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
        } catch {
            print("Failed to initialize audio recorder: \(error.localizedDescription)")
        }
    }
    
    func startRecording() {
        guard let recorder = audioRecorder else { return }
        
        if !recorder.isRecording {
            recorder.prepareToRecord()
            recorder.record()
            isRecording = true
            print("Recording started.")
        }
    }
    
    func stopRecording() {
        guard let recorder = audioRecorder else { return }
        
        if recorder.isRecording {
            recorder.stop()
            isRecording = false
            print("Recording stopped.")
            convertAudioToBase64()
        }
    }
    
    private func convertAudioToBase64() {
        guard let url = recordingURL else { return }
        
        do {
            let audioData = try Data(contentsOf: url)
            base64Audio = audioData.base64EncodedString()
            print("Base64 Audio String Generated.")
            // You can handle the Base64 string here (e.g., send it to a server)
        } catch {
            print("Failed to convert audio to Base64: \(error.localizedDescription)")
        }
    }
    
    // MARK: - AVAudioRecorderDelegate Methods
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("Recording finished successfully.")
        } else {
            print("Recording failed to finish successfully.")
        }
    }
}

