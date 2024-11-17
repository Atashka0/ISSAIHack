import Foundation
import SwiftUI
import SDWebImageSwiftUI
import AVFoundation


struct VoiceInteractionView: View {
    let character: Character
    @StateObject private var speechService = AudioService()
    @State private var translatedText: String = ""
    @Environment(\.presentationMode) var presentationMode
    @State private var isProcessing: Bool = false
    @State private var responseContent: String = ""
    @State private var audioPlayer: AVAudioPlayer?
    @State private var displayedContent: String = ""
    @State private var timer: Timer? = nil
    
    private let lottieAnimationName: String = "abay.mp4.lottie"
    private let gifURL = URL(string: "https://resource2.heygen.ai/video/gifs/82c311f7b05d467a9df1c2bd66531b40.gif")!
    let kazLLMAPI = KazLLMAPI()
    let soyleAPI = SoyleAPI()
   
    var body: some View {
            ZStack {
                Image("soyleWallpaper")
                    .resizable()
                    .scaledToFill()
                    .frame(height: UIScreen.main.bounds.height + 50)
                    .ignoresSafeArea()
                    .ignoresSafeArea()
                VStack {
                    // Main content
                    Spacer()
                    Spacer()
                    AnimatedImage(url: URL(string: character.gifUrl), isAnimating: $speechService.isPlaying)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 300)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.black, lineWidth: 4))
                        .shadow(radius: 10)
                    Spacer()
                    ScrollView {
                        Text(displayedContent)
                            .font(.title3)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity) // Allow text to take full width
                    }
                    .frame(height: 150) // Limit the height of the text view
                    .background(Color.black.opacity(0.3)) // Optional background for contrast
                    .cornerRadius(10)
                    .padding(.horizontal)

                    Spacer()

                    Button(action: handleMicTap) {
                        Image(systemName: speechService.isRecording ? "mic.fill" : "mic.slash.fill")
                            .font(.system(size: 50))
                            .foregroundColor(speechService.isRecording ? .black : .white)
                            .padding(40)
                            .background(speechService.isRecording ? Color.white : Color.black)
                            .clipShape(Circle())
                    }
                    .padding(.top, 50)
                    Spacer()
                }
                .padding()
                .onReceive(speechService.$base64Audio) { base64Audio in
                    if !base64Audio.isEmpty {
                        processAudio(base64Audio: base64Audio)
                    }
                }
                .onDisappear {
                    speechService.stopRecording()
                }

                // Custom Back Button
                VStack {
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss() // Dismiss the current view
                        }) {
                            ZStack {
                                Image("woodBackground") // Use the custom background image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .cornerRadius(8)

                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                        }
                        .padding([.top, .leading], 60)
                        .padding(.top, 40)

                        Spacer()
                    }
                    Spacer()
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    
    private func processAudio(base64Audio: String) {
            isProcessing = true
            translatedText = ""
            
            // Translate the audio to text
            print("PROCESSED AUDIO")
            soyleAPI.translateAudio(targetLanguage: "kaz", audioBase64: base64Audio) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let text):
                        print("PROCESSED AUDIO")
                        self.createInteractionWithKazLLM(text: text)
                    case .failure(let error):
                        self.isProcessing = false
                        self.translatedText = "Error translating audio: \(error.localizedDescription)"
                    }
                }
            }
        }
    
    private func createInteractionWithKazLLM(text: String) {
            
        kazLLMAPI.createInteraction(assistantID: character.externalId, textPrompt: text + " бір сөзбен жауап бер") { interactionResult in
            DispatchQueue.main.async {
                switch interactionResult {
                case .success(let interactionResponse):
                    self.responseContent = interactionResponse.vllmResponse.content
                    self.displayContentLetterByLetter()
                    self.synthesizeResponse(interactionResponse.vllmResponse.content)
                case .failure(let error):
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func displayContentLetterByLetter() {
        displayedContent = "" // Reset the displayed content
        timer?.invalidate() // Cancel any existing timer
        var currentIndex = 0

        timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            if currentIndex < self.responseContent.count {
                let index = self.responseContent.index(self.responseContent.startIndex, offsetBy: currentIndex)
                self.displayedContent.append(self.responseContent[index])
                currentIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func synthesizeResponse(_ string: String) {
        print("UNICODE")
        print(string)
        soyleAPI.translateText(sourceLanguage: "kaz", targetLanguage: "kaz", text: string, gender: character.gender) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let audioBase16):
                    if let audioData = Data(hexString: audioBase16) {
                        print("got Base16")
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
            speechService.playAudio(fromBase64: base64)
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
