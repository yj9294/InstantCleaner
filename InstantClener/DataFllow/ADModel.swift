//
//  ADModel.swift
//  InstantClener
//
//  Created by yangjian on 2022/8/8.
//

import Foundation
import GoogleMobileAds

var AppEnterbackground = false

class ADBaseModel: NSObject, Identifiable {
    let id = UUID().uuidString
    /// 廣告加載完成時間
    var loadedDate: Date?
    
    /// 點擊回調
    var clickHandler: (() -> Void)?
    /// 展示回調
    var impressionHandler: (() -> Void)?
    /// 加載完成回調
    var loadedHandler: ((_ result: Bool, _ error: String) -> Void)?
    
    /// 當前廣告model
    var model: ADModel?
    /// 廣告位置
    var position: ADPosition = .native
    
    init(model: ADModel?) {
        super.init()
        self.model = model
    }
}

extension ADBaseModel {
    @objc public func loadAd( completion: @escaping ((_ result: Bool, _ error: String) -> Void)) {
        
    }
    
    @objc public func present() {
        
    }
}

struct ADModel: Codable {
    var theAdPriority: Int
    var theAdID: String
}

struct ADLimit: Codable {
    var showTimes: Int
    var clickTimes: Int
    var date: Date
    
    enum Status {
        case show, click
    }
}

enum ADPosition: String, CaseIterable {
    case all, interstitial, native

    var isNativeAD: Bool {
        switch self {
        case .native:
            return true
        default:
            return false
        }
    }
    
    var isInterstitialAd: Bool {
        switch self {
        case .interstitial:
            return true
        default:
            return false
        }
    }
}

class ADLoadModel: NSObject {
    /// 當前廣告位置類型
    var position: ADPosition = .native
    /// 當前正在加載第幾個 ADModel
    var preloadIndex: Int = 0
    /// 是否正在加載中
    var isPreloadingAd = false
    /// 正在加載術組
    var loadingArray: [ADBaseModel] = []
    /// 加載完成
    var loadedArray: [ADBaseModel] = []
    /// 展示
    var displayArray: [ADBaseModel] = []
    
    var isLoaded: Bool {
        return loadedArray.count > 0
    }
    
    var isDisplay: Bool {
        return displayArray.count > 0
    }
    
    /// 该广告位显示广告時間 每次显示更新时间
    var impressionDate = Date(timeIntervalSinceNow: -100)
    
    /// 显示的时间间隔小于 11.2秒
    var isNeedShow: Bool {
        if Date().timeIntervalSince1970 - impressionDate.timeIntervalSince1970 < 11 {
            debugPrint("[AD] (\(position)) 11s 模型填充間隔，包含了广告的展示间隔，和异步加载完成数据的判定。如果出现这个日志不代表用户马上展示该广告位广告，只是表示一个模型的填充。进行判断是为了防止间隔过快的填充，实际加载广告以用户看到数据为准。")
            return false
        }
        return true
    }
        
    init(position: ADPosition) {
        super.init()
        self.position = position
    }
}

extension ADLoadModel {
    func beginAddWaterFall(callback: ((_ isSuccess: Bool) -> Void)? = nil, in store: Store) {
        if isPreloadingAd == false, loadedArray.count == 0 {
            debugPrint("[AD] (\(position.rawValue) start to prepareLoad.--------------------")
            if let array: [ADModel] = store.state.ad.adConfig?.arrayWith(position), array.count > 0 {
                preloadIndex = 0
                debugPrint("[AD] (\(position.rawValue)) start to load array = \(array.count)")
                prepareLoadAd(array: array, callback: callback, in: store)
            } else {
              isPreloadingAd = false
                debugPrint("[AD] (\(position.rawValue)) no configer.")
            }
        } else if loadedArray.count > 0 {
            debugPrint("[AD] (\(position.rawValue)) loaded ad.")
            callback?(true)
        } else if loadingArray.count > 0 {
            debugPrint("[AD] (\(position.rawValue)) loading ad.")
            callback?(false)
        }
    }
    
    func prepareLoadAd(array: [ADModel], callback: ((_ isSuccess: Bool) -> Void)?, in store: Store) {
        if array.count == 0 || preloadIndex >= array.count {
            debugPrint("[AD] (\(position.rawValue)) prepare Load Ad Failed, no more avaliable config.")
            isPreloadingAd = false
            return
        }
        debugPrint("[AD] (\(position)) prepareLoaded.")
        if store.state.ad.isUserCanShowAdmob == false {
            debugPrint("[AD] (\(position.rawValue)) 用戶禁止請求廣告。")
            store.dispatch(.adClean(.native))
            store.dispatch(.adDisapear(.native))
            callback?(false)
            return
        }
        if store.state.ad.isLimited(in: store) {
            debugPrint("[AD] (\(position.rawValue)) 用戶超限制。")
            callback?(false)
            return
        }
        if loadedArray.count > 0 {
            debugPrint("[AD] (\(position.rawValue)) 已經加載完成。")
            callback?(false)
            return
        }
        if isPreloadingAd, preloadIndex == 0 {
            debugPrint("[AD] (\(position.rawValue)) 正在加載中.")
            callback?(false)
            return
        }
        
//        if Date().timeIntervalSince1970 - loadDate.timeIntervalSince1970 < 11, position == .indexNative || position == .textTranslateNative || position == .backToIndexInter {
//            debugPrint("[AD] (\(position.rawValue)) 10s 刷新間隔.")
//            callback?(false)
//            return
//        }
        
        isPreloadingAd = true
        var ad: ADBaseModel? = nil
        if position.isNativeAD {
            ad = NativeADModel(model: array[preloadIndex])
        } else if position.isInterstitialAd {
            ad = InterstitialADModel(model: array[preloadIndex])
        }
        ad?.position = position
        ad?.loadAd { [weak ad] result, error in
            guard let ad = ad else { return }
            /// 刪除loading 中的ad
            self.loadingArray = self.loadingArray.filter({ loadingAd in
                return ad.id != loadingAd.id
            })
            
            /// 成功
            if result {
                self.isPreloadingAd = false
                self.loadedArray.append(ad)
                callback?(true)
                return
            }
            
            if self.loadingArray.count == 0 {
                let next = self.preloadIndex + 1
                if next < array.count {
                    debugPrint("[AD] (\(self.position.rawValue)) Load Ad Failed: try reload at index: \(next).")
                    self.preloadIndex = next
                    self.prepareLoadAd(array: array, callback: callback, in: store)
                } else {
                    debugPrint("[AD] (\(self.position.rawValue)) prepare Load Ad Failed: no more avaliable config.")
                    self.isPreloadingAd = false
                    callback?(false)
                }
            }
            
        }
        if let ad = ad {
            loadingArray.append(ad)
        }
    }
    
    func display() {
        self.displayArray = self.loadedArray
        self.loadedArray = []
    }
    
    func closeDisplay() {
        self.displayArray = []
    }
    
    func clean() {
        self.displayArray = []
        self.loadedArray = []
        self.loadingArray = []
    }
}

extension Date {
    var isExpired: Bool {
        Date().timeIntervalSince1970 - self.timeIntervalSince1970 > 3000
    }
    
    var isToday: Bool {
        let diff = Calendar.current.dateComponents([.day], from: self, to: Date())
        if diff.day == 0 {
            return true
        } else {
            return false
        }
    }
}


class InterstitialADModel: ADBaseModel {
    /// 關閉回調
    var closeHandler: (() -> Void)?
    var autoCloseHandler: (()->Void)?
    /// 異常回調 點擊了兩次
    var clickTwiceHandler: (() -> Void)?
    
    /// 是否點擊過，用於拉黑用戶
    var isClicked: Bool = false
    
    /// 插屏廣告
    var interstitialAd: GADInterstitialAd?
    
    deinit {
        debugPrint("[Memory] (\(position.rawValue)) \(self) 💧💧💧.")
    }
}

extension InterstitialADModel {
    public override func loadAd(completion: ((_ result: Bool, _ error: String) -> Void)?) {
        loadedHandler = completion
        loadedDate = nil
        GADInterstitialAd.load(withAdUnitID: model?.theAdID ?? "", request: GADRequest()) { [weak self] ad, error in
            guard let self = self else { return }
            if let error = error {
                debugPrint("[AD] (\(self.position.rawValue)) load ad FAILED for id \(self.model?.theAdID ?? "invalid id")")
                self.loadedHandler?(false, error.localizedDescription)
                return
            }
            debugPrint("[AD] (\(self.position.rawValue)) load ad SUCCESSFUL for id \(self.model?.theAdID ?? "invalid id")")
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
            self.loadedDate = Date()
            self.loadedHandler?(true, "")
        }
    }
    
    override func present() {
        if let keyWindow = UIApplication.shared.windows.filter({$0.isKeyWindow}).first, let rootVC = keyWindow.rootViewController {
            interstitialAd?.present(fromRootViewController: rootVC)
        }
    }
    
    func dismiss() {
        if let topController = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController, let presented = topController.presentedViewController {
            presented.dismiss(animated: true) {
                topController.dismiss(animated: true)
            }
            closeHandler?()
        }
    }
}

extension InterstitialADModel : GADFullScreenContentDelegate {
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        loadedDate = Date()
        impressionHandler?()
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        debugPrint("[AD] (\(self.position.rawValue)) didFailToPresentFullScreenContentWithError ad FAILED for id \(self.model?.theAdID ?? "invalid id")")
        closeHandler?()
    }
    
    func adWillDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        if !AppEnterbackground {
            closeHandler?()
        }
    }
    
    func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        if isClicked {
            debugPrint("[AD] 連續兩次點擊，限制48小時不請求廣告，並且清楚已緩存廣告。")
            clickTwiceHandler?()
            /// 拉黑 並且清除廣告數據
            if let topController = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController, let presented = topController.presentedViewController {
                presented.dismiss(animated: true) {
                    topController.dismiss(animated: true)
                }
            }
            closeHandler?()
        } else {
            isClicked = true
            clickHandler?()
        }
    }
}

class NativeADModel: ADBaseModel {
    /// 廣告加載器
    var loader: GADAdLoader?
    /// 原生廣告
    var nativeAd: GADNativeAd?
    
    deinit {
        debugPrint("[Memory] (\(position.rawValue)) \(self) 💧💧💧.")
    }
}

extension NativeADModel {
    public override func loadAd(completion: ((_ result: Bool, _ error: String) -> Void)?) {
        loadedDate = nil
        loadedHandler = completion
        loader = GADAdLoader(adUnitID: model?.theAdID ?? "", rootViewController: nil, adTypes: [.native], options: nil)
        loader?.delegate = self
        loader?.load(GADRequest())
    }
    
    public func unregisterAdView() {
        nativeAd?.unregisterAdView()
    }
}

extension NativeADModel: GADAdLoaderDelegate {
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        debugPrint("[AD] (\(position.rawValue)) load ad FAILED for id \(model?.theAdID ?? "invalid id")")
        loadedHandler?(false, error.localizedDescription)
    }
}

extension NativeADModel: GADNativeAdLoaderDelegate {
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        debugPrint("[AD] (\(position.rawValue)) load ad SUCCESSFUL for id \(model?.theAdID ?? "invalid id")")
        self.nativeAd = nativeAd
        loadedDate = Date()
        loadedHandler?(true, "")
    }
}

extension NativeADModel: GADNativeAdDelegate {
    func nativeAdDidRecordClick(_ nativeAd: GADNativeAd) {
        clickHandler?()
    }
    
    func nativeAdDidRecordImpression(_ nativeAd: GADNativeAd) {
        impressionHandler?()
    }
    
    func nativeAdWillPresentScreen(_ nativeAd: GADNativeAd) {
    }
}


