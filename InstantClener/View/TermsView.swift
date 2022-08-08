//
//  TermsView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/8/5.
//

import Foundation
import SwiftUI

struct TermsView: View {
    @Environment(\.presentationMode) var presentationModel
    
    var body: some View {
        ScrollView {
            Text("""
                 These Terms of Service ("Terms") and our Privacy Policy govern your use of all available services and apps, so please read them carefully before using the app.

                 By using our app, you agree to be bound by these terms. If you do not agree to these terms, please do not use. If you use the application on behalf of an organization (such as your employer), you agree to these terms of that organization and you have the right to bind that organization to these terms. In this context, "you" and "your" will refer to the organization.



                 Use of data

                 You agree that the application provider may collect and use technical data and related information, including but not limited to periodically collected technical information about your device, system and application software, and peripherals in order to provide software updates, product support and other services provided to you in connection with the application.

                 Application providers may use the information we collect, but in a form that does not personally identify you, to improve their products or provide you with services or technology.



                 Terms Update

                 We may revise the Terms from time to time. Changes may be posted to our app, so please check back regularly. The latest version will always be posted on our terms page. If you continue to use our services after the modification takes effect, you agree to be bound by the modified terms. If you do not agree to the new terms, please discontinue use.



                 Neither we nor any third party provide any warranty or guarantee as to the accuracy, timeliness, performance, completeness or suitability of the information and materials found or provided on this website for any particular purpose. You acknowledge that such information and materials may contain inaccuracies or errors, and we expressly exclude liability for any such inaccuracies or errors to the fullest extent permitted by law.
                 """)
                .foregroundColor(Color(hex: 0x232936))
                .font(.system(size: 11))
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(.linearGradient(colors: [Color(hex: 0xE2F3FF), Color(hex: 0xF8FEFF)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .ignoresSafeArea()
        )
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    self.presentationModel.wrappedValue.dismiss()
                }, label: {
                    Image("arrow_left")
                })
            }
        })
        .navigationTitle("Terms of Users")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}
