//
//  CompressionView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/8/4.
//

import Foundation
import SwiftUI

struct CompressionView: View {
    @EnvironmentObject var store: Store
    @Environment(\.presentationMode) var presentationModel
    var body: some View {
        ZStack{
            VStack(spacing: 16){
                VStack(spacing: 14){
                    Image("compression_icon")
                    Text("Photos Compression Done")
                        .foregroundColor(Color.white)
                        .font(.system(size: 15))
                }
                .padding(.vertical, 40)
                .background(Image("compression_bg"))
                VStack{
                    Text("A total of ")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: 0x2E3648))
                    + Text("\(store.state.compression.images.count)")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(Color(hex: 0x2E3648))
                    + Text(" photo(s) were compressed this time, saving a total of ")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: 0x2E3648))
                    + Text(store.state.compression.size.format.0 + store.state.compression.size.format.1)
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(Color(hex: 0x2E3648))
                    + Text(" of space")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: 0x2E3648))
                }
                .padding(.top, 16)
                .padding(.horizontal, 30)

                VStack{
                    NativeView(model: store.state.home.adModel)
                        .frame(height: 68)
                }
                .padding(.top, 100)
                .padding(.horizontal, 20)

                
                Spacer()
                // 按钮
                Button {
                    saveAction()
                } label: {
                    Text("Save")
                        .foregroundColor(Color.white)
                        .frame(width: 263, height: 56)
                }
                .background(RoundedRectangle(cornerRadius: 28).fill(.linearGradient(colors: [Color(hex: 0x2088FF), Color(hex: 0x7A40FD)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                .padding(.bottom, 16)
            }
            .padding(.top, 44)
            .padding(.horizontal, 16)
            .background(RoundedRectangle(cornerRadius: 0).fill(
                .linearGradient(colors: [Color(hex: 0xE2F3FF), Color(hex: 0xF8FEFF)], startPoint: .topLeading, endPoint: .bottomTrailing)
            ))
            
        }
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    store.dispatch(.rootShowManageView(false))
                    store.dispatch(.navigationTitle("Instant Cleaner"))

                    /// 返回首页
                    store.dispatch(.adDisapear(.native))
                    store.dispatch(.adLoad(.interstitial))
                    store.dispatch(.adLoad(.native))
                }, label: {
                    Image("arrow_left")
                })
            }
        })
        .navigationTitle("Compression done")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(false)
    }
}

extension CompressionView {
    func saveAction() {
        store.dispatch(.compressStore)
    }
}
