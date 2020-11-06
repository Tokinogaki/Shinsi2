import UIKit
import Hero
import Photos

class ViewerVC: UICollectionViewController {
    
    enum ViewerMode: Int {
        case horizontal = 0
        case vertical = 1
    }
    var selectedIndexPath: IndexPath? {
        set { _selectedIndexPath = newValue }
        get {
            if let i = _selectedIndexPath { return IndexPath(item: i.item + (Defaults.Gallery.isAppendBlankPage ? 1 : 0), section: i.section) }
            return _selectedIndexPath
        }
    }
    private var _selectedIndexPath: IndexPath?
    weak var galleryModel: GalleryModel!
    var mode: ViewerMode {
        return Defaults.Viewer.mode
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layoutIfNeeded()
        collectionView?.reloadData()
        
        if let selectedIndex = selectedIndexPath {
            switch mode {
            case .horizontal:
                collectionView!.scrollToItem(at: selectedIndex, at: .right, animated: false)
            case .vertical:
                collectionView!.scrollToItem(at: selectedIndex, at: .top, animated: false)
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleLoadCalleryPageNotification(notification:)), name: .loadGalleryModel, object: nil)
        
        //Close gesture
        let panGR = UIPanGestureRecognizer()
        panGR.addTarget(self, action: #selector(pan(ges:)))
        panGR.delegate = self
        collectionView?.addGestureRecognizer(panGR)
        
        let tapToCloseGesture = UITapGestureRecognizer(target: self, action: #selector(tapToClose(ges:)))
        tapToCloseGesture.numberOfTapsRequired = 1
        collectionView?.addGestureRecognizer(tapToCloseGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress(ges:)))
        longPressGesture.delaysTouchesBegan = true
        collectionView?.addGestureRecognizer(longPressGesture)
        
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard UIApplication.shared.applicationState == .active else {return} 
        let indexPath = collectionView.indexPathsForVisibleItems.first
        super.viewWillTransition(to: size, with: coordinator)
        collectionView?.collectionViewLayout.invalidateLayout()
        coordinator.animate(alongsideTransition: { _ in
            if let indexPath = indexPath {
                self.collectionView.reloadData()
                let position: UICollectionView.ScrollPosition = self.mode == .vertical ? .top : (indexPath.item % 2 == 0 ? .left : .right)
                self.collectionView!.scrollToItem(at: indexPath, at: position, animated: false)
            }
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView?.isPagingEnabled = mode != .vertical
        if let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = mode == .vertical ? .vertical : .horizontal
        }
    }
    
    override var prefersStatusBarHidden: Bool { return true }
    
    override var prefersHomeIndicatorAutoHidden: Bool { return true }
    
    @objc func handleLoadCalleryPageNotification(notification: Notification) {
        var insertIndexPaths: [IndexPath] = []
        var lastIndext = 0
        if self.galleryModel.loadPageDirection == "down" {
            lastIndext = self.galleryModel.shows.count - self.galleryModel.perPageCount
        }
        
        for i in 0...(self.galleryModel.perPageCount - 1) {
            insertIndexPaths.append(IndexPath(item: i + lastIndext, section: 0))
        }
        
        let scrollToItem = (collectionView.indexPathsForVisibleItems.sorted().first?.item ?? 0) + self.galleryModel.perPageCount
        let bottomOffset = self.collectionView!.contentSize.height - self.collectionView!.contentOffset.y

        if self.galleryModel.loadPageDirection == "up" && self.mode == .vertical {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
        }
        
        self.collectionView.performBatchUpdates({
            self.collectionView.insertItems(at: insertIndexPaths)
        }) {_ in
            if self.galleryModel.loadPageDirection == "up" {
                if self.mode == .vertical {
                    self.collectionView!.contentOffset = CGPoint.init(x: 0, y: self.collectionView!.contentSize.height - bottomOffset)
                    CATransaction.commit()
                } else {
                    self.collectionView.scrollToItem(at: IndexPath(item: scrollToItem, section: 0), at: .centeredHorizontally, animated: false)
                }
            }
        }
    }
    
    @objc func longPress(ges: UILongPressGestureRecognizer) {
        guard ges.state == .began else {return}
        let p = ges.location(in: collectionView)
        if let indexPath = collectionView!.indexPathForItem(at: p) {
            let item = self.galleryModel.shows[indexPath.item]
            if item.hasImage {
                let alert = UIAlertController(title: "Save to camera roll", message: nil, preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default) { _ in
                    PHPhotoLibrary.requestAuthorization({ s in
                        if s == .authorized {
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetChangeRequest.creationRequestForAsset(from: item.image!)
                            }, completionHandler: nil)
                        }
                    })
                }
                let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alert.addAction(ok)
                alert.addAction(cancel)
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @objc func tapToClose(ges: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func pan(ges: UIPanGestureRecognizer) {
        guard mode != .vertical else {return}
        let translation = ges.translation(in: nil)
        let progress = translation.y / collectionView!.bounds.height
        switch ges.state {
        case .began:
            hero.dismissViewController()
        case .changed:
            Hero.shared.update(progress)
            for indexPath in collectionView!.indexPathsForVisibleItems {
                let cell = collectionView!.cellForItem(at: indexPath) as! ScrollingImageCell
                let currentPos = CGPoint(x: translation.x + view.center.x, y: translation.y + view.center.y)
                Hero.shared.apply(modifiers: [.position(currentPos)], to: cell.imageView)
            }
        default:
            if progress + ges.velocity(in: nil).y / collectionView!.bounds.height > 0.3 {
                Hero.shared.finish()
            } else {
                Hero.shared.cancel()
            }
        }
    }
}

extension ViewerVC: UICollectionViewDelegateFlowLayout {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.galleryModel.shows.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ScrollingImageCell
        let showModel = self.galleryModel.shows[indexPath.item]
        
        cell.showModel = showModel
        cell.image = showModel.image ?? showModel.thumb ?? UIImage(named: "placeholder")
        cell.imageView.hero.id = heroID(for: indexPath)
        cell.imageView.hero.modifiers = [.arc(intensity: 1), .forceNonFade]
        cell.imageView.isOpaque = true
        cell.readLabel.text = "\(showModel.index) / \(self.galleryModel.shows.count)"
        self.galleryModel.downloadImages(for: indexPath.item)
        
        return cell
    }
    
    func heroID(for indexPath: IndexPath) -> String {
        let index = indexPath.item - (Defaults.Gallery.isAppendBlankPage ? 1 : 0)
        return "image_\(galleryModel.gid)_\(index)"
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let showModel = self.galleryModel.shows[indexPath.item]
        self.galleryModel.readPage = showModel.index
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if mode == .horizontal {
            return collectionView.bounds.size
        } else {
            return CGSize(width: collectionView.bounds.size.width, height: collectionView.bounds.size.width * paperRatio)
        }
    }
    
}

extension ViewerVC: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard mode != .vertical else {return false}
        guard let panGR = gestureRecognizer as? UIPanGestureRecognizer else {return false}
        guard collectionView.visibleCells.count > 0 else {return false}
        guard let cell = collectionView.visibleCells[0] as? ScrollingImageCell, cell.scrollView.zoomScale == 1 else {return false}
        let v = panGR.velocity(in: nil)
        return v.y > abs(v.x)
    } 
}

extension ViewerVC {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let visibleItems = collectionView.indexPathsForVisibleItems.sorted()
        
        if self.mode == .horizontal {
            // Up loading
            if let indexPath = visibleItems.first,
               indexPath.item < Defaults.Viewer.upPrefetch {
                self.galleryModel.loadGalleryModel(direction: "up")
            }
            // Down loading
            else if let indexPath = visibleItems.last,
                    indexPath.item > (self.galleryModel.shows.count - 1 - Defaults.Viewer.downPrefetch) {
                self.galleryModel.loadGalleryModel(direction: "down")
            }
        } else {
            let contentSizeHeight = scrollView.contentSize.height
            let frameSizeHeight = scrollView.frame.size.height
            let contentOffsetY = scrollView.contentOffset.y
            
            if contentSizeHeight == 0 || visibleItems.count == 0 {
                return
            }
            
            // Up loading
            if let indexPath = visibleItems.first,
               let itemHeight = collectionView.cellForItem(at: indexPath)?.bounds.height,
               contentOffsetY < (itemHeight * CGFloat(Defaults.Viewer.upPrefetch) - 70) {
                self.galleryModel.loadGalleryModel(direction: "up")
            }
            // down loading
            else if let indexPath = visibleItems.last,
                    let itemHeight = collectionView.cellForItem(at: indexPath)?.bounds.height,
                    contentOffsetY > (contentSizeHeight - frameSizeHeight - itemHeight * CGFloat(Defaults.Viewer.downPrefetch)) {
                self.galleryModel.loadGalleryModel(direction: "down")
            }
        }
    }
}
