//
//  LaunchView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/7/30.
//

import SwiftUI

struct LaunchView: View {
    @EnvironmentObject var store: Store
    var body: some View {
        ZStack{
            Image("launch_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            VStack(spacing: 180){
                Image("launch_title")
                VStack{
                    Image("launch_subtitle")
                    HStack{
                        if #available(iOS 15.0, *) {
                            ProgressView(value: store.state.launch.progress)
                                .background(Color.white                                .cornerRadius(4))
                                .tint(Color(hex: 0x635FFF))
                        } else {
                            ProgressView(value: store.state.launch.progress)
                                .background(Color.white                                .cornerRadius(4))
                                .accentColor(Color(hex: 0x635FFF))
                        }
                    }
                    .padding(.horizontal, 80)
                }
            }
        }
    }
}

struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchView().environmentObject(Store())
    }
}
