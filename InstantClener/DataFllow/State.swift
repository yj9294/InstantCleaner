//
//  state.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/7/29.
//

import Foundation
import Photos
import SwiftUI
import System
import MachO
import Contacts
import EventKit
import UIKit
import Lottie

struct AppState {
    var log: String? = nil
    var contactStore = CNContactStore()
    let calendarStore = EKEventStore()

    var root = Root()
    var launch = Launch()
    var tabbar = Tabbar()
    var home = Home()
    var permission = Permission()
    var loading = Loading()
    var photoManagement = PhotoManagement()
    var contact = Contact()
    var calendar = Calendar()
    var patch = Patch()
    var speed = Speed()
    var compression = Compression()
    var firebase = Firebase()
    var ad = AD()
    var animation = Animation()
}

extension AppState {
    struct Root {
        var selection: Index = .launch
        /// 进入后台
        var isEnterbackground = false
        /// 进入过后台
        var isEnterbackgrounded = false

        /// 弹窗
        var isAlert: Bool = false
        
        /// 弹窗详情
        var alertMessage: String = "Unknow."
        
        /// 是否显示删除进度
        var isDelete: Bool = false
        
        
        /// 是否展示photopermissionview
        var isShowPhotoPermission = false
        
        /// 弹出图片选择
        var isShowImagePicker = false
        
        /// 弹出loading
        var isShowLoading = false
        
        /// 进入patch view
        var isShowManageView = false
        /// 当前是进入patch还是进入的是compression
        var manageEvent: AppState.PhotoManagement.Event = .photo
    
        enum Index {
            case launch, tab
        }
    }
}

extension AppState {
    struct Tabbar {
        var selection: Index = .home
        
        enum Index {
            case home, clean, setting
        }
    }
}


extension AppState {
    struct Launch {
        /// 加载总时间
        var duration = 0.0
        /// 加载进度
        var progress = 0.0
        /// 最短加载时间
        var minTime = 2.0
        /// 最长加载时间
        var maxTime = 16.0
    }
}

extension AppState {
    struct Permission {
        @UserDefault(key: "state.permission.alert")
        var alert: Bool?
        var photoStatus: PHAuthorizationStatus = .authorized
        var contactStatus: CNAuthorizationStatus = .authorized
        var calendarStatis: EKAuthorizationStatus = .authorized
        enum PermissionType {
            case photo, contact, calendar
        }
    }
}

extension AppState {
    struct Home{
        /// 是否正在扫描动画
        var isScanAnimation: Bool = false
        /// 硬盘信息 
        var totalDisk: String { UIDevice.current.totalDiskSpaceInGB }
        /// 已使用硬盘
        var usedDisk: String { UIDevice.current.usedDiskSpaceInGB }
        /// 使用比例
        var radio: Double {
            let use = UIDevice.current.usedDiskSpaceInBytes
            let total = UIDevice.current.totalDiskSpaceInBytes
             return Double(use) / Double(total)
        }
        /// 进度
        var progress: Double = 0.0
        
        /// 原生广告
        var adModel: NativeViewModel = .None
        
        /// 导航条title
        var navigationTitle: String = "Instant Cleaner"

    }
}

extension AppState {
    struct Loading{
        /// 加载总时长
        var duration: Double = 0.0
        /// 加载最长时间
        var maxTime: Double = 50.0
        /// 加载最短时间
        var minTime: Double = 2.0
        ///  加载进度
        var progress: Double = 0.0
    }
}

extension AppState {
    struct PhotoManagement{
        /// 加载进度
        var progress: Int = 0
        /// 加载模型
        var loadModel: PhotoLoadModel? = PhotoLoadModel(.smart)

        /// 显示模型
        var displayLoadModel: PhotoLoadModel? = PhotoLoadModel(.smart)
        
        /// 图片使用总内存
        var photoDisk: UInt64 = 0
        /// 视频使用总内存
        var videoDisk: UInt64 = 0
        /// 总内存
        var smartDisk: UInt64 = 0
        
        /// 是否进入子页面
        var push: Bool = false
        
        var pushEvent: Point = .similarPhoto
        
        
        /// 相似图片
        var similarArray: [[PhotoItem]] {
            displayLoadModel?.loaded.similarPhoto ?? []
        }
        /// 选中所有的数组
        var similarSelectArray: [PhotoItem] {
            similarArray.flatMap {
                $0
            }.filter { item in
                item.isSelected == true
            }
        }
        /// 选中状态
        var similarSelect: Bool {
            similarSelectArray.count > 0
        }
        
        
        /// 屏幕截图
        var screenshotArray: [[PhotoItem]] {
            displayLoadModel?.loaded.screenshot ?? []
        }
        /// 选中数组
        var screenshotSelectArray: [PhotoItem] {
            screenshotArray.flatMap {
                $0
            }.filter { item in
                item.isSelected == true
            }
        }
        /// 选中状态
        var screenshotSelect: Bool {
            screenshotSelectArray.count > 0
        }
        
        
        
        /// 超大图片
        var largeArray: [[PhotoItem]] {
            displayLoadModel?.loaded.largePhoto ?? []
        }
        /// 选中状态数组
        var largeSelectArray: [PhotoItem] {
            largeArray.flatMap({
                $0
            }).filter { item in
                item.isSelected == true
            }
        }
        var largeSelect: Bool {
            largeSelectArray.count > 0
        }
        
        /// 模糊图片
        var blurryArray: [[PhotoItem]] {
            displayLoadModel?.loaded.blurryPhoto ?? []
        }
        /// 选中状态shuzu
        var blurrySelectArray: [PhotoItem] {
            blurryArray.flatMap({
                $0
            }).filter { item in
                item.isSelected == true
            }
        }
        /// 选中状态
        var blurrySelect: Bool {
            blurrySelectArray.count > 0
        }
        
        
        
        /// 相似视频
        var similarVideoArray: [[PhotoItem]] {
            displayLoadModel?.loaded.similarVideo ?? []
        }
        /// 选中状态
        var similarVideoSelectArray: [PhotoItem] {
            similarVideoArray.flatMap {
                $0
            }.filter { item in
                item.isSelected == true
            }
        }
        /// 选中状态
        var similarVideoSelect: Bool {
            similarVideoSelectArray.count > 0
        }
        
        
        /// 超大视频
        var largeVideoArray: [[PhotoItem]] {
            displayLoadModel?.loaded.largeVideo ?? []
        }
        /// 选中状态
        var largeVideoSelectArray: [PhotoItem] {
            largeVideoArray.flatMap({
                $0
            }).filter { item in
                item.isSelected == true
            }
        }
        /// 选中状态
        var largeVideoSelect: Bool {
            largeVideoSelectArray.count > 0
        }
        
        
        enum Event: CaseIterable {
            case smart, photo, video, contact, calendar, patch, compression, speed
            var title: String {
                switch self {
                case .smart:
                    return "Smart Clean"
                case .photo:
                    return "Photo Management"
                case .video:
                    return "Video Management"
                case .contact:
                    return "Contact Management"
                case .calendar:
                    return "Calendar Management"
                case .patch:
                    return "Photo Patch"
                case .speed:
                    return "Speed Test"
                case .compression:
                    return "Compression done"
                }
            }
            var isPhoto: Bool{
                switch self {
                case .smart, .photo:
                    return true
                default:
                    return false
                }
            }
            
            var isVideo: Bool{
                switch self {
                case .smart, .video:
                    return true
                default:
                    return false
                }
            }
        }
        
        enum Point: CaseIterable {
            case similarPhoto, screenshot, largePhoto, blurryPhoto, similarVideo, largeVideo
            var isVideo: Bool{
                switch self {
                case .similarVideo, .largeVideo:
                    return true
                default:
                    return false
                }
            }
            var isPhoto: Bool {
                !isVideo
            }
            var isSmimilar: Bool {
                switch self {
                case .similarVideo, .similarPhoto:
                    return true
                default:
                    return false
                }
            }
            
            var title: String {
                return paraseTitle().0
            }
            var subTitle: String {
                return paraseTitle().1
            }
            func paraseTitle() -> (String, String) {
                switch self {
                case .similarPhoto:
                    return ("Similar Photos", "Smart identify similar photos")
                case .largePhoto:
                    return ("Oversized Photos", "Photos that take up much space")
                case .screenshot:
                    return ("Screenshot","Scan to filter redundant screenshots")
                case .blurryPhoto:
                    return ("Blurred Photos", "Smart identify blurred photos")
                case .similarVideo:
                    return ("Duplicate Videos", "Smart identify similar videos")
                case .largeVideo:
                    return ("Oversized Videos", "Videos that take up much space")
                }
            }
            
            func headLine(num: Int, size: UInt64) -> String {
                if num == 0 {
                    return ""
                }
                switch self {
                case .similarPhoto:
                    return num > 1 ? "\(num) similar photos" : "\(num) similar photo"
                case .screenshot:
                    return num > 1 ? "\(num) screenshots, total \(size.format.0)\(size.format.1)" : "\(num) screenshots, total \(size.format.0)\(size.format.1)"
                case .largePhoto:
                    return num > 1 ? "\(num) oversized photos, total \(size.format.0)\(size.format.1)" : "\(num) oversized photo, total \(size.format.0)\(size.format.1)"
                case .blurryPhoto:
                    return num > 1 ? "\(num) blurred photos, total \(size.format.0)\(size.format.1)" : "\(num) blurred photo, total \(size.format.0)\(size.format.1)"
                case .similarVideo:
                    return num > 1 ? "\(num) similar videos" : "\(num) similar video"
                case .largeVideo:
                    return num > 1 ? "\(num) oversized videos, total \(size.format.0)\(size.format.1)" : "\(num) oversized video, total \(size.format.0)\(size.format.1)"
                }
            }
        }
    }
}

extension AppState {
    struct Contact {
        var contacts: [ContactItem] = []
        var duplicationName: [[ContactItem]] = []
        var duplicationNumber: [[ContactItem]] = []
        var noNumber: [[ContactItem]] = []
        var noName: [[ContactItem]] = []
        
        /// 是否进入子页面
        var push: Bool = false
        
        var pushEvent: Point = .duplicateName
        
        enum Point: String {
            case duplicateName, duplicateNumber, noName, noNumber
            
            var title: String {
                switch self {
                case .duplicateName:
                    return "Duplicate Name"
                case .duplicateNumber:
                    return "Duplicate Number"
                case .noName:
                    return "No Name"
                case .noNumber:
                    return "No Number"
                }
            }
        }
    }
}

extension AppState {
    struct Calendar {
        var calendars: [[CalendarItem]] = []
    }
}

extension AppState {
    struct Patch{
        var images: [UIImage] = []
        var direction: Point = .vertical
        enum Point{
            case vertical, horizontal
        }
    }
}

extension AppState {
    struct Speed {
        var ip: String = "123.456.78.912"
        var country: String = "San Diego, USA"
        var download: UInt64 = 0
        var upload: UInt64 = 0
        var ping: String = "0"
        var status: Status = .normal
        var monitorFlowModel = MonitorFlow()
        var test = SpeedTest()
        
        enum Status {
            case normal, testing, tested
            var title: String {
                switch self {
                case .normal:
                    return "Start"
                case .testing:
                    return "Stop"
                case .tested:
                    return "Restart"
                }
            }
        }
    }
}

extension AppState {
    struct Compression{
        var images: [UIImage] = []
        var compressionImages: [UIImage] = []
        var size: UInt64 = 0
    }
}

extension AppState {
    struct Firebase {
        
        enum FirebaseProperty: String {
            /// 設備
            case local = "new_man"
            
            var first: Bool {
                switch self {
                case .local:
                    return true
                }
            }
        }
        
        enum FirebaseEvent: String {
            
            var first: Bool {
                switch self {
                case .open, .photoPermission, .photoPermissionAgree:
                    return true
                default:
                    return false
                }
            }
            
            /// 首次打開
            case open = "lah_new"
            /// 冷啟動
            case openCold = "lah_cold"
            /// 熱起動
            case openHot = "lah_hot"
            
            case photoPermission = "alb_per"
            
            case photoPermissionAgree = "alb_per_sucs"
            
            case homeShow = "ho_sh"
            
            case homeClickSmart = "ho_smart"
            
            case homeScan = "ho_scan"
            
            case homePhotoClick = "ho_pic"
            
            case homeVideoClick = "ho_video"
            
            case homeContactClick = "ho_contact"
            
            case photoLoadSuccess = "ho_pic_suss"
            
            case videoLoadSuccess = "ho_video_suess"
            
            case contactLoadSuccess = "home_cct_ture"
            
            case scanStart = "scan_start"
            
            case scanSucess = "scan_scess"
            
            case scanDelete = "scan_de"
        }

    }
}

extension AppState {
    struct AD {
        /// 用戶惡意點擊 48小時無法請求admob
        var isUserCanShowAdmob: Bool {
            if isUserCanShowAdmobDate == nil {
                return true
            }
            return Date().timeIntervalSince1970 >= (isUserCanShowAdmobDate ?? Date()).timeIntervalSince1970
        }
        
        /// 遠程或者本地配置
        @UserDefault(key: "state.ad.config")
        var adConfig: ADConfig?
        
        /// 惡意點擊时间
        @UserDefault(key: "state.ad.date")
        var isUserCanShowAdmobDate: Date?
       
        /// 本地紀錄點擊次數和展示次數
        @UserDefault(key: "state.ad.limit")
        var limit: ADLimit?
        
        /// 广告位加载模型
        let ads:[ADLoadModel] = ADPosition.allCases.map { p in
            ADLoadModel(position: p)
        }.filter { m in
            m.position != .all
        }
        
        func isLoaded(_ position: ADPosition) -> Bool {
            return self.ads.filter {
                $0.position == position
            }.first?.isLoaded == true
        }
        
        /// 是否超出限制
        func isLimited(in store: Store) -> Bool {
            if limit?.date.isToday == true {
                if (store.state.ad.limit?.showTimes ?? 0) >= (store.state.ad.adConfig?.showTimes ?? 0) || (store.state.ad.limit?.clickTimes ?? 0) >= (store.state.ad.adConfig?.clickTimes ?? 0) {
                    return true
                }
            }
            return false
        }
    }
}
    
extension AppState {
    struct Animation {
        var testingModel: LottieViewModel = LottieViewModel(name: "testing", loopModel: .loop, animationView: AnimationView())
        var loadingModel: LottieViewModel = LottieViewModel(name: "loading", loopModel: .loop, animationView: AnimationView())
        var scanModel: LottieViewModel = LottieViewModel(name: "scan", loopModel: .loop, animationView: AnimationView())
    }
}



