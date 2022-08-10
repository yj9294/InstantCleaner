//
//  HomeView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/7/30.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: Store
    var body: some View {
        ScrollView(showsIndicators: false){
            VStack(alignment:.leading, spacing: 15){
                TopView()
                NativeView(model: store.state.home.adModel)
                    .frame(height: 68)
                CenterView()
                BottomView()
            }
            .padding(.top, 15)
            .padding(.horizontal, 24)
        }
        .padding(.bottom,1)
        .background(Color(hex: 0xE2F3FF)
            .ignoresSafeArea()
        )
        .sheet(isPresented: $store.state.home.isPresentImagePicker) {
            NavigationView {
                ImagePickerView { images in
                    if store.state.home.pushEvent == .patch {
                        store.dispatch(.patchImages(images))
                    } else if store.state.home.pushEvent == .compression {
                        store.dispatch(.compression(images))
                    }
                    store.dispatch(.homePush)
                }.navigationBarHidden(true)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification), perform: { _ in
            store.state.animation.scanModel.animationView.play()
        })
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            store.dispatch(.adDisapear(.native))
            store.dispatch(.homeAdModel(.None))
        }
        .navigationTitle("Instant Cleaner")
        .onAppear {
            showView()
        }
        .onDisappear {
            hideView()
        }
    }
    
    struct TopView: View {
        @EnvironmentObject var store: Store
        var memoryLayoutIsLeading: Bool {
            store.state.home.radio >= 0.5
        }
        var body: some View {
            VStack {
                VStack(alignment:.leading, spacing: 8){
                    HStack{
                        Text("Phone Storage")
                        Spacer()
                    }
                    
                    // 内存
                    GeometryReader { metrics in
                        ZStack(alignment: .leading){
                            RoundedRectangle(cornerRadius: 12).fill(
                                Color(hex: 0xDDFBFD)
                            )
                            
                            RoundedCorners(tl: 12, tr: 0, bl: 12, br: 0)
                                .fill(
                                    LinearGradient(colors: [Color(hex: memoryLayoutIsLeading ? 0xFFB233 : 0x225FFF ), Color(hex: memoryLayoutIsLeading ? 0xFF5022 : 0x34E8FF)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .frame(width: metrics.size.width * store.state.home.progress)
                            
                            VStack(alignment: memoryLayoutIsLeading ? .leading : .trailing, spacing: 5){
                                HStack( alignment: .bottom, spacing:0){
                                    if !memoryLayoutIsLeading {
                                        Spacer()
                                    }
                                    Text("\(Int(store.state.home.progress * 100))")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(memoryLayoutIsLeading ? .white : Color(hex: 0x3286FF))
                                    Text("%")
                                        .foregroundColor(memoryLayoutIsLeading ? .white : Color(hex: 0x3286FF))
                                    if memoryLayoutIsLeading {
                                        Spacer()
                                    }
                                }
                                Text("used")
                                    .font(.footnote)
                                    .foregroundColor(memoryLayoutIsLeading ? .white : Color(hex: 0x3B3B3B))
                                Text("\(store.state.home.usedDisk)/\(store.state.home.totalDisk)")
                                    .font(.footnote)
                                    .foregroundColor(memoryLayoutIsLeading ? .white : Color(hex: 0x3B3B3B))
                            }
                            .padding(.vertical, 13)
                            .padding(.horizontal, 16)
                        }
                    }
                    .frame(height: 116)

                    
                    NavigationLink {
                        LoadingView()
                            .navigationBarBackButtonHidden(true)
                    } label: {
                        HStack{
                            Text("One-Click Smart Scan")
                                .foregroundColor(Color.white)
                            Spacer()
                            LottieView(store.state.animation.scanModel.animationView)
                                .frame(width: 24, height: 24)
                                .onAppear {
                                    store.state.animation.scanModel.animationView.play()
                                }
                        }
                    }
                    .simultaneousGesture(TapGesture().onEnded({ _ in
                        smartClean()
                    }))
                    .padding(.vertical, 19)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(colors: [Color(hex: 0x2088FF), Color(hex: 0x7A40FD)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    )
                    
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        }
    }
    
    struct CenterView: View {
        @EnvironmentObject var store: Store
        var body: some View {
            let colums = [GridItem(.flexible()), GridItem(.flexible())]
            let items: [Item] = Item.Style.allCases.compactMap {
                Item(style: $0)
            }.filter{
                !$0.style.isSmall
            }
            LazyVGrid(columns: colums) {
                ForEach(0..<items.count, id: \.self) { index in
                    if index == 0 {
                        /// photo
                        NavigationLink {
                            LoadingView()
                                .navigationBarBackButtonHidden(true)
                        } label: {
                            items[index]
                        }.simultaneousGesture(TapGesture().onEnded({ _ in
                            photoAction()
                        }))
                    } else if index == 1 {
                        NavigationLink {
                            LoadingView()
                                .navigationBarBackButtonHidden(true)
                        } label: {
                            items[index]
                        }.simultaneousGesture(TapGesture().onEnded({ _ in
                            videoAction()
                        }))
                    } else {
                        Button {
                            didSelectItem(style: items[index].style)
                        } label: {
                            items[index]
                        }
                    }
                }
            }.padding(.top, 8)
        }
        struct Item: View{
            var style: Style
            enum Style: String, CaseIterable {
                case photo, video, contact, calendar, patch, speed, compression
                var isSmall: Bool {
                    switch self {
                    case .patch, .speed, .compression:
                        return true
                    default:
                        return false
                    }
                }
                var title: String {
                    return paraseTitle().0
                }
                var subTitle: String {
                    return paraseTitle().1
                }
                func paraseTitle() -> (String, String) {
                    switch self {
                    case .photo:
                        return ("Photo Management", "Quickly manage and optimize your photos")
                    case .video:
                        return ("Video Management", "Quickly manage and optimize your videos")
                    case .contact:
                        return ("Contact Management","Optimize your contacts")
                    case .calendar:
                        return ("Calendar Management", "Quickly clean up your schedule")
                    case .patch:
                        return ("Photo Patch", "")
                    case .speed:
                        return ("Speed Test", "")
                    case .compression:
                        return ("Compression", "")
                    }
                }
            }
            var body: some View{
                if style.isSmall {
                    VStack(spacing: 6){
                        Image(style.rawValue)
                        Text(style.title)
                            .font(.footnote)
                            .foregroundColor(Color(hex: 0x232936))
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
                    .frame(width: 100, height: 100)
                } else {
                    VStack(alignment: .leading , spacing: 6){
                        Image(style.rawValue)
                            .padding(.leading, -16)
                        Text(style.title)
                            .font(.headline)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(Color(hex: 0x232936))
                        Text(style.subTitle)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(Color(hex: 0x74797F))
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .frame(width: 156.0)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .padding(.top, 28)
                    )
                }
            }
        }
    }
    
    struct BottomView: View {
        @EnvironmentObject var store: Store
        var body: some View {
            HStack {
                Button(action: patchAction, label: {
                    CenterView.Item(style: .patch)
                })
                Spacer()
                NavigationLink {
                    SpeedView()
                } label: {
                    CenterView.Item(style: .speed)
                }

                Spacer()
                Button(action: compressionAction) {
                    CenterView.Item(style: .compression)
                }
            }
            .padding(.bottom, 20)
        }
    }
}

extension HomeView {
    func showView() {
        store.dispatch(.homeStartScanAnimation)
        store.dispatch(.logEvent(.homeShow))
        store.dispatch(.logEvent(.homeScan))
                
        store.dispatch(.adLoad(.interstitial))
        store.dispatch(.adDisapear(.native))
        store.dispatch(.adLoad(.native) { adModel in
            store.dispatch(.homeAdModel(adModel))
        })
    }
    
    func hideView() {
        store.dispatch(.homeStopScanAnimation)
    }
    
}

extension HomeView.TopView {
    func smartClean() {
        store.dispatch(.loadingEvent(.smart))
        store.dispatch(.photoLoad(.smart))
        store.dispatch(.loadingPresent(true))
        store.dispatch(.homeStopScanAnimation)
        store.dispatch(.logEvent(.homeClickSmart))
        store.dispatch(.logEvent(.scanStart))
    }
}

extension HomeView.CenterView {
    func didSelectItem(style: HomeView.CenterView.Item.Style) {
        if style == .contact {
            contactAction()
        } else if style == .photo {
            photoAction()
        } else if style == .video {
            videoAction()
        } else if style == .calendar {
            calendarAction()
        }
    }
    
    func contactAction() {
        store.dispatch(.logEvent(.scanStart))
        store.dispatch(.logEvent(.homeContactClick))
        store.dispatch(.permissionRequest(.contact))
        if store.state.permission.contactStatus == .notDetermined {
            return
        }
        
        store.dispatch(.loadingEvent(.contact))
        store.dispatch(.loadingStart)
        store.dispatch(.contactLoad)
        store.dispatch(.loadingPresent(true))
        store.dispatch(.homeStopScanAnimation)
        
    }
    
    func calendarAction() {
        store.dispatch(.logEvent(.scanStart))
        store.dispatch(.permissionRequest(.calendar))
        if store.state.permission.calendarStatis == .notDetermined {
            return
        }
        
        store.dispatch(.loadingEvent(.calendar))
        store.dispatch(.loadingStart)
        store.dispatch(.calendarLoad)
        store.dispatch(.loadingPresent(true))
        store.dispatch(.homeStopScanAnimation)
    }
    
    func photoAction() {

        store.dispatch(.loadingEvent(.photo))
        store.dispatch(.photoLoad(.photo))
        store.dispatch(.loadingPresent(true))
        store.dispatch(.homeStopScanAnimation)
        store.dispatch(.logEvent(.homePhotoClick))
        store.dispatch(.logEvent(.scanStart))
    }
    
    func videoAction() {

        store.dispatch(.loadingEvent(.video))
        store.dispatch(.photoLoad(.video))
        store.dispatch(.loadingPresent(true))
        store.dispatch(.homeStopScanAnimation)
        store.dispatch(.logEvent(.homeVideoClick))
        store.dispatch(.logEvent(.scanStart))
    }
}

extension HomeView.BottomView {
    func patchAction() {
        if store.state.permission.photoStatus == .denied {
            store.dispatch(.homeShowPhotoPermission(true))
            return
        }
        store.dispatch(.homePushEvent(.patch))
        store.dispatch(.presentImagePicker)
    }

    func compressionAction() {
        if store.state.permission.photoStatus == .denied {
            store.dispatch(.homeShowPhotoPermission(true))
            return
        }
        store.dispatch(.homePushEvent(.compression))
        store.dispatch(.presentImagePicker)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
