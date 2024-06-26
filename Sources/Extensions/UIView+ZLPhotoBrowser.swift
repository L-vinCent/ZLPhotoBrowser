//
//  UIView+ZLPhotoBrowser.swift
//  ZLPhotoBrowser
//
//  Created by long on 2022/9/27.
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

extension ZLPhotoBrowserWrapper where Base: UIView {
    var top: CGFloat {
        base.frame.minY
    }
    
    var bottom: CGFloat {
        base.frame.maxY
    }
    
    var left: CGFloat {
        base.frame.minX
    }
    
    var right: CGFloat {
        base.frame.maxX
    }
    
    var width: CGFloat {
        base.frame.width
    }
    
    var height: CGFloat {
        base.frame.height
    }
    
    var size: CGSize {
        base.frame.size
    }
    
    var center: CGPoint {
        base.center
    }
    
    var centerX: CGFloat {
        base.center.x
    }
    
    var centerY: CGFloat {
        base.center.y
    }
    
    var snapshotImage: UIImage {
        return UIGraphicsImageRenderer.zl.renderImage(size: base.zl.size) { format in
            format.opaque = base.isOpaque
        } imageActions: { context in
            base.layer.render(in: context)
        }
    }
    
    func setCornerRadius(_ radius: CGFloat) {
        base.layer.cornerRadius = radius
        base.layer.masksToBounds = true
    }
    
    func addBorder(color: UIColor, width: CGFloat) {
        base.layer.borderColor = color.cgColor
        base.layer.borderWidth = width
    }
    
    func addShadow(color: UIColor, radius: CGFloat, opacity: Float = 1, offset: CGSize = .zero) {
        base.layer.shadowColor = color.cgColor
        base.layer.shadowRadius = radius
        base.layer.shadowOpacity = opacity
        base.layer.shadowOffset = offset
    }
    
    func findParentViewController<T: UIViewController>() -> T? {
        // 定义一个变量用于保存找到的视图控制器
        var parentViewController: UIViewController? = nil
        
        // 从当前视图开始，逐级向上查找父视图，直到找到包含指定类型控制器的视图控制器或到达顶层视图
        var nextResponder: UIResponder? = base
        while let responder = nextResponder {
            // 判断当前响应者是否为视图控制器
            if let viewController = responder as? XPhotoViewController {
                // 如果是目标类型的视图控制器，设置为找到的视图控制器并退出循环
                if viewController is T {
                    parentViewController = viewController
                    break
                }
            }
            
            // 如果当前响应者不是视图控制器，继续向上查找父响应者
            nextResponder = responder.next
        }
        
        // 将找到的视图控制器转换为指定类型返回
        return parentViewController as? T
    }
}


