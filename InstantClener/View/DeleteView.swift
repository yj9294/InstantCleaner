//
//  DeleteView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/8/3.
//

import SwiftUI

struct DeleteView: View {
    @State private var isRotated = false
    var animation: Animation {    Animation.linear(duration: 3).repeatForever(autoreverses: false)}
    var body: some View {
        VStack{
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 10){
                    Image("deleting")
                        .resizable()
                        .frame(width: 27, height: 27)
                        .rotationEffect(Angle.degrees(isRotated ? 360 : 0))
                        .onAppear(perform: {
                            withAnimation(animation) {
                                isRotated = !isRotated
                            }
                        })

                    Text("loading")
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
