//
//  PatchView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/8/4.
//

import Foundation
import SwiftUI

struct PatchView: View {
    @EnvironmentObject var store: Store
    @Environment(\.presentationMode) var presentationModel
    var dataSource: [UIImage] {
        store.state.patch.images
    }
    
    var direction: AppState.Patch.Point {
        store.state.patch.direction
    }
    
    var body: some View {
        ZStack {
            VStack{
                ScrollView(direction == .vertical ? .vertical : .horizontal, showsIndicators: false) {
                    if direction == .vertical {
                        VStack(spacing: 0){
                            ForEach(0..<dataSource.count, id: \.self){ index in
                                Image(uiImage: dataSource[index])
                                    .resizable()
                                    .scaledToFit()
                                    .background(Color.black)
                            }
                        }
                    } else {
                        HStack(spacing: 0){
                            ForEach(0..<dataSource.count, id: \.self){ index in
                                Image(uiImage: dataSource[index])
                                    .resizable()
                                    .scaledToFit()
                                    .background(Color.black)
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, self.direction == .vertical ? 35 : 0)
                .background(Color(hex: 0xE2F3FF))
                
                // 底部试图
                HStack(spacing: 35){
                    VStack(spacing: 11){
                        Image(store.state.patch.direction == .vertical ? "vertical_selected" : "vertical_normal")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("Vertical Patch")
                            .foregroundColor(store.state.patch.direction == .vertical ? Color(hex: 0x232936) : Color(hex: 0x899092))
                            .font(.system(size: 11))
                    }
                    .onTapGesture {
                        verticalAction()
                    }
                    VStack(spacing: 11){
                        Image(store.state.patch.direction == .horizontal ? "horizontial_selected" : "horizontial_normal")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("Horizontal Patch")
                            .foregroundColor(store.state.patch.direction == .horizontal ? Color(hex: 0x232936) : Color(hex: 0x899092))
                            .font(.system(size: 11))
                    }
                    .onTapGesture {
                        horizontialAction()
                    }
                    Button {
                        saveAction()
                    } label: {
                        Text("Save")
                            .foregroundColor(Color.white)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 22)
                    .background(RoundedRectangle(cornerRadius: 28).fill(.linearGradient(colors: [Color(hex: 0x2088FF), Color(hex: 0x7A40FD)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                }
                .padding(.vertical, 14)
            }
            
        }
        .background(Color(hex: 0xE2F3FF))
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    store.dispatch(.rootShowManageView(false))
                    store.dispatch(.navigationTitle("Instant Cleaner"))

                    store.dispatch(.adDisapear(.native))
                    store.dispatch(.adLoad(.native))
                    store.dispatch(.adLoad(.interstitial))
                }, label: {
                    Image("arrow_left")
                })
            }
        })
        .navigationTitle("Photo Patch")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}

extension PatchView {
    func saveAction() {
        store.dispatch(.patchStore)
    }
    
    func verticalAction() {
        store.dispatch(.patchDirection(.vertical))
    }
    
    func horizontialAction() {
        store.dispatch(.patchDirection(.horizontal))
    }
}
