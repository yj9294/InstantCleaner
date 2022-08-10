//
//  PhotoManagementCommand.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/8/1.
//

import Foundation
import Photos
import UIKit

struct PhotoFetchCommand: Command {
    
    var event: AppState.PhotoManagement.Event
    
    let startDate: Date
    
    init(_ event: AppState.PhotoManagement.Event, _ date: Date = Date()) {
        self.event = event
        self.startDate = date
    }
    
    func execute(in store: Store) {
        
        AMSimilarityManager.startClean()
        
        let minToken = SubscriptionToken()
        let maxToken = SubscriptionToken()
        
        store.dispatch(.loadingProgress(0.0))
        var start: Bool = false // 最短时间开始
        var stop: Bool = false // 超时
        
        store.dispatch(.videoDisk(0))
        store.dispatch(.smartDisk(0))
        store.dispatch(.photoDisk(0))
        
        
        if let load = store.state.photoManagement.loadModel {
            load.load(event) { progress in
                if !store.state.loading.isPushEvent {
                    /// 已经离开了loading界面 就不需要更新loading进度了
                    store.dispatch(.loadingProgress(Double(progress) / 100.0))
                }
                if  progress == 100 {
                    if start == false {
                        // 2s内完成
                        maxToken.unseal()
                        minToken.unseal()
                        if !store.state.loading.isPushEvent {
                            /// 已经离开了loading界面 就不需要更新loading进度了
                            store.dispatch(.loadingProgress(0.99))
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            completion(in: store)
                        }
                    } else if stop == false {
                        // 正常结束
                        maxToken.unseal()
                        completion(in: store)
                    }
                }
            }
        }        

        Timer.publish(every: store.state.loading.minTime, on: .main, in: .common).autoconnect().sink { _ in
            minToken.unseal()
            start = true
        }.seal(in: minToken)
        
        Timer.publish(every: store.state.loading.maxTime, on: .main, in: .common).autoconnect().sink { _ in
            minToken.unseal()
            maxToken.unseal()
            stop = true
            // 超过时间
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                completion(in: store)
            }
        }.seal(in: maxToken)
    }
    
    func completion(in store: Store) {
        let time = Date().timeIntervalSince1970 - self.startDate.timeIntervalSince1970
        var model: [String] = []
        let isSimilarPhoto = store.state.photoManagement.loadModel!.loaded.similarPhoto.flatMap{$0}.count > 0 ? "1" : "0"
        let isSimilarVideo = store.state.photoManagement.loadModel!.loaded.similarVideo.flatMap{$0}.count > 0 ? "1" : "0"
        let isScreenshot = store.state.photoManagement.loadModel!.loaded.screenshot.flatMap{$0}.count > 0 ? "1" : "0"
        let isBigPhoto = store.state.photoManagement.loadModel!.loaded.largePhoto.flatMap{$0}.count > 0 ? "1" : "0"
        let isBigVideo = store.state.photoManagement.loadModel!.loaded.largeVideo.flatMap{$0}.count > 0 ? "1" : "0"
        let isBlurry = store.state.photoManagement.loadModel!.loaded.blurryPhoto.flatMap{$0}.count > 0 ? "1" : "0"
        switch store.state.photoManagement.loadModel?.event {
        case .photo:
            model = [isSimilarPhoto,isScreenshot, isBigPhoto, isBlurry]
            let string = model.joined(separator: ",")
            store.dispatch(.logEvent(.photoLoadSuccess, ["once": "\(ceil(time))", "result": string]))
        case .video:
            model = [isSimilarVideo, isBigVideo]
            let string = model.joined(separator: ",")
            store.dispatch(.logEvent(.videoLoadSuccess, ["once": "\(ceil(time))", "result": string]))
        default: break
        }
        store.dispatch(.loadingPushEvent(true))
        store.dispatch(.logEvent(.scanSucess))
    }
}

struct PhotoDiskCommand: Command {
    let loads: PhotoLoadModel?
    init(_ loads: PhotoLoadModel?) {
        self.loads = loads
    }
    
    func execute(in store: Store) {
        // 默认全部选中
        if let displayLoad = store.state.photoManagement.displayLoadModel, let load = self.loads {
            load.loaded.similarPhoto = load.loaded.similarPhoto.map{
                $0.sorted {
                    $0.imageDataLength > $1.imageDataLength
                }
            }.filter({
                $0.count > 0
            })
            
            load.loaded.similarVideo = load.loaded.similarVideo.map{
                $0.sorted {
                    $0.imageDataLength > $1.imageDataLength
                }
            }.filter({
                $0.count > 0
            })
            
            displayLoad.loaded = load.loaded
            AppState.PhotoManagement.Point.allCases.forEach {
                store.dispatch(.photoAllSelect($0, false))
            }
        }
        
        if let load = store.state.photoManagement.loadModel {
            let loaded = load.loaded
            let similarPhotoDisk = loaded.similarPhoto.flatMap({
                $0
            }).map { item in
                item.imageDataLength
            }.reduce(0, +)
            
            let screeshot = loaded.screenshot.flatMap({
                $0
            }).map {
                $0.imageDataLength
            }.reduce(0, +)
            
            let largePhoto = loaded.largePhoto.flatMap({
                $0
            }).map {
                $0.imageDataLength
            }.reduce(0, +)
            
            let blurryPhoto = loaded.blurryPhoto.flatMap({
                $0
            }).map {
                $0.imageDataLength
            }.reduce(0, +)
            
            let similarVideo = loaded.similarVideo.flatMap({
                $0
            }).map { item in
                item.imageDataLength
            }.reduce(0, +)
            
            let largeVideo = loaded.largeVideo.flatMap({
                $0
            }).map {
                $0.imageDataLength
            }.reduce(0, +)
            
            if load.event == .smart {
                store.dispatch(.smartDisk(similarPhotoDisk + screeshot + largePhoto + blurryPhoto + similarVideo + largeVideo))
            } else if load.event == .video {
                store.dispatch(.videoDisk(similarVideo + largeVideo))
            } else if load.event == .photo {
                store.dispatch(.photoDisk(similarPhotoDisk + screeshot + largePhoto + blurryPhoto))
            }
        }
    }
}

struct PhotoDeleteCommand: Command {
    let point: AppState.PhotoManagement.Point
    init(_ point: AppState.PhotoManagement.Point) {
        self.point = point
    }
    func execute(in store: Store) {
        var assets: [PHAsset] = []
        switch point {
        case .similarPhoto:
            assets = store.state.photoManagement.similarSelectArray.map({
                if let asset = $0.asset {
                    return asset
                }
                debugPrint("[clean] 错误 asset 为 nil")
                return  PHAsset()
            })
        case .similarVideo:
            assets = store.state.photoManagement.similarVideoSelectArray.map({
                if let asset = $0.asset {
                    return asset
                }
                debugPrint("[clean] 错误 asset 为 nil")
                return  PHAsset()
            })
        case .screenshot:
            assets = store.state.photoManagement.screenshotSelectArray.map({
                if let asset = $0.asset {
                    return asset
                }
                debugPrint("[clean] 错误 asset 为 nil")
                return  PHAsset()
            })
        case .largePhoto:
            assets = store.state.photoManagement.largeSelectArray.map({
                if let asset = $0.asset {
                    return asset
                }
                debugPrint("[clean] 错误 asset 为 nil")
                return  PHAsset()
            })
        case .blurryPhoto:
            assets = store.state.photoManagement.blurrySelectArray.map({
                if let asset = $0.asset {
                    return asset
                }
                debugPrint("[clean] 错误 asset 为 nil")
                return  PHAsset()
            })
        case .largeVideo:
            assets = store.state.photoManagement.largeVideoSelectArray.map({
                if let asset = $0.asset {
                    return asset
                }
                debugPrint("[clean] 错误 asset 为 nil")
                return  PHAsset()
            })
        }
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        } completionHandler: { isSuccess, error in
            if isSuccess {
                var message = ""
                delete(point: point, in: store)
                if assets.count > 1 {
                    if self.point.isVideo {
                        message = "\(assets.count) videos cleaned successfully"
                    } else {
                        message = "\(assets.count) photos cleaned successfully"
                    }
                } else {
                    if self.point.isVideo {
                        message = "\(assets.count) video cleaned successfully"
                    } else {
                        message = "\(assets.count) photo cleaned successfully"
                    }
                }
                store.dispatch(.rootAlert(message))
            }
        }
    }
    
    func delete(point: AppState.PhotoManagement.Point, in store: Store) {
        switch point {
        case .similarPhoto:
            let similarPhoto = store.state.photoManagement.displayLoadModel?.loaded.similarPhoto
            let result: [[PhotoItem]] = similarPhoto.flatMap{
                $0.map {
                    $0.filter {
                        $0.isSelected == false
                    }
                }.filter {
                    $0.count > 0
                }
            } ?? []
            store.state.photoManagement.loadModel?.loaded.similarPhoto = result
            store.state.photoManagement.displayLoadModel?.loaded.similarPhoto = result
        case .similarVideo:
            let similarVideo = store.state.photoManagement.displayLoadModel?.loaded.similarVideo
            let result: [[PhotoItem]] = similarVideo.flatMap{
                $0.map {
                    $0.filter {
                        $0.isSelected == false
                    }
                }.filter {
                    $0.count > 0
                }
            } ?? []
            store.state.photoManagement.loadModel?.loaded.similarVideo = result
            store.state.photoManagement.displayLoadModel?.loaded.similarVideo = result
        case .screenshot:
            let similarPhoto = store.state.photoManagement.displayLoadModel?.loaded.screenshot
            let result: [[PhotoItem]] = similarPhoto.flatMap{
                $0.map {
                    $0.filter {
                        $0.isSelected == false
                    }
                }.filter {
                    $0.count > 0
                }
            } ?? []
            store.state.photoManagement.loadModel?.loaded.screenshot = result
            store.state.photoManagement.displayLoadModel?.loaded.screenshot = result
        case .largePhoto:
            let similarPhoto = store.state.photoManagement.displayLoadModel?.loaded.largePhoto
            let result: [[PhotoItem]] = similarPhoto.flatMap{
                $0.map {
                    $0.filter {
                        $0.isSelected == false
                    }
                }.filter {
                    $0.count > 0
                }
            } ?? []
            store.state.photoManagement.loadModel?.loaded.largePhoto = result
            store.state.photoManagement.displayLoadModel?.loaded.largePhoto = result
        case .blurryPhoto:
            let similarPhoto = store.state.photoManagement.displayLoadModel?.loaded.blurryPhoto
            let result: [[PhotoItem]] = similarPhoto.flatMap{
                $0.map {
                    $0.filter {
                        $0.isSelected == false
                    }
                }.filter {
                    $0.count > 0
                }
            } ?? []
            store.state.photoManagement.loadModel?.loaded.blurryPhoto = result
            store.state.photoManagement.displayLoadModel?.loaded.blurryPhoto = result
        case .largeVideo:
            let similarPhoto = store.state.photoManagement.displayLoadModel?.loaded.largeVideo
            let result: [[PhotoItem]] = similarPhoto.flatMap{
                $0.map {
                    $0.filter {
                        $0.isSelected == false
                    }
                }.filter {
                    $0.count > 0
                }
            } ?? []
            store.state.photoManagement.loadModel?.loaded.largeVideo = result
            store.state.photoManagement.displayLoadModel?.loaded.largeVideo = result
        }
    }
}

struct PhotoCancelCommand: Command {
    let point: AppState.PhotoManagement.Point
    init(_ point: AppState.PhotoManagement.Point) {
        self.point = point
    }
    func execute(in store: Store) {
        guard let displayLoad = store.state.photoManagement.displayLoadModel else { return }
        switch point {
        case .similarPhoto:
            displayLoad.loaded.similarPhoto = displayLoad.loaded.similarPhoto.compactMap({
                $0.map {
                    PhotoItem(asset: $0.asset, image: $0.image, imageDataLength: $0.imageDataLength, isSelected: false, isBest: $0.isBest, second: $0.second)
                }
            })
        case .similarVideo:
            displayLoad.loaded.similarVideo = displayLoad.loaded.similarVideo.compactMap({
                $0.map {
                    PhotoItem(asset: $0.asset, image: $0.image, imageDataLength: $0.imageDataLength, isSelected: false, isBest: $0.isBest, second: $0.second)
                }
            })
        case .screenshot:
            displayLoad.loaded.screenshot = displayLoad.loaded.screenshot.compactMap({
                $0.map {
                    PhotoItem(asset: $0.asset, image: $0.image, imageDataLength: $0.imageDataLength, isSelected: false, isBest: $0.isBest, second: $0.second)
                }
            })
        case .largePhoto:
            displayLoad.loaded.largePhoto = displayLoad.loaded.largePhoto.compactMap({
                $0.map {
                    PhotoItem(asset: $0.asset, image: $0.image, imageDataLength: $0.imageDataLength, isSelected: false, isBest: $0.isBest, second: $0.second)
                }
            })
        case .blurryPhoto:
            displayLoad.loaded.blurryPhoto = displayLoad.loaded.blurryPhoto.compactMap({
                $0.map {
                    PhotoItem(asset: $0.asset, image: $0.image, imageDataLength: $0.imageDataLength, isSelected: false, isBest: $0.isBest, second: $0.second)
                }
            })
        case .largeVideo:
            displayLoad.loaded.largeVideo = displayLoad.loaded.largeVideo.compactMap({
                $0.map {
                    PhotoItem(asset: $0.asset, image: $0.image, imageDataLength: $0.imageDataLength, isSelected: false, isBest: $0.isBest, second: $0.second)
                }
            })
        }
    }
}

struct PhotoAllSelectCommand: Command {
    let point: AppState.PhotoManagement.Point
    let isAll: Bool
    init(_ point: AppState.PhotoManagement.Point, _ all: Bool) {
        self.point = point
        self.isAll = all
    }
    func execute(in store: Store) {
        guard let displayLoad = store.state.photoManagement.displayLoadModel else { return }
        switch point {
        case .similarPhoto:
            displayLoad.loaded.similarPhoto = displayLoad.loaded.similarPhoto.compactMap({ itemArray in
                itemArray.map {
                    PhotoItem(asset: $0.asset, image: $0.image, imageDataLength: $0.imageDataLength, isSelected: self.isAll ? true : $0 != itemArray.first, isBest: $0.isBest, second: $0.second)
                }
            })
            
        case .similarVideo:
            displayLoad.loaded.similarVideo = displayLoad.loaded.similarVideo.compactMap({ itemArray in
                itemArray.map {
                    PhotoItem(asset: $0.asset, image: $0.image, imageDataLength: $0.imageDataLength, isSelected: self.isAll ? true : $0 != itemArray.first, isBest: $0.isBest, second: $0.second)
                }
            })
        case .screenshot:
            displayLoad.loaded.screenshot = displayLoad.loaded.screenshot.compactMap({
                $0.map {
                    PhotoItem(asset: $0.asset, image: $0.image, imageDataLength: $0.imageDataLength, isSelected: true, isBest: $0.isBest, second: $0.second)
                }
            })
        case .largePhoto:
            displayLoad.loaded.largePhoto = displayLoad.loaded.largePhoto.compactMap({
                $0.map {
                    PhotoItem(asset: $0.asset, image: $0.image, imageDataLength: $0.imageDataLength, isSelected: true, isBest: $0.isBest, second: $0.second)
                }
            })
        case .blurryPhoto:
            displayLoad.loaded.blurryPhoto = displayLoad.loaded.blurryPhoto.compactMap({
                $0.map {
                    PhotoItem(asset: $0.asset, image: $0.image, imageDataLength: $0.imageDataLength, isSelected: true, isBest: $0.isBest, second: $0.second)
                }
            })
        case .largeVideo:
            displayLoad.loaded.largeVideo = displayLoad.loaded.largeVideo.compactMap({
                $0.map {
                    PhotoItem(asset: $0.asset, image: $0.image, imageDataLength: $0.imageDataLength, isSelected: true, isBest: $0.isBest, second: $0.second)
                }
            })
        }
    }
}

struct PhotoDidSelectCommand: Command {
    let item: PhotoItem
    init(_ item: PhotoItem) {
        self.item = item
    }
    func execute(in store: Store) {
        item.isSelected = !item.isSelected
    }
}

struct PhotoPatchCommand: Command {
    func execute(in store: Store) {
        
        let imageArray = store.state.patch.images
        let direction = store.state.patch.direction
        // 1.1.图片的宽度
       var width: CGFloat = 0
       // 1.2.图片的高度
       var height: CGFloat = 0

       // 1.3.遍历图片数组里的所有图片
       for image in imageArray {
           if direction == .vertical {
               // 1.3.1.获取每一张图片的宽度
               width = (image.size.width > width) ? image.size.width : width
               // 1.3.2.获取每一张图片的高度, 并且相加
               height += image.size.height
           } else {
               width += image.size.width
               if height ==  0 {
                   height = image.size.height
               } else {
                   height = (image.size.height < height) ? image.size.height : height
               }
           }
       }

       // 1.4.开始绘制图片的大小
       UIGraphicsBeginImageContext(CGSize(width: width, height: height))

       // 1.5.设置一个变量用来获取UIImage的Y值
       var imageY: CGFloat = 0

       // 1.6.遍历图片的数组
       for image in imageArray {
           if direction == .vertical {
               // 1.6.1.开始绘画图片
               image.draw(at: CGPoint(x: 0, y: imageY))
               // 1.6.2.自增每张图片的Y轴
               imageY += image.size.height
           } else {
               image.draw(at: CGPoint(x: imageY, y: 0))
               imageY += image.size.width
           }
       }

       // 1.7.获取已经绘制好的图片
       let drawImage = UIGraphicsGetImageFromCurrentImageContext()

       // 1.8.结束绘制图片
       UIGraphicsEndImageContext()
        
        if let drawImage = drawImage {
            UIImageWriteToSavedPhotosAlbum(drawImage, nil, nil, nil)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if drawImage != nil {
                store.dispatch(.rootAlert("photos saved successfully"))
            }
        }
    }
}

struct CompressionCommand: Command {
    let images: [UIImage]
    init(_ images: [UIImage]) {
        self.images = images
    }
    func execute(in store: Store) {
        let totalSize: Double = images.compactMap {
            Double($0.jpegData(compressionQuality: 1.0)?.count ?? 0)
        }.reduce(0, +) / 5.0
        let compressionArray:[Data] = images.compactMap {
            $0.jpegData(compressionQuality: 0.5)
        }

        let size = compressionArray.map {
            Double($0.count)
        }.reduce(0, +) / 5.0
        
        DispatchQueue.global().async {
            let compressionImages:[UIImage] = compressionArray.compactMap {
                UIImage(data: $0)
            }
            DispatchQueue.main.async {
                store.dispatch(.compressionImages(compressionImages))
            }
        }
        
        store.dispatch(.compressionSize(UInt64(totalSize - size)))
    }
}

struct CompressionStoreCommand: Command {
    let images: [UIImage]
    init(_ images: [UIImage]) {
        self.images = images
    }
    func execute(in store: Store) {
        _ = images.map {
            UIImageWriteToSavedPhotosAlbum($0, nil, nil, nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            store.dispatch(.rootAlert("photos saved successfully"))
        }
    }
}
