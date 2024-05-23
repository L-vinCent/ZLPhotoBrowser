//
//  XDataSourcesManager.swift
//  ZLPhotoBrowser
//
//  Created by admin on 2024/5/21.
//

import Foundation

public class XDataSourcesManager {
    public static let shared = XDataSourcesManager()

    private init() {
        // 私有初始化方法，防止外部实例化
    }

    var arrSelectedModels: [ZLPhotoModel]?
    
    
    // 清除 arrSelectedModels 的方法
    public  func clearDatas() {
          arrSelectedModels?.removeAll()
          arrSelectedModels = nil
      }
    // 公有的 getter 方法
    public  func getArrSelectedModels() -> [ZLPhotoModel]? {
        return arrSelectedModels
    }
    
    // 公有的 setter 方法
    public func setArrSelectedModels(_ models: [ZLPhotoModel]?) {
        guard let models = models else {return}
        arrSelectedModels = models
        
    }
}

extension XDataSourcesManager{
    //设置相册页数据
    static func customConfigure(maxSelect:Int = 9){
        let config = ZLPhotoConfiguration.default()
        let uiConfig = ZLPhotoUIConfiguration.default()
        config.allowMixSelect = false
        config.allowEditVideo = false
        config.allowSelectVideo = false
        config.maxSelectCount = maxSelect
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

extension NSNotification.Name {

   public static let PuzzleAgainDidChange = NSNotification.Name("PuzzleAgainDidChange")
    
}
