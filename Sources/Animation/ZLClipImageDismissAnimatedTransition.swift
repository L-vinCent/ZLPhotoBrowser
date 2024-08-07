//
//  ZLClipImageDismissAnimatedTransition.swift
//  ZLPhotoBrowser
//
//  Created by long on 2020/9/8.
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

// 定义协议
public protocol ImageDismissTransitionHandler: UIViewController {
    var originalImageFrame: CGRect { get }
    func finishClipDismissAnimation()
}


class ZLClipImageDismissAnimatedTransition: NSObject, UIViewControllerAnimatedTransitioning {
    let clipTransTime:TimeInterval = 0.25

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return clipTransTime
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let fromVC = transitionContext.viewController(forKey: .from) as? ZLClipImageViewController else {
            
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            return
        }
        // 检查 toViewController 是否是 UINavigationController
        let toVC: ImageDismissTransitionHandler?
        if let navController = transitionContext.viewController(forKey: .to) as? UINavigationController {
            toVC = navController.topViewController as? ImageDismissTransitionHandler
        } else {
            toVC = transitionContext.viewController(forKey: .to) as? ImageDismissTransitionHandler
        }
        
        
        guard let destinationVC = toVC else {
            
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            return
        }
        
        let containerView = transitionContext.containerView
        
        guard let toView = transitionContext.view(forKey: .to) else {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            return
        }
        
        fromVC.view.alpha = 0
        containerView.addSubview(toView)
        
        
        let imageView = UIImageView(frame: fromVC.dismissAnimateFromRect)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = fromVC.dismissAnimateImage
        containerView.addSubview(imageView)
        
        
        
        UIView.animate(withDuration: clipTransTime, animations: {
            imageView.frame = destinationVC.originalImageFrame
            
            
        }) { _ in
            destinationVC.finishClipDismissAnimation()
            imageView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

