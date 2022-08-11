//
//  LoadingView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/7/31.
//

import SwiftUI

struct LoadingView: View {
    @EnvironmentObject var store: Store
    var body: some View {
        ZStack{
            Image("launch_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            VStack(spacing: 84){
                LottieView( store.state.animation.loadingModel.animationView).onAppear {
                    store.state.animation.loadingModel.animationView.play()
                }.frame(width: 300, height: 300)
                VStack(spacing: 12) {
                    HStack(alignment: .bottom, spacing: 0){
                        Text("\(Int(store.state.loading.progress * 100))")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("%")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .padding(.bottom, 5)
                    }
                    Text("Smart Scanning...")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: 0x232936))
                }
            }
        }
        .onAppear {
            viewShow()
        }
    }
}

extension LoadingView {
    func viewShow() {
//        store.dispatch(.loadingStart)
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
