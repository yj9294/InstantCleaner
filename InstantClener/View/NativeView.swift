//
//  NativeView.swift
//  TraslateNow
//
//  Created by yangjian on 2022/7/5.
//

import Foundation
import SwiftUI

struct NativeView: UIViewRepresentable {
    @EnvironmentObject var store: Store
    let model: NativeViewModel
    func makeUIView(context: UIViewRepresentableContext<NativeView>) -> UIView {
        return model.view
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<NativeView>) {
        if let uiView = uiView as? UINativeAdView {
            uiView.refreshUI(ad: model.ad?.nativeAd, installTouchOnly: store.state.ad.adConfig?.installOnlyTouch ?? true)
        }
    }
}

class NativeViewModel: NSObject {
    let ad: NativeADModel?
    let view: UINativeAdView
    init(ad: NativeADModel? = nil, view: UINativeAdView) {
        self.ad = ad
        self.view = view
        self.view.refreshUI(ad: ad?.nativeAd, installTouchOnly: true)
    }
    
    static var None:NativeViewModel {
        NativeViewModel(view: UINativeAdView())
    }
}
