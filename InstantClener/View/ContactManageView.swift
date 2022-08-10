//
//  ContactManageView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/8/3.
//

import SwiftUI

struct ContactManageView: View {
    @EnvironmentObject var store: Store
    var body: some View {
        VStack{
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16){
                    VStack{
                        // 头部视图
                        HStack{
                            Image("contact_management")
                            VStack(alignment: .leading, spacing: 5){
                                Text("Optimize your")
                                    .font(.footnote)
                                    .foregroundColor(Color(hex: 0xffffff, alpha: 0.5))
                                HStack(alignment: .bottom, spacing: 0){
                                    Text("\(store.state.contact.contacts.count) ")
                                        .font(.system(size: 39))
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.white)
                                    Text("contacts")
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
                    }
                    VStack(alignment:.leading){
                        Text("Duplicate Contact")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: 0x899092))
                        NavigationLink {
                            ContactView(point: .duplicateName)
                        } label: {
                            ItemView(point: .duplicateName)
                        }
                        NavigationLink {
                            ContactView(point: .duplicateNumber)
                        } label: {
                            ItemView(point: .duplicateNumber)
                        }
                    }
                    VStack(alignment:.leading){
                        Text("Incomplete Contact")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: 0x899092))
                        NavigationLink {
                            ContactView(point: .noName)
                        } label: {
                            ItemView(point: .noName)
                        }
                        NavigationLink {
                            ContactView(point: .noNumber)
                        } label: {
                            ItemView(point: .noNumber)
                        }
                    }
                    Spacer()
                }
            }
            NativeView(model: store.state.home.adModel)
                .frame(height: 68)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 30)
        .background(Color(hex: 0xE2F3FF).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    store.dispatch(.loadingPushEvent(false))
                    store.dispatch(.homeStartScanAnimation)
                    store.dispatch(.logEvent(.homeShow))
                    store.dispatch(.logEvent(.homeScan))
                    store.dispatch(.adDisapear(.native))
                    store.dispatch(.homeAdModel(.None))
                }, label: {
                    Image("arrow_left")
                })
            }
        }
        .navigationTitle("Contact Management")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            store.dispatch(.adLoad(.native))
        }
    }
    
    struct ItemView: View{
        var point: AppState.Contact.Point
        var body: some View {
            VStack {
                HStack(spacing: 12){
                    Image(point.rawValue)
                    VStack(alignment:.leading){
                        Text(point.title)
                            .foregroundColor(Color(hex: 0x232936))
                            .font(.system(size: 15))
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
