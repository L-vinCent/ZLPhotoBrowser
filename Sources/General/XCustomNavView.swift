//
//  XCustomNavView.swift
//  ZLPhotoBrowser
//
//  Created by admin on 2024/4/17.
//

import UIKit

class XCustomNavView:UIView{
    
    var clickBackHandle:(()->Void)?
    var title:String = ""{
        didSet{
            self.titleLabel.text = title
        }
    }
    lazy var contentView:UIView = {
        let view = UIView()
        view.backgroundColor = .zl.thumbnailBgColor
        return view
    }()
   lazy var titleLabel:UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.white
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.zl.PingFangMedium(size: 18)
       titleLabel.text = "导入照片"
        return titleLabel
    }()
    
    lazy var backBtn:UIButton = {
        let btn = ZLEnlargeButton()
        btn.enlargeInset = 10
        btn.addTarget(self, action: #selector(navTapped), for: .touchUpInside)
        btn.setImage(.zl.getImage("zl_navBack"), for: .normal)
        return btn
        
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func configUI(){
        self.backgroundColor = UIColor.zl.thumbnailBgColor
        addSubview(contentView)
        contentView.addSubview(backBtn)
        contentView.addSubview(titleLabel)
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *) {
            insets = safeAreaInsets
        }
        
        contentView.frame = CGRect(x: 0, y: insets.top, width: self.zl.width, height: self.zl.height - insets.top)
        self.backBtn.frame = CGRect(x: 15, y: 0, width: 24, height: 24)
        self.titleLabel.frame = CGRect(x: 0, y: 0, width: 150, height: contentView.zl.height)
        self.backBtn.center.y = contentView.zl.height/2.0
        self.titleLabel.center = CGPoint(x: contentView.zl.width/2.0, y: contentView.zl
            .height/2.0)
    }
    
    @objc func navTapped() {
        self.clickBackHandle?()
    }

    deinit {
        print("控制器=====View deinit \(String(describing: self))")
    }
    
}
