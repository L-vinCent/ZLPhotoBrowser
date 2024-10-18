//
//  ZLPhotoManager.swift
//  ZLPhotoBrowser
//
//  Created by long on 2020/8/11.
//
//  Copyright (c) 2020 Long Zhang <495181165@qq.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit
import Photos
import CoreImage
import ImageIO
import MobileCoreServices


@objcMembers
public class ZLPhotoManager: NSObject {
    /// Save image to album.
    public class func saveImageToAlbum(image: UIImage,name:String? = nil,metadata:[String: Any]? = nil,fileType:XImageFormat = .jpeg,completion: ((Bool, PHAsset?) -> Void)?) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .denied || status == .restricted {
            completion?(false, nil)
            return
        }
        var placeholderAsset: PHObjectPlaceholder?
        let completionHandler: ((Bool, Error?) -> Void) = { suc, _ in
            if suc {
                let asset = self.getAsset(from: placeholderAsset?.localIdentifier)
                ZLMainAsync {
                    completion?(suc, asset)
                }
            } else {
                ZLMainAsync {
                    completion?(false, nil)
                }
            }
        }

            switch fileType {
            case .heic, .heif: // Combine cases directly without `case` keyword in between
                // Handle HEIC and HEIF formats
                   if let data = image.heic(metadata: metadata){
                       PHPhotoLibrary.shared().performChanges({
                           let newAssetRequest = PHAssetCreationRequest.forAsset()
                           let options = PHAssetResourceCreationOptions()
                           options.originalFilename = name
                           newAssetRequest.addResource(with: .photo, data: data, options: options)
                           placeholderAsset = newAssetRequest.placeholderForCreatedAsset
                       }, completionHandler: completionHandler)
                   }else{
                       PHPhotoLibrary.shared().performChanges({
                           let newAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                           placeholderAsset = newAssetRequest.placeholderForCreatedAsset
                       }, completionHandler: completionHandler)
                   }
            default:
                // Create the data representation with metadata preserved.
                guard let data = image.jpeg(metadata: metadata) else {
                          PHPhotoLibrary.shared().performChanges({
                              let newAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                              placeholderAsset = newAssetRequest.placeholderForCreatedAsset
                          }, completionHandler: completionHandler)
                          return
                      }
                      
                      PHPhotoLibrary.shared().performChanges({
                          let newAssetRequest = PHAssetCreationRequest.forAsset()
                          let options = PHAssetResourceCreationOptions()
                          options.originalFilename = name
                          newAssetRequest.addResource(with: .photo, data: data, options: options)
                          placeholderAsset = newAssetRequest.placeholderForCreatedAsset
                      }, completionHandler: completionHandler)
            }

    }
   
    /// Save data to album.

    public class func saveImageToAlbum(data: Data,name:String? = nil ,completion: ((Bool, PHAsset?) -> Void)?) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .denied || status == .restricted {
            completion?(false, nil)
            return
        }
        var placeholderAsset: PHObjectPlaceholder?
        let completionHandler: ((Bool, Error?) -> Void) = { suc, _ in
            if suc {
                let asset = self.getAsset(from: placeholderAsset?.localIdentifier)
                ZLMainAsync {
                    completion?(suc, asset)
                }
            } else {
                ZLMainAsync {
                    completion?(false, nil)
                }
            }
        }

        PHPhotoLibrary.shared().performChanges({
            let newAssetRequest = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.originalFilename = name
            newAssetRequest.addResource(with: .photo, data: data, options: options)
            
        }, completionHandler: completionHandler)
        
    }
    
    
    /// Save video to album.
    public class func saveVideoToAlbum(url: URL, completion: ((Bool, PHAsset?) -> Void)?) {
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .denied || status == .restricted {
            completion?(false, nil)
            return
        }
        
        var placeholderAsset: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let newAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            placeholderAsset = newAssetRequest?.placeholderForCreatedAsset
        }) { suc, _ in
            if suc {
                let asset = self.getAsset(from: placeholderAsset?.localIdentifier)
                ZLMainAsync {
                    completion?(suc, asset)
                }
            } else {
                ZLMainAsync {
                    completion?(false, nil)
                }
            }
        }
    }
    
    private class func getAsset(from localIdentifier: String?) -> PHAsset? {
        guard let id = localIdentifier else {
            return nil
        }
        
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        return result.firstObject
    }
    
    /// Fetch photos from result.
    public class func fetchPhoto(in result: PHFetchResult<PHAsset>, ascending: Bool, allowSelectImage: Bool, allowSelectVideo: Bool, limitCount: Int = .max) -> [ZLPhotoModel] {
        var models: [ZLPhotoModel] = []
        let option: NSEnumerationOptions = ascending ? .init(rawValue: 0) : .reverse
        var count = 1
        
        result.enumerateObjects(options: option) { asset, _, stop in
            let m = ZLPhotoModel(asset: asset)
            
            if m.type == .image, !allowSelectImage {
                return
            }
            if m.type == .video, !allowSelectVideo {
                return
            }
            if count == limitCount {
                stop.pointee = true
            }
            
            models.append(m)
            count += 1
        }
        
        return models
    }
    
    /// Fetch all album list.
    public class func getPhotoAlbumList(ascending: Bool, allowSelectImage: Bool, allowSelectVideo: Bool, completion: ([ZLAlbumListModel]) -> Void) {
        let option = PHFetchOptions()
        if !allowSelectImage {
            option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.video.rawValue)
        }
        if !allowSelectVideo {
            option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
        }
       
//        option.predicate = NSPredicate(format: "isInCloud == NO") // 仅获取已下载的照片
        
        
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil) as? PHFetchResult<PHCollection>
        let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil) as? PHFetchResult<PHCollection>
        let streamAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumMyPhotoStream, options: nil) as? PHFetchResult<PHCollection>
        let syncedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumSyncedAlbum, options: nil) as? PHFetchResult<PHCollection>
        let sharedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumCloudShared, options: nil) as? PHFetchResult<PHCollection>
        let arr = [smartAlbums, albums, streamAlbums, syncedAlbums, sharedAlbums].compactMap { $0 }
        
        var albumList: [ZLAlbumListModel] = []
        arr.forEach { album in
            album.enumerateObjects { collection, _, _ in
                guard let collection = collection as? PHAssetCollection else { return }
                // 过滤掉“最近添加”的相册
                if collection.assetCollectionSubtype == .smartAlbumRecentlyAdded {
                    return
                }
                           
                if collection.assetCollectionSubtype == .smartAlbumAllHidden {
                    return
                }
                if #available(iOS 11.0, *), collection.assetCollectionSubtype.rawValue > PHAssetCollectionSubtype.smartAlbumLongExposures.rawValue {
                    return
                }
                let result = PHAsset.fetchAssets(in: collection, options: option)
                if result.count == 0 {
                    return
                }
                let title = self.getCollectionTitle(collection)
                
                if collection.assetCollectionSubtype == .smartAlbumUserLibrary {
                    // Album of all photos.
                    let m = ZLAlbumListModel(title: title, result: result, collection: collection, option: option, isCameraRoll: true)
                    albumList.insert(m, at: 0)
                } else {
                    let m = ZLAlbumListModel(title: title, result: result, collection: collection, option: option, isCameraRoll: false)
                    albumList.append(m)
                }
            }
        }
        
        completion(albumList)
    }
    
    /// Fetch camera roll album.
    public class func getCameraRollAlbum(allowSelectImage: Bool, allowSelectVideo: Bool, completion: @escaping (ZLAlbumListModel) -> Void) {
        DispatchQueue.global().async {
            let option = PHFetchOptions()
            if !allowSelectImage {
                option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.video.rawValue)
            }
            if !allowSelectVideo {
                option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
            }
            
            let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
            smartAlbums.enumerateObjects { collection, _, stop in
                if collection.assetCollectionSubtype == .smartAlbumUserLibrary {
                    stop.pointee = true
                    
                    let result = PHAsset.fetchAssets(in: collection, options: option)
                    let albumModel = ZLAlbumListModel(title: self.getCollectionTitle(collection), result: result, collection: collection, option: option, isCameraRoll: true)
                    ZLMainAsync {
                        completion(albumModel)
                    }
                }
            }
        }
    }
    
    /// Conversion collection title.
    private class func getCollectionTitle(_ collection: PHAssetCollection) -> String {
        if collection.assetCollectionType == .album {
            // Albums created by user.
            var title: String?
            if ZLCustomLanguageDeploy.language == .system {
                title = collection.localizedTitle
            } else {
                switch collection.assetCollectionSubtype {
                case .albumMyPhotoStream:
                    title = localLanguageTextValue(.myPhotoStream)
                default:
                    title = collection.localizedTitle
                }
            }
            return title ?? localLanguageTextValue(.noTitleAlbumListPlaceholder)
        }
        
        var title: String?
        if ZLCustomLanguageDeploy.language == .system {
            title = collection.localizedTitle
        } else {
            switch collection.assetCollectionSubtype {
            case .smartAlbumUserLibrary:
                title = localLanguageTextValue(.cameraRoll)
            case .smartAlbumPanoramas:
                title = localLanguageTextValue(.panoramas)
            case .smartAlbumVideos:
                title = localLanguageTextValue(.videos)
            case .smartAlbumFavorites:
                title = localLanguageTextValue(.favorites)
            case .smartAlbumTimelapses:
                title = localLanguageTextValue(.timelapses)
            case .smartAlbumRecentlyAdded:
                title = localLanguageTextValue(.recentlyAdded)
            case .smartAlbumBursts:
                title = localLanguageTextValue(.bursts)
            case .smartAlbumSlomoVideos:
                title = localLanguageTextValue(.slomoVideos)
            case .smartAlbumSelfPortraits:
                title = localLanguageTextValue(.selfPortraits)
            case .smartAlbumScreenshots:
                title = localLanguageTextValue(.screenshots)
            case .smartAlbumDepthEffect:
                title = localLanguageTextValue(.depthEffect)
            case .smartAlbumLivePhotos:
                title = localLanguageTextValue(.livePhotos)
            default:
                title = collection.localizedTitle
            }
            
            if #available(iOS 11.0, *) {
                if collection.assetCollectionSubtype == PHAssetCollectionSubtype.smartAlbumAnimated {
                    title = localLanguageTextValue(.animated)
                }
            }
        }
        
        return title ?? localLanguageTextValue(.noTitleAlbumListPlaceholder)
    }
    
    @discardableResult
    public class func fetchImage(for asset: PHAsset, size: CGSize, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (UIImage?, Bool) -> Void) -> PHImageRequestID {
        return fetchImage(for: asset, size: size, resizeMode: .fast, progress: progress, completion: completion)
    }
    
    @discardableResult
    public class func fetchOriginalImage(for asset: PHAsset, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (UIImage?, Bool) -> Void) -> PHImageRequestID {
        
        var size = PHImageManagerMaximumSize
        let originalSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        let maxLength: CGFloat = CGFloat(ZLPhotoUIConfiguration.default().xMaxOriginalLongSize)
        if originalSize.width > maxLength || originalSize.height > maxLength {
            let aspectRatio = min(maxLength / originalSize.width, maxLength / originalSize.height)
            size = CGSize(width: originalSize.width * aspectRatio, height: originalSize.height * aspectRatio)
        }
        return fetchImage(for: asset, size: size, resizeMode: .fast, progress: progress, completion: completion)
    }
    
    /// Fetch asset data.
    @discardableResult
    public class func fetchOriginalImageData(for asset: PHAsset, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (Data, [AnyHashable: Any]?, Bool) -> Void) -> PHImageRequestID {
        let option = PHImageRequestOptions()
        if asset.zl.isGif {
            option.version = .original
        }
        option.isNetworkAccessAllowed = true
        option.resizeMode = .fast
        option.deliveryMode = .highQualityFormat
        option.progressHandler = { pro, error, stop, info in
            ZLMainAsync {
                progress?(CGFloat(pro), error, stop, info)
            }
        }
        
        let resultHandler: (Data?, [AnyHashable: Any]?) -> Void = { data, info in
            let cancel = info?[PHImageCancelledKey] as? Bool ?? false
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
            if !cancel, let data = data {
                completion(data, info, isDegraded)
            }
        }
        
        if #available(iOS 13.0, *) {
            return PHImageManager.default().requestImageDataAndOrientation(for: asset, options: option) { data, _, _, info in
                resultHandler(data, info)
            }
        } else {
            return PHImageManager.default().requestImageData(for: asset, options: option) { data, _, _, info in
                resultHandler(data, info)
            }
        }
    }
    
    /// Fetch image for asset.
    private class func fetchImage(for asset: PHAsset, size: CGSize, resizeMode: PHImageRequestOptionsResizeMode, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (UIImage?, Bool) -> Void) -> PHImageRequestID {
        let option = PHImageRequestOptions()
        option.resizeMode = resizeMode
        option.isNetworkAccessAllowed = true
        option.progressHandler = { pro, error, stop, info in
            ZLMainAsync {
                progress?(CGFloat(pro), error, stop, info)
            }
        }
        
        return PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: option) { image, info in
            var downloadFinished = false
            if let info = info {
                downloadFinished = !(info[PHImageCancelledKey] as? Bool ?? false) && (info[PHImageErrorKey] == nil)
            }
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
            if downloadFinished {
                ZLMainAsync {
                    completion(image, isDegraded)
                }
            }
        }
    }
    
    public class func fetchLivePhoto(for asset: PHAsset, completion: @escaping (PHLivePhoto?, [AnyHashable: Any]?, Bool) -> Void) -> PHImageRequestID {
        let option = PHLivePhotoRequestOptions()
        option.version = .current
        option.deliveryMode = .opportunistic
        option.isNetworkAccessAllowed = true
        
        return PHImageManager.default().requestLivePhoto(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: option) { livePhoto, info in
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
            completion(livePhoto, info, isDegraded)
        }
    }
    
    public class func fetchVideo(for asset: PHAsset, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (AVPlayerItem?, [AnyHashable: Any]?, Bool) -> Void) -> PHImageRequestID {
        let option = PHVideoRequestOptions()
        option.isNetworkAccessAllowed = true
        option.progressHandler = { pro, error, stop, info in
            ZLMainAsync {
                progress?(CGFloat(pro), error, stop, info)
            }
        }
        
        // https://github.com/longitachi/ZLPhotoBrowser/issues/369#issuecomment-728679135
        if asset.zl.isInCloud {
            return PHImageManager.default().requestExportSession(forVideo: asset, options: option, exportPreset: AVAssetExportPresetHighestQuality, resultHandler: { session, info in
                // iOS11 and earlier, callback is not on the main thread.
                ZLMainAsync {
                    let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
                    if let avAsset = session?.asset {
                        let item = AVPlayerItem(asset: avAsset)
                        completion(item, info, isDegraded)
                    } else {
                        completion(nil, nil, true)
                    }
                }
            })
        } else {
            return PHImageManager.default().requestPlayerItem(forVideo: asset, options: option) { item, info in
                // iOS11 and earlier, callback is not on the main thread.
                ZLMainAsync {
                    let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
                    completion(item, info, isDegraded)
                }
            }
        }
    }
    
    class func isFetchImageError(_ error: Error?) -> Bool {
        guard let error = error as NSError? else {
            return false
        }
        if error.domain == "CKErrorDomain" || error.domain == "CloudPhotoLibraryErrorDomain" {
            return true
        }
        return false
    }
    
    public class func fetchAVAsset(forVideo asset: PHAsset, completion: @escaping (AVAsset?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        
        if asset.zl.isInCloud {
            return PHImageManager.default().requestExportSession(forVideo: asset, options: options, exportPreset: AVAssetExportPresetHighestQuality) { session, info in
                // iOS11 and earlier, callback is not on the main thread.
                ZLMainAsync {
                    if let avAsset = session?.asset {
                        completion(avAsset, info)
                    } else {
                        completion(nil, info)
                    }
                }
            }
        } else {
            return PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, info in
                ZLMainAsync {
                    completion(avAsset, info)
                }
            }
        }
    }
    
    /// Fetch the size of asset. Unit is KB.
    public class func fetchAssetSize(for asset: PHAsset) -> ZLPhotoConfiguration.KBUnit? {
        guard let resource = PHAssetResource.assetResources(for: asset).first,
              let size = resource.value(forKey: "fileSize") as? CGFloat else {
            return nil
        }
        
        return size / 1024
    }
    
    /// Fetch asset local file path.
    /// - Note: Asynchronously to fetch the file path. calls completionHandler block on the main queue.
    public class func fetchAssetFilePath(for asset: PHAsset, completion: @escaping (String?) -> Void) {
        asset.requestContentEditingInput(with: nil) { input, _ in
            var path = input?.fullSizeImageURL?.absoluteString
            if path == nil,
               let dir = asset.value(forKey: "directory") as? String,
               let name = asset.zl.filename {
                path = String(format: "file:///var/mobile/Media/%@/%@", dir, name)
            }
            completion(path)
        }
    }
    public class func saveAssetAsImage(_ asset: PHAsset, toFile fileUrl: URL, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (UIImage?, Error?) -> Void) {
        guard let resource = asset.zl.resource else {
            completion(nil, NSError.assetSaveError)
            return
        }

        var timer: Timer?
        var canceled = false
        let pointer = UnsafeMutablePointer<PHImageRequestID>.allocate(capacity: MemoryLayout<Int32>.stride)
        pointer.pointee = PHInvalidImageRequestID
        
        func cleanTimer() {
            timer?.invalidate()
            timer = nil
        }

        func handleWriteCompletion(isDegraded: Bool, error: Error?, imageData: Data?) {
            if let error = error {
                cleanTimer()
                completion(nil, error)
            } else if !isDegraded {
                cleanTimer()
                // 转换为 UIImage 并调用 completion 回调
                if let data = imageData, let image = UIImage(data: data) {
                    completion(image, nil)
                } else {
                    completion(nil, NSError(domain: "ImageConversionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert data to UIImage."]))
                }
            }
        }

        timer = .scheduledTimer(withTimeInterval: ZLPhotoUIConfiguration.default().timeout, repeats: false) { _ in
            canceled = true
            PHImageManager.default().cancelImageRequest(pointer.pointee)
            completion(nil, NSError.timeoutError)
        }

        if asset.mediaType == .video {
            pointer.pointee = fetchVideo(for: asset) { _, error, _, _ in
                handleWriteCompletion(isDegraded: true, error: error, imageData: nil)
            } completion: { _, info, isDegraded in
                guard !canceled else { return }
                let error = info?[PHImageErrorKey] as? Error
                handleWriteCompletion(isDegraded: isDegraded, error: error, imageData: nil)
            }
        } else if asset.zl.isInCloud {
            pointer.pointee = fetchOriginalImageData(for: asset) { _, error, _, _ in
                handleWriteCompletion(isDegraded: true, error: error, imageData: nil)
            } completion: { imageData, info, isDegraded in
                guard !canceled else { return }
                let error = info?[PHImageErrorKey] as? Error
                handleWriteCompletion(isDegraded: isDegraded, error: error, imageData: imageData)
            }
        } else {
            fetchOriginalImage(for: asset, progress: progress) { image, isDegraded in
                guard !canceled else { return }
                if let image = image, let imageData = image.pngData() {
                    handleWriteCompletion(isDegraded: isDegraded, error: nil, imageData: imageData)
                } else {
                    handleWriteCompletion(isDegraded: isDegraded, error: nil, imageData: nil)
                }
            }
        }
    }
    /// Save asset original data to file url. Support save image and video.
    /// - Note: Asynchronously write to a local file. Calls completionHandler block on the main queue. If the asset object is in iCloud, it will be downloaded first and then written in the method. The timeout time is `ZLPhotoConfiguration.default().timeout`.
    public class func saveAsset(_ asset: PHAsset, toFile fileUrl: URL, completion: @escaping ((Error?) -> Void)) {
        guard let resource = asset.zl.resource else {
            completion(NSError.assetSaveError)
            return
        }
        
        let pointer = UnsafeMutablePointer<PHImageRequestID>.allocate(capacity: MemoryLayout<Int32>.stride)
        pointer.pointee = PHInvalidImageRequestID
        var canceled = false
        
        var timer: Timer? = .scheduledTimer(
            withTimeInterval: ZLPhotoUIConfiguration.default().timeout,
            repeats: false
        ) { timer in
            timer.invalidate()
            canceled = true
            PHImageManager.default().cancelImageRequest(pointer.pointee)
            
            completion(NSError.timeoutError)
        }
        
        func cleanTimer() {
            timer?.invalidate()
            timer = nil
        }
        
        func write(_ isDegraded: Bool, _ error: Error?) {
            if error != nil {
                cleanTimer()
                completion(error)
            } else if !isDegraded {
                cleanTimer()
                PHAssetResourceManager.default().writeData(for: resource, toFile: fileUrl, options: nil) { error in
                    ZLMainAsync {
                        completion(error)
                    }
                }
            }
        }
        
        if asset.mediaType == .video {
            pointer.pointee = fetchVideo(for: asset) { _, error, _, _ in
                write(true, error)
            } completion: { _, info, isDegraded in
                guard !canceled else { return }
                
                let error = info?[PHImageErrorKey] as? Error
                write(isDegraded, error)
            }
        } else if asset.zl.isInCloud {
            pointer.pointee = fetchOriginalImageData(for: asset) { _, error, _, _ in
                write(true, error)
            } completion: { _, info, isDegraded in
                guard !canceled else { return }
                
                let error = info?[PHImageErrorKey] as? Error
                write(isDegraded, error)
            }
        } else {
            write(false, nil)
        }
    }
}

/// Authority related.
public extension ZLPhotoManager {
    class func hasPhotoLibratyAuthority() -> Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }
    
    class func hasCameraAuthority() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .restricted || status == .denied {
            return false
        }
        return true
    }
    
    class func hasMicrophoneAuthority() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        if status == .restricted || status == .denied {
            return false
        }
        return true
    }
}


//MARK: 处理HEIF
extension ZLPhotoManager{
   
    public class func extractMetadata(from asset: PHAsset, completion: @escaping ([String: Any]?) -> Void) {
        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = true
        
        asset.requestContentEditingInput(with: options) { (input, _) in
            guard let input = input,
                  let url = input.fullSizeImageURL,
                  let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                completion(nil)
                return
            }
            
            // Extract metadata from the image
            let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any]
            completion(metadata)
        }
    }
    
    public class func getImageFormat(for asset: PHAsset) -> String? {
        // Get the list of resources associated with the PHAsset
        let resources = PHAssetResource.assetResources(for: asset)
        
        // Check the primary resource (original image)
        if let resource = resources.first {
            // Get the uniform type identifier (UTI) for the resource
            let uti = resource.uniformTypeIdentifier
            
            // Convert the UTI to a readable format (like JPEG, HEIF, etc.)
            if let fileType = UTTypeCopyDescription(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, uti as CFString, nil)?.takeRetainedValue() ?? uti as CFString)?.takeRetainedValue() {
                return fileType as String
            } else {
                return uti // Return the UTI if conversion fails
            }
        }
        
        return nil // Return nil if no resource is found
    }
    
    /// Create JPEG data with metadata.
    private class func createJPEGDataWithMetadata(from image: UIImage, metadata: [String: Any]?) -> Data? {
        guard let cgImage = image.zl.fixOrientation().cgImage else { return nil }
        
        // Create a mutable dictionary to hold the metadata including orientation.
        var mutableMetadata = metadata ?? [String: Any]()
        if let metadata = metadata,
           let orientationValue = metadata[kCGImagePropertyOrientation as String] as? UInt32 {
            // Map the orientation value to UIImage.Orientation
            let imageOrientation = UIImage.Orientation(rawValue: Int(orientationValue))
            print("图片方向\(imageOrientation)")
        }
//        let cgImageOrientation = cgImageOrientationFromUIImageOrientation(.up)
//          mutableMetadata[kCGImagePropertyOrientation as String] = cgImageOrientation
//
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData, kUTTypeJPEG, 1, nil) else { return nil }
        
        // Add the image to the destination with the metadata including orientation.
        CGImageDestinationAddImage(destination, cgImage, mutableMetadata as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        
        return mutableData as Data
    }
    private class func cgImageOrientationFromUIImageOrientation(_ orientation: UIImage.Orientation) -> UInt32 {
        switch orientation {
        case .up: return 0
        case .down: return 1
        case .left: return 8
        case .right: return 6
        case .upMirrored: return 2
        case .downMirrored: return 4
        case .leftMirrored: return 5
        case .rightMirrored: return 7
        default: return 1
        }
    }
}


extension UIImage{
    var cgImageOrientation: CGImagePropertyOrientation { .init(imageOrientation) }

    var heic: Data? { heic() }
    func heic(compressionQuality: CGFloat = 1,metadata: [String: Any]? = nil) -> Data? {
        guard
            let mutableData = CFDataCreateMutable(nil, 0),
            let destination = CGImageDestinationCreateWithData(mutableData, "public.heic" as CFString, 1, nil),
            let cgImage = cgImage
        else { return nil }
        // 创建一个可变的元数据字典，确保方向信息和其他元数据都被正确添加
        var mutableMetadata = metadata ?? [String: Any]()
        mutableMetadata[kCGImagePropertyOrientation as String] = cgImageOrientation.rawValue

        
        CGImageDestinationAddImage(destination, cgImage, mutableMetadata as CFDictionary)

        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
    
    func jpeg(compressionQuality: CGFloat = 1, metadata: [String: Any]? = nil) -> Data? {
           guard
               let mutableData = CFDataCreateMutable(nil, 0),
               let destination = CGImageDestinationCreateWithData(mutableData, kUTTypeJPEG, 1, nil),
               let cgImage = cgImage
           else { return nil }
           
           // 创建一个可变的元数据字典，确保方向信息和其他元数据都被正确添加
           let mutableMetadata = createMutableMetadata(from: metadata, withOrientation: cgImageOrientation)
//           mutableMetadata[kCGImagePropertyOrientation as String] = cgImageOrientation.rawValue
         let properties: [CFString: Any] = [
                    kCGImageDestinationLossyCompressionQuality: compressionQuality,
                    kCGImagePropertyOrientation: cgImageOrientation.rawValue,
                ]
           CGImageDestinationAddImage(destination, cgImage, mutableMetadata as CFDictionary)
           guard CGImageDestinationFinalize(destination) else { return nil }
           return mutableData as Data
       }
    
    func createMutableMetadata(from metadata: [String: Any]?, withOrientation orientation: CGImagePropertyOrientation) -> [String: Any] {
        // 创建一个新的可变字典来存储复制后的元数据
           var mutableMetadata = [String: Any]()

           // 遍历传入的元数据并复制所有键值对
           metadata?.forEach { key, value in
               mutableMetadata[key] = value
           }

           // 设置或更新顶层的 kCGImagePropertyOrientation 的值为指定的方向
           mutableMetadata[kCGImagePropertyOrientation as String] = orientation.rawValue

           // 如果存在 EXIF 元数据字典，则更新 EXIF 中的方向信息
           if var exifDict = mutableMetadata[kCGImagePropertyExifDictionary as String] as? [String: Any] {
               exifDict[kCGImagePropertyOrientation as String] = orientation.rawValue
               mutableMetadata[kCGImagePropertyExifDictionary as String] = exifDict
           } else {
               mutableMetadata[kCGImagePropertyExifDictionary as String] = [kCGImagePropertyOrientation as String: orientation.rawValue]
           }

           // 如果存在 TIFF 元数据字典，则更新 TIFF 中的方向信息
           if var tiffDict = mutableMetadata[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
               tiffDict[kCGImagePropertyOrientation as String] = orientation.rawValue
               mutableMetadata[kCGImagePropertyTIFFDictionary as String] = tiffDict
           } else {
               mutableMetadata[kCGImagePropertyTIFFDictionary as String] = [kCGImagePropertyOrientation as String: orientation.rawValue]
           }

           return mutableMetadata
    }
    
    
}

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
        @unknown default:
            fatalError()
        }
    }
}

