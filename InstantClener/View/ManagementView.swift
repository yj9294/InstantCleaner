//
//  SmarkResultView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/7/31.
//

import SwiftUI

struct ManagementView: View {
    @EnvironmentObject var store: Store
    
    var event: AppState.PhotoManagement.Event
    
    var icon: String {
        switch self.event {
        case .smart:
            return "smart_management"
        case .photo:
            return "photo_management"
        case .video:
            return "video_management"
        default:
            return ""
        }
    }
    
    var disk: UInt64 {
        switch event {
        case .smart:
            return store.state.photoManagement.smartDisk
        case .photo:
            return store.state.photoManagement.photoDisk
        case .video:
            return store.state.photoManagement.videoDisk
        default:
            return 0
        }
    }
    
    var items: [ItemView] {
        AppState.PhotoManagement.Point.allCases.filter {
            switch event {
            case .photo:
                return $0.isPhoto
            case .video:
                return $0.isVideo
            default:
                return true
            }
        }.map {
            ItemView(point: $0)
        }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            /// 滚动视图
            ScrollView(showsIndicators: false){
                VStack{
                    // 头部视图
                    HStack{
                        Image(icon)
                        VStack(alignment: .leading, spacing: 5){
                            Text("Phone Storage used")
                                .font(.footnote)
                                .foregroundColor(Color(hex: 0xffffff, alpha: 0.5))
                            HStack(alignment: .bottom){
                                Text(disk.format.0)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.white)
                                Text(disk.format.1)
                                    .foregroundColor(Color.white)
                                    .padding(.bottom, 5)
                            }
                        }
                        Spacer()
                    }
                    .frame(height: 132)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(colors: [Color(hex: 0x2088FF), Color(hex: 0x7A40FD)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    )
                    
                    /// 列表视图
                    LazyVGrid(columns: [GridItem(.flexible())]){
                        ForEach(0..<items.count, id: \.self) { index in
                            Button {
                                store.dispatch(.adDisapear(.native))
                                
                                store.dispatch(.photoPush)
                                store.dispatch(.photoPushSubView(items[index].point))
                            } label: {
                                items[index]
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
            }
            /// 广告视图
            NativeView(model: store.state.home.adModel)
                .padding(.horizontal, 20)
                .frame(height: 68)
        }
        .padding(.bottom, 8)
        .background(Color(hex: 0xE2F3FF).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    if store.state.photoManagement.push {
                        store.state.photoManagement.push = false

                        store.dispatch(.adLoad(.native))
                    } else {
                        store.dispatch(.rootShowManageView(false))
                        store.dispatch(.navigationTitle("Instant Cleaner"))

                        store.dispatch(.photoStopLoad)
                        store.dispatch(.homeStartScanAnimation)
                        store.dispatch(.logEvent(.homeShow))
                        store.dispatch(.logEvent(.homeScan))
                       
                        store.dispatch(.adDisapear(.native))
                        
                        store.dispatch(.adLoad(.native))
                        store.dispatch(.adLoad(.interstitial))
                    }
                }, label: {
                    Image("arrow_left")
                })
            }
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            /// 数据源
            store.dispatch(.photoDisplayLoad(store.state.photoManagement.loadModel))
        }
    }
    
    struct ItemView: View{
        var point: AppState.PhotoManagement.Point
        var body: some View {
            VStack {
                HStack(spacing: 12){
                    Image(point.title)
                    VStack(alignment:.leading){
                        Text(point.title)
                            .foregroundColor(Color(hex: 0x232936))
                        Text(point.subTitle)
                            .font(.footnote)
                            .foregroundColor(Color(hex: 0x74797F))
                            .lineLimit(1)
                    }
                    Spacer()
                    Image("arrow_right")
                }
                .frame(height: 60)
                Divider()
                    .padding(.leading, 40)
            }
        }
    }
}
