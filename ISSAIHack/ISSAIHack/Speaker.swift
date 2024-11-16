import UIKit
import SwiftUI
import Lottie

struct VoiceInteractionView: View {
    private let lottieAnimationName = "abay.mp4.lottie"
    @StateObject private var service = SpeechToBase64Service()
    @State private var apiResult: String = "" // State to store the API result
    @State private var isLoading: Bool = false // State to show loading status
    let soyleAPI = SoyleAPI()
    
    var body: some View {
        VStack {
            // Lottie Animation
            LottieView(animationName: lottieAnimationName, isPlaying: $service.isRecording)

            // Button to start/stop recording
            Button(action: handleMicTap) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .padding(40)
                    .background(
                        ZStack {
                            if service.isRecording {
                                PulsatingCircle(color: Color.red)
                            } else {
                                Circle()
                                    .fill(Color.blue)
                            }
                        }
                    )
            }
            .padding(.top, 50)
            
            // New Button to Test API Call Directly
            
            // Loading Indicator
            if isLoading {
                ProgressView("Processing...")
                    .padding()
            }
            
            // API Result
            if !apiResult.isEmpty {
                Text("API Response:")
                    .font(.headline)
                    .padding(.top, 20)
                Text(apiResult)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.purple]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
        )
        .onDisappear {
            service.stopRecording()
        }
        .onReceive(service.$base64Audio) { base64Audio in
            if !base64Audio.isEmpty {
                processAudio(base64Audio: base64Audio)
            }
        }
    }
    
    private func handleMicTap() {
        if service.isRecording {
            service.stopRecording()
        } else {
            service.startRecording()
        }
    }
    
    private func processAudio(base64Audio: String) {
        soyleAPI.checkAPI()
        isLoading = true
        soyleAPI.translateAudio(
            targetLanguage: "eng",
            audioBase64: base64Audio
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    apiResult = response
                case .failure(let error):
                    apiResult = "Error: \(error.localizedDescription)"
                }
            }
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
            .onDisappear {
                pulsate = false
            }
    }
    
    private func pulsateAnimation() {
        withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulsate = true
        }
    }
}
