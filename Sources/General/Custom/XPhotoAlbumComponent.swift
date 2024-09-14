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

    //照片预览页展示
   public static let trackPageShowNotification = Notification.Name("trackPageShowNotification")
    //照片预览页
    public static let trackButtonClickNotification = Notification.Name("trackButtonClickNotification")
    //裁剪功能页展示
    public static let trackClipShowNotification = Notification.Name("trackClipShowNotification")
    //裁剪功能使用
    public static let trackClipClickNotification = Notification.Name("trackClipClickNotification")
}

public class XPhotoAlbumComponent{
    
    static func notifyUTrackCameraCount(count:Int) {
        // 发送通知，包含事件名称和参数
        NotificationCenter.default.post(name: .trackCameraCountsNotification, object: nil, userInfo:["key":String(count)])
    }
    static func notifyPageShowOnPhotoPreviewVC() {
        // 发送通知，包含事件名称和参数
        NotificationCenter.default.post(name: .trackPageShowNotification, object: nil, userInfo:nil)
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
    
    
}
