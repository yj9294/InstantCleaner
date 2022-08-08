//
//  RootView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/7/30.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: Store
    var body: some View {
        TabView(selection: $store.state.root.selection) {
            /// 启动页
            LaunchView()
                .tag(AppState.Root.Index.launch)
                .hiddenTabBar()
            /// 主页
            NavigationView{
                TabbarView()
            }
                .tag(AppState.Root.Index.tab)
                .preferredColorScheme(.light)
                .hiddenTabBar()
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            /// 前台
            store.dispatch(.logEvent(.openHot))
            store.dispatch(.rootBackgrund(false))
            store.dispatch(.launchBegin)
            store.dispatch(.adRequestConfig)
            
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            /// 后台
            store.dispatch(.rootBackgrund(true))
        }
    }
}
