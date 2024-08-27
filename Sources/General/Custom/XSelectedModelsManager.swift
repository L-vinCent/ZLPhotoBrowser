//
//  XDataSourcesManager.swift
//  ZLPhotoBrowser
//
//  Created by admin on 2024/5/21.
//

import Foundation

public class XSelectedModelsManager {

    private(set) var arrSelectedModels: [ZLPhotoModel] = []

    var onSelectionChanged: (() -> Void)?

    // 访问和修改 arrSelectedModels 的示例
    func add(_ model: ZLPhotoModel) {
        arrSelectedModels.append(model)
        onSelectionChanged?()
    }
    
    func remove(_ model: ZLPhotoModel) {
        if let index = arrSelectedModels.firstIndex(where: { $0 == model }) {
            arrSelectedModels.remove(at: index)
            onSelectionChanged?()
        }
    }
    
    func removeAtIndex(_ index: Int) {
        guard index >= 0 && index < arrSelectedModels.count else {
            print("Index out of bounds")
            return
        }
        arrSelectedModels.remove(at: index)
        onSelectionChanged?()
    }
    
    func removeAll() {
        arrSelectedModels.removeAll()
        onSelectionChanged?()
    }
    
}

extension XSelectedModelsManager{
    //设置相册页数据
    static func customConfigure(maxSelect:Int = 9){
        let config = ZLPhotoConfiguration.default()
        let uiConfig = ZLPhotoUIConfiguration.default()
        if(maxSelect == 9){
            uiConfig.x_bottomTipsLabelTitle = "请选择2~9张图片"
            uiConfig.x_bottomCustomBtnTitle = "开始拼图"
            config.x_MinSelevtedPhoto = 2

        }
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
