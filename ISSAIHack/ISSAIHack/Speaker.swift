import Foundation
import SwiftUI
import AVFoundation

struct VoiceInteractionView: View {
    @StateObject private var speechService = SpeechToBase64Service()
    @State private var translatedText: String = ""
    @State private var kazLLMResponse: String = ""
    @State private var isProcessing: Bool = false
    @State private var audioPlayer: AVAudioPlayer?
    
    let soyleAPI = SoyleAPI()
    let kazLLMAPI = KazLLMAPI()
    
    var body: some View {
        VStack {
            // Microphone button to start/stop recording
            Button(action: handleMicTap) {
                Image(systemName: speechService.isRecording ? "mic.fill" : "mic.slash.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .padding(40)
                    .background(speechService.isRecording ? Color.red : Color.blue)
                    .clipShape(Circle())
            }
            
            if isProcessing {
                ProgressView("Processing...")
                    .padding()
            }
            
            // Display KazLLM response
            if !kazLLMResponse.isEmpty {
                Text("KazLLM Response:")
                    .font(.headline)
                Text(kazLLMResponse)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.purple]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .edgesIgnoringSafeArea(.all)
        .onReceive(speechService.$base64Audio) { base64Audio in
            if !base64Audio.isEmpty {
                processAudio(base64Audio: base64Audio)
            }
        }
    }
    
    private func handleMicTap() {
        if speechService.isRecording {
            speechService.stopRecording()
        } else {
            speechService.startRecording()
        }
    }
    
    private func processAudio(base64Audio: String) {
        isProcessing = true
        translatedText = ""
        kazLLMResponse = ""
        
        // Translate the audio to text
        soyleAPI.translateAudio(targetLanguage: "kaz", audioBase64: base64Audio) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    self.createInteractionWithKazLLM(text: text)
                case .failure(let error):
                    self.isProcessing = false
                    self.translatedText = "Error translating audio: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func createInteractionWithKazLLM(text: String) {
        let assistantID = 84
        
        kazLLMAPI.createInteraction(assistantID: assistantID, textPrompt: text) { interactionResult in
            DispatchQueue.main.async {
                switch interactionResult {
                case .success(let interactionResponse):
                    self.kazLLMResponse = interactionResponse.vllmResponse.content
                    self.synthesizeResponse(interactionResponse.vllmResponse.content)
                case .failure(let error):
                    self.isProcessing = false
                    self.kazLLMResponse = "Error creating interaction: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func synthesizeResponse(_ unicodeString: String) {
        if let decodedString = unicodeString.applyingTransform(.init("Any-Hex/Unicode"), reverse: false) {
            print("Decoded String: \(decodedString)")
            soyleAPI.translateText(sourceLanguage: "kaz", targetLanguage: "kaz", text: decodedString) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let audioBase64):
                        print("Synthesized Audio Base64: \(audioBase64)")
                    case .failure(let error):
                        print("Failed to synthesize response: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            print("Failed to decode Unicode string")
        }
    }
    
    private func playAudioFromBase64(_ base64: String) {
        guard let audioData = Data(base64Encoded: base64) else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.play()
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }
}
