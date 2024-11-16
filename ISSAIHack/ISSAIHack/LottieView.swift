//
//  LottieView.swift
//  ISSAIHack
//
//  Created by Abrorbek on 16.11.2024.
//

import SwiftUI
import UIKit
import Lottie

struct LottieView: UIViewRepresentable {
    var animationName: String
    @Binding var isPlaying: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        // Initialize the animation view
        let animationView = LottieAnimationView()
        animationView.animation = LottieAnimation.named(animationName)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the animation view to the main view
        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Store the animation view in the context's coordinator
        context.coordinator.animationView = animationView
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let animationView = context.coordinator.animationView else { return }
        
        if isPlaying {
            animationView.play()
        } else {
            animationView.stop()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var animationView: LottieAnimationView?
    }
}

