//
//  UINativeADView.swift
//  TraslateNow
//
//  Created by yangjian on 2022/7/5.
//

import Foundation
import SnapKit
import GoogleMobileAds
import UIKit

let NativeViewWidth = UIScreen.main.bounds.width - 40 - 114
let NativeViewHeight = NativeViewWidth * 110.0 / 195.0

class UINativeAdView: GADNativeAdView {
    
    /// 是否是install 按鈕可點擊
    var installOnley = true

    init(){
        super.init(frame: UIScreen.main.bounds)
        setupUI()
        refreshUI(ad: nil, installTouchOnly: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 暫未圖
    lazy var placeholderView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    lazy var adView: UIImageView = {
        let image = UIImageView(image: UIImage(named: "ad_tag"))
        return image
    }()
    
    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .gray
        imageView.layer.cornerRadius = 2
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()
    
    lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.textColor = .white
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()
    
    lazy var installLabel: UIButton = {
        let label = UIButton()
        label.backgroundColor = UIColor(red: 11 / 255.0, green: 140 / 255.0, blue: 66 / 255.0, alpha: 1.0)
        label.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.setTitleColor(UIColor.white, for: .normal)
        label.layer.cornerRadius = 18
        label.layer.masksToBounds = true
        return label
    }()
    
    lazy var videoView: GADMediaView = {
        let view = GADMediaView()
        return view
    }()
    
    lazy var bigView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .gray
        view.contentMode = .scaleAspectFill
        view.layer.masksToBounds = true
        return view
    }()
}

extension UINativeAdView {
    func setupUI() {
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
        
        addSubview(placeholderView)
        placeholderView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
        
        
        
        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.left.equalToSuperview().offset(12)
            make.width.height.equalTo(40)
        }
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView)
            make.left.equalTo(iconImageView.snp.right).offset(12)
            make.right.equalToSuperview().offset(-130)
        }
        
        addSubview(adView)
        adView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalTo(titleLabel.snp.right)
            make.width.equalTo(21)
            make.height.equalTo(12)
        }
        
        addSubview(subTitleLabel)
        subTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.left.equalTo(titleLabel)
            make.right.equalToSuperview().offset(-110)
        }
        
        addSubview(installLabel)
        installLabel.snp.makeConstraints { make in
            make.centerX.equalTo(iconImageView)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.width.equalTo(77)
            make.height.equalTo(36)
            make.bottom.equalToSuperview()
        }
        
        
    }
    
    func refreshUI(ad: GADNativeAd? = nil, installTouchOnly: Bool) {
        self.installOnley = installTouchOnly
        self.nativeAd = ad
        placeholderView.image = UIImage(named: "ad_placeholder")
        let bgColor = UIColor.white
        let subTitleColor = UIColor(red: 128 / 255.0, green: 128 / 255.0, blue: 128 / 255.0, alpha: 1.0)
        let titleColor = UIColor(red: 16 / 255.0, green: 16 / 255.0, blue: 16 / 255.0, alpha: 1.0)
        let installColor = UIColor(red: 11 / 255.0, green: 140 / 255.0, blue: 66 / 255.0, alpha: 1.0)
        let installTitleColor = UIColor.white
        self.backgroundColor = ad == nil ? .clear : bgColor
        self.adView.image = UIImage(named: "ad_tag")
        self.installLabel.backgroundColor = installColor
        self.installLabel.setTitleColor(installTitleColor, for: .normal)
        self.subTitleLabel.textColor = subTitleColor
        self.titleLabel.textColor = titleColor
        
        self.iconView = self.iconImageView
        self.headlineView = self.titleLabel
        self.bodyView = self.subTitleLabel
        self.callToActionView = self.installLabel
        self.imageView = self.bigView
        self.mediaView = self.videoView
        self.installLabel.setTitle(ad?.callToAction, for: .normal)
        self.iconImageView.image = ad?.icon?.image
        self.titleLabel.text = ad?.headline
        self.subTitleLabel.text = ad?.body
        self.bigView.image = ad?.images?.first?.image
        self.videoView.mediaContent = ad?.mediaContent
        self.hiddenSubviews(hidden: self.nativeAd == nil)
        self.videoView.isHidden = ad?.mediaContent == nil
        self.bigView.isHidden = ad?.mediaContent != nil
        if ad == nil {
            self.videoView.isHidden = true
            self.bigView.isHidden = true
            self.placeholderView.isHidden = false
        } else {
            self.placeholderView.isHidden = true
        }
    }
    
    func hiddenSubviews(hidden: Bool) {
        self.iconImageView.isHidden = hidden
        self.titleLabel.isHidden = hidden
        self.subTitleLabel.isHidden = hidden
        self.installLabel.isHidden = hidden
        self.bigView.isHidden = hidden
        self.videoView.isHidden = hidden
        self.adView.isHidden = hidden
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if installOnley{
            let frameInTouch = self.installLabel.convert(self.installLabel.bounds, to: self)
            if frameInTouch.contains(point) {
                return true
            }
            return false
        }
        return true
    }
}
