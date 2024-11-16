//
//  Speaker.swift
//  ISSAIHack
//
//  Created by Abrorbek on 16.11.2024.
//

import UIKit
import SwiftUI
import Lottie

struct VoiceInteractionView: View {
    private let lottieAnimationName = "abay.mp4.lottie"
    @StateObject private var service = SpeechToBase64Service()

    var body: some View {
        VStack {
            LottieView(animationName: lottieAnimationName, isPlaying: $service.isRecording)

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
                // Handle the Base64 audio string (e.g., send to a server or process further)
                print("Received Base64 Audio: \(base64Audio)")
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


struct VoiceInteractionView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceInteractionView()
    }
}

