//
//  XTempVC.swift
//  ZLPhotoBrowser
//
//  Created by admin on 2024/5/21.
//

import Foundation
import Photos

public class XTempVC:UIViewController{
    //数据源 所有相册
    private var albumLists: [ZLAlbumListModel] = []
    //segment用到，当前相册
    private var albumList: ZLAlbumListModel?
    //scrollow 所有内容view
    private var contentViews:[XThumbNailCollectionView] = []
    //完成的回调数据
    public var DoneImageBlock: (([ZLResultModel]) -> Void)?
    //失败的回调数据
    public var selectImageErrorBlock: (([PHAsset], [Int]) -> Void)?

    //完成后获取图片的队列
    private lazy var fetchImageQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 3
        return queue
    }()

    //存在单例的选中数据源，方便全局调用，在控制器销毁的时候会clear
    var arrSelectedModels: [ZLPhotoModel] {
        get {
            return XDataSourcesManager.shared.arrSelectedModels ?? []
        }
        set {
            XDataSourcesManager.shared.arrSelectedModels = newValue
        }
    }
    // 导航栏
    private lazy var customNav: XCustomNavView = {
        let view = XCustomNavView()
        view.isHidden = false
        view.clickBackHandle = {[weak self] in
            NotificationCenter.default.removeObserver(self,name: .PuzzleAgainDidChange, object: nil)

            self?.navigationController?.popViewController(animated: true)
        }
        return view
    }()
    
    //titleView
    private lazy var segmentView: XSegmentAlbumView = {
        let view = XSegmentAlbumView(selectedAlbum: albumList)
        view.isHidden = false
        view.clickSegHandle = {[weak self] selectedAlbum in
            self?.albumList = selectedAlbum
//            self?.loadPhotos()
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
        return view
    }()
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: view.zl.width, height: view.zl.height))
        scrollView.isPagingEnabled = true
//        scrollView.delegate = self
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
        
        var bottomViewH: CGFloat = CustomSelectedBottomPreview.height
        customNav.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: insets.top + navViewNormalH)
        segmentView.frame = CGRect(x: 0, y: customNav.zl.bottom, width: view.bounds.width, height: XSegmentAlbumView.height)
        bottomSelectedPreview.frame = CGRect(x: 0, y: view.frame.height - insets.bottom - bottomViewH, width: view.bounds.width, height: bottomViewH + insets.bottom)
        scrollView.frame =  CGRect(x: 0, y: segmentView.zl.bottom , width: view.zl.width, height: view.zl.height-customNav.zl.height -  XSegmentAlbumView.height - bottomViewH - insets.bottom)
    }
 
    public override func viewDidLoad() {
        super.viewDidLoad()
        XDataSourcesManager.customConfigure()
        configUI()
        loadContent()
    }
    
    private func configUI(){
        view.backgroundColor  = UIColor.zl.thumbnailBgColor
        view.addSubview(scrollView)
        view.addSubview(segmentView)
        view.addSubview(bottomSelectedPreview)
        view.addSubview(customNav)
        
        NotificationCenter.default.addObserver(self, selector: #selector(resetCurrentVCDidChange), name: .PuzzleAgainDidChange, object: nil)
        
    }
    
    private func loadContent(){
        let hud = ZLProgressHUD.show(timeout: ZLPhotoUIConfiguration.default().timeout)
        hud.show()
        loadAlbumList { [weak self] in
            guard let self = self else {return}
            if (self.albumLists.isEmpty) {return}
            self.scrollView.contentSize = CGSize(width: self.view.zl.width * CGFloat(self.albumLists.count), height: 0)
            for (index,item) in albumLists.enumerated(){
                self.x_createCollectionView(index)
            }
            hud.hide()
        }
    }
    
    deinit {
        print("XTempVC deinit")
        XDataSourcesManager.shared.clearDatas()
    }
    
}

//MARK:  处理通知
extension XTempVC {
    //重置到初始状态
    @objc private func resetCurrentVCDidChange() {
        arrSelectedModels.removeAll()
        contentViews.forEach { $0.collectionView.reloadData()}
        self.resetCustomSelectPreviewStatus()

    }

}


//MARK: 底部视图点击事件
extension XTempVC{
    
    //底部 删除一张图片
    private func closeTargetModel(index:Int){
        let model = self.arrSelectedModels[index]
        self.arrSelectedModels.remove(at: index)
        self.reloadAllContentTargetItems(model: model)
        self.resetCustomSelectPreviewStatus()
    }
    //开始拼图
    private func startPuzzle(){
//        var DoneSelectedModels:[ZLPhotoModel] = []
//        DoneSelectedModels.append(contentsOf: arrSelectedModels)
//        DoneImageBlock?(DoneSelectedModels)
        
        self.requestSelectPhoto()
    }
    
    
    
}

//MARK: 创建滑动内容，数据加载
extension XTempVC{
    
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
                if(!self.albumLists.isEmpty){
                    self.albumList = self.albumLists[0]
                }
                ZLMainAsync {
                    completion?()
                }
            }
        }
    }

    //仅内部调用创建控制器
    final func x_createCollectionView(_ index: Int)  {
        let labum = self.albumLists[index]
        var datas: [ZLPhotoModel] = []
        if labum.models.isEmpty {
            labum.refetchPhotos()
            datas.append(contentsOf: labum.models)
        }
        
        let view = XThumbNailCollectionView()
        view.arrDataSources = datas
        view.arrSelectedModels = self.arrSelectedModels
        view.selectImageBlock = {[weak self] models,model in
            self?.resetCustomSelectPreviewStatus()
            //刷新所有contentView
            self?.reloadAllContentTargetItems(model: model)
            
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
    }
    
}

//MARK: view 底部栏状态刷新
extension XTempVC{
   
    //刷新自定义视图
    private func resetCustomSelectPreviewStatus() {
        
        self.bottomSelectedPreview.arrSelectedModels = arrSelectedModels
        var startTitle = "开始拼图"
        if(!arrSelectedModels.isEmpty){
            startTitle += "(" + String(arrSelectedModels.count) + ")"
        }
        
        self.bottomSelectedPreview.startTitle = startTitle
        self.bottomSelectedPreview.updateStartButton(isEnabled: arrSelectedModels.count > 1)
    }
    
}
//MARK: 一些私有方法
extension XTempVC{
    
    private func reloadAllContentTargetItems(model:ZLPhotoModel?){
        guard let iden = model?.ident else {return}
        contentViews.forEach { $0.reloadTarget(iden:iden) }
    }
    
  
}
//MARK: 相册选择完成的回调 缩略图-原图

extension XTempVC{
    

    private func requestSelectPhoto() {
        
        let config = ZLPhotoConfiguration.default()
        var isOriginal = true
        
        let hud = ZLProgressHUD.show(toast: .processing, timeout: ZLPhotoUIConfiguration.default().timeout)
        var timeout = false
        hud.timeoutBlock = { [weak self] in
            timeout = true
            showAlertView(localLanguageTextValue(.timeout), self)
            self?.fetchImageQueue.cancelAllOperations()
        }
        
        let callback = { [weak self] (sucModels: [ZLResultModel], errorAssets: [PHAsset], errorIndexs: [Int]) in
            hud.hide()
            
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
            
            self?.dismiss(animated: true, completion: {
                call()
            })
            
            XDataSourcesManager.shared.clearDatas()
        }
        
        var results: [ZLResultModel?] = Array(repeating: nil, count: arrSelectedModels.count)
        var errorAssets: [PHAsset] = []
        var errorIndexs: [Int] = []
        var sucCount = 0
        let totalCount = arrSelectedModels.count
        
       
        
        
        for (i, m) in arrSelectedModels.enumerated() {
            
            let operation = ZLFetchImageOperation(model: m, isOriginal: isOriginal) { image, asset in
                guard !timeout else { return }
                
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
