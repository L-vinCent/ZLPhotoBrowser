//
//  XTempVC.swift
//  ZLPhotoBrowser
//
//  Created by admin on 2024/5/21.
//

import Foundation
import Photos

public class XPhotoViewController:UIViewController{
    private var collectionViewCache: [Int: XThumbNailCollectionView] = [:]

    //数据源 所有相册
    private var albumLists: [ZLAlbumListModel] = []
    //scrollow 所有内容view
    private var contentViews:[XThumbNailCollectionView] = []
    //完成的回调数据
    public var DoneImageBlock: (([ZLResultModel]) -> Void)?
    //失败的回调数据
    public var selectImageErrorBlock: (([PHAsset], [Int]) -> Void)?
    //当前页面销毁时，是否清理单例的数据，默认true ，某些特殊情况不销毁， 比如 拼图->替换照片调相册，选择照片后就不用销毁，因为要保证拼图那个相册页的原始数据
//    public var whenDeinitNeedClearSharedData:Bool = true
    //跳转的承接控制器
    private weak var sender: UIViewController?
    //预览页是否显示自定义选择按钮
    public var x_PreviewShowButton:Bool = false
    private var dataManager:XSelectedModelsManager = XSelectedModelsManager()
    private var arrSelectedModels: [ZLPhotoModel] {
        return dataManager.arrSelectedModels
    }
    
    //完成后获取图片的队列
    private lazy var fetchImageQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 3
        return queue
    }()
    
//    private var isScrolling = false // 标志位，用于跟踪用户是否在滑动页面
//    private var needsRefreshAfterScroll = false // 标志位，用于指示滑动停止后是否需要刷新


    
    
    //选中的数据
//    var arrSelectedModels: [ZLPhotoModel] = []
    
    
    // 导航栏
    private lazy var customNav: XCustomNavView = {
        let view = XCustomNavView()
        view.isHidden = false
        view.clickBackHandle = {[weak self] in
            guard let self = self else {return}
            NotificationCenter.default.removeObserver(self,name: .PuzzleAgainDidChange, object: nil)
//            PHPhotoLibrary.shared().unregisterChangeObserver(self)

            self.navigationController?.popViewController(animated: true)
        }
        return view
    }()
    
    //titleView
    private lazy var segmentView: XSegmentAlbumView = {
        let view = XSegmentAlbumView()
        view.isHidden = false
        view.clickSegHandle = {[weak self] selectedAlbum in
            guard let index = self?.albumLists.firstIndex(where: {$0 == selectedAlbum }) else {return}
            self?.scrollToIndex(index, animated: true)
        }
        return view
    }()
    
    //底部选择view
    private lazy var bottomSelectedPreview: CustomSelectedBottomPreview = {
        let view = CustomSelectedBottomPreview()
        view.backgroundColor = .zl.thumbnailBgColor
        view.isHidden = false
        view.bottomCloseClick = {[weak self] index in
            self?.closeTargetModel(index: index)
        }
        view.bottomStartClick = {[weak self] in
            self?.startPuzzle()
        }
        view.bottomHeightChanged = {[weak self] height in
            self?.heightChange()
        }
     
        return view
    }()
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: view.zl.width, height: view.zl.height))
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.zl.thumbnailBgColor
        scrollView.bounces = true
        scrollView.isScrollEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
//        scrollView.gestureRecognizerEnabledHandle = {[weak self] in
//            self?.gestureRecognizerEnabledHandle?($0)
//        }
        return scrollView
    }()
    
    //MARK: 生命周期
    public override func viewDidLayoutSubviews() {
        let navViewNormalH: CGFloat = 44

        var insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        var collectionViewInsetTop: CGFloat = 20
        if #available(iOS 11.0, *) {
            insets = view.safeAreaInsets
            collectionViewInsetTop = navViewNormalH
        } else {
            collectionViewInsetTop += navViewNormalH
        }
        
        
        var bottomViewH: CGFloat = bottomSelectedPreview.height
        if(ZLPhotoConfiguration.default().maxSelectCount == 1){
            bottomViewH = 0
            bottomSelectedPreview.isHidden = true
        }else{
            bottomSelectedPreview.isHidden = false
        }
        
        customNav.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: insets.top + navViewNormalH)
        segmentView.frame = CGRect(x: 0, y: customNav.zl.bottom, width: view.bounds.width, height: XSegmentAlbumView.height)
        bottomSelectedPreview.frame = CGRect(x: 0, y: view.frame.height - insets.bottom - bottomViewH, width: view.bounds.width, height: bottomViewH + insets.bottom)
        scrollView.frame =  CGRect(x: 0, y: segmentView.zl.bottom , width: view.zl.width, height: view.zl.height-customNav.zl.height -  XSegmentAlbumView.height - bottomViewH - insets.bottom)
        
    }
 
    public convenience init(with maxSelect:Int = 9,hudStyle:ZLProgressHUD.Style = .custom,autoPop:Bool = true) {
        self.init()
        ZLPhotoUIConfiguration.default().hudStyle = hudStyle
        ZLPhotoConfiguration.default().autoPopToVC = autoPop
        XSelectedModelsManager.customConfigure(maxSelect: maxSelect)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
        loadContent()
        // 注册相册变化观察者
        PHPhotoLibrary.shared().register(self)
    }
    
    private func configUI(){
        view.backgroundColor  = UIColor.zl.thumbnailBgColor
        view.addSubview(scrollView)
        view.addSubview(segmentView)
        view.addSubview(bottomSelectedPreview)
        view.addSubview(customNav)
        resetCustomSelectPreviewStatus()
        NotificationCenter.default.addObserver(self, selector: #selector(resetCurrentVCDidChange), name: .PuzzleAgainDidChange, object: nil)
        
    }
    
    
    private let albumLoadingQueue = OperationQueue() // 创建一个 NSOperationQueue 用于管理相册数据加载

    private func loadContent(show:Bool = true){
        var hud:ZLProgressHUD?
        if(show){
          hud = ZLProgressHUD.show(timeout: ZLPhotoUIConfiguration.default().timeout)
        }
//        let startTime = CFAbsoluteTimeGetCurrent()

      
      
        loadAlbumList { [weak self] in
//            let endTime = CFAbsoluteTimeGetCurrent()
//            print("相册清单花费时间\(endTime - startTime)")
            guard let self = self else {return}
            if (self.albumLists.isEmpty) {return}
            self.scrollView.contentSize = CGSize(width: self.view.zl.width * CGFloat(self.albumLists.count), height: 0)
            let firstPreviewAlbumModel = self.albumLists[0]
            firstPreviewAlbumModel.refetchPhotos(limitCount: 500)
            let newView = self.x_createCollectionView(index:0, datas: firstPreviewAlbumModel.models)
            self.collectionViewCache[0] = newView

            loadRemainingAlbums()
            
            if let temp = hud {
                temp.hide()
            }
        }
    }
    
    // 异步加载剩余的所有相册数据
    private func loadRemainingAlbums() {
        albumLoadingQueue.maxConcurrentOperationCount = 6 // 设置最大并发操作数
        // 处理第一个相册 (index 为 0)
           if let firstAlbum = albumLists.first {
               let loadFirstAlbumOperation = BlockOperation {
                   firstAlbum.refetchPhotos(limitCount: .max) // 加载从第 501 张到最后的照片
                   DispatchQueue.main.async { [weak self] in
                       guard let self = self else { return }
                       self.handleAlbumLoadCompletion(index: 0, models: firstAlbum.models)
                       print("第 0 个相册加载完成，刷新页面")
                   }
               }
               albumLoadingQueue.addOperation(loadFirstAlbumOperation)
           }
        
        for (index, album) in albumLists.enumerated() where index > 0 {
            let loadOperation = BlockOperation {
                album.refetchPhotos(limitCount: .max) // 加载所有剩余照片
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.handleAlbumLoadCompletion(index: index, models: album.models)
                    print("\(index) 加载完成，刷新页面")
                }
            }
            albumLoadingQueue.addOperation(loadOperation)
        }
    }
    // 处理相册数据加载完成
    private func handleAlbumLoadCompletion(index: Int, models: [ZLPhotoModel]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
//            // 判断当前是否在滑动状态
//            if self.isScrolling {
////                // 如果正在滑动，设置标志位，在滑动停止后刷新
//                self.needsRefreshAfterScroll = true
//            } else {
                // 如果页面静止，立即刷新显示

                if let existingView = self.collectionViewCache[index] {
                    // 已经创建，直接更新数据源
                    self.updateCollectionView(existingView, index: index)
                } else {
                    // 未创建，创建新的 CollectionView 并缓存
                    let newView = self.x_createCollectionView(index:index,datas:models)
                    self.collectionViewCache[index] = newView
                }
                
            }
//        }
    }
 
    
    deinit {
        print("XTempVC deinit")
        PHPhotoLibrary.shared().unregisterChangeObserver(self)

//        if(whenDeinitNeedClearSharedData){
//            XSelectedModelsManager.shared.clearDatas()
//        }
    }
    
}


//提供给外部的调用方法
extension XPhotoViewController{
    public func show(sender: UIViewController) {
        self.sender = sender
        checkPhotoLibraryAuthorization {
            sender.navigationController?.pushViewController(self, animated: true)
        }
    }
    
    // 检查权限的方法
    public func checkPhotoLibraryAuthorization(completion: @escaping () -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()

        switch status {
        case .restricted, .denied:
            showNoAuthorityAlert()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                ZLMainAsync {
                    if newStatus == .authorized {
                        completion()
                    } else {
                        self.showNoAuthorityAlert()
                    }
                }
            }
        case .authorized:
            completion()
        default:
            break
        }
    }
    
//     //外部调用的跳转
//    public func show(sender: UIViewController) {
//        self.sender = sender
//        let status = PHPhotoLibrary.authorizationStatus()
//        if status == .restricted || status == .denied {
//            showNoAuthorityAlert()
//        } else if status == .notDetermined {
//            PHPhotoLibrary.requestAuthorization { status in
//                ZLMainAsync {
//                    if status == .denied {
//                        self.showNoAuthorityAlert()
//                    } else if status == .authorized {
//                        sender.navigationController?.pushViewController(self, animated: true)
//                    }
//                }
//            }
//            
//        } else {
//            sender.navigationController?.pushViewController(self, animated: true)
//        }
//        
////        if #available(iOS 14.0, *), PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited {
////            PHPhotoLibrary.shared().register(self)
////        }
//    }

    private func showNoAuthorityAlert() {
        let action = ZLCustomAlertAction(title: localLanguageTextValue(.gotoSettings), style: .default) { _ in
            ZLPhotoConfiguration.default().noAuthorityCallback?(.library)
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        showAlertController(title: nil, message: String(format: localLanguageTextValue(.noPhotoLibratyAuthority), getAppName()), style: .alert, actions: [action], sender: sender)
    }

    
}

//MARK:  处理通知
extension XPhotoViewController {
    //重置到初始状态
    @objc private func resetCurrentVCDidChange() {
        
        contentViews.forEach { $0.collectionView.reloadData()}
        self.resetCustomSelectPreviewStatus()

    }
}

extension XPhotoViewController: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        ZLMainAsync {
            self.loadContent(show: false)
        }
    }
}



//MARK: 底部视图点击事件
extension XPhotoViewController{
    
    //底部 删除一张图片
    private func closeTargetModel(index:Int){
        let model = dataManager.arrSelectedModels[index]
        self.removeModelAtIndex(index)
        self.reloadAllContentTargetItems(model: model)
        self.resetCustomSelectPreviewStatus()
    }
    //开始拼图
    private func startPuzzle(){
        self.requestSelectPhoto()
    }
    
    //开始拼图
    private func heightChange(){
        view.setNeedsLayout()
        view.layoutIfNeeded()
        updateContentViewsHeight()
    }
    
    
}

//MARK: 创建滑动内容，数据加载
extension XPhotoViewController{
    
    private func loadAlbumList(completion: (() -> Void)? = nil) {
        
        DispatchQueue.global().async {
            ZLPhotoManager.getPhotoAlbumList(
                ascending: ZLPhotoUIConfiguration.default().sortAscending,
                allowSelectImage: ZLPhotoConfiguration.default().allowSelectImage,
                allowSelectVideo: ZLPhotoConfiguration.default().allowSelectVideo
            ) { [weak self] albumList in
                guard let self = self else {return}
                self.albumLists.removeAll()
                self.albumLists.append(contentsOf: albumList)
                ZLMainAsync {
                    completion?()
                    self.segmentView.arrDataSource = self.albumLists
                }
            }
        }
    }

    //仅内部调用创建控制器
    final func x_createCollectionView(index: Int,datas:[ZLPhotoModel]) -> XThumbNailCollectionView {
//        let labum = self.albumLists[index]
//        var datas: [ZLPhotoModel] = []
//        if labum.models.isEmpty {
//            labum.refetchPhotos()
//            datas.append(contentsOf: labum.models)
//        }
        
        let view = XThumbNailCollectionView(dataManager: dataManager)
        view.arrDataSources = datas
        view.selectImageBlock = {[weak self] model in
            if (ZLPhotoConfiguration.default().maxSelectCount == 1){
                //单图模式，直接返回数据
                self?.requestSelectPhoto()
                return
            }
            self?.resetCustomSelectPreviewStatus()
            //刷新所有contentView
            self?.reloadAllContentTargetItems(model: model)
            
        }
        view.largeBlock = {[weak self] index in
            guard let self = self else {return}
            let vc = ZLPhotoPreviewController(photos:datas, index: index,showBottomViewAndSelectBtn: false)
            vc.previewShowButton = self.x_PreviewShowButton
            vc.beautyEditBlock = {model in
//                self.dataManager.add(model)
                self.addPhotoModel(model)
                self.requestSelectPhoto()
            }
            self.show(vc, sender: nil)

        }
        //设置viewController的frame
        let X = scrollView.zl.width * CGFloat(index)
        let Y = 0
        let W = scrollView.zl.width
        let H = scrollView.zl.height
        view.frame = CGRect(x: X, y: CGFloat(Y), width: W, height: H)
        
        //将控制器的view添加到scrollView上
        self.scrollView.addSubview(view)
        self.contentViews.append(view)
        return view
    }
    // 更新 CollectionView 的方法
    private func updateCollectionView(_ collectionView: XThumbNailCollectionView, index: Int) {
        let album = self.albumLists[index]
        if album.models.isEmpty {
            album.refetchPhotos()
        }
        let datas = collectionView.arrDataSources
        collectionView.arrDataSources = album.models
        
        collectionView.largeBlock = { [weak self] index in
               guard let self = self else { return }
               // 使用当前更新的 `datas`
               let vc = ZLPhotoPreviewController(photos: datas, index: index, showBottomViewAndSelectBtn: false)
               vc.previewShowButton = self.x_PreviewShowButton
               vc.beautyEditBlock = { model in
                   self.addPhotoModel(model)
                   self.requestSelectPhoto()
               }
               self.show(vc, sender: nil)
           }
        
    }

    //更新视图高度
    func updateContentViewsHeight() {
        let H = scrollView.frame.height
         for (index, view) in contentViews.enumerated() {
             let X = scrollView.frame.width * CGFloat(index)
             let Y: CGFloat = 0
             let W = scrollView.frame.width
             view.frame = CGRect(x: X, y: Y, width: W, height: scrollView.frame.height)
         }
         // 更新 scrollView 的 contentSize
         scrollView.contentSize = CGSize(width: scrollView.frame.width * CGFloat(contentViews.count), height: H)
     }
    
}

//MARK: scroll 滚动相关方法
extension XPhotoViewController:UIScrollViewDelegate{
    // 滚动到指定的index
    private func scrollToIndex(_ index: Int, animated: Bool) {
        let offsetX = scrollView.bounds.width * CGFloat(index)
        let offset = CGPoint(x: offsetX, y: 0)
        scrollView.setContentOffset(offset, animated: animated)
    }
    
    
    
//    // 监听滑动状态的方法
//    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        isScrolling = true
//    }
//
//    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        if !decelerate {
//            isScrolling = false
//        }
//    }
//    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        isScrolling = false

        let pageWidth = scrollView.bounds.width
        let currentPage = Int(scrollView.contentOffset.x / pageWidth)
        segmentView.scrollToCurrentIndex(index: currentPage)
        // 你可以在这里添加更多逻辑来处理滚动结束后的操作
        
    }
}
//MARK: view 底部栏状态刷新
extension XPhotoViewController{
   
    //刷新自定义视图
    private func resetCustomSelectPreviewStatus() {
        
        self.bottomSelectedPreview.arrSelectedModels = arrSelectedModels
        var startTitle = ZLPhotoUIConfiguration.default().x_bottomCustomBtnTitle

        if(!arrSelectedModels.isEmpty){
            startTitle += "(" + String(arrSelectedModels.count) + ")"
        }
        
        self.bottomSelectedPreview.startTitle = startTitle
        self.bottomSelectedPreview.updateStartButton(isEnabled: arrSelectedModels.count >= ZLPhotoConfiguration.default().x_MinSelevtedPhoto)
        self.segmentView.currentIndex = 0
    }
    
}
//MARK: 一些私有方法
extension XPhotoViewController{
    
    private func reloadAllContentTargetItems(model:ZLPhotoModel?){
        guard let iden = model?.ident else {return}
        contentViews.forEach { $0.reloadTarget(iden:iden) }
    }
}

//MARK: 选中数据管理
extension XPhotoViewController{
    
    // 访问和修改 arrSelectedModels 的示例
    private func addPhotoModel(_ model: ZLPhotoModel) {
        dataManager.add(model)
    }
    private func removePhotoModel(_ model: ZLPhotoModel) {
        dataManager.remove(model)
    }
    private func removeModelAtIndex(_ index:Int){
        dataManager.removeAtIndex(index)
    }
    private func removeAllModel() {
        dataManager.removeAll()
    }
    
}

//MARK: 相册选择完成的回调 缩略图-原图

extension XPhotoViewController{
    

    private func requestSelectPhoto() {
        
        let config = ZLPhotoConfiguration.default()
        var isOriginal = true
        
        var hud:ZLProgressHUD?
        if let block = ZLPhotoUIConfiguration.default().xCustomHudShowBlock{
            block(true)
        }else{
            hud = ZLProgressHUD.show(toast: .loading, timeout: ZLPhotoUIConfiguration.default().timeout)
            var timeout = false
            hud?.timeoutBlock = { [weak self] in
                timeout = true
                showAlertView(localLanguageTextValue(.timeout), self)
                self?.fetchImageQueue.cancelAllOperations()
            }
        }
       
        let callback = { [weak self] (sucModels: [ZLResultModel], errorAssets: [PHAsset], errorIndexs: [Int]) in
            hud?.hide()
            if let block = ZLPhotoUIConfiguration.default().xCustomHudShowBlock{
                block(false)
            }
            func call() {
                self?.DoneImageBlock?(sucModels)
                if !errorAssets.isEmpty {
                    self?.selectImageErrorBlock?(errorAssets, errorIndexs)
                }
            }
            
            if(config.maxSelectCount > 1){
                //不做dismiss操作，直接跳转
                call()
                

                return
            }
            
            if(config.maxSelectCount == 1){
                //不做dismiss操作，直接跳转
                call()
                if(config.autoPopToVC){
                    self?.navigationController?.popViewController(animated: true)
                }else{
                    // 选择一张而且不做自动隐藏的情况下，跳转后要清除选中后的图片
                    self?.removeAllModel()
                }
//                PHPhotoLibrary.shared().unregisterChangeObserver(self)
                return
            }

                        
        }
        
        var results: [ZLResultModel?] = Array(repeating: nil, count: arrSelectedModels.count)
        var errorAssets: [PHAsset] = []
        var errorIndexs: [Int] = []
        var sucCount = 0
        let totalCount = arrSelectedModels.count
        for (i, m) in arrSelectedModels.enumerated() {
            
            let operation = ZLFetchImageOperation(model: m, isOriginal: isOriginal) { image, asset in
//                guard !timeout else { return }
                
                sucCount += 1
                
                if let image = image {
                    let isEdited = m.editImage != nil && !config.saveNewImageAfterEdit
                    let model = ZLResultModel(
                        asset: asset ?? m.asset,
                        image: image,
                        isEdited: isEdited,
                        editModel: isEdited ? m.editImageModel : nil,
                        index: i
                    )
                    results[i] = model
                    zl_debugPrint("ZLPhotoBrowser: suc request \(i)")
                } else {
                    errorAssets.append(m.asset)
                    errorIndexs.append(i)
                    zl_debugPrint("ZLPhotoBrowser: failed request \(i)")
                }
                
                guard sucCount >= totalCount else { return }
                
                callback(
                    results.compactMap { $0 },
                    errorAssets,
                    errorIndexs
                )
            }
            fetchImageQueue.addOperation(operation)
        }

    }

}
