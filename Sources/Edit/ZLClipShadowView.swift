//
//  ZLClipShadowView.swift
//  ZLPhotoBrowser
//
//  Created by admin on 2024/7/18.
//

import Foundation
import UIKit
// MARK: 裁剪比例cell
class ZLClipShadowView: UIView {
    var isCircle = false {
        didSet {
            (layer as? ZLClipShadowViewLayer)?.isCircle = isCircle
        }
    }

    
    var clearRect: CGRect = .zero {
        didSet {
            (layer as? ZLClipShadowViewLayer)?.clearRect = clearRect
            
            blurEffectView?.clearRect = clearRect
//            setNeedsLayout()
        }
    }
    var isHiddenBlurView = false {
        didSet{
            blurEffectView?.updateBlurVisibility(hidden: isHiddenBlurView, animated: true)
        }
    }
    
    override class var layerClass: AnyClass {
        return ZLClipShadowViewLayer.self
    }
    
    override init(frame: CGRect) {
         super.init(frame: frame)
         setupBlurEffectView()
     }

     required init?(coder: NSCoder) {
         super.init(coder: coder)
         setupBlurEffectView()
     }
    
    private var blurEffectView: ZLClipBlurView?
    
   
    private func setupBlurEffectView() {
        blurEffectView = ZLClipBlurView(effect: UIBlurEffect(style: .dark))
        blurEffectView?.clearRect = clearRect
        if let blurEffectView = blurEffectView {
            addSubview(blurEffectView)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        blurEffectView?.frame = self.bounds
    }
    
    override func action(for layer: CALayer, forKey event: String) -> CAAction? {
        
        guard event == #keyPath(ZLClipShadowViewLayer.clearRect),
              let action = super.action(for: layer, forKey: #keyPath(backgroundColor)) as? CAAnimation,
              let animation: CABasicAnimation = (action.copy() as? CABasicAnimation) else {
            

            return super.action(for: layer, forKey: event)
        }
        animation.keyPath = #keyPath(ZLClipShadowViewLayer.clearRect)
        animation.fromValue = (layer as? ZLClipShadowViewLayer)?.clearRect
        animation.toValue = clearRect
        layer.add(animation, forKey: #keyPath(ZLClipShadowViewLayer.clearRect))
        return animation
    }
   
    override func draw(_ layer: CALayer, in ctx: CGContext) {
        guard let shadowLayer = layer as? ZLClipShadowViewLayer else {
            return super.draw(layer, in: ctx)
        }
        ctx.setFillColor(UIColor(white: 0, alpha: 0.5).cgColor)
        ctx.fill(layer.frame)
        ctx.clear(shadowLayer.clearRect)

        if !isCircle {
            ctx.clear(shadowLayer.clearRect)
        } else {
            ctx.setBlendMode(.clear)
            ctx.setFillColor(UIColor.clear.cgColor)
            ctx.fillEllipse(in: shadowLayer.clearRect)
        }
    }
    
}


class ZLClipBlurView: UIVisualEffectView {
    var clearRect: CGRect = .zero {
        didSet {
            setNeedsLayout()
        }
    }

    private let maskLayer = CAShapeLayer()

    override init(effect: UIVisualEffect?) {
        super.init(effect: effect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        layer.mask = maskLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateMask()
    }
    func updateBlurVisibility(hidden:Bool,animated: Bool) {
        let alpha: CGFloat = hidden ? 0.0 : 1.0
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.alpha = alpha
            }
        } else {
            self.alpha = alpha
        }
    }
    
    private func updateMask() {
        let path = UIBezierPath(rect: bounds)
        
        // 使用外部传入的 clearRect
        let clearPath = UIBezierPath(rect: clearRect)
        path.append(clearPath.reversing())
        
        maskLayer.path = path.cgPath
    }
    
}

class ZLClipShadowViewLayer: CALayer {
    @NSManaged var clearRect: CGRect
    @NSManaged var isCircle: Bool
    override class func needsDisplay(forKey key: String) -> Bool {
        return super.needsDisplay(forKey: key) || key == #keyPath(clearRect) || key == #keyPath(isCircle)
    }
}

// MARK: 裁剪网格视图

class ZLClipOverlayView: UIView {
    static let cornerLineWidth: CGFloat = 3
    
    private var cornerBoldLines: [UIView] = []
    
    private var velLines: [UIView] = []
    
    private var horLines: [UIView] = []
    
    var isCircle = false {
        didSet {
            guard oldValue != isCircle else {
                return
            }
            setNeedsDisplay()
        }
    }
    
    var isEditing = false {
        didSet {
            guard isCircle else {
                return
            }
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = false
        // 两种方法实现裁剪框，drawrect动画效果 更好一点
//        func line(_ isCorner: Bool) -> UIView {
//            let line = UIView()
//            line.backgroundColor = .white
//            line.layer.shadowColor  = UIColor.black.cgColor
//            if !isCorner {
//                line.layer.shadowOffset = .zero
//                line.layer.shadowRadius = 1.5
//                line.layer.shadowOpacity = 0.8
//            }
//            self.addSubview(line)
//            return line
//        }
//
//        (0..<8).forEach { (_) in
//            self.cornerBoldLines.append(line(true))
//        }
//
//        (0..<4).forEach { (_) in
//            self.velLines.append(line(false))
//            self.horLines.append(line(false))
//        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
//        let borderLineLength: CGFloat = 20
//        let borderLineWidth: CGFloat = ZLClipOverlayView.cornerLineWidth
//        for (i, line) in self.cornerBoldLines.enumerated() {
//            switch i {
//            case 0:
//                // 左上 hor
//                line.frame = CGRect(x: -borderLineWidth, y: -borderLineWidth, width: borderLineLength, height: borderLineWidth)
//            case 1:
//                // 左上 vel
//                line.frame = CGRect(x: -borderLineWidth, y: -borderLineWidth, width: borderLineWidth, height: borderLineLength)
//            case 2:
//                // 右上 hor
//                line.frame = CGRect(x: self.bounds.width-borderLineLength+borderLineWidth, y: -borderLineWidth, width: borderLineLength, height: borderLineWidth)
//            case 3:
//                // 右上 vel
//                line.frame = CGRect(x: self.bounds.width, y: -borderLineWidth, width: borderLineWidth, height: borderLineLength)
//            case 4:
//                // 左下 hor
//                line.frame = CGRect(x: -borderLineWidth, y: self.bounds.height, width: borderLineLength, height: borderLineWidth)
//            case 5:
//                // 左下 vel
//                line.frame = CGRect(x: -borderLineWidth, y: self.bounds.height-borderLineLength+borderLineWidth, width: borderLineWidth, height: borderLineLength)
//            case 6:
//                // 右下 hor
//                line.frame = CGRect(x: self.bounds.width-borderLineLength+borderLineWidth, y: self.bounds.height, width: borderLineLength, height: borderLineWidth)
//            case 7:
//                line.frame = CGRect(x: self.bounds.width, y: self.bounds.height-borderLineLength+borderLineWidth, width: borderLineWidth, height: borderLineLength)
//
//            default:
//                break
//            }
//        }
//
//        let normalLineWidth: CGFloat = 1
//        var x: CGFloat = 0
//        var y: CGFloat = -1
//        // 横线
//        for (index, line) in self.horLines.enumerated() {
//            if index == 0 || index == 3 {
//                x = borderLineLength-borderLineWidth
//            } else  {
//                x = 0
//            }
//            line.frame = CGRect(x: x, y: y, width: self.bounds.width - x * 2, height: normalLineWidth)
//            y += (self.bounds.height + 1) / 3
//        }
//
//        x = -1
//        y = 0
//        // 竖线
//        for (index, line) in self.velLines.enumerated() {
//            if index == 0 || index == 3 {
//                y = borderLineLength-borderLineWidth
//            } else  {
//                y = 0
//            }
//            line.frame = CGRect(x: x, y: y, width: normalLineWidth, height: self.bounds.height - y * 2)
//            x += (self.bounds.width + 1) / 3
//        }
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        context?.setStrokeColor(UIColor.white.cgColor)
        context?.setLineWidth(1)
        context?.beginPath()
        
        let circleDiff: CGFloat = (3 - 2 * sqrt(2)) * (rect.width - 2 * ZLClipOverlayView.cornerLineWidth) / 6
        
        var dw: CGFloat = 3
        for i in 0..<4 {
            let isInnerLine = isCircle && 1...2 ~= i
            context?.move(to: CGPoint(x: rect.origin.x + dw, y: ZLClipOverlayView.cornerLineWidth + (isInnerLine ? circleDiff : 0)))
            context?.addLine(to: CGPoint(x: rect.origin.x + dw, y: rect.height - ZLClipOverlayView.cornerLineWidth - (isInnerLine ? circleDiff : 0)))
            dw += (rect.size.width - 6) / 3
        }

        var dh: CGFloat = 3
        for i in 0..<4 {
            let isInnerLine = isCircle && 1...2 ~= i
            context?.move(to: CGPoint(x: ZLClipOverlayView.cornerLineWidth + (isInnerLine ? circleDiff : 0), y: rect.origin.y + dh))
            context?.addLine(to: CGPoint(x: rect.width - ZLClipOverlayView.cornerLineWidth - (isInnerLine ? circleDiff : 0), y: rect.origin.y + dh))
            dh += (rect.size.height - 6) / 3
        }

        context?.strokePath()

        context?.setLineWidth(ZLClipOverlayView.cornerLineWidth)

        let boldLineLength: CGFloat = 20
        // 左上
        context?.move(to: CGPoint(x: 0, y: 1.5))
        context?.addLine(to: CGPoint(x: boldLineLength, y: 1.5))

        context?.move(to: CGPoint(x: 1.5, y: 0))
        context?.addLine(to: CGPoint(x: 1.5, y: boldLineLength))

        // 右上
        context?.move(to: CGPoint(x: rect.width - boldLineLength, y: 1.5))
        context?.addLine(to: CGPoint(x: rect.width, y: 1.5))

        context?.move(to: CGPoint(x: rect.width - 1.5, y: 0))
        context?.addLine(to: CGPoint(x: rect.width - 1.5, y: boldLineLength))

        // 左下
        context?.move(to: CGPoint(x: 1.5, y: rect.height - boldLineLength))
        context?.addLine(to: CGPoint(x: 1.5, y: rect.height))

        context?.move(to: CGPoint(x: 0, y: rect.height - 1.5))
        context?.addLine(to: CGPoint(x: boldLineLength, y: rect.height - 1.5))

        // 右下
        context?.move(to: CGPoint(x: rect.width - boldLineLength, y: rect.height - 1.5))
        context?.addLine(to: CGPoint(x: rect.width, y: rect.height - 1.5))

        context?.move(to: CGPoint(x: rect.width - 1.5, y: rect.height - boldLineLength))
        context?.addLine(to: CGPoint(x: rect.width - 1.5, y: rect.height))

        context?.strokePath()

        context?.setShadow(offset: CGSize(width: 1, height: 1), blur: 0)
    }
}
