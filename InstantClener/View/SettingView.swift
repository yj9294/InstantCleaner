//
//  SettingView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/7/30.
//

import SwiftUI

struct SettingView: View {
    @State var isPresentShare = false
    var body: some View {
        VStack{
            NavigationLink {
                PrivacyView()
            } label: {
                ItemView(title: "Privacy Policy")
            }
            
            NavigationLink {
                TermsView()
            } label: {
                ItemView(title: "Terms of Users")
            }

            Button {
                shareAction()
            } label: {
                ItemView(title: "Share with friends")
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(.linearGradient(colors: [Color(hex: 0xE2F3FF), Color(hex: 0xF8FEFF)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .ignoresSafeArea()
        )
        .sheet(isPresented: $isPresentShare) {
            ShareSheetView(activityItems:["https://itunes.apple.com/cn/app/id"])
        }
    }
    
    struct ItemView: View {
        let title: String
        var body: some View {
            HStack{
                Text(title)
                    .foregroundColor(Color(hex: 0x232936))
                    .font(.system(size: 15))
                Spacer()
                Image("arrow_right")
            }.padding(.vertical, 22)
        }
    }
}

extension SettingView {
//    func privacyAction() {
//
//    }
//
//    func termsAction() {
//
//    }
//
    func shareAction() {
        isPresentShare = true
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}
