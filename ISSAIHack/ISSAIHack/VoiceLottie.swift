//
//  VoiceLottie.swift
//  ISSAIHack
//
//  Created by Abrorbek on 17.11.2024.
//

import SwiftUI
import AVFAudio
import SDWebImageSwiftUI
import Lottie

struct VoiceInteractionViewLottie: View {
    @StateObject private var speechService = AudioService()
    @State private var translatedText: String = ""
    @Environment(\.presentationMode) var presentationMode
    @State private var isProcessing: Bool = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var displayedContent: String = ""
    @State private var responseContent: String = ""
    @State private var timer: Timer? = nil
    
    let lottieAnimationName: String
    let kazLLMAPI = KazLLMAPI()
    let soyleAPI = SoyleAPI()
   
    var body: some View {
            ZStack {
                Image("wall")
                    .resizable()
                    .scaledToFill()
                    .frame(height: UIScreen.main.bounds.height + 50)
                    .ignoresSafeArea()
                    .ignoresSafeArea()
                VStack {
                    // Main content
                    Spacer()
                    
                    LottieView(animationName: lottieAnimationName, isPlaying: $speechService.isPlaying)
                        .scaledToFill()
                        .frame(width: 300, height: 300)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.black, lineWidth: 4))
                        .shadow(radius: 10)
                        .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    ScrollView {
                        Text(displayedContent)
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            .frame(width: 350, height: 150)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(10)

                    Spacer()

                    Button(action: handleMicTap) {
                        Image(systemName: speechService.isRecording ? "mic.fill" : "mic.slash.fill")
                            .font(.system(size: 50))
                            .foregroundColor(speechService.isRecording ? .black : .white)
                            .padding(40)
                            .background(speechService.isRecording ? Color.white : Color.black)
                            .clipShape(Circle())
                    }
                    .scaleEffect( speechService.isRecording ? 1.1 : 1.0) // Scale effect for pulsating
                    .animation(
                        Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: speechService.isRecording
                    )
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
                                Rectangle()
                                    .fill(Color.gray.opacity(0.8))
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        ZStack {
                            // Rectangle background
                            Rectangle()
                                .fill(Color.black.opacity(0.8))
                                .frame(width: 40, height: 40)
                                .cornerRadius(8)

                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .font(.headline)
                        }
                    }
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
            let assistantID = 84
            
            kazLLMAPI.createInteraction(assistantID: assistantID, textPrompt: text + " бір сөзбен жауап бер") { interactionResult in
                DispatchQueue.main.async {
                    switch interactionResult {
                    case .success(let interactionResponse):
                        print("CREATED INTERACTION")
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
        soyleAPI.translateText(sourceLanguage: "kaz", targetLanguage: "kaz", text: string, gender: "male") { result in
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
