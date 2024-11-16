import Foundation
import SwiftUI
import AVFoundation

struct VoiceInteractionView: View {
    @StateObject private var speechService = AudioService()
    @State private var translatedText: String = ""
    @State private var isProcessing: Bool = false
    @State private var audioPlayer: AVAudioPlayer?
    
    private let lottieAnimationName: String = "abay.mp4.lottie"
    let kazLLMAPI = KazLLMAPI()
    let soyleAPI = SoyleAPI()
    
    var body: some View {
        VStack {
            // Lottie Animation
            LottieView(animationName: lottieAnimationName, isPlaying: $speechService.isPlaying)

            // Button to start/stop recording
            Button(action: handleMicTap) {
                Image(systemName: speechService.isRecording ? "mic.fill" : "mic.slash.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .padding(40)
                    .background(speechService.isRecording ? Color.red : Color.blue)
                    .clipShape(Circle())
            }
            .padding(.top, 50)

            // Play Recording Button
            if !speechService.base64Audio.isEmpty {
                Button(action: {
                    speechService.playAudio()
                }) {
                    Text("Play Recording")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
            }
        }
        .background(.white)
        .onReceive(speechService.$base64Audio) { base64Audio in
            if !base64Audio.isEmpty {
                processAudio(base64Audio: base64Audio)
            }
        }
        .onDisappear {
            speechService.stopRecording()
        }
    }
    
    private func processAudio(base64Audio: String) {
            isProcessing = true
            translatedText = ""
            
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
            
            kazLLMAPI.createInteraction(assistantID: assistantID, textPrompt: text + " бір сөзбен жауап бер") { interactionResult in
                DispatchQueue.main.async {
                    switch interactionResult {
                    case .success(let interactionResponse):
                        self.synthesizeResponse(interactionResponse.vllmResponse.content)
                    case .failure(let error):
                        self.isProcessing = false
                    }
                }
            }
        }
    
    private func synthesizeResponse(_ unicodeString: String) {
        print("UNICODE")
        print(unicodeString)
        soyleAPI.translateText(sourceLanguage: "kaz", targetLanguage: "kaz", text: unicodeString) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let audioBase16):
                    if let audioData = Data(hexString: audioBase16) {
                        
                        let audioBase64 = audioData.base64EncodedString()
                        self.playAudioFromBase64(audioBase64)
                    } else {
                        print("Failed to decode Base16 string.")
                    }
                case .failure(let error):
                    print("Failed to synthesize response: \(error.localizedDescription)")
                }
            }
        }
    }

    
    private func playAudioFromBase64(_ base64: String) {
        guard let audioData = Data(base64Encoded: base64) else { return }
        if let audioData = Data(base64Encoded: base64) {
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.m4a")
            try? audioData.write(to: fileURL)
            print("Audio written to: \(fileURL)")
        }
//        do {
            speechService.playAudio(fromBase64: base64)
//            audioPlayer = try AVAudioPlayer(data: audioData)
//            audioPlayer?.play()
//        } catch {
//            print("Error playing audio: \(error.localizedDescription)")
//        }
    }

    private func handleMicTap() {
        if speechService.isRecording {
            speechService.stopRecording()
        } else {
            speechService.startRecording()
        }
    }
}


struct PulsatingCircle: View {
    var color: Color
    @State private var pulsate = false

    var body: some View {
        Circle()
            .fill(color)
            .scaleEffect(pulsate ? 1.2 : 1.0)
            .onAppear {
                pulsateAnimation()
            }
        }

    private func pulsateAnimation() {
        withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulsate = true
        }
    }
}


//struct VoiceInteractionView_Previews: PreviewProvider {
//    static var previews: some View {
//        VoiceInteractionView()
//    }
//}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}


extension Data {
    init?(hexString: String) {
        let length = hexString.count
        guard length % 2 == 0 else { return nil }

        var data = Data()
        var index = hexString.startIndex

        for _ in 0..<(length / 2) {
            let nextIndex = hexString.index(index, offsetBy: 2)
            if let byte = UInt8(hexString[index..<nextIndex], radix: 16) {
                data.append(byte)
            } else {
                return nil
            }
            index = nextIndex
        }

        self = data
    }
}
