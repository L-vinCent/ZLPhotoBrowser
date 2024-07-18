//
//  ZLClipSegmentView.swift
//  ZLPhotoBrowser
//
//  Created by admin on 2024/7/17.
//

import Foundation

import UIKit

class ZLClipSegmentView:UIView{

    static let height = 36
    private var buttons = [UIButton]()
    private let indicatorView = UIView()
    private var buttonTapHandler: ((XClipSegmentTap) -> Void)?
    public var titles:[XClipSegmentTap] = []

    convenience init(frame: CGRect, titles: [XClipSegmentTap] , buttonTapHandler: ((XClipSegmentTap) -> Void)?) {
        self.init()
        self.titles = titles
        self.buttonTapHandler = buttonTapHandler
//        setupButtons(with: titles)
//        setupIndicatorView()
    }


    override func layoutSubviews() {
        
        setupButtons(with: titles)
        setupIndicatorView()
    }
    //设置按钮
    private func setupButtons(with titles: [XClipSegmentTap]) {
        let buttonWidth = 36.0

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
//        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) // 设置内边距
        stackView.isLayoutMarginsRelativeArrangement = true

        for (_, type) in titles.enumerated() {
            let button = UIButton(type: .custom)
            button.setTitle(type.toName(), for: .normal)
            button.setTitleColor(.zl.rgba(102, 102, 102), for: .normal)
            button.setTitleColor(.white, for: .selected)
            let font = UIFont(name: "PingFangSC-Medium", size: 14)
            button.titleLabel?.font = font
            button.tag = type.rawValue
            
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
            buttons.append(button)
        }
        if let btn = buttons.first {
            btn.isSelected = true
        }
        addSubview(stackView)
        // 设置 stackView 的 frame
        guard let superview = superview else { return }
        let stackViewHeight: CGFloat = frame.height - 3
        let stackViewWidth = frame.width
        stackView.frame = CGRect(x: 0, y: 0, width: stackViewWidth, height: stackViewHeight)
        
        let totalButtonWidth = CGFloat(titles.count) * buttonWidth
        let totalSpacing = frame.width - totalButtonWidth - stackView.layoutMargins.left - stackView.layoutMargins.right
        stackView.spacing = totalSpacing / CGFloat(titles.count - 1)
        
        
        // 计算和设置每个按钮的 frame
//        let buttonWidth = (stackViewWidth - stackView.layoutMargins.left - stackView.layoutMargins.right - stackView.spacing * CGFloat(titles.count - 1)) / CGFloat(titles.count)
        for (index, button) in buttons.enumerated() {
            let buttonX = stackView.layoutMargins.left + CGFloat(index) * (buttonWidth + stackView.spacing)
            button.frame = CGRect(x: buttonX, y: 0, width: buttonWidth, height: stackViewHeight)
        }
    }
    private func setupIndicatorView() {
        guard let firstButton = buttons.first else { return }

        indicatorView.backgroundColor = .blue // 设置指示器颜色
        addSubview(indicatorView)
        
        // 设置 indicatorView 的 frame
        
        let indicatorHeight: CGFloat = 3
        let indicatorY = frame.height - indicatorHeight - 3
        let indicatorWidth = firstButton.frame.width
        let indicatorX = firstButton.frame.midX - indicatorWidth / 2
        
        indicatorView.frame = CGRect(x: indicatorX, y: indicatorY, width: indicatorWidth, height: indicatorHeight)
    }

    @objc private func buttonTapped(_ sender: UIButton) {
        
        // 遍历所有按钮，将选中状态设为 false
        for button in buttons {
            button.isSelected = false
        }
        sender.isSelected = true
        updateIndicatorPosition(for: sender)
        
        if let segment = XClipSegmentTap(rawValue: sender.tag) {
            buttonTapHandler?(segment)
        }
    }
       
    private func updateIndicatorPosition(for button: UIButton) {
        let indicatorHeight: CGFloat = 3
        let indicatorY = frame.height - indicatorHeight - 3
        let indicatorWidth = button.frame.width
        let indicatorX = button.frame.midX - indicatorWidth / 2
        
        self.indicatorView.frame = CGRect(x: indicatorX, y: indicatorY, width: indicatorWidth, height: indicatorHeight)
        
    }

}
