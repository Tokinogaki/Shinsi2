import UIKit
import Photos
import UIColor_Hex_Swift

class ViewerVC: UICollectionViewController {
    
    private var _readLabel: InsetLabel?
    
    private var bigin: CGPoint = CGPoint.init()
    
    var readLabel: InsetLabel {
        if _readLabel == nil {
            _readLabel = InsetLabel()
            _readLabel?.backgroundColor = UIColor.init(hex3: 0x0, alpha: 0.3)
            _readLabel?.textColor = UIColor.white
            _readLabel?.numberOfLines = 2
            _readLabel?.font = UIFont.systemFont(ofSize: 11)
            _readLabel?.translatesAutoresizingMaskIntoConstraints = false

            self.view.addSubview(_readLabel!)

            NSLayoutConstraint.activate([
                _readLabel!.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                _readLabel!.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20)
            ])
        }
        return _readLabel!
    }
    
    enum ViewerMode: Int {
        case horizontal = 0
        case vertical = 1
    }
    var selectedIndexPath: IndexPath? {
        set { _selectedIndexPath = newValue }
        get {
            if let i = _selectedIndexPath { return IndexPath(item: i.item, section: i.section) }
            return _selectedIndexPath
        }
    }
    private var _selectedIndexPath: IndexPath?
    weak var galleryModel: GalleryModel!
    var mode: ViewerMode {
        return Defaults.Viewer.mode
    }
    
    override var shouldAutorotate: Bool {
        return Defaults.GeneralSetting.isAutorotate
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layoutIfNeeded()
        collectionView?.reloadData()
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        self.navigationController?.setNavigationBarHidden(true, animated: false)
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
        var pageCount = self.galleryModel.shows.count % self.galleryModel.perPageCount
        pageCount = pageCount == 0 ? self.galleryModel.perPageCount : pageCount
        if self.galleryModel.loadPageDirection == "down" {
            lastIndext = self.galleryModel.shows.count - pageCount
        }
        
        for i in 0...(pageCount - 1) {
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
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationController?.popViewController(animated: false)
    }
    
    @objc func pan(ges: UIPanGestureRecognizer) {
        let translation = ges.translation(in: nil)
        switch ges.state {
        case .began:
            self.bigin = translation
        case .changed:
            if self.mode == .vertical {
                if abs(self.bigin.y - translation.y) < 20 &&
                    abs(self.bigin.x - translation.x) > 80 {
                    Defaults.Viewer.mode = .horizontal
                    self.viewDidLayoutSubviews()
                    self.selectedIndex()
                }
            } else {
                if abs(self.bigin.y - translation.y) > 80 &&
                    abs(self.bigin.x - translation.x) < 20 {
                    Defaults.Viewer.mode = .vertical
                    self.viewDidLayoutSubviews()
                    self.selectedIndex()
                }
            }
        @unknown default:
            break
        }
    }
    
    func selectedIndex() {
        for (i, showPage) in self.galleryModel.shows.enumerated() {
            if showPage.index == self.galleryModel.readPage {
                let selectedIndex = IndexPath(item: i, section: 0)
                switch mode {
                case .horizontal:
                    collectionView!.scrollToItem(at: selectedIndex, at: .right, animated: false)
                case .vertical:
                    collectionView!.scrollToItem(at: selectedIndex, at: .top, animated: false)
                }
                break
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
        cell.setImageData(showModel.imageData ?? showModel.thumbData ?? UIImage(named: "placeholder")!.pngData()!)
        cell.imageView.isOpaque = true
        self.galleryModel.downloadImages(for: indexPath.item)
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let showModel = self.galleryModel.shows[indexPath.item]
        self.galleryModel.readPage = showModel.index
        self.readLabel.text = "\(showModel.index)/\(self.galleryModel.shows.count)/\(self.galleryModel.`length`)"
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
        guard mode != .vertical else {return true}
        guard let panGR = gestureRecognizer as? UIPanGestureRecognizer else {return true}
        guard collectionView.visibleCells.count > 0 else {return true}
        guard let cell = collectionView.visibleCells[0] as? ScrollingImageCell, cell.scrollView.zoomScale == 1 else {return true}
        let t = panGR.translation(in: nil)
        guard t.x != 0 else { return true }
        let v = panGR.velocity(in: nil)
        return v.y > abs(v.x)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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
