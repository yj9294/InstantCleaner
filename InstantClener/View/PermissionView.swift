//
//  PermissionView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/7/30.
//

import SwiftUI

struct PermissionView: View {
    var agreen: ()->Void
    var body: some View {
        ZStack{
            Color(hex: 0x000000, alpha: 0.5)
            VStack{
                Text("Personal Information Protection")
                    .font(.headline)
                    .foregroundColor(Color(hex: 0x232936))
                ScrollView(showsIndicators: false) {
                   Text("We will collect and use information in accordance with the Privacy Policy, but will not conduct compulsory bundled information collection because of agreeing to the Privacy Policy. 2. Sensitive permissions such as photo albums and contacts will not be enabled by default, and will only be used when using functions or services after your authorization. Please click the 'Agree' button below to express your acceptance of our services.")
                }
                .frame(height: 250)
                .padding(.horizontal, 20)
                HStack{
                    Spacer()
                    Button {
                        agreen()
                    } label: {
                        Text("Agree")
                            .foregroundColor(.white)
                            .frame(height: 48)
                            .padding(.horizontal, 42)
                    }
                    Spacer()
                }
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0x6C2EF9)))
                .padding(.horizontal, 42)
                Button {
                    exit(0)
                } label: {
                    Text("Disagree and exit")
                        .foregroundColor(Color(hex: 0x74797F))
                }

            }
            .padding(.vertical, 20)
            .frame(width: 290, height: 390)
            .background(RoundedRectangle(cornerRadius: 8.0).fill(Color.white))
        }
        .ignoresSafeArea()
    }
}

struct PermissionView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionView {
        }
    }
}
