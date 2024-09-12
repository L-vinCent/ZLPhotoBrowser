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
    //自定义的XTempVC 里面用到
    var arrDataSource: [ZLAlbumListModel]?{
        didSet{
            reloadChooseState(albums: arrDataSource)
        }
    }
    
    //当前索引
    var currentIndex:Int = 0 {
        didSet{
            scrollToCurrentIndex(index: currentIndex)
        }
    }

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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
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
    
    
    func reloadChooseState(albums: [ZLAlbumListModel]?){
        guard let albums = albums else {return}
        if(!albums.isEmpty){
            selectedAlbum = albums[0]
        }
        self.collectionView.reloadData()
    }
    
    func scrollToCurrentIndex(index:Int){
        guard let albums = self.arrDataSource,albums.indices.contains(index) else {return}
        selectedAlbum = albums[index]
        scrollToCenter(at: index)
        DispatchQueue.main.async {
              self.collectionView.reloadData()
          }
    }
    
    func scrollToCenter(at index: Int) {
        guard index >= 0 && index < collectionView.numberOfItems(inSection: 0) else {
            return // 确保 index 在有效范围内
        }
        
        let indexPath = IndexPath(item: index, section: 0)
        
        // 滚动到指定的item位置，并指定滚动位置为居中
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    
}
    //改为外部提供
//    private func loadAlbumList(completion: (() -> Void)? = nil) {
//        DispatchQueue.global().async {
//            ZLPhotoManager.getPhotoAlbumList(
//                ascending: ZLPhotoUIConfiguration.default().sortAscending,
//                allowSelectImage: ZLPhotoConfiguration.default().allowSelectImage,
//                allowSelectVideo: ZLPhotoConfiguration.default().allowSelectVideo
//            ) { [weak self] albumList in
//                self?.arrDataSource.removeAll()
//                self?.arrDataSource.append(contentsOf: albumList)
//                
//                ZLMainAsync {
//                    completion?()
//                    self?.collectionView.reloadData()
//                }
//            }
//        }
//    }
    
//}

extension XSegmentAlbumView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       
            return arrDataSource?.count ?? 0
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return XSegmentAlbumCell.cellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: XSegmentAlbumCell.zl.identifier, for: indexPath) as! XSegmentAlbumCell
        let model = self.arrDataSource?[indexPath.row]
        let selected = (model == selectedAlbum) ? true : false
        cell.model = model
        cell.isCellSelected = selected
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let model = self.arrDataSource?[indexPath.row] else {return}
        if(selectedAlbum == model) {return}
        selectedAlbum = model
        self.clickSegHandle?(model)
        self.collectionView.reloadData()
    }
    
    
}

