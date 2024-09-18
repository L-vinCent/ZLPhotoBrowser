//
//  CustomSelectedBottomPreview.swift
//  ZLPhotoBrowser
//
//  Created by admin on 2024/5/24.
//


class CustomSelectedBottomPreview: UIView {
    var height: CGFloat{
        get{
            let height = arrSelectedModels.isEmpty ? 90.0 : 165.0
            return height
        }
    }
    
    var startTitle:String?{
        didSet{
            self.startBtn.setTitle(startTitle, for: .normal)
        }
    }
    
    var bottomCloseClick:((Int) -> Void)?
    var bottomStartClick:(() -> Void)?
    var bottomHeightChanged:((CGFloat) -> Void)?

    var arrSelectedModels: [ZLPhotoModel] = []{
        didSet{
            self.collectionView.reloadData()
            self.bottomHeightChanged?(CGFloat(height))
        }
    }

    
    private lazy var icon = UIImageView(image: .zl.getImage("zl_warning"))
    
    private lazy var tipsLabel: UILabel = {
        let label = UILabel()
        label.font = .zl.PingFangLight(size: 13)
        label.text = ZLPhotoUIConfiguration.default().x_bottomTipsLabelTitle
        label.textColor = ZLPhotoUIConfiguration.default().x_CustomTitleColor300
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    
    lazy var startBtn: UIButton = {
        let btn = UIButton(type: .custom)
        let title = ZLPhotoUIConfiguration.default().x_bottomCustomBtnTitle
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .zl.PingFangRegular(size: 14)
        btn.backgroundColor = ZLPhotoUIConfiguration.default().x_CustomSelectedBtnbgColor
        btn.addTarget(self, action: #selector(startBtnClick), for: .touchUpInside)
        btn.layer.cornerRadius = 5
        btn.layer.masksToBounds = true
        return btn
    }()
    
    
    lazy var collectionView: UICollectionView = {
        let layout = ZLCollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSizeMake(60, 60)
        layout.minimumLineSpacing = 5
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self
//        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        
        ZLPhotoPreviewSelectedViewCell.zl.register(view)
 
        
        return view
    }()
    
  
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(tipsLabel)
        addSubview(startBtn)
        addSubview(collectionView)
        self.backgroundColor = .zl.thumbnailBgColor
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *) {
            insets = self.safeAreaInsets
        }
        
        tipsLabel.frame = CGRect(x: 20, y:  26, width: 120, height: 20)
        startBtn.frame = CGRect(x: frame.width - 20 - 100, y:0 , width: 100, height: 30)
        startBtn.center.y = tipsLabel.center.y
        collectionView.frame = CGRect(x: 20, y:startBtn.zl.bottom + 15 ,width: frame.width - 20*2, height: 60)
        
    }
  
    
    func scrollToRightmostItem() {
        let itemCount = arrSelectedModels.count
        guard itemCount > 0 else { return }

        let lastItemIndex = itemCount - 1
        let lastIndexPath = IndexPath(item: lastItemIndex, section: 0)
        collectionView.scrollToItem(at: lastIndexPath, at: .right, animated: true)
    }

    
    func updateStartButton(isEnabled: Bool) {
        startBtn.isEnabled = isEnabled
        
        if isEnabled {
            // 如果按钮可用，设置正常的背景色和文字颜色
            startBtn.backgroundColor = ZLPhotoUIConfiguration.default().x_CustomSelectedBtnbgColor
            startBtn.setTitleColor(.white, for: .normal)
        } else {
            // 如果按钮不可用，设置灰色背景和白色文字颜色
            startBtn.backgroundColor = .zl.rgba(39, 38, 44,1)
            startBtn.setTitleColor(.zl.rgba(102, 102, 102,1), for: .normal)
        }
    }
    
    @objc private func startBtnClick() {
        //走完成选项
        self.bottomStartClick?()
    }
    
    deinit {
        print("控制器=====View deinit \(String(describing: self))")
    }
}


extension CustomSelectedBottomPreview:UICollectionViewDataSource,UICollectionViewDelegate{
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrSelectedModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLPhotoPreviewSelectedViewCell.zl.identifier, for: indexPath) as! ZLPhotoPreviewSelectedViewCell
        let m = arrSelectedModels[indexPath.row]
        cell.model = m
//        cell.closeHandleClick = {[weak self] in
//            self?.bottomCloseClick?(indexPath.row)
//        }
        return cell
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        self.bottomCloseClick?(indexPath.row)

    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let m = arrSelectedModels[indexPath.row]
   
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let indexPath = collectionView.indexPathForItem(at: gestureRecognizer.location(in: collectionView))
        return indexPath != nil
    }
    
 
}
