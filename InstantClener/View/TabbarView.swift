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
                    store.dispatch(.homeAdModel(.None))
                }
                
                if $0 == AppState.Tabbar.Index.clean {
                    store.dispatch(.loadingEvent(.smart))
                    store.dispatch(.photoLoad(.smart))
                    store.dispatch(.tabbarPushLoading(true))
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
            
            if store.state.home.isPushView {
                NavigationLink(isActive: $store.state.home.isPushView) {
                    if store.state.home.pushEvent == .patch {
                        PatchView()
                    } else if store.state.home.pushEvent == .compression {
                        CompressionView()
                    } else {
                        EmptyView()
                    }
                } label: {
                    EmptyView()
                }
            }
            
            if store.state.tabbar.isPushLoading {
                NavigationLink(isActive: $store.state.tabbar.isPushLoading) {
                    LoadingView()
                        .navigationBarBackButtonHidden(true)
                } label: {
                    EmptyView()
                }
            }
            
            if store.state.loading.isPushEvent {
                NavigationLink(isActive: $store.state.loading.isPushEvent) {
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
                } label: {
                    EmptyView()
                }
            }

            
            if store.state.permission.alert == nil {
                PermissionView {
                    store.dispatch(.permissionAlert)
                }
            }
            
            if store.state.home.isShowPhotoPermission {
                PhotoPermissionView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            store.dispatch(.homeShowPhotoPermission(false))
                        }
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
