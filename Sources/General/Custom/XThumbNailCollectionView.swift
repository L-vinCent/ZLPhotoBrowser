//
//  XThumbNailCollectionView.swift
//  ZLPhotoBrowser
//
//  Created by admin on 2024/5/21.
//

import Foundation




class XThumbNailCollectionView:UIView{
    var offset: Int = 0
    
    var dataManager:XSelectedModelsManager
    var arrSelectedModels: [ZLPhotoModel] {
        return dataManager.arrSelectedModels
    }
    var hasLoadedNextBatch = false // 标志位

    /// 预览跳转
    var largeBlock: ((Int) -> Void)?
    var scrollowBlock: ((Int) -> Void)?

    var selectImageBlock: ((ZLPhotoModel) -> Void)?
    var showAddPhotoCell:Bool = false
    var showCameraCell:Bool = false


//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        addSubview(self.collectionView)
//    }
    init(dataManager: XSelectedModelsManager) {
          self.dataManager = dataManager
          super.init(frame: .zero)
          addSubview(self.collectionView)

      }
      
      required init?(coder: NSCoder) {
          fatalError("init(coder:) has not been implemented")
      }
    
    deinit{
        print("XThumbNailCollectionView deinit")
        
    }
//    convenience init() {
//        self.init()
//        self.arrSelectedModels = arrSelectedModels
//        print("arrSelectedModels 内存地址: \(Unmanaged.passUnretained(self.arrSelectedModels as AnyObject).toOpaque())")
//
//        addSubview(self.collectionView)
//    }
    
//    private func addPhotoModel(_ model: ZLPhotoModel) {
//        dataManager.add(model)
//    }
//    
//    private func removeAllModel() {
//        dataManager.removeAll()
//    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = self.bounds
    }
    
    lazy var collectionView: UICollectionView = {
        let layout = ZLCollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 3, left: 0, bottom: 3, right: 0)
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .zl.thumbnailBgColor
        view.dataSource = self
        view.delegate = self
        view.alwaysBounceVertical = true
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .always
        }
        ZLCameraCell.zl.register(view)
        ZLThumbnailPhotoCell.zl.register(view)
        ZLAddPhotoCell.zl.register(view)
        
        return view
    }()
    var arrDataSources: [ZLPhotoModel] = []{
        didSet{
            self.collectionView.reloadData()
            if arrDataSources.count != oldValue.count {
                hasLoadedNextBatch = false
//                print("test=====新\(arrDataSources.count)旧\(oldValue.count)")
            }
        }
    }
}

extension XThumbNailCollectionView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return ZLPhotoUIConfiguration.default().minimumInteritemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return ZLPhotoUIConfiguration.default().minimumLineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let uiConfig = ZLPhotoUIConfiguration.default()
        var columnCount: Int
        
        if let columnCountBlock = uiConfig.columnCountBlock {
            columnCount = columnCountBlock(collectionView.zl.width)
        } else {
            let defaultCount = uiConfig.columnCount
            columnCount = deviceIsiPad() ? (defaultCount + 2) : defaultCount
            if UIApplication.shared.statusBarOrientation.isLandscape {
                columnCount += 2
            }
        }
        
        let totalW = collectionView.bounds.width - CGFloat(columnCount - 1) * uiConfig.minimumInteritemSpacing
        let singleW = totalW / CGFloat(columnCount)
        return CGSize(width: singleW, height: singleW)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrDataSources.count + offset
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let config = ZLPhotoConfiguration.default()
        let uiConfig = ZLPhotoUIConfiguration.default()
        
        
        if showCameraCell, (uiConfig.sortAscending && indexPath.row == arrDataSources.count) || (!uiConfig.sortAscending && indexPath.row == 0) {
            // camera cell
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLCameraCell.zl.identifier, for: indexPath) as! ZLCameraCell
            
            if uiConfig.showCaptureImageOnTakePhotoBtn {
                cell.startCapture()
            }
            
            cell.isEnable = (arrSelectedModels.count ?? 0) < config.maxSelectCount
            
            return cell
        }
        
        if #available(iOS 14, *) {
            if self.showAddPhotoCell, (uiConfig.sortAscending && indexPath.row == self.arrDataSources.count - 1 + self.offset) || (!uiConfig.sortAscending && indexPath.row == self.offset - 1) {
                return collectionView.dequeueReusableCell(withReuseIdentifier: ZLAddPhotoCell.zl.identifier, for: indexPath)
            }
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLThumbnailPhotoCell.zl.identifier, for: indexPath) as! ZLThumbnailPhotoCell
        
        let model: ZLPhotoModel
        
        if !uiConfig.sortAscending {
            model = arrDataSources[indexPath.row - offset]
        } else {
            model = arrDataSources[indexPath.row]
        }
        
//        if (config.x_showCustomSelectedPreview){
//            model.isSelected = false
//        }

        
        
        cell.largeBlock = {[weak self] in
            self?.largeBlock?(indexPath.row)
//            guard let self = self,let sender = self.zl.findParentViewController() else {return}
//            let vc = ZLPhotoPreviewController(photos:self.arrDataSources, index: indexPath.row,showBottomViewAndSelectBtn: false)
//            sender.show(vc, sender: nil)
        }
        
        let chooseed = arrSelectedModels.containsModel(withIdent: model.ident)
        cell.chooseed = chooseed
        
        
        cell.selectedBlock = { [weak self,weak cell ] block in
            guard let cell = cell else { return }

            if !model.isSelected || config.x_showCustomSelectedPreview{
                let sender = self?.zl.findParentViewController()
                let currentSelectCount = self?.arrSelectedModels.count ?? 0
                guard canAddModel(model, currentSelectCount: currentSelectCount, sender:sender ) else {
                    return
                }
                
                downloadAssetIfNeed(model: model, sender: sender) {
                    if self?.shouldDirectEdit(model) == false {
                        model.isSelected = true

                        self?.dataManager.add(model)

                        block(true)
                        
                        let chooseed = self?.arrSelectedModels.containsModel(withIdent: model.ident)
                        cell.chooseed = chooseed
                        
                        config.didSelectAsset?(model.asset)
                        self?.refreshCellIndexAndMaskView()
                        
//                        print("arrSelectedModels 内存地址: \(Unmanaged.passUnretained(self?.arrSelectedModels as AnyObject).toOpaque())")

                        self?.selectImageBlock?(model)

//                        if  config.maxSelectCount == 1, config.x_showCustomSelectedPreview {
//                            //自定义模式下，单张图直接dismiss
//                            self?.selectImageBlock?()
//                        }
//                        
//                        if config.maxSelectCount == 1, !config.allowPreviewPhotos {
//                            self?.selectImageBlock?()
//                        }
                        
//                        self?.resetBottomToolBtnStatus()
//                        self?.resetCustomSelectPreviewStatus()
//                        self?.bottomSelectedPreview.scrollToRightmostItem()

                    }
                }
            } else {
                model.isSelected = false
//                self?.removeAllModel()
                self?.dataManager.remove(model)
                block(false)
                
                config.didDeselectAsset?(model.asset)
                self?.refreshCellIndexAndMaskView()
//                self?.resetBottomToolBtnStatus()
//                self?.resetCustomSelectPreviewStatus()
            }
        }
        
        if config.showSelectedIndex,
           let index = arrSelectedModels.firstIndex(where: { $0 == model }) {
            setCellIndex(cell, showIndexLabel: true, index: index + config.initialIndex)
        } else {
            cell.indexLabel.isHidden = true
        }
        
        setCellMaskView(cell, isSelected: model.isSelected, model: model)
        
        cell.model = model
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let c = cell as? ZLThumbnailPhotoCell else {
            return
        }
        var index = indexPath.row
        if !ZLPhotoUIConfiguration.default().sortAscending {
            index -= offset
        }
        let model = arrDataSources[index]
        setCellMaskView(c, isSelected: model.isSelected, model: model)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        guard let cell = cell as? ZLThumbnailPhotoCell else {
            return
        }
        
        let config = ZLPhotoConfiguration.default()
        let uiConfig = ZLPhotoUIConfiguration.default()
        
        if config.x_showCustomSelectedPreview{
            uiConfig.showInvalidMask = false
            uiConfig.showSelectedMask = false
            cell.btnSelectClick()
            return
        }

        
    }
    
     func reloadTarget(iden:String){
        guard let index = self.arrDataSources.firstIndex(where: {$0.ident == iden}) else {return}
        print("\(index)")
        self.collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
    }
    
    private func shouldDirectEdit(_ model: ZLPhotoModel) -> Bool {
        let config = ZLPhotoConfiguration.default()
        
        let canEditImage = config.editAfterSelectThumbnailImage &&
            config.allowEditImage &&
            config.maxSelectCount == 1 &&
            model.type.rawValue < ZLPhotoModel.MediaType.video.rawValue
        
        let canEditVideo = (config.editAfterSelectThumbnailImage &&
            config.allowEditVideo &&
            model.type == .video &&
            config.maxSelectCount == 1) ||
            (config.allowEditVideo &&
                model.type == .video &&
                !config.allowMixSelect &&
                config.cropVideoAfterSelectThumbnail)
        
        // 当前未选择图片 或已经选择了一张并且点击的是已选择的图片
//        let nav = navigationController as? ZLImageNavController
        let arrSelectedModels = arrSelectedModels ?? []
        let flag = arrSelectedModels.isEmpty || (arrSelectedModels.count == 1 && arrSelectedModels.first?.ident == model.ident)
        
        /*
        if canEditImage, flag {
            showEditImageVC(model: model)
        } else if canEditVideo, flag {
            showEditVideoVC(model: model)
        }
        */
        return flag && (canEditImage || canEditVideo)
    }
    
    private func setCellIndex(_ cell: ZLThumbnailPhotoCell?, showIndexLabel: Bool, index: Int) {
        guard ZLPhotoConfiguration.default().showSelectedIndex else {
            return
        }
        cell?.index = index
        cell?.indexLabel.isHidden = !showIndexLabel
    }
    
    private func refreshCellIndexAndMaskView() {
        refreshCameraCellStatus()
        let config = ZLPhotoConfiguration.default()
        let uiConfig = ZLPhotoUIConfiguration.default()
        let showIndex = config.showSelectedIndex
        let showMask = uiConfig.showSelectedMask || uiConfig.showInvalidMask
        
        guard showIndex || showMask else {
            return
        }
        
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        
        visibleIndexPaths.forEach { indexPath in
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? ZLThumbnailPhotoCell else {
                return
            }
            var row = indexPath.row
            if !uiConfig.sortAscending {
                row -= self.offset
            }
            let m = self.arrDataSources[row]
            
            let arrSel = arrSelectedModels ?? []
            var show = false
            var idx = 0
            var isSelected = false
            for (index, selM) in arrSel.enumerated() {
                if m == selM {
                    show = true
                    idx = index + config.initialIndex
                    isSelected = true
                    break
                }
            }
            if showIndex {
                self.setCellIndex(cell, showIndexLabel: show, index: idx)
            }
            if showMask {
                self.setCellMaskView(cell, isSelected: isSelected, model: m)
            }
        }
    }
    
    private func setCellMaskView(_ cell: ZLThumbnailPhotoCell, isSelected: Bool, model: ZLPhotoModel) {
        cell.coverView.isHidden = true
        cell.enableSelect = true
        let arrSel = arrSelectedModels ?? []
        let config = ZLPhotoConfiguration.default()
        let uiConfig = ZLPhotoUIConfiguration.default()
        
        if isSelected {
            cell.coverView.backgroundColor = .zl.selectedMaskColor
            cell.coverView.isHidden = !uiConfig.showSelectedMask
            if uiConfig.showSelectedBorder {
                cell.layer.borderWidth = 4
            }
        } else {
            let selCount = arrSel.count
            if selCount < config.maxSelectCount {
                if config.allowMixSelect {
                    let videoCount = arrSel.filter { $0.type == .video }.count
                    if videoCount >= config.maxVideoSelectCount, model.type == .video {
                        cell.coverView.backgroundColor = .zl.invalidMaskColor
                        cell.coverView.isHidden = !uiConfig.showInvalidMask
                        cell.enableSelect = false
                    } else if (config.maxSelectCount - selCount) <= (config.minVideoSelectCount - videoCount), model.type != .video {
                        cell.coverView.backgroundColor = .zl.invalidMaskColor
                        cell.coverView.isHidden = !uiConfig.showInvalidMask
                        cell.enableSelect = false
                    }
                } else if selCount > 0 {
                    cell.coverView.backgroundColor = .zl.invalidMaskColor
                    cell.coverView.isHidden = (!uiConfig.showInvalidMask || model.type != .video)
                    cell.enableSelect = model.type != .video
                }
            } else if selCount >= config.maxSelectCount {
                cell.coverView.backgroundColor = .zl.invalidMaskColor
                cell.coverView.isHidden = !uiConfig.showInvalidMask
                if(ZLPhotoConfiguration.default().x_showCustomSelectedPreview){
                    cell.enableSelect = true
                }else{
                    cell.enableSelect = false
                }
            }
            if uiConfig.showSelectedBorder {
                cell.layer.borderWidth = 0
            }
        }
    }
    
    private func refreshCameraCellStatus() {
        let count = dataManager.arrSelectedModels.count ?? 0
        
        for cell in collectionView.visibleCells {
            if let cell = cell as? ZLCameraCell {
                cell.isEnable = count < ZLPhotoConfiguration.default().maxSelectCount
                break
            }
        }
    }
}



extension XThumbNailCollectionView:UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 计算当前可视区域的起点
             let visibleRect = CGRect(origin: scrollView.contentOffset, size: scrollView.bounds.size)
             
             // 获取当前可视的所有cell
             let visibleCells = collectionView.visibleCells
             
//             // 获取当前可见的第一个cell的索引
//             if let firstVisibleCellIndexPath = collectionView.indexPathsForVisibleItems.last {
//                 let row = firstVisibleCellIndexPath.row
//                 let section = firstVisibleCellIndexPath.section
//                 print("当前可见第 \(section) 组，第 \(row) 行的 cell")
//             }
             
             // 计算滑动的2/3位置
             let scrollPosition = scrollView.contentOffset.y + scrollView.bounds.height
             let twoThirdsPosition = scrollView.contentSize.height * 4 / 5
             
             // 如果滑动到2/3的位置，触发回调
             if scrollPosition >= twoThirdsPosition && !hasLoadedNextBatch {
                 
                 let row = arrDataSources.count
                 let nextLoadingCount = calculateLimitCount(for: row)
                 self.scrollowBlock?(nextLoadingCount)
                hasLoadedNextBatch = true // 标志位
//                 print("view执行次数=====")

             }
        
    }
    
}
extension XThumbNailCollectionView{
    
    private func calculateLimitCount(for currentNums: Int) -> Int {
        switch currentNums {
        case 0..<5000:
            return 5000
        case 5000..<10000:
            return 10000
        case 10000..<20000:
            return 20000
        case 20000..<50000:
            return 50000
        default:
            return .max
        }
    }

    
}


