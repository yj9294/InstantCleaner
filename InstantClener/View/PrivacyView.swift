//
//  PrivacyView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/8/5.
//

import Foundation
import SwiftUI

struct PrivacyView: View {
    @Environment(\.presentationMode) var presentationModel
    
    var body: some View {
        ScrollView {
            Text("""
Privacy Policy



We attach great importance to the protection of users' personal information and will treat such information with diligence and prudence. We hope to introduce to you how we handle your personal information through this "Privacy Policy", so we recommend that you read all the terms of this "Privacy Policy" carefully and completely. Among them, the content related to your information and rights will be prompted for your attention in bold, please read it carefully. Please read the corresponding chapters according to the following index:

1. How we collect your personal information

2. How we use your information



Personal Information We Actively Collect and Use

When you use instant cleaner and related services, in order to ensure the normal operation of software and services, we will collect your hardware model, operating system version number, International Mobile Equipment Identity (IMEI), network device hardware address (MAC), IP address , software version number, network access method and type, operation log and other information. Please understand that this information is the basic information we must collect in order to provide our services and ensure the proper functioning of our products.

Information you upload or provide when using the Services

When you use the CleanMaster service to store content and provide feedback services, we will collect various information according to the actual situation, such as the information in your stored files, the email information you filled in when you receive feedback, etc. We will use this information to fulfill your request, provide related products or services, or for anti-fraud purposes.

Camera and photo permissions

In order to take full advantage of our features and adequate performance of the app, we need your authorization to access your camera and photos, then you can access full functionality and have a lot of fun. We can only access your camera and photo albums if you confirm these permissions. Then we will process the photo and feedback the effect to you. Such photos and effects will not contain any personally identifiable information. We do not store or share this data with any third parties.

2. How we use your personal information

We strictly abide by the provisions of laws and regulations and the agreement with users, and use the collected information for the following purposes. If we use your information beyond the following purposes, we will explain to you again and obtain your consent.

(1) To provide you with services

We use your personal information to provide and support services. As part of providing the Services, we may send you service bulletins, technical notices, updates, security alerts and support-related messages via the Services or by email. We may also contact you with your support requests, questions or feedback.

(2) To meet your individual needs

We will use the collected information for internal data analysis and research, indirect population analysis based on feature tags, and provide more accurate and personalized services and content.

(3) Product development and service optimization

We use the information we collect to better understand your interests and services, improve services and develop new features. When our system fails, we record and analyze the information generated when the system fails to optimize our services.

(4) Safety

We will use your information for authentication, security protection, anti-fraud monitoring, file backup, customer security services and other purposes.

(5) Recommend advertisements and information that may be of interest to you.

We will use your information to match recommended ads and news within the app. Please note that the collection of your personal information is only used to improve the accuracy of the advertisements and information recommended to you and to improve your user experience. Your personal information will not be used for other purposes and we cannot identify you from the personal information obtained.

(6) To evaluate and improve the effectiveness of our advertising and other promotions and promotions.

We will use your information for analysis and evaluation, and based on the evaluation results, improve the way we advertise and other promotions for better performance and user experience.
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
        .navigationTitle("Privacy Protection")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}
