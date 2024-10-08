//
//  ZLProgressHUD.swift
//  ZLPhotoBrowser
//
//  Created by long on 2020/8/17.
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

public class ZLProgressHUD: UIView {
    private let style: ZLProgressHUD.Style
    
    private lazy var loadingView = UIImageView(image: style.icon)
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 2
        label.textColor = style.textColor
        label.font = .zl.font(ofSize: 12)
        label.text = localLanguageTextValue(.hudLoading)
        label.lineBreakMode = .byWordWrapping
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    // 蒙层
     private lazy var overlayView: UIView = {
         let view = UIView(frame: UIScreen.main.bounds)
         view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
         view.isHidden = true
         return view
     }()
    
    // 控制是否显示蒙层
//      public var shouldShowOverlay: Bool = true
    
    private var timer: Timer?
    
    public var timeoutBlock: (() -> Void)?
    
    deinit {
        zl_debugPrint("ZLProgressHUD deinit")
        cleanTimer()
    }
    
    public init(style: ZLProgressHUD.Style) {
        self.style = style
        super.init(frame: UIScreen.main.bounds)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(overlayView)

        let view = UIView(frame: CGRect(x: 0, y: 0, width: 135, height: 135))
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 12
        view.backgroundColor = style.bgColor
        view.clipsToBounds = true
        view.center = center
        
        if let effectStyle = style.blurEffectStyle {
            let effect = UIBlurEffect(style: effectStyle)
            let effectView = UIVisualEffectView(effect: effect)
            effectView.frame = view.bounds
            view.addSubview(effectView)
        }
        
        loadingView.frame = CGRect(x: 135 / 2 - 20, y: 27, width: 40, height: 40)
        view.addSubview(loadingView)
        
        titleLabel.frame = CGRect(x: 10, y: 60, width: view.bounds.width - 20, height: 60)
        view.addSubview(titleLabel)
        
        addSubview(view)
    }
    
    private func startAnimation() {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * 2
        animation.duration = 0.8
        animation.repeatCount = .infinity
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        loadingView.layer.add(animation, forKey: nil)
    }
    
    public func show(
        toast: ZLProgressHUD.Toast = .loading,
        shouldShowOverlay:Bool = true,
        in view: UIView? = UIApplication.shared.keyWindow,
        timeout: TimeInterval = 100,
        timeoutBlock:(()->Void)? = nil
    ) {
        ZLMainAsync {
            self.titleLabel.text = toast.value
            
            view?.addSubview(self)
            if shouldShowOverlay {
                self.overlayView.isHidden = false
            }
            
            switch toast{
            case .loading:
                self.startAnimation()
//            case .custome:
//                self.loadingView.isHidden = true
            default:
                break
            }
            
        }
        
        if timeout > 0 {
            cleanTimer()
            timer = Timer.scheduledTimer(timeInterval: timeout, target: ZLWeakProxy(target: self), selector: #selector(timeout(_:)), userInfo: nil, repeats: false)
            RunLoop.current.add(timer!, forMode: .default)
            self.timeoutBlock?()
        }
    }
    
    @objc public func hide() {
        cleanTimer()
        ZLMainAsync {
            self.loadingView.layer.removeAllAnimations()
            self.removeFromSuperview()
            self.overlayView.isHidden = true // 隐藏蒙层
        }
    }
    
    @objc func timeout(_ timer: Timer) {
        timeoutBlock?()
        hide()
    }
    
    func cleanTimer() {
        timer?.invalidate()
        timer = nil
    }
}

public extension ZLProgressHUD {
    class func show(
        toast: ZLProgressHUD.Toast = .loading,
        in view: UIView? = UIApplication.shared.keyWindow,
        timeout: TimeInterval = 100,
        timeoutBlock:(()->Void)? = nil
    ) -> ZLProgressHUD {
        let hud = ZLProgressHUD(style: ZLPhotoUIConfiguration.default().hudStyle)
        hud.show(toast: toast,shouldShowOverlay: true, in: view, timeout: timeout,timeoutBlock: timeoutBlock)
        return hud
    }
    
    class func showMagicToast(
        message:String,
        shouldShowOverlay:Bool = false,
        in view: UIView? = UIApplication.shared.keyWindow,
        timeout: TimeInterval = 1.5
    ) -> ZLProgressHUD {
        let hud = ZLProgressHUD(style: .magicToast)
        hud.show(toast:.custome(message),shouldShowOverlay: shouldShowOverlay, in: view, timeout: timeout)
        return hud
    }
}

public extension ZLProgressHUD {
    @objc(ZLProgressHUDStyle)
    enum Style: Int {
        case light
        case lightBlur
        case dark
        case darkBlur
        case custom // 证件照
        case magic //魔术手
        case magicToast

        var bgColor: UIColor {
            switch self {
            case .light:
                return .white
            case .dark:
                return .darkGray
            case .lightBlur:
                return UIColor.white.withAlphaComponent(0.8)
            case .darkBlur:
                return UIColor.darkGray.withAlphaComponent(0.8)
            case .magicToast:
                return UIColor.black.withAlphaComponent(0.9)
            case .custom ,.magic:
                return UIColor.clear

            }
        
        }
        
        var icon: UIImage? {
            switch self {
            case .light, .lightBlur:
                return .zl.getImage("zl_loading_dark")
            case .dark, .darkBlur:
                return .zl.getImage("zl_loading_light")
            case .custom:
                return .zl.getImage("x_icon_hud_loading")
            case .magic:
                return .zl.getImage("x_icon_hud_loading_magic")
            case .magicToast:
                return .zl.getImage("x_icon_hud_loading_magic")
            }
            
        }
        
        var textColor: UIColor {
            switch self {
            case .light, .lightBlur:
                return .black
            case .dark, .darkBlur:
                return .white
            case .custom ,.magic,.magicToast:
                return .white
            }
        
        }
        
        var blurEffectStyle: UIBlurEffect.Style? {
            switch self {
            case .light, .dark:
                return nil
            case .lightBlur:
                return .extraLight
            case .darkBlur:
                return .dark
            case .magicToast:
                return nil
            case .custom ,.magic:
                return nil
            }
            
        }
    }
    
    enum Toast {
        case loading
        case processing
        case custome(String)
        
        var value: String {
            switch self {
            case .loading:
                return localLanguageTextValue(.hudLoading)
            case .processing:
                return localLanguageTextValue(.hudProcessing)
            case let .custome(text):
                return text
            }
        }
    }
}
