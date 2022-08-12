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
                    store.dispatch(.rootManageView(.smart))
                    store.dispatch(.photoLoad(.smart))
                    store.dispatch(.rootShowLoadingView(true))
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

            
            if store.state.root.isShowLoading  {
                LoadingView()
                    .navigationBarHidden(true)
            }
            
            if store.state.root.isShowImagePicker {
                ImagePickerView { images in
                    store.dispatch(.rootShowImagePickerView(false))
                    if images.count > 0 {
                        if store.state.root.manageEvent == .patch {
                            store.dispatch(.patchImages(images))
                        } else if store.state.root.manageEvent == .compression {
                            store.dispatch(.compression(images))
                            store.dispatch(.adLoad(.native))
                        }
                        store.dispatch(.rootShowManageView(true))
                        
                        store.dispatch(.navigationTitle(store.state.root.manageEvent.title))
                    } else {
                        store.dispatch(.adLoad(.interstitial))
                        store.dispatch(.adLoad(.native))
                    }
                }.navigationBarHidden(true)
            }
            
            if store.state.root.isShowManageView {
                switch store.state.root.manageEvent {
                case .smart, .photo, .video:
                    ManagementView(event: store.state.root.manageEvent)
                case .contact:
                    ContactManageView()
                case .calendar:
                    CalendarView()
                case .patch:
                    PatchView()
                case .speed:
                    SpeedView()
                case .compression:
                    CompressionView()
                }
            }
            
            if store.state.photoManagement.push {
                SimilarPhotoView(point: store.state.photoManagement.pushEvent)
            }
            
            if store.state.contact.push {
                ContactView(point: store.state.contact.pushEvent)
            }
            
            if store.state.root.isShowPhotoPermission {
                PhotoPermissionView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            store.dispatch(.rootShowPhotoPermission(false))
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
