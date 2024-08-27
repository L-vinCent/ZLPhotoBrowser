//
//  ZLClipImageViewController.swift
//  ZLPhotoBrowser
//
//  Created by long on 2020/8/27.
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

extension ZLClipImageViewController {
    enum ClipPanEdge {
        case none
        case top
        case bottom
        case left
        case right
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
}
public typealias UMRotateTuple = (horFlip: Bool, verFlip: Bool,right90:Bool,left90:Bool)

public class ZLClipImageViewController: UIViewController {
    private static let bottomToolViewH: CGFloat = 90
    
    private static let clipRatioItemSize = CGSize(width: 48, height: 70)
    
    /// 取消裁剪时动画frame
    private var cancelClipAnimateFrame: CGRect = .zero
    
    private var viewDidAppearCount = 0
    
    private let originalImage: UIImage
//    private var mirrorImage: UIImage

    private var clipRatios :[XCropProportionEnum] = XCropProportionEnum.allCases
    private var clipRotates :[XCropRotateEnum] = XCropRotateEnum.allCases

    private let dimClippedAreaDuringAdjustments: Bool

    private var editImage: UIImage
//    //是否进行了翻转
    var flipTuple:FlipTuple = (false,false)
//    public var hasTransitioning:Bool = false
    
    /// 初次进入界面时候，裁剪范围
    private var editRect: CGRect
    
  

    private var shouldLayout = true
    
    private var panEdge: ZLClipImageViewController.ClipPanEdge = .none
    
    private var beginPanPoint: CGPoint = .zero
    
    private var clipBoxFrame: CGRect = .zero
    
    private var clipOriginFrame: CGRect = .zero
    
    private var isRotating = false
    
    private var angle: CGFloat = 0


    private var selectedRatio: XCropProportionEnum = .custom(size: .zero)
    
    private var thumbnailImage: UIImage?
    
    private lazy var maxClipFrame = calculateMaxClipFrame()
    
    private var minClipSize = CGSize(width: 45, height: 45)
    
    private var resetTimer: Timer?
    
    var animate = true
    /// 用作进入裁剪界面首次动画frame
    public var presentAnimateFrame: CGRect?
    /// 用作进入裁剪界面首次动画和取消裁剪时动画的image
    public var presentAnimateImage: UIImage?
    
    public var dismissAnimateFromRect: CGRect = .zero
    
    public var dismissAnimateImage: UIImage?
    
    public var animateImageView: UIImageView?

    /// 传回旋转角度，图片编辑区域的rect
    public var clipDoneBlock: ((CGFloat, CGRect, XCropProportionEnum) -> Void)?
    
    /// 传回旋转角度，图片编辑区域的rect
    public var xClipDoneBlock: ((ZLClipStatus,UIImage,UMRotateTuple) -> Void)?
    
    public var successClipBlock: ((UIImage) -> Void)?

    public var cancelClipBlock: (() -> Void)?
    
    private var UClickRotate: UMRotateTuple = UMRotateTuple(false,false,false,false)

    public override var prefersStatusBarHidden: Bool { true }
    
    public override var prefersHomeIndicatorAutoHidden: Bool { true }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    
    private lazy var mainScrollView: UIScrollView = {
        let view = UIScrollView()
        view.alwaysBounceVertical = true
        view.alwaysBounceHorizontal = true
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .never
        }
        view.delegate = self
        return view
    }()
    
    private lazy var containerView = UIView()
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.image = editImage
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var shadowView: ZLClipShadowView = {
        let view = ZLClipShadowView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
//        view.isCircle = selectedRatio.isCircle
        return view
    }()
    
    private lazy var overlayView: ZLClipOverlayView = {
        let view = ZLClipOverlayView()
        view.isUserInteractionEnabled = false
//        view.isCircle = selectedRatio.isCircle
        return view
    }()
    
    private lazy var gridPanGes: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(gridGesPanAction(_:)))
        pan.delegate = self
        return pan
    }()
    
    private lazy var bottomToolView = UIView()
    
//    private lazy var bottomShadowLayer: CAGradientLayer = {
//        let layer = CAGradientLayer()
//        layer.colors = [
//            UIColor.black.withAlphaComponent(0.15).cgColor,
//            UIColor.black.withAlphaComponent(0.35).cgColor
//        ]
//        layer.locations = [0, 1]
//        return layer
//    }()
    
    private lazy var bottomToolLineView: UIView = {
        let view = UIView()
        view.backgroundColor = .zl.rgba(240, 240, 240,0.1)
        return view
    }()
    
    private lazy var cancelBtn: ZLEnlargeButton = {
        let btn = ZLEnlargeButton(type: .custom)
        btn.setImage(.zl.getImage("crop_close"), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.enlargeInset = 20
        btn.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
        return btn
    }()
    
    private lazy var revertBtn: ZLEnlargeButton = {
        let btn = ZLEnlargeButton(type: .custom)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle(localLanguageTextValue(.revert), for: .normal)
        btn.enlargeInset = 20
        btn.titleLabel?.font = ZLLayout.bottomToolTitleFont
        btn.addTarget(self, action: #selector(revertBtnClick), for: .touchUpInside)
        return btn
    }()
    
    lazy var doneBtn: ZLEnlargeButton = {
        let btn = ZLEnlargeButton(type: .custom)
        btn.setImage(.zl.getImage("crop_sure"), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.enlargeInset = 20
        btn.addTarget(self, action: #selector(doneBtnClick), for: .touchUpInside)
        return btn
    }()
    
    private lazy var rotateBtn: ZLEnlargeButton = {
        let btn = ZLEnlargeButton(type: .custom)
        btn.setImage(.zl.getImage("zl_rotateimage"), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.enlargeInset = 20
//        btn.addTarget(self, action: #selector(rotateBtnClick), for: .touchUpInside)
        btn.isHidden = true
        return btn
    }()
    
    private lazy var clipRatioColView: UICollectionView = {
        let layout = ZLCollectionViewFlowLayout()
        layout.itemSize = ZLClipImageViewController.clipRatioItemSize
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .black
        view.isHidden = clipRatios.count <= 1
        view.showsHorizontalScrollIndicator = false
        
        ZLImageClipRatioCell.zl.register(view)
        return view
    }()
    
    private lazy var rotateColView: UICollectionView = {
        let layout = ZLCollectionViewFlowLayout()
        layout.itemSize = ZLClipImageViewController.clipRatioItemSize
        
        layout.sectionInset = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30)
//        let spacing = view.zl.width -  / 3
        layout.scrollDirection = .horizontal

        let width = (view.zl.width - 60 - (ZLClipImageViewController.clipRatioItemSize.width * 4)) / 3
//        layout.minimumInteritemSpacing = width
        layout.minimumLineSpacing = width
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .black
        
        view.showsHorizontalScrollIndicator = false
        view.isHidden = true
        ZLImageClipRatioCell.zl.register(view)
        return view
    }()
    
    private var currentClipSegment:XClipSegmentTap = .clip{
        didSet{
            let isClip = currentClipSegment == .clip ? true : false
            clipRatioColView.isHidden = !isClip
            rotateColView.isHidden = isClip
        }
    }
    
    //底部segment 布局、滤镜
    private lazy var segmentedControl: ZLClipSegmentView = {
        let titles = ["裁剪","旋转"]
        let control = ZLClipSegmentView(frame: .zero,titles: XClipSegmentTap.allCases) { [weak self] type in
            self?.handSegmentTap(type: type)
        }
        return control
    }()
    
    //MARK: 生命周期函数
    deinit {
        zl_debugPrint("ZLClipImageViewController deinit")
        cleanTimer()
    }
    //isRecordStatus wei ture,会根据status 状态记录上一次图片的裁剪状态和位置, false 默认不记录，进来就是新状态
    public init(image: UIImage, status: ZLClipStatus? = nil) {
       originalImage = image
//       mirrorImage = originalImage
       currentClipSegment = .clip
        let configuration = ZLPhotoConfiguration.default().editImageConfiguration
//        clipRatios = configuration.clipRatios
        dimClippedAreaDuringAdjustments = configuration.dimClippedAreaDuringAdjustments
       
       
        if let status = status{
            editRect = status.editRect
            angle = status.angle
            flipTuple = status.flipTuple
            //更新ratios
            let angle = ((Int(angle) % 360) - 360) % 360
            if angle == -90 {
                editImage = image.zl.rotate(orientation: .left)
            } else if angle == -180 {
                editImage = image.zl.rotate(orientation: .down)
            } else if angle == -270 {
                editImage = image.zl.rotate(orientation: .right)
            } else {
                editImage = image
            }
            selectedRatio = status.ratio
        }else{
            editImage = image
            editRect =  CGRectMake(0, 0, editImage.zl.width, editImage.zl.height)
            selectedRatio = .custom(size: image.size)
        }
        

        super.init(nibName: nil, bundle: nil)

       updateRatioSize(for: editRect.size)

    }
    
  
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        generateThumbnailImage()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewDidAppearCount += 1
        if let navigationController = presentingViewController as? UINavigationController,
           let presentingVC = navigationController.topViewController as? ImageDismissTransitionHandler {
            transitioningDelegate = self
        } else if let presentingVC = presentingViewController as? ImageDismissTransitionHandler {
            transitioningDelegate = self
        }


        
        guard viewDidAppearCount == 1 else {
            return
        }
        
        if let presentAnimateFrame = presentAnimateFrame,
           let presentAnimateImage = presentAnimateImage,
           let animateImageView = animateImageView {
//            let animateImageView = UIImageView(image: presentAnimateImage)
//            animateImageView.contentMode = .scaleAspectFill
//            animateImageView.clipsToBounds = true
//            animateImageView.frame = presentAnimateFrame
//            view.addSubview(animateImageView)
            
            cancelClipAnimateFrame = clipBoxFrame
//            self.shadowView.isHiddenBlurView = true
            UIView.animate(withDuration: 0.25, animations: {
                animateImageView.frame = self.clipBoxFrame
                self.bottomToolView.alpha = 1
                self.rotateBtn.alpha = 1
            }) { _ in
                self.shadowView.alpha = 1

                UIView.animate(withDuration: 0.1, animations: {
                    self.mainScrollView.alpha = 1
                    self.overlayView.alpha = 1
//                    self.shadowView.alpha = 1
                    
                }) { _ in
                    animateImageView.removeFromSuperview()
//                    self.shadowView.isHiddenBlurView = false

                }
            }
        } else {
            bottomToolView.alpha = 1
            rotateBtn.alpha = 1
            mainScrollView.alpha = 1
            overlayView.alpha = 1
            shadowView.alpha = 1
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard shouldLayout else { return }
        shouldLayout = false
        
        mainScrollView.frame = view.bounds
        shadowView.frame = view.bounds
        
        layoutInitialImage()
        
        bottomToolView.frame = CGRect(x: 0, y: view.bounds.height - ZLClipImageViewController.bottomToolViewH, width: view.bounds.width, height: ZLClipImageViewController.bottomToolViewH)
//        bottomShadowLayer.frame = bottomToolView.bounds
        
        bottomToolLineView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 1 / UIScreen.main.scale)
        let toolBtnH: CGFloat = 25
        let toolBtnY = (ZLClipImageViewController.bottomToolViewH - toolBtnH) / 2 - 10
        cancelBtn.frame = CGRect(x: 30, y: toolBtnY, width: toolBtnH, height: toolBtnH)
        let revertBtnW = localLanguageTextValue(.revert).zl.boundingRect(font: ZLLayout.bottomToolTitleFont, limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: toolBtnH)).width + 20
        revertBtn.frame = CGRect(x: (view.bounds.width - revertBtnW) / 2, y: toolBtnY, width: revertBtnW, height: toolBtnH)
        doneBtn.frame = CGRect(x: view.bounds.width - 30 - toolBtnH, y: toolBtnY, width: toolBtnH, height: toolBtnH)
        
        let ratioColViewY = bottomToolView.frame.minY - ZLClipImageViewController.clipRatioItemSize.height
        rotateBtn.frame = CGRect(x: 30, y: ratioColViewY + (ZLClipImageViewController.clipRatioItemSize.height - 25) / 2, width: 25, height: 25)
        let ratioColViewX = 0.0
        clipRatioColView.frame = CGRect(x: ratioColViewX, y: ratioColViewY, width: view.bounds.width - ratioColViewX, height: 70)
        rotateColView.frame = CGRect(x: ratioColViewX, y: ratioColViewY, width: view.bounds.width - ratioColViewX, height: 70)
        
        let spacing = (UIScreen.main.bounds.width - 40 - 72 - (rotateBtn.zl.width * 2)) / 3
        let width = spacing + 72
        segmentedControl.frame = CGRect(x: (view.bounds.width - width) / 2, y: 0, width: width, height: 45)
        segmentedControl.center.y = cancelBtn.zl.centerY
        

        if clipRatios.count > 1, let index = clipRatios.firstIndex(where: { $0 == self.selectedRatio }) {
            clipRatioColView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        shouldLayout = true
        maxClipFrame = calculateMaxClipFrame()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(mainScrollView)
        mainScrollView.addSubview(containerView)
        containerView.addSubview(imageView)
        view.addSubview(shadowView)
        view.addSubview(overlayView)
        
        view.addSubview(bottomToolView)
//        bottomToolView.layer.addSublayer(bottomShadowLayer)
        bottomToolView.backgroundColor = .black
        bottomToolView.addSubview(bottomToolLineView)
        bottomToolView.addSubview(cancelBtn)
//        bottomToolView.addSubview(revertBtn)
        bottomToolView.addSubview(doneBtn)
        bottomToolView.addSubview(segmentedControl)

        view.addSubview(rotateBtn)
        view.addSubview(clipRatioColView)
        view.addSubview(rotateColView)

        view.addGestureRecognizer(gridPanGes)
        mainScrollView.panGestureRecognizer.require(toFail: gridPanGes)
        
        mainScrollView.alpha = 0
        overlayView.alpha = 0
        shadowView.alpha = 0
//        bottomToolView.alpha = 0
//        rotateBtn.alpha = 0
        if let presentAnimateFrame = presentAnimateFrame,
           let presentAnimateImage = presentAnimateImage {
            let animateImageView = UIImageView(image: presentAnimateImage)
            animateImageView.contentMode = .scaleAspectFill
            animateImageView.clipsToBounds = true
            animateImageView.frame = presentAnimateFrame
            self.animateImageView = animateImageView
            view.addSubview(self.animateImageView!)
        }
        
    }
    
    private func generateThumbnailImage() {
        let size: CGSize
        let ratio = (editImage.size.width / editImage.size.height)
        let fixLength: CGFloat = 100
        if ratio >= 1 {
            size = CGSize(width: fixLength * ratio, height: fixLength)
        } else {
            size = CGSize(width: fixLength, height: fixLength / ratio)
        }
        thumbnailImage = editImage.zl.resize_vI(size)
    }
   
   
}
//MARK: 拖动框的frame计算
extension ZLClipImageViewController{
    
    private func calculatePanEdge(at point: CGPoint) -> ZLClipImageViewController.ClipPanEdge {
        let frame = clipBoxFrame.insetBy(dx: -30, dy: -30)
        
        let cornerSize = CGSize(width: 60, height: 60)
        let topLeftRect = CGRect(origin: frame.origin, size: cornerSize)
        if topLeftRect.contains(point) {
            return .topLeft
        }
        
        let topRightRect = CGRect(origin: CGPoint(x: frame.maxX - cornerSize.width, y: frame.minY), size: cornerSize)
        if topRightRect.contains(point) {
            return .topRight
        }
        
        let bottomLeftRect = CGRect(origin: CGPoint(x: frame.minX, y: frame.maxY - cornerSize.height), size: cornerSize)
        if bottomLeftRect.contains(point) {
            return .bottomLeft
        }
        
        let bottomRightRect = CGRect(origin: CGPoint(x: frame.maxX - cornerSize.width, y: frame.maxY - cornerSize.height), size: cornerSize)
        if bottomRightRect.contains(point) {
            return .bottomRight
        }
        
        let topRect = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: cornerSize.height))
        if topRect.contains(point) {
            return .top
        }
        
        let bottomRect = CGRect(origin: CGPoint(x: frame.minX, y: frame.maxY - cornerSize.height), size: CGSize(width: frame.width, height: cornerSize.height))
        if bottomRect.contains(point) {
            return .bottom
        }
        
        let leftRect = CGRect(origin: frame.origin, size: CGSize(width: cornerSize.width, height: frame.height))
        if leftRect.contains(point) {
            return .left
        }
        
        let rightRect = CGRect(origin: CGPoint(x: frame.maxX - cornerSize.width, y: frame.minY), size: CGSize(width: cornerSize.width, height: frame.height))
        if rightRect.contains(point) {
            return .right
        }
        
        return .none
    }
    
    private func updateClipBoxFrame(point: CGPoint) {
        var frame = clipBoxFrame
        let originFrame = clipOriginFrame
        
        var newPoint = point
        newPoint.x = max(maxClipFrame.minX, newPoint.x)
        newPoint.y = max(maxClipFrame.minY, newPoint.y)
        
        let diffX = ceil(newPoint.x - beginPanPoint.x)
        let diffY = ceil(newPoint.y - beginPanPoint.y)
        let ratio = selectedRatio.whRatio
        
        switch panEdge {
        case .left:
            frame.origin.x = originFrame.minX + diffX
            frame.size.width = originFrame.width - diffX
            if ratio != 0 {
                frame.size.height = originFrame.height - diffX / ratio
            }
        case .right:
            frame.size.width = originFrame.width + diffX
            if ratio != 0 {
                frame.size.height = originFrame.height + diffX / ratio
            }
        case .top:
            frame.origin.y = originFrame.minY + diffY
            frame.size.height = originFrame.height - diffY
            if ratio != 0 {
                frame.size.width = originFrame.width - diffY * ratio
            }
        case .bottom:
            frame.size.height = originFrame.height + diffY
            if ratio != 0 {
                frame.size.width = originFrame.width + diffY * ratio
            }
        case .topLeft:
            if ratio != 0 {
//                if abs(diffX / ratio) >= abs(diffY) {
                frame.origin.x = originFrame.minX + diffX
                frame.size.width = originFrame.width - diffX
                frame.origin.y = originFrame.minY + diffX / ratio
                frame.size.height = originFrame.height - diffX / ratio
//                } else {
//                    frame.origin.y = originFrame.minY + diffY
//                    frame.size.height = originFrame.height - diffY
//                    frame.origin.x = originFrame.minX + diffY * ratio
//                    frame.size.width = originFrame.width - diffY * ratio
//                }
            } else {
                frame.origin.x = originFrame.minX + diffX
                frame.size.width = originFrame.width - diffX
                frame.origin.y = originFrame.minY + diffY
                frame.size.height = originFrame.height - diffY
            }
        case .topRight:
            if ratio != 0 {
//                if abs(diffX / ratio) >= abs(diffY) {
                frame.size.width = originFrame.width + diffX
                frame.origin.y = originFrame.minY - diffX / ratio
                frame.size.height = originFrame.height + diffX / ratio
//                } else {
//                    frame.origin.y = originFrame.minY + diffY
//                    frame.size.height = originFrame.height - diffY
//                    frame.size.width = originFrame.width - diffY * ratio
//                }
            } else {
                frame.size.width = originFrame.width + diffX
                frame.origin.y = originFrame.minY + diffY
                frame.size.height = originFrame.height - diffY
            }
        case .bottomLeft:
            if ratio != 0 {
//                if abs(diffX / ratio) >= abs(diffY) {
                frame.origin.x = originFrame.minX + diffX
                frame.size.width = originFrame.width - diffX
                frame.size.height = originFrame.height - diffX / ratio
//                } else {
//                    frame.origin.x = originFrame.minX - diffY * ratio
//                    frame.size.width = originFrame.width + diffY * ratio
//                    frame.size.height = originFrame.height + diffY
//                }
            } else {
                frame.origin.x = originFrame.minX + diffX
                frame.size.width = originFrame.width - diffX
                frame.size.height = originFrame.height + diffY
            }
        case .bottomRight:
            if ratio != 0 {
//                if abs(diffX / ratio) >= abs(diffY) {
                frame.size.width = originFrame.width + diffX
                frame.size.height = originFrame.height + diffX / ratio
//                } else {
//                    frame.size.width += diffY * ratio
//                    frame.size.height += diffY
//                }
            } else {
                frame.size.width = originFrame.width + diffX
                frame.size.height = originFrame.height + diffY
            }
        default:
            break
        }
        
        let minSize: CGSize
        let maxSize: CGSize
        let maxClipFrame: CGRect
        if ratio != 0 {
            if ratio >= 1 {
                minSize = CGSize(width: minClipSize.height * ratio, height: minClipSize.height)
            } else {
                minSize = CGSize(width: minClipSize.width, height: minClipSize.width / ratio)
            }
            if ratio > self.maxClipFrame.width / self.maxClipFrame.height {
                maxSize = CGSize(width: self.maxClipFrame.width, height: self.maxClipFrame.width / ratio)
            } else {
                maxSize = CGSize(width: self.maxClipFrame.height * ratio, height: self.maxClipFrame.height)
            }
            maxClipFrame = CGRect(origin: CGPoint(x: self.maxClipFrame.minX + (self.maxClipFrame.width - maxSize.width) / 2, y: self.maxClipFrame.minY + (self.maxClipFrame.height - maxSize.height) / 2), size: maxSize)
        } else {
            minSize = minClipSize
            maxSize = self.maxClipFrame.size
            maxClipFrame = self.maxClipFrame
        }
        
        frame.size.width = min(maxSize.width, max(minSize.width, frame.size.width))
        frame.size.height = min(maxSize.height, max(minSize.height, frame.size.height))
        
        frame.origin.x = min(maxClipFrame.maxX - minSize.width, max(frame.origin.x, maxClipFrame.minX))
        frame.origin.y = min(maxClipFrame.maxY - minSize.height, max(frame.origin.y, maxClipFrame.minY))
        
        if panEdge == .topLeft || panEdge == .bottomLeft || panEdge == .left, frame.size.width <= minSize.width + CGFloat.ulpOfOne {
            frame.origin.x = originFrame.maxX - minSize.width
        }
        if panEdge == .topLeft || panEdge == .topRight || panEdge == .top, frame.size.height <= minSize.height + CGFloat.ulpOfOne {
            frame.origin.y = originFrame.maxY - minSize.height
        }
        
        changeClipBoxFrame(newFrame: frame)
    }
    
    private func startEditing() {
        cleanTimer()
        if !dimClippedAreaDuringAdjustments {
            shadowView.alpha = 0
        }
        shadowView.isHiddenBlurView = true
        overlayView.isEditing = true
//        if rotateBtn.alpha != 0 {
//            rotateBtn.layer.removeAllAnimations()
//            clipRatioColView.layer.removeAllAnimations()
//            UIView.animate(withDuration: 0.2) {
//                self.rotateBtn.alpha = 0
//                self.clipRatioColView.alpha = 0
//            }
//        }
    }
    
    @objc private func endEditing() {
        overlayView.isEditing = false
        moveClipContentToCenter()
        overlayView.setShowInnerGridLines(false)

//        self.shadowView.isHiddenBlurView = false

    }
    
    private func startTimer() {
        cleanTimer()
        // TODO: 换target写法
        resetTimer = Timer.scheduledTimer(timeInterval: 0.8, target: ZLWeakProxy(target: self), selector: #selector(endEditing), userInfo: nil, repeats: false)
        RunLoop.current.add(resetTimer!, forMode: .common)
    }
    
    private func cleanTimer() {
        resetTimer?.invalidate()
        resetTimer = nil
    }
    
    private func moveClipContentToCenter() {
        let maxClipRect = maxClipFrame
        var clipRect = clipBoxFrame
        
        if clipRect.width < CGFloat.ulpOfOne || clipRect.height < CGFloat.ulpOfOne {
            return
        }
        
        let scale = min(maxClipRect.width / clipRect.width, maxClipRect.height / clipRect.height)
        
        let focusPoint = CGPoint(x: clipRect.midX, y: clipRect.midY)
        let midPoint = CGPoint(x: maxClipRect.midX, y: maxClipRect.midY)
        
        clipRect.size.width = ceil(clipRect.width * scale)
        clipRect.size.height = ceil(clipRect.height * scale)
        clipRect.origin.x = maxClipRect.minX + ceil((maxClipRect.width - clipRect.width) / 2)
        clipRect.origin.y = maxClipRect.minY + ceil((maxClipRect.height - clipRect.height) / 2)
        
        var contentTargetPoint = CGPoint.zero
        contentTargetPoint.x = (focusPoint.x + mainScrollView.contentOffset.x) * scale
        contentTargetPoint.y = (focusPoint.y + mainScrollView.contentOffset.y) * scale
        
        var offset = CGPoint(x: contentTargetPoint.x - midPoint.x, y: contentTargetPoint.y - midPoint.y)
        offset.x = max(-clipRect.minX, offset.x)
        offset.y = max(-clipRect.minY, offset.y)
        UIView.animate(withDuration: 0.3) {
            if scale < 1 - CGFloat.ulpOfOne || scale > 1 + CGFloat.ulpOfOne {
                self.mainScrollView.zoomScale *= scale
                self.mainScrollView.zoomScale = min(self.mainScrollView.maximumZoomScale, self.mainScrollView.zoomScale)
            }

            if self.mainScrollView.zoomScale < self.mainScrollView.maximumZoomScale - CGFloat.ulpOfOne {
                offset.x = min(self.mainScrollView.contentSize.width - clipRect.maxX, offset.x)
                offset.y = min(self.mainScrollView.contentSize.height - clipRect.maxY, offset.y)
                self.mainScrollView.contentOffset = offset
            }
            self.rotateBtn.alpha = 1
            self.clipRatioColView.alpha = 1
            if !self.dimClippedAreaDuringAdjustments {
                self.shadowView.alpha = 1
            }

            self.changeClipBoxFrame(newFrame: clipRect)
//            self.shadowView.isHiddenBlurView = false
            DispatchQueue.main.asyncAfter(deadline: .now()+0.2, execute: {[weak self] in
                self?.shadowView.isHiddenBlurView = false
            })
        }
    }
    
    private func clipImage() -> (clipImage: UIImage, editRect: CGRect) {
        let frame = convertClipRectToEditImageRect()
        let clipImage = editImage.zl.clipImage(angle: 0, editRect: frame, isCircle: false)
        return (clipImage, frame)
    }
    
    private func convertClipRectToEditImageRect() -> CGRect {
        let imageSize = editImage.size
        let contentSize = mainScrollView.contentSize
        let offset = mainScrollView.contentOffset
        let insets = mainScrollView.contentInset
        
        var frame = CGRect.zero
        frame.origin.x = floor((offset.x + insets.left) * (imageSize.width / contentSize.width))
        frame.origin.x = max(0, frame.origin.x)
        
        frame.origin.y = floor((offset.y + insets.top) * (imageSize.height / contentSize.height))
        frame.origin.y = max(0, frame.origin.y)
        
        frame.size.width = ceil(clipBoxFrame.width * (imageSize.width / contentSize.width))
        frame.size.width = min(imageSize.width, frame.width)
        
        frame.size.height = ceil(clipBoxFrame.height * (imageSize.height / contentSize.height))
        frame.size.height = min(imageSize.height, frame.height)
        
        return frame
    }
}
//MARK: 交互点击事件
extension ZLClipImageViewController{
    
     @objc private func cancelBtnClick() {
         dismissAnimateFromRect = cancelClipAnimateFrame
         dismissAnimateImage = presentAnimateImage
         cancelClipBlock?()
         dismiss(animated: animate, completion: nil)

     }
     
     @objc private func revertBtnClick() {
         angle = 0
         editImage = originalImage
         calculateClipRect()
         imageView.image = editImage
         layoutInitialImage()
         
         generateThumbnailImage()
         clipRatioColView.reloadData()
     }
     
     @objc private func doneBtnClick() {
         let image = clipImage()
         dismissAnimateFromRect = clipBoxFrame
         dismissAnimateImage = image.clipImage
         let temp = image.clipImage
         if presentingViewController is ZLCustomCamera {
             dismiss(animated: animate) {
                 self.clipDoneBlock?(self.angle, image.editRect, self.selectedRatio)
             }
         } else {
//             clipDoneBlock?(angle, image.editRect, selectedRatio)
//             dismiss(animated: animate, completion: nil)

             //这里不需要再次做旋转操作
             let result = editImage.zl.clipImage(angle: 0, editRect: image.editRect, isCircle: false)

             selectedRatio = selectedRatio.updateSize(to: image.editRect.size)
             let clipStatus = ZLClipStatus(angle: self.angle, editRect: image.editRect,ratio: selectedRatio,flip: flipTuple)
//             clipDoneBlock?(angle, image.editRect, selectedRatio)
             xClipDoneBlock?(clipStatus,result,UClickRotate)

             dismiss(animated: animate, completion: nil)

//             self.navigationController?.popViewController(animated: true)

         }
         
     }
    
    private func handSegmentTap(type:XClipSegmentTap){
        currentClipSegment = type
    }
    
    
    private func rotateClick(type:XCropRotateEnum){
        rotateBtnClick(type:type)
    }
    //翻转
    private func toggleFlip(for type: XCropRotateEnum) {
        switch type {
        case .cropHor:
            flipTuple.horFlip.toggle()
        case .cropVer:
            flipTuple.verFlip.toggle()
        default:
            break
        }
    }
    //保证修改锚点后 frame 保持不变 , 锚点更新，lastLocation要更新
    private func updateAnchorPoint(_ anchorPoint: CGPoint, for view: UIView) {
        let oldFrame = view.frame
        view.layer.anchorPoint = anchorPoint
        view.frame = oldFrame
    }
      private func rotateBtnClick(type:XCropRotateEnum) {
          
         guard !isRotating else {
             return
         }
          
          let orientation = type.toImageOrientation()
          if (type == .cropHor){
              UClickRotate.horFlip = true
          }
          if (type == .cropVer){
              UClickRotate.verFlip = true
          }

          if (type == .cropHor || type == .cropVer){
              let orientation = type.toImageOrientation()
              editImage = editImage.zl.rotate(orientation: orientation)
//              mirrorImage = mirrorImage.zl.rotate(orientation: orientation)
              imageView.image = editImage
              toggleFlip(for: type)
              return
          }
        
          
//         angle -= 90
//         if angle == -360 {
//             angle = 0
//         }
          rotateImageAngle(direction: type)
         isRotating = true
         
         let animateImageView = UIImageView(image: editImage)
         animateImageView.contentMode = .scaleAspectFit
         animateImageView.clipsToBounds = true
         let originFrame = view.convert(containerView.frame, from: mainScrollView)
         animateImageView.frame = originFrame
         view.addSubview(animateImageView)
        
//
//          let layerFrame = mainScrollView.convert(overlayView.frame, from: view)
//          let layerCenterX = abs(layerFrame.minX) + overlayView.bounds.width / 2.0
//          let layerCenterY = abs(layerFrame.minY) + overlayView.bounds.height / 2.0
//
//          // 计算中心点相对于 containerView 宽度和高度的比例
//          let relativeCenterX = layerCenterX / containerView.bounds.width
//          let relativeCenterY = layerCenterY / containerView.bounds.height
//          let anchorPoint = CGPoint(x: relativeCenterX, y: relativeCenterY)
////          updateAnchorPoint(anchorPoint, for: animateImageView)
//          
//         if selectedRatio.whRatio == 0 || selectedRatio.whRatio == 1 {
             // 自由比例和1:1比例，进行edit rect转换

             // 将edit rect转换为相对edit image的rect
             let rect = convertClipRectToEditImageRect()
             // 旋转图片
             let startTime = CFAbsoluteTimeGetCurrent()

             editImage = editImage.zl.rotate(orientation: orientation)
             print("test===\(editImage.size)")

             let endTime2 = CFAbsoluteTimeGetCurrent()
             print("花费时间===\(endTime2 - startTime)")

             // 将rect进行旋转，转换到相对于旋转后的edit image的rect
             if(type == .cropLeft){
                 editRect = CGRect(x: rect.minY, y: editImage.size.height - rect.minX - rect.width, width: rect.height, height: rect.width)
             }
             if(type == .cropRight){
                 editRect = CGRect(x: editImage.size.width - rect.maxY, y: rect.minX, width: rect.height, height: rect.width)
             }
             // 向右旋转可用下面这行代码
//         } else {
//             // 其他比例的裁剪框，旋转后都重置edit rect
//             
//             // 旋转图片
//             editImage = editImage.zl.rotate(orientation: orientation)
//             calculateClipRect()
//         }
         imageView.image = editImage
          layoutInitialImage()
//          changeClipBoxFrame(newFrame: editRect,animation: true)
//toFrame 是转换后旋转View的目标frame 、  锚点是转换前的
          
          let toFrame = view.convert(containerView.frame, from: mainScrollView)
//         
         var angle = -CGFloat.pi / 2
          if(type == .cropRight){
              angle = CGFloat.pi / 2
          }
         let transform = CGAffineTransform(rotationAngle: angle)

         overlayView.alpha = 0
         shadowView.alpha = 0
         containerView.alpha = 0
          UIView.animate(withDuration: 0.3, animations: {
             animateImageView.transform = transform
             animateImageView.frame = toFrame
         }) { _ in
             animateImageView.removeFromSuperview()
             self.overlayView.alpha = 1
             self.containerView.alpha = 1
             self.shadowView.alpha = 1
             self.isRotating = false

         }
         generateThumbnailImage()
//         clipRatioColView.reloadData()
        
     }
     
   private  func rotateImageAngle(direction: XCropRotateEnum) {
        switch direction {
        case .cropRight:
            angle += 90
            if angle == 360 {
                angle = 0
            }
            UClickRotate.right90 = true
        case .cropLeft:
            angle -= 90
            if angle == -360 {
                angle = 0
            }
            UClickRotate.left90 = true
        default:
            break
        }
       //角度统一为向左的度数计算
       if(angle > 0){
           angle -= 360
       }
       print("Current angle: \(angle)")

    }
     @objc private func gridGesPanAction(_ pan: UIPanGestureRecognizer) {
         let point = pan.location(in: view)
         if pan.state == .began {
             startEditing()
             beginPanPoint = point
             clipOriginFrame = clipBoxFrame
             panEdge = calculatePanEdge(at: point)
             overlayView.setShowInnerGridLines(true)
         } else if pan.state == .changed {
             guard panEdge != .none else {
                 return
             }
             updateClipBoxFrame(point: point)
         } else if pan.state == .cancelled || pan.state == .ended {
             panEdge = .none
             startTimer()
//             overlayView.setShowInnerGridLines(false)

         }
     }
    
}

//MARK: Frame 计算
extension ZLClipImageViewController{
    
    //更新枚举值
    func updateRatioSize(for size: CGSize) {
//        var newSize:CGSize = .zero
//        switch type {
//        case .custom(let size),.original(let size):
//            newSize = size
//        default:
//            break
//        }

        for (index, ratio) in clipRatios.enumerated() {
            clipRatios[index] = ratio.updateSize(to: size)
        }

    }
    
    /// 计算最大裁剪范围
    private func calculateMaxClipFrame() -> CGRect {
        var insets = deviceSafeAreaInsets()
        insets.top += 20
        var rect = CGRect.zero
        rect.origin.x = 15
        rect.origin.y = insets.top
        rect.size.width = UIScreen.main.bounds.width - 15 * 2
        rect.size.height = UIScreen.main.bounds.height - insets.top - ZLClipImageViewController.bottomToolViewH - ZLClipImageViewController.clipRatioItemSize.height - 25
        return rect
    }
    
    private func calculateClipRect() {
        var imageSize:CGSize
        switch selectedRatio{
        case .original(let size):
//            editRect = CGRect(origin: .zero, size: editImage.)
            imageSize = size
        case .custom(let size):
            editRect.size = size
            return
        default:
            imageSize = editImage.size
        }
        
        let imageWHRatio = imageSize.width / imageSize.height
        var w: CGFloat = 0, h: CGFloat = 0
        if selectedRatio.whRatio >= imageWHRatio {
            w = imageSize.width
            h = w / selectedRatio.whRatio
        } else {
            h = imageSize.height
            w = h * selectedRatio.whRatio
        }
        editRect = CGRect(x: (imageSize.width - w) / 2, y: (imageSize.height - h) / 2, width: w, height: h)
        
//        if selectedRatio == .original || selectedRatio == .custom {
//            editRect = CGRect(origin: .zero, size: editImage.size)
//        } else {
//           
//        }
    }
    
    private func calculChangeScale()->CGRect{
        let maxClipRect = maxClipFrame
        let editSize = editRect.size

//        containerView.frame = CGRect(origin: .zero, size: editImage.size)
//        imageView.frame = containerView.bounds
        
        // editRect比例，计算editRect所占frame
        let editScale = min(maxClipRect.width / editSize.width, maxClipRect.height / editSize.height)
        let scaledSize = CGSize(width: floor(editSize.width * editScale), height: floor(editSize.height * editScale))
        
        var frame = CGRect.zero
        frame.size = scaledSize
        frame.origin.x = maxClipRect.minX + floor((maxClipRect.width - frame.width) / 2)
        frame.origin.y = maxClipRect.minY + floor((maxClipRect.height - frame.height) / 2)
        
        return frame
    }
    
    private func layoutInitialImage() {
//        let lastScale = mainScrollView.zoomScale
        mainScrollView.minimumZoomScale = 1
        mainScrollView.maximumZoomScale = 1
        mainScrollView.zoomScale = 1
        
        
        
        let editSize = editRect.size
        mainScrollView.contentSize = editSize
        let maxClipRect = maxClipFrame
        
        containerView.frame = CGRect(origin: .zero, size: editImage.size)
        imageView.frame = containerView.bounds
        
        // editRect比例，计算editRect所占frame
        let editScale = min(maxClipRect.width / editSize.width, maxClipRect.height / editSize.height)
        let scaledSize = CGSize(width: floor(editSize.width * editScale), height: floor(editSize.height * editScale))
        
        // 计算当前裁剪rect区域
        var frame = CGRect.zero
        frame.size = scaledSize
        frame.origin.x = maxClipRect.minX + floor((maxClipRect.width - frame.width) / 2)
        frame.origin.y = maxClipRect.minY + floor((maxClipRect.height - frame.height) / 2)
        
        // 按照edit image进行计算缩放比例
        let originalScale = max(frame.width / editImage.size.width, frame.height / editImage.size.height)
        
        // 将 edit rect 相对 originalScale 进行缩放，缩放到图片未放大时候的clip rect
        let scaleEditSize = CGSize(width: editRect.width * originalScale, height: editRect.height * originalScale)
        // 计算缩放后的clip rect相对maxClipRect的比例
        let clipRectZoomScale = min(maxClipRect.width / scaleEditSize.width, maxClipRect.height / scaleEditSize.height)
        
        mainScrollView.minimumZoomScale = originalScale
        mainScrollView.maximumZoomScale = 10
        
        // 设置当前zoom scale
        let zoomScale = clipRectZoomScale * originalScale
        mainScrollView.zoomScale = zoomScale
        mainScrollView.contentSize = CGSize(width: editImage.size.width * zoomScale, height: editImage.size.height * zoomScale)
        
        changeClipBoxFrame(newFrame: frame)
        
        if (frame.size.width < scaledSize.width - CGFloat.ulpOfOne) || (frame.size.height < scaledSize.height - CGFloat.ulpOfOne) {
            var offset = CGPoint.zero
            offset.x = -floor((mainScrollView.frame.width - scaledSize.width) / 2)
            offset.y = -floor((mainScrollView.frame.height - scaledSize.height) / 2)
            mainScrollView.contentOffset = offset
        }
        
        // edit rect 相对 image size 的 偏移量
        let diffX = editRect.origin.x / editImage.size.width * mainScrollView.contentSize.width
        let diffY = editRect.origin.y / editImage.size.height * mainScrollView.contentSize.height
        mainScrollView.contentOffset = CGPoint(x: -mainScrollView.contentInset.left + diffX, y: -mainScrollView.contentInset.top + diffY)
    }
    
    private func changeClipBoxFrame(newFrame: CGRect,animation:Bool = false) {
        guard clipBoxFrame != newFrame else {
            return
        }
        if newFrame.width < CGFloat.ulpOfOne || newFrame.height < CGFloat.ulpOfOne {
            return
        }
        var frame = newFrame
        let originX = ceil(maxClipFrame.minX)
        let diffX = frame.minX - originX
        frame.origin.x = max(frame.minX, originX)
//        frame.origin.x = floor(max(frame.minX, originX))
        if diffX < -CGFloat.ulpOfOne {
            frame.size.width += diffX
        }
        let originY = ceil(maxClipFrame.minY)
        let diffY = frame.minY - originY
        frame.origin.y = max(frame.minY, originY)
//        frame.origin.y = floor(max(frame.minY, originY))
        if diffY < -CGFloat.ulpOfOne {
            frame.size.height += diffY
        }
        let maxW = maxClipFrame.width + maxClipFrame.minX - frame.minX
        frame.size.width = max(minClipSize.width, min(frame.width, maxW))
//        frame.size.width = floor(max(self.minClipSize.width, min(frame.width, maxW)))
        
        let maxH = maxClipFrame.height + maxClipFrame.minY - frame.minY
        frame.size.height = max(minClipSize.height, min(frame.height, maxH))
//        frame.size.height = floor(max(self.minClipSize.height, min(frame.height, maxH)))
        
        clipBoxFrame = frame
        if(animation){
            UIView.animate(withDuration: 0.2) {
                self.shadowView.clearRect = frame
                self.overlayView.frame = frame.insetBy(dx: -ZLClipOverlayView.cornerLineWidth, dy: -ZLClipOverlayView.cornerLineWidth)
                
                // 需要调用 setNeedsDisplay 或类似的方法来更新 shadowView 和 overlayView 的显示
                self.shadowView.setNeedsDisplay()
                self.overlayView.setNeedsDisplay()
            }
        }else{
            shadowView.clearRect = frame
            overlayView.frame = frame.insetBy(dx: -ZLClipOverlayView.cornerLineWidth, dy: -ZLClipOverlayView.cornerLineWidth)
        }

      
        mainScrollView.contentInset = UIEdgeInsets(top: frame.minY, left: frame.minX, bottom: mainScrollView.frame.maxY - frame.maxY, right: mainScrollView.frame.maxX - frame.maxX)
        
        let scale = max(frame.height / editImage.size.height, frame.width / editImage.size.width)
        mainScrollView.minimumZoomScale = scale
        
//        var size = self.mainScrollView.contentSize
//        size.width = floor(size.width)
//        size.height = floor(size.height)
//        self.mainScrollView.contentSize = size
        
        mainScrollView.zoomScale = mainScrollView.zoomScale
    }
    
}


//MARK: 手势处理
extension ZLClipImageViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == gridPanGes else {
            return true
        }
        let point = gestureRecognizer.location(in: view)
        let frame = overlayView.frame
        let innerFrame = frame.insetBy(dx: 22, dy: 22)
        let outerFrame = frame.insetBy(dx: -22, dy: -22)
        
        if innerFrame.contains(point) || !outerFrame.contains(point) {
            return false
        }
        return true
    }
}
//MARK: UICollectionViewDataSource 、UICollectionViewDelegate
extension ZLClipImageViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    

    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (collectionView == clipRatioColView){
            return clipRatios.count
        }else{
            return clipRotates.count
        }
    }
    
    
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLImageClipRatioCell.zl.identifier, for: indexPath) as! ZLImageClipRatioCell
        
        if (collectionView == clipRatioColView){
            let ratio = clipRatios[indexPath.row]
            let selectIndex = clipRatios.firstIndex(of: selectedRatio) ?? 0
            cell.configureCell(ratio: ratio,select: selectIndex == indexPath.row)
            
        }else{
            let ratio = clipRotates[indexPath.row]
            cell.configureRotateCell(rotate: ratio)
        }
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if (collectionView == clipRatioColView){
            let ratio = clipRatios[indexPath.row]
            print("asdasdasd\(ratio)")
            guard ratio != selectedRatio else {
                return
            }
            selectedRatio = ratio
            clipRatioColView.reloadData()
            clipRatioColView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            calculateClipRect()
            let rect = calculChangeScale()
            changeClipBoxFrame(newFrame: rect,animation: true)
            
        }else{
            let rotate = clipRotates[indexPath.row]
            rotateClick(type: rotate)
        }
    }
}
//MARK: UIScrollViewDelegate

extension ZLClipImageViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }
    
    
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        startEditing()
    }
    
//   public func scrollViewDidZoom(_ scrollView: UIScrollView) {
//        // 打印每次缩放后的 zoomScale
//        print("Current zoomScale: \(scrollView.zoomScale)")
//    }

    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard scrollView == mainScrollView else {
            return
        }
        if !scrollView.isDragging {
            startTimer()
        }
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else {
            return
        }
        startEditing()
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else {
            return
        }
        startTimer()
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == mainScrollView else {
            return
        }
        if !decelerate {
            startTimer()
        }
    }
}
//
//extension ZLClipImageViewController{
//    //提供外部跳转到clip的动画
//    public class func toClipVC(sender:UIViewController ,currentClipStatus:ZLClipStatus,currentEditImage:UIImage,rect:CGRect,beforePresent:(() -> Void)?,cancelClick: (() -> Void)?,doneClick:((CGFloat, CGRect, XCropProportionEnum) -> Void)?) {
//        guard let sender = sender as? ImageDismissTransitionHandler else {
//               print("Sender does not conform to ImageDismissTransitionHandler")
//               return
//           }
//        let vc = ZLClipImageViewController(image: currentEditImage, status: currentClipStatus)
//        vc.presentAnimateFrame = rect
//        vc.hasTransitioning = true
//        vc.presentAnimateImage = currentEditImage.zl
//            .clipImage(
//                angle: currentClipStatus.angle,
//                editRect: currentClipStatus.editRect,
//                isCircle:  false
//            )
//        vc.modalPresentationStyle = .fullScreen
//        
//        vc.clipDoneBlock = { angle, editRect, selectRatio in
//            doneClick?(angle,editRect,selectRatio)
////            guard let `self` = self else { return }
//            
////            self.clipImage(status: ZLClipStatus(angle: angle, editRect: editRect, ratio: selectRatio))
////            self.editorManager.storeAction(.clip(oldStatus: self.preClipStatus, newStatus: self.currentClipStatus))
//        }
//        
//        vc.cancelClipBlock = cancelClick
//        
//        sender.present(vc, animated: false) {
////            self.mainScrollView.alpha = 0
////            self.topShadowView.alpha = 0
////            self.bottomShadowView.alpha = 0
////            self.adjustSlider?.alpha = 0
//            beforePresent?()
//        }
//
//    }
//
//}
//MARK: 控制器转场 UIViewControllerTransitioningDelegate

extension ZLClipImageViewController: UIViewControllerTransitioningDelegate {
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            return ZLClipImageDismissAnimatedTransition()
    }
}



