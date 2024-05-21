//
//  XDataSourcesManager.swift
//  ZLPhotoBrowser
//
//  Created by admin on 2024/5/21.
//

import Foundation

class XDataSourcesManager {
    static let shared = XDataSourcesManager()

    private init() {
        // 私有初始化方法，防止外部实例化
    }

    var arrSelectedModels: [ZLPhotoModel]?
    
    // 清除 arrSelectedModels 的方法
      func clearDatas() {
          arrSelectedModels?.removeAll()
          arrSelectedModels = nil
      }
}

extension XDataSourcesManager{
    //设置相册页数据
    static func customConfigure(){
        let config = ZLPhotoConfiguration.default()
        let uiConfig = ZLPhotoUIConfiguration.default()
        config.allowMixSelect = false
        config.allowEditVideo = false
        config.allowSelectVideo = false
        config.maxSelectCount = 9
        config.allowTakePhotoInLibrary = false
        config.allowSlideSelect = false
        config.x_showCustomSelectedPreview = true
        uiConfig.showAddPhotoButton = false
        uiConfig.columnCount = 3
        uiConfig.cellCornerRadio = 5
        uiConfig.sortAscending = false
        uiConfig.showSelectedPhotoPreview = false
        uiConfig.languageType = .chineseSimplified
    }
    
}
