//
//  AlertView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/8/3.
//

import SwiftUI

struct AlertView: View {
    let message: String
    var body: some View {
        VStack{
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 10){
                    Image("successfully")
                        .resizable()
                        .frame(width: 34, height: 34)
                        .clipped()
                    Text(message)
                        .foregroundColor(Color(hex: 0x232936))
                        .font(.system(size: 13))
                        .lineLimit(0)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 17)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
                Spacer()
            }
            Spacer()
        }
        .background(Color(hex: 0x000000, alpha: 0.5).ignoresSafeArea())
    }
}

struct AlertView_Previews: PreviewProvider {
    static var previews: some View {
        AlertView(message: "Unkonw error.")
    }
}
