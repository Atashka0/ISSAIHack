import AVFoundation
import Speech

final class SpeechToBase64Service: ObservableObject {
    
    private let audioEngine = AVAudioEngine()
    private lazy var audioSession = AVAudioSession.sharedInstance()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioFile: AVAudioFile?
    
    @Published var base64Result: String = ""
    @Published var error: Error?
    @Published var isRecording = false
    
    func startRecording() {
        let inputNode = audioEngine.inputNode
        
        do {
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("recording.caf")
            audioFile = try AVAudioFile(forWriting: tempURL, settings: inputNode.outputFormat(forBus: 0).settings)
        } catch {
            self.error = error
            return
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNode.outputFormat(forBus: 0)) { buffer, _ in
            try? self.audioFile?.write(from: buffer)
        }
        
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            self.error = error
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isRecording = false
        
        if let audioFileURL = audioFile?.url {
            do {
                let audioData = try Data(contentsOf: audioFileURL)
                base64Result = audioData.base64EncodedString()
                print(base64Result)
            } catch {
                self.error = error
                print(error)
            }
        }
    }
    
    func reset() {
        base64Result = "NULL"
        error = nil
    }
}
