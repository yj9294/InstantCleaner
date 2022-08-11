//
//  SpeedView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/8/4.
//

import Foundation
import SwiftUI

struct SpeedView: View {
    @EnvironmentObject var store: Store
    @Environment(\.presentationMode) var presentationModel
    var speed: AppState.Speed {
        store.state.speed
    }
    
    var body: some View {
        ZStack{
            VStack{
                ZStack{
                    LottieView(store.state.animation.testingModel.animationView)
                        .frame(height: 180)
                    VStack(alignment: .leading,spacing: 3){
                        HStack{
                            Text("IP: " + speed.ip)
                                .font(.system(size: 15))
                                .foregroundColor(Color.white)
                            Spacer()
                        }
                        Text(speed.country)
                            .foregroundColor(Color.white)
                            .font(.system(size: 11))
                        Spacer()
                    }
                    .padding([.leading, .vertical], 16)
                }
                .padding([.leading, .vertical], 16)
                .padding(.top, 16)
                .frame(height: 212)
                
                ScrollView (showsIndicators: false){
                    ItemView(style:.download, speed: speed.download.format.0, speedUnit: speed.download.format.1 + "ps")
                    Divider()
                        .padding(.leading, 60)
                    ItemView(style:.upload, speed: speed.upload.format.0, speedUnit: speed.upload.format.1 + "ps")
                    Divider()
                        .padding(.leading, 60)
                    ItemView(style:.ping, speed: speed.ping, speedUnit: "ms")
                    Divider()
                        .padding(.leading, 60)
                }
                
                NativeView(model: store.state.home.adModel)
                    .frame(height: 68)
        
                Spacer()
                // 按钮
                Button {
                    buttonAction()
                } label: {
                    VStack(spacing: 3){
                        Text(store.state.speed.status.title)
                            .foregroundColor(Color.white)
                        if store.state.speed.status == .tested {
                            Text("Speed ​​test completed")
                                .foregroundColor(Color(hex: 0xFFFFFF, alpha: 0.7))
                                .font(.system(size: 11))
                        }
                    }
                    .frame(width: 263, height: 56)
                }
                .background(RoundedRectangle(cornerRadius: 28).fill(.linearGradient(colors: [Color(hex: 0x2088FF), Color(hex: 0x7A40FD)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                .padding(.bottom, 16)

            }
            .padding(.horizontal, 16)
            
        }
        .onDisappear(perform: {
            store.dispatch(.speedStopTest)
            store.dispatch(.speedStatus(.normal))
        })
        .background(RoundedRectangle(cornerRadius: 0).fill(
            .linearGradient(colors: [Color(hex: 0xE2F3FF), Color(hex: 0xF8FEFF)], startPoint: .topLeading, endPoint: .bottomTrailing)
        ))
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    store.dispatch(.speedPing("0"))
                    store.dispatch(.speedUpload(0))
                    store.dispatch(.speedDownload(0))
                    
                    store.state.home.isPushView = false
                
                    store.dispatch(.adDisapear(.native))
                    store.dispatch(.adLoad(.interstitial))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        store.dispatch(.adLoad(.native))
                    }
                }, label: {
                    Image("arrow_left")
                })
            }
        })
        .navigationTitle("Speed")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(false)
    }
    
    struct ItemView: View {
        let style: Style
        let speed: String
        let speedUnit: String
        enum Style: String {
            case download, upload, ping
            var title: String {
                switch self {
                case .download:
                    return "Download"
                case .upload:
                    return "Upload"
                case .ping:
                    return "PING"
                }
            }
        }
        var body: some View {
            HStack{
                HStack(spacing: 12){
                    Image(style.rawValue)
                        .resizable()
                        .frame(width: 32, height: 32)
                    Text(style.title)
                        .foregroundColor(Color(hex: 0x232936))
                        .font(.system(size: 15))
                }
                Spacer()
                HStack(spacing: 0){
                    Text(speed)
                        .font(.system(size: 21))
                        .foregroundColor(Color(hex: 0x232936))
                    Text(speedUnit)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: 0x74797F))
                }
            }
            .padding(.vertical,20)
        }
    }
}

extension SpeedView {
    func buttonAction() {
        switch store.state.speed.status {
        case .normal:
            store.dispatch(.speedStartTest)
            store.dispatch(.speedStatus(.testing))
        case .tested:
            store.dispatch(.speedStartTest)
            store.dispatch(.speedStatus(.testing))
        case .testing:
            store.dispatch(.speedStopTest)
            store.dispatch(.speedPing("0"))
            store.dispatch(.speedUpload(0))
            store.dispatch(.speedDownload(0))
            store.dispatch(.speedStatus(.normal))
        }
    }
}
