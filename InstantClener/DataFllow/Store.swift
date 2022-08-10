//
//  Store.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/7/29.
//

import Foundation
import SwiftUI
import Combine

class Store: ObservableObject {
    @Published var state = AppState()
    var disposeBag = [AnyCancellable]()
    init() {
        commonInit()
    }
}

extension Store {
    
    private func commonInit() {
        
        dispatch(.adRequestConfig)
        dispatch(.adCacheTimeout)
        
        dispatch(.launchBegin)
        dispatch(.speedRequestIP)
        
        dispatch(.logProperty(.local))
        dispatch(.logEvent(.open))
        dispatch(.logEvent(.openCold))
    }
    
    public func dispatch(_ action: Action) {
        if action.isLog {
            let string = "[ACTION]: \(action) thread:\(Thread.isMainThread)"
            debugPrint(string)
            state.log = "\(state.log ?? "")\n\(string)"
        }
        let result = Store.reduce(state: state, action: action)
        state = result.0
        if let command = result.1 {
            let string = "[COMMAND]: \(command) thread:\(Thread.isMainThread)"
            debugPrint(string)
            state.log = "\(state.log ?? "")\n\(string)"
            command.execute(in: self)
        }
    }
    
    static func reduce(state: AppState, action: Action) -> (AppState, Command?) {
        var appState = state
        var appCommand: Command? = nil
        switch action {
        case .permissionAlert:
            appState.permission.alert = true
        case .permissionPhoto(let staus):
            appState.permission.photoStatus = staus
        case .permissionContact(let status):
            appState.permission.contactStatus = status
        case .permissionCalendar(let status):
            appState.permission.calendarStatis = status
        case .permissionRequest(let type):
            appCommand = PermissionCommand(type)
            
        case .rootAlert(let message):
            appState.root.alertMessage = message
            appState.root.isAlert = true
        case .rootBackgrund(let isEnter):
            appState.root.isEnterbackground = isEnter
            
        case .launchBegin:
            appState.root.selection = .launch
            appState.launch.progress = 0.0
            appCommand = LaunchCommand()
        case .launched:
            appState.root.selection = .tab
        case .launchProgress(let progress):
            appState.launch.progress = progress
        case .launchDuration(let duration):
            appState.launch.duration = duration
            
        case .tabbar(let index):
            appState.tabbar.selection = index
        case .tabbarPushLoading(let isPush):
            appState.tabbar.isPushLoading = isPush
            
        case .homeStartScanAnimation:
            if appState.home.isScanAnimation {
                break
            }
            appState.home.isScanAnimation = true
            appCommand = HomeScanAnimationCommand()
        case .homeStopScanAnimation:
            appState.home.isScanAnimation = false
        case .homeProgress(let progress):
            appState.home.progress = progress
        case .homeShowPhotoPermission(let isShow):
            appState.home.isShowPhotoPermission = isShow
        case .homePush:
            if appState.home.isPushView == true {
                break
            }
            appState.home.isPushView = true
        case .homePushEvent(let event):
            if appState.home.pushEvent == event  {
                break
            }
            appState.home.pushEvent = event
            
            
        case .loadingStart:
            appCommand = LoadingCommand()
        case .loadingProgress(let progress):
            appState.loading.progress = progress
        case .loadingDuration(let duration):
            appState.loading.duration = duration
        case .loadingMaxTime(let maxTime):
            appState.loading.maxTime = maxTime
        case .loadingMinTime(let minTime):
            appState.loading.minTime = minTime
        case .loadingPushEvent(let isPush):
            if appState.loading.isPushEvent == isPush {
                break
            }
            appState.loading.isPushEvent = isPush
            
        case .loadingEvent(let event):
            appState.loading.pushEvent = event
            
        case .photoStopLoad:
            appState.photoManagement.loadModel?.stopLoad()
        case .photoLoad(let point):
            appCommand = PhotoFetchCommand(point)
        case .photoProgress(let progress):
            appState.photoManagement.progress = progress
        case .photoDisk(let disk):
            appState.photoManagement.photoDisk = disk
        case .videoDisk(let disk):
            appState.photoManagement.videoDisk = disk
        case .smartDisk(let disk):
            appState.photoManagement.smartDisk = disk
        case .photoDisplayLoad(let loads):
            appCommand = PhotoDiskCommand(loads)
        case .photoDelete(let point):
            appCommand = PhotoDeleteCommand(point)
        case .photoCancel(let point):
            appCommand = PhotoCancelCommand(point)
        case .photoAllSelect(let point, let isAll):
            appCommand = PhotoAllSelectCommand(point, isAll)
        case .photoDidselect(let item):
            appCommand = PhotoDidSelectCommand(item)
        case .photoDeleting(let isDelete):
            appState.photoManagement.deleting = isDelete
            
        case .contactLoad:
            appCommand = ContactLoadCommand()
        case .contactStore(let contacts):
            appState.contact.contacts = contacts
        case .contactNoName(let array):
            appState.contact.noName = array
        case .contactNoNumber(let array):
            appState.contact.noNumber = array
        case .contactDuplicateName(let array):
            appState.contact.duplicationName = array
        case .contactDuplicateNumber(let array):
            appState.contact.duplicationNumber = array
        case .contactSelect(let item):
            appCommand = ContactSelectCommand(item)
        case .contactFresh:
            appCommand = ContactFreshCommand()
        case .contactDelete:
            appCommand = ContactDeleteCommand()
        case .contactAllSelect(let point):
            appCommand = ContactAllSelectCommand(point)
        case .contactCancel:
            appCommand = ContactCancelSelectCommand()
            
        case .calendarLoad:
            appCommand = CalendarCommand()
        case .calendarStore(let array):
            appState.calendar.calendars = array
        case .calendarCancel:
            appCommand = CalendarCancelCommand()
        case .calendarAllSelect:
            appCommand = CalendarAllSelectCommand()
        case .calendarSelect(let item):
            appCommand = CalendarSelectCommand(item)
        case .calendarDelete:
            appCommand = CalendarDeleteCommand()
        
        case .presentImagePicker:
            appState.home.isPresentImagePicker = true
        
        case .patchImages(let images):
            appState.patch.images = images
        case .patchDirection(let point):
            appState.patch.direction = point
        case .patchStore:
            appCommand = PhotoPatchCommand()
        
        case .compression(let images):
            appState.compression.images = images
            appCommand = CompressionCommand(images)
        case .compressionImages(let images):
            appState.compression.compressionImages = images
        case .compressionSize(let size):
            appState.compression.size = size
        case .compressStore:
            let images = appState.compression.compressionImages
            appCommand = CompressionStoreCommand(images)
            
        case .speedIP(let ip):
            appState.speed.ip = ip
        case .speedCountry(let country):
            appState.speed.country = country
        case .speedStatus(let status):
            appState.speed.status = status
        case .speedStartTest:
            appCommand = SpeedStartTestCommand()
        case .speedStopTest:
            appCommand = SpeedStopTestCommand()
        
        case .speedDownload(let download):
            appState.speed.download = download
        case .speedUpload(let upload):
            appState.speed.upload = upload
        case .speedPing(let ping):
            appState.speed.ping = ping
        case .speedRequestIP:
            appCommand = SpeedRequestIPCommand()
            
            
        case .logProperty(let property, let value):
            appCommand = FirebasePropertyCommand(property, value)
        case .logEvent(let event, let params):
            appCommand = FirebaseEvnetCommand(event, params)
        
        case .adRequestConfig:
            appCommand = ADRequestConfigCommand()
        case .adUpdateConfig(let config):
            appState.ad.adConfig = config
        case .adIncreaseShowTimes:
            appCommand = ADIncreaseTimesCommand(.show)
        case .adIncreaseClickTimes:
            appCommand = ADIncreaseTimesCommand(.click)
        case .adCanShowADmobDate(let date):
            appState.ad.isUserCanShowAdmobDate = date
        case .adLoad(let position, let completion):
            appCommand = ADLoadCommand(position, completion)
        case .adShow(let position, let compeltion):
            appCommand = ADShowCommand(position, compeltion)
        case .adDisplay(let position):
            appCommand = ADDisplayCommand(position)
        case .adDisapear(let position):
            appCommand = ADDisapearCommand(position)
        case .adClean(let position):
            appCommand = ADCleanCommand(position)
        case .adCacheTimeout:
            appCommand = ADCacheTimeoutCommand()
        case .adDismiss:
            appCommand = ADDismissCommand()
        case .adUpdateImpressionDate(let position):
            appState.ad.ads.filter {
                $0.position == position
            }.first?.impressionDate = Date()
        case .homeAdModel(let model):
            appState.home.adModel = model
        }
        return (appState, appCommand)
    }
}
