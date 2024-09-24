//
//  XPhotoAlbumComponent.swift
//  ZLPhotoBrowser
//
//  Created by admin on 2024/9/13.
//

import Foundation


// 定义通知名称
public extension Notification.Name {
    //统计相册数量
    public static let trackCameraCountsNotification = Notification.Name("trackCameraCountsNotification")
    //照片列表页展示
    public static let trackAlbumListPageShowNotification = Notification.Name("trackAlbumListPageShowNotification")
    //照片预览页展示
    public static let trackPreviewPageShowNotification = Notification.Name("trackPreviewPageShowNotification")
    //照片预览页
    public static let trackButtonClickNotification = Notification.Name("trackButtonClickNotification")
    //裁剪功能页展示
    public static let trackClipShowNotification = Notification.Name("trackClipShowNotification")
    //裁剪功能使用
    public static let trackClipClickNotification = Notification.Name("trackClipClickNotification")
    //相册功能
    public static let CameraCheckNotification = Notification.Name("CameraCheckNotification")
}

public class XPhotoAlbumComponent{
    
    static func notifyUTrackCameraCount(count:Int) {
        // 发送通知，包含事件名称和参数
        NotificationCenter.default.post(name: .trackCameraCountsNotification, object: nil, userInfo:["key":String(count)])
    }
    static func notifyPageShowOnPhotoPreviewVC() {
        // 发送通知，包含事件名称和参数
        NotificationCenter.default.post(name: .trackPreviewPageShowNotification, object: nil, userInfo:nil)
    }
    
    static func notifyAlbumPageShowOnPhotoVC(paramString:String?) {
        guard let paramString = paramString else {
            NotificationCenter.default.post(name: .trackAlbumListPageShowNotification, object: nil, userInfo:["key":"import_photo"])
            return
        }
        // 发送通知，包含事件名称和参数
        NotificationCenter.default.post(name: .trackAlbumListPageShowNotification, object: nil, userInfo:["key":paramString])
    }
    static func notifyBuottonClickPreviewVC(isClose:Bool) {
        // 发送通知，包含事件名称和参数
        NotificationCenter.default.post(name: .trackButtonClickNotification, object: nil, userInfo:["key": !isClose ? "edit_photos" : "close"])
    }
    
    static func notifyClipPageShow(paramString:String) {
        // 发送通知，包含事件名称和参数
        NotificationCenter.default.post(name: .trackClipShowNotification, object: nil, userInfo:["key":paramString])
    }
    
    static func notifyClipClick(paramString:String) {
        // 发送通知，包含事件名称和参数
        NotificationCenter.default.post(name: .trackClipClickNotification, object: nil, userInfo:["key":paramString])
    }
    static func notifyCameraCheck(paramInfo:[String:String]) {
        // 发送通知，包含事件名称和参数
        NotificationCenter.default.post(name: .CameraCheckNotification, object: nil, userInfo:paramInfo)
    }
    
}
