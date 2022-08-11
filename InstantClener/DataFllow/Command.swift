//
//  Command.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/7/29.
//

import Foundation
import Combine
import AVFoundation
import Photos
import Contacts
import EventKit

protocol Command {
    func execute(in store: Store)
}

class SubscriptionToken {
    var cancelable: AnyCancellable?
    func unseal() { cancelable = nil }
}

extension AnyCancellable {
    /// 需要 出现 unseal 方法释放 cancelable
    func seal(in token: SubscriptionToken) {
        token.cancelable = self
    }
}

struct LaunchCommand: Command {
    func execute(in store: Store) {
        /// 1. 在 2s 内快速走完 80% 进度，1s 内走完剩余进度
        let duration = store.state.launch.minTime / 0.6
        store.dispatch(.launchDuration(duration))
        let token = SubscriptionToken()
        let token1 = SubscriptionToken()
        var isNeedShowAD = false
        Timer.publish(every: 0.01, on: .main, in: .common).autoconnect().sink { _ in
            let progress = store.state.launch.progress
            let totalCount = 1.0 / 0.01 * store.state.launch.duration
            let value = progress + 1 / totalCount
            if value < 1.0 {
                store.dispatch(.launchProgress(value))
            } else {
                token.unseal()
                store.dispatch(.adShow(.interstitial, { _ in
                    store.dispatch(.launched)
                    
                    store.dispatch(.adLoad(.interstitial))
                    store.dispatch(.adLoad(.native))
                    
                    store.dispatch(.logEvent(.homeShow))
                    store.dispatch(.logEvent(.homeScan))
                }))
            }
            
            if store.state.ad.isLoaded(.interstitial), isNeedShowAD {
                isNeedShowAD = false
                store.dispatch(.launchDuration(1.0))
            }
        }.seal(in: token)
        
        /// 1. 在 2s 内快速走完 80% 进度，1s 内走完剩余进度
        Timer.publish(every: store.state.launch.minTime, on: .main, in: .common).autoconnect().sink { _ in
            token1.unseal()
            isNeedShowAD = true
            store.dispatch(.launchDuration(store.state.launch.maxTime))
        }.seal(in: token1)
        
        store.dispatch(.adLoad(.interstitial))
        store.dispatch(.adLoad(.native))
    }
}

struct PermissionCommand: Command {
    let type: AppState.Permission.PermissionType
    init(_ type: AppState.Permission.PermissionType) {
        self.type = type
    }
    func execute(in store: Store) {
        switch type {
        case .photo:
            store.dispatch(.permissionPhoto(PHPhotoLibrary.authorizationStatus(for: .readWrite)))
            store.dispatch(.logEvent(.photoPermission))
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        store.dispatch(.logEvent(.photoPermissionAgree))
                    }
                    store.dispatch(.permissionPhoto(status))
                }
            }
        case .contact:
            store.dispatch(.permissionContact(CNContactStore.authorizationStatus(for: .contacts)))
            CNContactStore().requestAccess(for: .contacts) { granted, error in
                DispatchQueue.main.async {
                    store.dispatch(.permissionContact(CNContactStore.authorizationStatus(for: .contacts)))
                    if granted {
                        store.dispatch(.loadingEvent(.contact))
                        store.dispatch(.loadingStart)
                        store.dispatch(.contactLoad)
                        store.dispatch(.presentLoading(true))
                        store.dispatch(.homeStopScanAnimation)
                        
                        ///离开
                        store.dispatch(.adDisapear(.native))
                    }
                }
            }
        case .calendar:
            store.dispatch(.permissionCalendar(EKEventStore.authorizationStatus(for: .event)))
            EKEventStore().requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    store.dispatch(.permissionCalendar(EKEventStore.authorizationStatus(for: .event)))
                    if granted{

                        store.dispatch(.loadingEvent(.calendar))
                        store.dispatch(.loadingStart)
                        store.dispatch(.calendarLoad)
                        store.dispatch(.presentLoading(true))
                        store.dispatch(.homeStopScanAnimation)
                        
                        store.dispatch(.adDisapear(.native))
                    }
                }
            }
        }
    }
}

struct HomeScanAnimationCommand: Command {
    func execute(in store: Store) {
//        Timer.publish(every: 0.01, on: .main, in: .common).autoconnect().sink { _ in
//            var degress = store.state.home.degree
//            degress +=  360.0 / 100.0
//            if degress > Double(Int.max) {
//                token.unseal()
//            } else {
//                store.dispatch(.homeDegree(degress))
//            }
//            if !store.state.home.isScanAnimation {
//                token.unseal()
//            }
//        }.seal(in: token)
        
        let token1 = SubscriptionToken()
        store.dispatch(.homeProgress(0))
        Timer.publish(every: 0.01, on: .main, in: .common).autoconnect().sink { _ in
            let progress = store.state.home.progress
            let totalCount = 1.0 / 0.01 * 2
            let value = progress + 1 / totalCount
            if value > store.state.home.radio {
                token1.unseal()
            } else {
                store.dispatch(.homeProgress(value))
            }
        }.seal(in: token1)
        
    }
}

struct LoadingCommand: Command {
    func execute(in store: Store) {
        let token = SubscriptionToken()
//        let maxTime = store.state.loading.maxTime
        let minTime = store.state.loading.minTime
        store.dispatch(.loadingProgress(0.0))
        store.dispatch(.loadingDuration(minTime))
        let startDate = Date()
        let duration = store.state.loading.duration
        Timer.publish(every: 0.01, on: .main, in: .common).autoconnect().sink { _ in
            let progress = store.state.loading.progress
            let totalCount = 1.0 / 0.01 * duration
            let value = progress + duration / totalCount
            if value < 1.0 {
                store.dispatch(.loadingProgress(value))
            } else {
                token.unseal()
                if !store.state.loading.isPushEvent {
                    /// 消失loading View
                    store.dispatch(.presentLoading(false))
                    /// 进入management view
                    store.dispatch(.loadingPushEvent(true))
                    
                    /// 更改title
                    store.dispatch(.navigationTitle(store.state.loading.pushEvent.title))

                    /// 打点
                    store.dispatch(.logEvent(.scanStart))
                    
                    /// contact 打点雨逻辑
                    if store.state.loading.pushEvent == .contact {
                        
                        /// contact 需要加载native ad
                        store.dispatch(.adLoad(.native))

                        let isNoName = store.state.contact.noName.flatMap {
                            $0
                        }.count > 0 ? "1" : "0"
                        let isNoNumber = store.state.contact.noNumber.flatMap {
                            $0
                        }.count > 0 ? "1" : "0"
                        
                        let duNumber = store.state.contact.duplicationNumber.flatMap {
                            $0
                        }.count > 0 ? "1" : "0"
                        
                        let duName = store.state.contact.duplicationName.flatMap {
                            $0
                        }.count > 0 ? "1" : "0"
                        let model = [duName, duNumber, isNoName, isNoNumber]
                        let string = model.joined(separator: ",")
                        let time = Date().timeIntervalSince1970 - startDate.timeIntervalSince1970
                        store.dispatch(.logEvent(.contactLoadSuccess, ["once": "\(ceil(time))", "result": string]))
                    }
                }
            }
        }.seal(in: token)
    }
}
