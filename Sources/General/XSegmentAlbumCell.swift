//
//  XSegmentAlbumCell.swift
//  ZLPhotoBrowser
//
//  Created by admin on 2024/4/16.
//

import UIKit

class XSegmentAlbumCell:UICollectionViewCell{
   static var cellSize: CGSize = CGSize(width: 86, height: 28)

    var isCellSelected:Bool = false {
        didSet{
            let color = ZLPhotoUIConfiguration.default().x_CustomTitleColor300
            let titleColor = isCellSelected ? UIColor.black : color
            let bgColor = isCellSelected ? color : UIColor.white.withAlphaComponent(0.1)
            titleLabel.textColor = titleColor
            titleLabel.backgroundColor = bgColor
        }
    }
    var model:ZLAlbumListModel?{
        didSet{
            titleLabel.text = model?.title
        }
    }
    
    lazy var titleLabel:UILabel = {
        let label = UILabel()
        label.font = .zl.PingFangRegular(size: 14)
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 14
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
    }
    
    func configUI(){
        addSubview(titleLabel)
        isCellSelected = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = self.bounds
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
