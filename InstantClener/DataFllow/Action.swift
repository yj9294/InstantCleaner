//
//  Action.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/7/29.
//

import Foundation
import UIKit
import Photos
import Contacts
import EventKit

enum Action {
    // MARK: permission
    /// user弹窗
    case permissionAlert
    /// 相机权限
    case permissionPhoto(PHAuthorizationStatus)
    /// 通讯录权限
    case permissionContact(CNAuthorizationStatus)
    /// 日历权限
    case permissionCalendar(EKAuthorizationStatus)
    /// 权限请求
    case permissionRequest(AppState.Permission.PermissionType)
    
    // MARK: Root
    // 系统弹窗
    case rootAlert(String)
    // 是否进入后台
    case rootBackgrund(Bool)
    
    // MARK: launch
    /// 冷热启动
    case launchBegin
    /// 加载完成
    case launched
    /// 加载进度
    case launchProgress(Double)
    /// 加载总时间
    case launchDuration(Double)
    
    // MARK: Tab
    /// 选中某个tab item
    case tabbar(AppState.Tabbar.Index)
    
    // MARK: home
    /// 扫描动画
    case homeDegree(Double)
    case homeStartScanAnimation
    case homeStopScanAnimation
    case homeProgress(Double)
    case homeShowPhotoPermission(Bool)
    case homePushEvent(AppState.PhotoManagement.Event)
    case homePush
    // MARK: loading
    case loadingStart
    case loadingDuration(Double)
    case loadingMaxTime(Double)
    case loadingMinTime(Double)
    case loadingProgress(Double)
    case loadingPresent(Bool)
    case loadingPush
    case loadingEvent(AppState.PhotoManagement.Event)
    // MARK: PhotoManagement
    case photoLoad(AppState.PhotoManagement.Event)
    case photoStopLoad
    case photoDisplayLoad(PhotoLoadModel?)
    case photoProgress(Int)
    case photoDisk(UInt64)
    case videoDisk(UInt64)
    case smartDisk(UInt64)
    case photoDelete(AppState.PhotoManagement.Point)
    case photoAllSelect(AppState.PhotoManagement.Point, Bool)
    case photoCancel(AppState.PhotoManagement.Point)
    case photoDidselect(PhotoItem)
    case photoDeleting(Bool)
    case photoAdModel(NativeViewModel)
    // MARK: Contack
    case contactLoad
    case contactStore([ContactItem])
    case contactNoNumber([[ContactItem]])
    case contactNoName([[ContactItem]])
    case contactDuplicateNumber([[ContactItem]])
    case contactDuplicateName([[ContactItem]])
    case contactSelect(ContactItem)
    case contactFresh
    case contactDelete
    case contactAllSelect(AppState.Contact.Point)
    case contactCancel
    case contactAdModel(NativeViewModel)
    // MARK: Calendar
    case calendarLoad
    case calendarStore([[CalendarItem]])
    case calendarCancel
    case calendarAllSelect
    case calendarSelect(CalendarItem)
    case calendarDelete
    
    case presentImagePicker

    // MARK: patch
    case patchImages([UIImage])
    case patchDirection(AppState.Patch.Point)
    case patchStore
    // MARK: compression
    case compression([UIImage])
    case compressionImages([UIImage])
    case compressionSize(UInt64)
    case compressStore
    case compressionAdModel(NativeViewModel)
    // MARK: Speed
    case speedStatus(AppState.Speed.Status)
    case speedStartTest
    case speedStopTest
    case speedIP(String)
    case speedCountry(String)
    case speedDownload(UInt64)
    case speedUpload(UInt64)
    case speedPing(String)
    case speedRequestIP
    case speedAdModel(NativeViewModel)
    
    case logEvent(AppState.Firebase.FirebaseEvent,[String:String]? = nil)
    case logProperty(AppState.Firebase.FirebaseProperty, String? = nil)
    
    case adRequestConfig
    case adUpdateConfig(ADConfig?)
    case adIncreaseClickTimes
    case adIncreaseShowTimes
    case adCanShowADmobDate(Date?)
    
    case adLoad(ADPosition, ((NativeViewModel)->Void)? = nil)
    case adShow(ADPosition, ((NativeViewModel)->Void)? = nil)
    case adDisplay(ADPosition)
    case adDisapear(ADPosition)
    case adClean(ADPosition)
    case adUpdateImpressionDate(ADPosition)
    case adCacheTimeout
    case adDismiss
    case homeAdModel(NativeViewModel)
    
    /// 是否开启日志
    var isLog: Bool {
        switch self {
        case .launchProgress(_), .homeDegree(_), .homeProgress(_), .loadingProgress(_) :
            return false
        default:
            return true
        }
    }
}

class PhotoItem: NSObject, Identifiable, NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        return PhotoItem(asset: self.asset, image: self.image, imageDataLength: self.imageDataLength, isSelected: self.isSelected, isBest: self.isBest, second: self.second)
    }
    
    var id: String = UUID().uuidString
    /// 图片资源
    @objc var asset: PHAsset?
    /// 图片
    @objc var image: UIImage?
    /// 图片数据大小
    @objc var imageDataLength: UInt64 = 0
    /// 是否选中
    @objc var isSelected: Bool = false
    /// 是否是最佳
    var isBest: Bool = false
    /// 视频时长
    var second: Int = 0
    
    @objc init(asset: PHAsset? = nil, image: UIImage? = nil, imageDataLength: UInt64 = 0, isSelected: Bool = false, isBest: Bool = false, second: Int = 0) {
        self.asset = asset
        self.image = image
        self.imageDataLength = imageDataLength
        self.isSelected = isSelected
        self.isBest = isBest
        self.second = second
    }
}

class ContactItem: NSObject, Identifiable {
    var id: String = UUID().uuidString
    var name: String = "No Name"
    var number: String = "No Number"
    var imageData: Data?
    var contact: CNContact?
    var isSelected = false
    var image: UIImage?
    init(name: String? = nil, number: String? = nil, imageData: Data? = nil, contact: CNContact? = nil, isSelected: Bool = false) {
        
        self.name = name ?? "No Name"
        self.number = number ?? "No Number"
        self.imageData = imageData
        self.contact = contact
        self.isSelected = isSelected
        if let imageData = imageData {
            self.image = UIImage(data: imageData)
        }
    }
    
    var n: String {
        if name.count == 0 {
            return "No Name"
        }
        return name
    }
    
    var p: String {
        if number.count == 0 {
            return "No Number"
        }
        return number
    }
}

class CalendarItem: NSObject, Identifiable {
    var id: String = UUID().uuidString
    var event: EKEvent?
    var date: String = ""
    var title: String = ""
    var content: String = ""
    var isSelected = false
    
    var dateInt: Int {
        Int(event?.startDate.timeIntervalSince1970 ?? 0)
    }
    var titleString: String {
        if title.count > 0 {
            return title.replacingOccurrences(of: " ", with: "")
        } else {
            return "New Event"
        }
    }
    
    init(event: EKEvent? = nil, date: String = "", title: String = "", content: String = "", isSelected: Bool = false) {
        self.event = event
        self.date = date
        self.title = title
        self.content = content
        self.isSelected = isSelected
    }
}

extension Date {
    func format() -> String {
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "MMM dd, yyyy"
        return dateformatter.string(from: self)
    }
}
