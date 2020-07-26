import UIKit
import Hero
import SDWebImage
import Photos
import RealmSwift

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
    weak var galleryPage: GalleryPage!
    private lazy var browsingHistory: BrowsingHistory? = {
        return RealmManager.shared.browsingHistory(for: galleryPage)
    }()
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
        
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIScene.willDeactivateNotification, object: nil)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        }
        
        self.galleryPage.startDownloadImage()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.updateBrowsingHistory()
        self.galleryPage.cancelDownloadImage()
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
    
    @objc func longPress(ges: UILongPressGestureRecognizer) {
        guard ges.state == .began else {return}
        let p = ges.location(in: collectionView)
        if let indexPath = collectionView!.indexPathForItem(at: p) {
            let item = self.galleryPage.showPageList[indexPath.item]
            if let image = item.image {
                let alert = UIAlertController(title: "Save to camera roll", message: nil, preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default) { _ in
                    PHPhotoLibrary.requestAuthorization({ s in
                        if s == .authorized {
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetChangeRequest.creationRequestForAsset(from: image)
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
    
    @objc func willResignActive(_ notification: Notification) {
        updateBrowsingHistory()
    }
    
    private func updateBrowsingHistory() {
        guard let browsingHistory = browsingHistory, let currentPage = selectedIndexPath?.item else { return }
        RealmManager.shared.updateBrowsingHistory(browsingHistory, currentPage: currentPage)
        print("currentPage: \(currentPage)")
    }
}

extension ViewerVC: UICollectionViewDelegateFlowLayout {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.galleryPage.showPageList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ScrollingImageCell
        let showPage = self.galleryPage.showPageList[indexPath.item]
        
        cell.imageView.hero.id = heroID(for: indexPath)
        cell.imageView.hero.modifiers = [.arc(intensity: 1), .forceNonFade]
        cell.imageView.isOpaque = true
        cell.showPage = self.galleryPage.showPageList[indexPath.item]
        cell.imageView.sd_setImage(with: URL(string: showPage.imageUrl), placeholderImage: nil, options: [.highPriority, .handleCookies])
        
        return cell
    }
    
    func heroID(for indexPath: IndexPath) -> String {
        let index = indexPath.item - (Defaults.Gallery.isAppendBlankPage ? 1 : 0)
        return "image_\(galleryPage.gid)_\(index)"
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
        guard let cell = collectionView?.visibleCells[0] as? ScrollingImageCell, cell.scrollView.zoomScale == 1 else {return false}
        let v = panGR.velocity(in: nil)
        return v.y > abs(v.x)
    } 
}
