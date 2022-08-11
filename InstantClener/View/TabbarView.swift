//
//  TabbarView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/7/30.
//

import SwiftUI

struct TabbarView: View {
    @EnvironmentObject var store: Store
    var tabbar: AppState.Tabbar {
        store.state.tabbar
    }
    
    var selection: Binding<AppState.Tabbar.Index> {
        Binding (
            get: { tabbar.selection },
            set: {
                if $0 != AppState.Tabbar.Index.home {
                    store.dispatch(.adDisapear(.native))
                } else {
                    store.dispatch(.adLoad(.native))
                }
                
                if $0 == AppState.Tabbar.Index.clean {
                    store.dispatch(.loadingEvent(.smart))
                    store.dispatch(.photoLoad(.smart))
                    store.dispatch(.presentLoading(true))
                    store.dispatch(.homeStopScanAnimation)
                    return
                }

                store.dispatch(.tabbar($0))
            }
        )
    }
    
    var body: some View {
        ZStack {
            TabView(selection: selection){
                HomeView()
                .tag(AppState.Tabbar.Index.home)
                .tabItem {
                    Item(index: .home, selected: tabbar.selection == .home)
                }
                CleanView()
                    .tag(AppState.Tabbar.Index.clean)
                    .tabItem {
                        Image("cleaner")
                    }
                SettingView()
                .tag(AppState.Tabbar.Index.setting)
                .tabItem {
                    Item(index: .setting, selected: tabbar.selection == .setting)
                }
            }
            .onAppear {
                viewShow()
            }

            
            if store.state.home.isPresentLoading  {
                LoadingView()
                    .navigationBarHidden(true)
            }
            
            
            if store.state.home.isPushView {
                if store.state.home.pushEvent == .patch {
                    PatchView()
                } else if store.state.home.pushEvent == .compression {
                    CompressionView()
                } else if store.state.home.pushEvent == .speed {
                    SpeedView()
                }
            }
            
            if store.state.loading.isPushEvent {
                if store.state.loading.pushEvent == .contact {
                    ContactManageView()
                        .navigationBarHidden(false)
                } else if store.state.loading.pushEvent == .calendar {
                    CalendarView()
                        .navigationBarHidden(false)
                } else {
                    SmarkResultView(event: store.state.loading.pushEvent)
                        .navigationBarHidden(false)
                }
            }
            
            if store.state.home.isPresentImagePicker {
                ImagePickerView { images in
                    store.state.home.isPresentImagePicker = false
                    if images.count > 0 {
                        if store.state.home.pushEvent == .patch {
                            store.dispatch(.patchImages(images))
                        } else if store.state.home.pushEvent == .compression {
                            store.dispatch(.compression(images))
                            store.dispatch(.adLoad(.native))
                        }
                        store.dispatch(.homePush)
                    } else {
                        store.dispatch(.adLoad(.interstitial))
                        store.dispatch(.adLoad(.native))
                    }
                }.navigationBarHidden(true)
            }
            
            if store.state.photoManagement.push {
                SimilarPhotoView(point: store.state.photoManagement.pushEvent)
            }
            
            if store.state.contact.push {
                ContactView(point: store.state.contact.pushEvent)
            }
            
            if store.state.home.isShowPhotoPermission {
                PhotoPermissionView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            store.dispatch(.homeShowPhotoPermission(false))
                        }
                    }
            }
        
            if store.state.root.isAlert {
                AlertView(message: store.state.root.alertMessage)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            store.state.root.isAlert = false
                        }
                    }
            }
            
            if store.state.permission.alert == nil {
                PermissionView {
                    store.dispatch(.permissionAlert)
                }
            }
            
        }
    }
    
    struct Item: View {
        var index: AppState.Tabbar.Index
        var selected: Bool
        var body: some View {
            switch index {
            case .home:
                VStack(spacing: 2) {
                    Image(selected ? "home_selected" : "home_normal")
                    Text("Home")
                        .font(.custom(size: 11, weight: .regular))
                        .foregroundColor(selected ? Color(hex: 0x232936) : Color(hex: 0x899092))
                }
            case .setting:
                VStack(spacing: 2) {
                    Image(selected ? "setting_selected" : "setting_normal")
                    Text("Setting")
                        .font(.custom(size: 11, weight: .regular))
                        .foregroundColor(selected ? Color(hex: 0x232936) : Color(hex: 0x899092))
                }
            case .clean:
                EmptyView()
            }
        }
    }
}

extension TabbarView {
    func viewShow() {
        store.dispatch(.permissionRequest(.photo))
    }
    
    func cleanAction() {
        
    }
}

struct TabbarView_Previews: PreviewProvider {
    static var previews: some View {
        TabbarView()
            .previewDevice("iPhone 8")
            .environmentObject(Store())
    }
}
