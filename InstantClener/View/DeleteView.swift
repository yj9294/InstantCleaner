//
//  DeleteView.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/8/3.
//

import SwiftUI

struct DeleteView: View {
    var body: some View {
        VStack{
            Spacer()
            HStack {
                Spacer()
                ActivityIndicatorView()
                Spacer()
            }
            Spacer()
        }
        .background(Color(hex: 0x000000, alpha: 0.5).ignoresSafeArea())
    }
}

struct ActivityIndicatorView: UIViewRepresentable {
    let view = UIActivityIndicatorView(style: .medium)
    func makeUIView(context: Context) -> some UIView {
        view.startAnimating()
        return self.view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
}

struct DeleteView_Previews: PreviewProvider {
    static var previews: some View {
        DeleteView()
    }
}
