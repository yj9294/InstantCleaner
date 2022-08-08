//
//  PhotoCleanModel.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/8/1.
//

import Foundation
import Photos

class PhotoLoadModel: NSObject {
    init(_ event: AppState.PhotoManagement.Event) {
        self.event = event
    }
    var event: AppState.PhotoManagement.Event = .smart
    var loaded: PhotoLoadResultModel = PhotoLoadResultModel()
    var loading: Bool = false
    
    private var totalCount: Int = 0
    private var scanenCount: Int = 0
    private var progressHandle: ((Int)->Void)? = nil
}

extension PhotoLoadModel {
    public func load(_ style: AppState.PhotoManagement.Event, progress: ((Int)->Void)? = nil ) {
        event = style
        totalCount = 0
        scanenCount = 0
        progressHandle = progress
        loaded.removeAll()
        loading = true
        // 设置筛选条件
        let momentOptions = options(key: "startDate", ascending: false)
        let asstsOptions = options(key: "creationDate", ascending: false)
        // 获取所有照片
        let allPhotos = PHAsset.fetchAssets(with: asstsOptions)
        self.totalCount = allPhotos.count
        if PHPhotoLibrary.authorizationStatus(for: .readWrite) != .authorized {
            self.handleAssets(daysResults: allPhotos)
            return
        }
        DispatchQueue.global().async {
            let collectionList = PHCollectionList.fetchCollectionLists(with: .momentList, subtype: .momentListCluster, options: momentOptions)
            collectionList.enumerateObjects { momentobj, _, _ in
                // 获取时刻里面的Asset集合
                if !self.loading  {
                    debugPrint("[clean] 停止清理。")
                    return
                }
                let result = PHAssetCollection.fetchMoments(inMomentList: momentobj, options: momentOptions)
                result.enumerateObjects { collectionobj, _, _ in
                    if !self.loading  {
                        debugPrint("[clean] 停止清理。")
                        return
                    }
                    // 获取以天为单位的资源集合
                    let daysResults = PHAsset.fetchAssets(in: collectionobj, options: asstsOptions)
                    self.handleAssets(daysResults: daysResults)
                }
            }
        }
    }
    
    public func stopLoad() {
        loading = false
        AMSimilarityManager.stopClean()
    }
    
    private func options(key: String, ascending: Bool) -> PHFetchOptions {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: key, ascending: ascending)]
        return options
    }
    
    private func handleAssets(daysResults: PHFetchResult<PHAsset>) {
        var asset: [PHAsset] = []
        var videoAsset: [PHAsset] = []

        // 筛选媒体类型，只留照片类型
        daysResults.enumerateObjects { obj, idx, stop in
            if !self.loading  {
                debugPrint("[clean] 停止清理。")
                return
                
            }
            
            if self.event.isPhoto {
                if obj.mediaType == .image, obj.sourceType == .typeUserLibrary {
                    asset.append(obj)
                }
            }
            
            if self.event.isVideo {
                if obj.mediaType == .video, obj.sourceType == .typeUserLibrary {
                    videoAsset.append(obj)
                }
            }
            
            self.scanenCount += 1
        }
        
        if !self.loading  {
            debugPrint("[clean] 停止清理。")
            return
        }
        
        
        if event.isPhoto {
            if let photoSimilarArray = AMSimilarityManager.similarityGroup(asset)["similar"] as? [[PhotoItem]] {
                loaded.similarPhoto.append(contentsOf: photoSimilarArray)
            }
            
            if let array = AMSimilarityManager.similarityGroup(asset)["screenshot"] as? [PhotoItem], loaded.screenshot.count > 0 {
                loaded.screenshot[0].append(contentsOf: array)
            }
            
            if let array = AMSimilarityManager.similarityGroup(asset)["bigImage"] as? [PhotoItem], loaded.largePhoto.count > 0 {
                loaded.largePhoto[0].append(contentsOf: array)
            }
            
            if let array = AMSimilarityManager.similarityGroup(asset)["blurry"] as? [PhotoItem], loaded.blurryPhoto.count > 0 {
                loaded.blurryPhoto[0].append(contentsOf: array)
            }
        }
        
        if event.isVideo {
            if let array = AMSimilarityManager.similarityVideoGroup(videoAsset)["similar"] as? [[PhotoItem]] {
                loaded.similarVideo.append(contentsOf: array)
            }
            
            if let array = AMSimilarityManager.similarityVideoGroup(videoAsset)["bigImage"] as? [PhotoItem], loaded.largeVideo.count > 0 {
                loaded.largeVideo[0].append(contentsOf: array)
            }
        }
        if self.progressHandle != nil {
            debugPrint("[clean] 正在扫描\(scanenCount)/\(totalCount)")
            if self.totalCount == 0 {
                self.loading = false
                self.progressHandle!(100)
                return
            }
            let progress = (self.scanenCount) * 100 / self.totalCount
            if progress == 100 {
                self.loading = false
            }
            DispatchQueue.main.async {
                self.progressHandle!(progress)
            }
        }
    }
}


struct PhotoLoadResultModel {
    var similarPhoto: [[PhotoItem]] = [[]]
    var screenshot: [[PhotoItem]] = [[]]
    var largePhoto: [[PhotoItem]] = [[]]
    var blurryPhoto: [[PhotoItem]] = [[]]
    var similarVideo: [[PhotoItem]] = [[]]
    var largeVideo: [[PhotoItem]] = [[]]
    
    mutating func removeAll() {
        similarPhoto = [[]]
        screenshot = [[]]
        largePhoto = [[]]
        blurryPhoto = [[]]
        similarVideo = [[]]
        largeVideo = [[]]
    }
}
