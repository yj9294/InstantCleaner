//
//  ADCommand.swift
//  InstantClener
//
//  Created by yangjian on 2022/8/8.
//

import Foundation
import GoogleMobileAds
import AppTrackingTransparency
import Firebase


struct ADRequestConfigCommand: Command {
    func execute(in store: Store) {
        
        // 获取本地配置
        if store.state.ad.adConfig == nil {
            let path = Bundle.main.path(forResource: "admob", ofType: "json")
            let url = URL(fileURLWithPath: path!)
            do {
                let data = try Data(contentsOf: url)
                let config = try JSONDecoder().decode(ADConfig.self, from: data)
                store.dispatch(.adUpdateConfig(config))
                debugPrint("[Config] Read local ad config success.")
            } catch let error {
                debugPrint("[Config] Read local ad config fail.\(error.localizedDescription)")
            }
        }
        
        /// 远程配置
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        remoteConfig.configSettings = settings
        remoteConfig.fetch { [weak remoteConfig] (status, error) -> Void in
            if status == .success {
                debugPrint("[Config] Config fetcher! ✅")
                remoteConfig?.activate(completion: { _, _ in
                    let keys = remoteConfig?.allKeys(from: .remote)
                    debugPrint("[Config] config params = \(keys ?? [])")
                    if let remoteAd = remoteConfig?.configValue(forKey: "adConfig").stringValue {
                        // base64 的remote 需要解码
                        let data = Data(base64Encoded: remoteAd) ?? Data()
                        if let remoteADConfig = try? JSONDecoder().decode(ADConfig.self, from: data) {
                            // 需要在主线程
                            DispatchQueue.main.async {
                                store.dispatch(.adUpdateConfig(remoteADConfig))
                            }
                        } else {
                            debugPrint("[Config] Config config 'ad_config' is nil or config not json.")
                        }
                    }
                })
            } else {
                debugPrint("[Config] config not fetcher, error = \(error?.localizedDescription ?? "")")
            }
        }
        
        /// 广告配置是否是当天的
        if store.state.ad.limit == nil || store.state.ad.limit?.date.isToday != true {
            store.state.ad.limit = ADLimit(showTimes: 0, clickTimes: 0, date: Date())
        }
    }
}

struct ADIncreaseTimesCommand: Command {
    
    let status: ADLimit.Status
    
    init(_ status: ADLimit.Status) {
        self.status = status
    }
    
    func execute(in store: Store) {
        if store.state.ad.isLimited(in: store) {
            debugPrint("[AD] 用戶超限制。")
            store.dispatch(.adClean(.all))
            store.dispatch(.adDisapear(.all))
            return
        }

        if status == .show {
            let showTime = store.state.ad.limit?.showTimes ?? 0
            store.state.ad.limit?.showTimes = showTime + 1
            debugPrint("[AD] [LIMIT] showTime: \(showTime+1) total: \(store.state.ad.adConfig?.showTimes ?? 0)")
        } else  if status == .click {
            let clickTime = store.state.ad.limit?.clickTimes ?? 0
            store.state.ad.limit?.clickTimes = clickTime + 1
            debugPrint("[AD] [LIMIT] clickTime: \(clickTime+1) total: \(store.state.ad.adConfig?.clickTimes ?? 0)")
        }
    }
}

struct ADCacheTimeoutCommand: Command {
    func execute(in store: Store) {
        let token = SubscriptionToken()
        Timer.publish(every: 0.1, on: .main, in: .common).autoconnect().sink { _ in
            store.state.ad.ads.forEach {
                $0.loadedArray = $0.loadedArray.filter({ model in
                    return model.loadedDate?.isExpired == false
                })
            }
            if store.state.launch.duration > 30 {
                token.unseal()
            }
        }.seal(in: token)
    }
}

struct ADLoadCommand: Command {
    
    let position: ADPosition
    
    var completion: ((NativeViewModel)->Void)? = nil
    
    init(_ position: ADPosition, _ completion: ((NativeViewModel)->Void)? = nil) {
        self.position = position
        self.completion = completion
    }
    
    func execute(in store: Store) {
        let ads = store.state.ad.ads.filter{
            $0.position == position
        }
        if let ad = ads.first {
            // 插屏直接一步加载
            if position.isInterstitialAd {
                ad.beginAddWaterFall(in: store)
            } else if position.isNativeAD{
                // 原生广告需要同步显示
                ad.beginAddWaterFall(callback: { isSuccess in
                    if isSuccess {
                        store.dispatch(.adShow(self.position,completion))
                    }
                }, in: store)
            }
        }
    }
}

struct ADShowCommand: Command {
    let position: ADPosition
    var completion: ((NativeViewModel)->Void)? = nil
    
    init(_ position: ADPosition, _ completion: ((NativeViewModel)->Void)? = nil) {
        self.position = position
        self.completion = completion
    }
    
    func execute(in store: Store) {
        
        // 超限需要清空广告
        if store.state.ad.isLimited(in: store) {
            store.dispatch(.adClean(.all))
        }
        // 拉黑需要清空广告
        if !store.state.ad.isUserCanShowAdmob {
            store.dispatch(.adClean(.all))
            store.dispatch(.adDisapear(.all))
        }
        let loadAD = store.state.ad.ads.filter {
            $0.position == position
        }.first
        switch position {
        case .interstitial:
            /// 有廣告
            if let ad = loadAD?.loadedArray.first as? InterstitialADModel,
               store.state.ad.isUserCanShowAdmob,
               !store.state.root.isEnterbackground, !store.state.ad.isLimited(in: store) {
                ad.impressionHandler = {
                    store.dispatch(.adIncreaseShowTimes)
                    store.dispatch(.adDisplay(position))
                    store.dispatch(.adLoad(position))
                }
                ad.clickHandler = {
                    store.dispatch(.adIncreaseClickTimes)
                }
                ad.closeHandler = {
                    store.dispatch(.adDisapear(position))
                    completion?(.None)
                }
                ad.clickTwiceHandler = {
                    store.dispatch(.adClean(.all))
                    /// 48小时
                    let date = Date(timeIntervalSinceNow: 48 * 60 * 60)
                    store.dispatch(.adCanShowADmobDate(date))
                }
                ad.present()
            } else {
                completion?(.None)
            }
            
        case .native:
            if let ad = loadAD?.loadedArray.first as? NativeADModel, !store.state.root.isEnterbackground, !store.state.ad.isLimited(in: store) {
                /// 预加载回来数据 当时已经有显示数据了
                if loadAD?.isDisplay == true {
                    return
                }
                ad.nativeAd?.unregisterAdView()
                ad.nativeAd?.delegate = ad
                ad.impressionHandler = {
                    store.dispatch(.adUpdateImpressionDate(position))
                    store.dispatch(.adIncreaseShowTimes)
                    store.dispatch(.adDisplay(position))
                    store.dispatch(.adLoad(position))
                }
                ad.clickHandler = {
                    store.dispatch(.adIncreaseClickTimes)
                }
                // 10秒间隔
                
                if loadAD?.isNeedShow == true {
                    completion?(NativeViewModel(ad:ad, view: UINativeAdView()))
                } else {
                    completion?(.None)
                }
            } else {
                /// 预加载回来数据 当时已经有显示数据了 并且没超过限制
                if loadAD?.isDisplay == true, !store.state.ad.isLimited(in: store) {
                    return
                }
                completion?(.None)
            }
        default:
            break
        }
    }
    
    
    func requestAtt() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            
        }
    }
}

struct ADDismissCommand: Command {
    func execute(in store: Store) {
        store.state.ad.ads.forEach {
            if let ad = $0.loadedArray.first as? InterstitialADModel {
                ad.dismiss()
            }
        }
    }
}

struct ADCleanCommand: Command {
    let position: ADPosition
    
    init(_ position: ADPosition) {
        self.position = position
    }
    
    func execute(in store: Store) {
        switch position {
        case .all:
            store.state.ad.ads.filter{
                $0.position.isNativeAD
            }.forEach {
                $0.clean()
            }
        default:
            let loadAD = store.state.ad.ads.filter{
                $0.position == position
            }.first
            loadAD?.clean()
        }
    }
}


/// 已经正式展示了该广告位，清空loaded数组 方便进行预加载
struct ADDisplayCommand: Command {
    let postion: ADPosition
    
    init(_ postion: ADPosition) {
        self.postion = postion
    }
    
    func execute(in store: Store) {
        switch postion {
        case .all:
            break
        default:
            store.state.ad.ads.filter {
                $0.position == postion
            }.first?.display()
        }
    }
}

// 移除显示
struct ADDisapearCommand: Command {
    let position: ADPosition
    
    init(_ position: ADPosition) {
        self.position = position
    }
    
    func execute(in store: Store) {
        switch position {
        case .all:
            store.state.ad.ads.forEach {
                $0.closeDisplay()
            }
        default:
            store.state.ad.ads.filter{
                $0.position == position
            }.first?.closeDisplay()
        }
        store.dispatch(.homeAdModel(.None))
    }
}

