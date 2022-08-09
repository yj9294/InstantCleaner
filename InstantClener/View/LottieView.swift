//
//  LottieView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/8/5.
//

import Foundation
import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    init(_ animationView: AnimationView) {
        self.animationView = animationView
    }
    let animationView: AnimationView
    func makeUIView(context: UIViewRepresentableContext<LottieView>) -> UIView {
        let view = UIView(frame: .zero)
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<LottieView>) {
        
    }
}

class LottieViewModel: NSObject {
    let name: String
    let loopMode: LottieLoopMode
    let animationView: AnimationView
    init(name: String, loopModel: LottieLoopMode, animationView: AnimationView) {
        self.name = name
        self.loopMode = loopModel
        self.animationView = animationView
        self.animationView.animation = Animation.named(name)
        self.animationView.contentMode = .scaleAspectFit
        self.animationView.loopMode = loopMode
    }
}
