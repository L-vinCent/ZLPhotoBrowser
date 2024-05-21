//
//  XSegmentAlbumView.swift
//  ZLPhotoBrowser
//
//  Created by admin on 2024/4/16.
//

import UIKit
import Photos
class XSegmentAlbumView:UIView{
    
    var clickSegHandle:((ZLAlbumListModel)->Void)?
    
    static let height: CGFloat = 50

    private var selectedAlbum: ZLAlbumListModel?
    private var arrDataSource: [ZLAlbumListModel] = []

    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
//        layout.minimumInteritemSpacing = 25
        layout.minimumLineSpacing = 8
        layout.scrollDirection = .horizontal

        let cw = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cw.backgroundColor =  UIColor.zl.thumbnailBgColor

        cw.delegate = self
        cw.dataSource = self
        XSegmentAlbumCell.zl.register(cw)

        return cw
    }()
    
    init(selectedAlbum: ZLAlbumListModel?) {
        self.selectedAlbum = selectedAlbum
        super.init(frame: .zero)
        setupUI()
        loadAlbumList()
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(){
        addSubview(self.collectionView)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.collectionView.frame = self.bounds
    }
    
    private func loadAlbumList(completion: (() -> Void)? = nil) {
        DispatchQueue.global().async {
            ZLPhotoManager.getPhotoAlbumList(
                ascending: ZLPhotoUIConfiguration.default().sortAscending,
                allowSelectImage: ZLPhotoConfiguration.default().allowSelectImage,
                allowSelectVideo: ZLPhotoConfiguration.default().allowSelectVideo
            ) { [weak self] albumList in
                self?.arrDataSource.removeAll()
                self?.arrDataSource.append(contentsOf: albumList)
                
                ZLMainAsync {
                    completion?()
                    self?.collectionView.reloadData()
                }
            }
        }
    }
    
}

extension XSegmentAlbumView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       
            return arrDataSource.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return XSegmentAlbumCell.cellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: XSegmentAlbumCell.zl.identifier, for: indexPath) as! XSegmentAlbumCell
        let model = self.arrDataSource[indexPath.row]
        let selected = (model == selectedAlbum) ? true : false
        cell.model = model
        cell.isCellSelected = selected
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let model = self.arrDataSource[indexPath.row]
        if(selectedAlbum == model) {return}
        selectedAlbum = model
        self.clickSegHandle?(model)
        self.collectionView.reloadData()
    }
    
    
}

