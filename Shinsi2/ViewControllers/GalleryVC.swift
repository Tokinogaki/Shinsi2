import UIKit
import SVProgressHUD
import SafariServices

class GalleryVC: BaseViewController {
    var galleryModel: GalleryModel!
    private var didScrollToHistory = false
    private var rowCount: Int { return min(5, max(2, Int(floor(collectionView.bounds.width / Defaults.Gallery.cellWidth)))) }
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tagButton: UIBarButtonItem!
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    @IBOutlet weak var commentButton: UIBarButtonItem!
    private var scrollBar: QuickScrollBar!
    weak var delegate: GalleryVCPreviewActionDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = galleryModel.getTitle()
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(ges:)))
        collectionView.addGestureRecognizer(pinchGesture)

        scrollToLastReadingPage()
        updateNavigationItems()

        NotificationCenter.default.addObserver(self, selector: #selector(handleLoadCalleryPageNotification(notification:)), name: .loadGalleryModel, object: nil)

        if Defaults.Gallery.isShowQuickScroll {
            scrollBar = QuickScrollBar(scrollView: collectionView, target: self)
            scrollBar.textForIndexPath = { indexPath in
                return "\(indexPath.item + 1)"
            }
            scrollBar.color = UIColor.init(white: 0.2, alpha: 0.6)
            scrollBar.gestureRecognizeWidth = 44
            let width: CGFloat = 38
            scrollBar.indicatorRightMargin = -width/2
            scrollBar.indicatorCornerRadius = width/2
            scrollBar.indicatorSize = CGSize(width: width + 6, height: width)
            scrollBar.isBarHidden = true
            scrollBar.textOffset = 10
            scrollBar.draggingTextOffset = 40
        }
        
        self.galleryModel.loadGalleryModel(direction: "down")
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard UIApplication.shared.applicationState == .active else {return}
        let indexPath = collectionView.indexPathsForVisibleItems.first
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.collectionViewLayout.invalidateLayout()
        coordinator.animate(alongsideTransition: { _ in
            if let indexPath = indexPath {
                self.collectionView!.scrollToItem(at: indexPath, at: .top, animated: false)
            }
        })
    }

    private var initCellWidth = Defaults.Gallery.defaultCellWidth
    @objc func pinch(ges: UIPinchGestureRecognizer) {
        if ges.state == .began {
            initCellWidth = collectionView.visibleCells.first?.frame.size.width ?? Defaults.Gallery.defaultCellWidth
        } else if ges.state == .changed {
            let scale = ges.scale - 1
            let dx = initCellWidth * scale
            let width = min(max(initCellWidth + dx, 80), view.bounds.width)
            if width != Defaults.Gallery.cellWidth {
                Defaults.Gallery.cellWidth = width
                collectionView.performBatchUpdates({
                    collectionView.collectionViewLayout.invalidateLayout()
                }, completion: nil)
            }
        }
    }

    func updateNavigationItems() {
        tagButton.isEnabled = true
        commentButton.isEnabled = galleryModel.comments.count > 0
        favoriteButton.isEnabled = galleryModel.favorite == .none && galleryModel.shows.count > 0
    }

    private func scrollToLastReadingPage() {
        guard Defaults.Gallery.isAutomaticallyScrollToHistory else {return}
        guard self.galleryModel.readPage > 0 else { return }
        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: IndexPath(row: self.galleryModel.readPage - 1, section: 0), at: .top, animated: true)
        }
    }

    @IBAction func addToFavorite(sender: UIBarButtonItem) {
        guard navigationController?.presentedViewController == nil else {return}
        if Defaults.Gallery.isShowFavoriteList {
            let sheet = UIAlertController(title: "Favorites", message: nil, preferredStyle: .actionSheet)
            Defaults.List.favoriteTitles.enumerated().forEach({ f in
                let a = UIAlertAction(title: f.element, style: .default, handler: { (_) in
                    self.favoriteButton.isEnabled = false
                    RequestManager.shared.addGalleryToFavorite(gallery: self.galleryModel, category: f.offset)
//                    SVProgressHUD.show("♥".toIcon(), status: nil)
                })
                sheet.addAction(a)
            })
            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            sheet.popoverPresentationController?.barButtonItem = sender
            present(sheet, animated: true, completion: nil)
        } else {
            favoriteButton.isEnabled = false
            RequestManager.shared.addGalleryToFavorite(gallery: self.galleryModel)
//            SVProgressHUD.show("♥".toIcon(), status: nil)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "showTag",
           let nv = segue.destination as? UINavigationController,
           let vc = nv.viewControllers.first as? TagVC {
            vc.galleryModel = self.galleryModel
            vc.clickBlock = { [unowned self, unowned vc] tag in
                vc.dismiss(animated: true, completion: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: {
                        self.pushToListVC(with: tag)
                    })
                })
            }
        }
        if segue.identifier == "showComment",
           let nv = segue.destination as? UINavigationController,
           let vc = nv.viewControllers.first as? CommentVC {
            vc.doujinshi = self.galleryModel
            vc.delegate = self
        }
    }

    func pushToListVC(with tag: String) {
        let vc = storyboard!.instantiateViewController(withIdentifier: "ListVC") as! ListVC
        vc.searchController.searchBar.text = tag
        navigationController?.pushViewController(vc, animated: true)
    }

    override var previewActionItems: [UIPreviewActionItem] {
        var actions: [UIPreviewActionItem] = []
        let artist = galleryModel.title.artist
        if let artist = artist {
            actions.append( UIPreviewAction(title: "Artist: \(artist)", style: .default) { (_, _) -> Void in
                self.delegate?.galleryDidSelectTag(text: "\(artist)" )
            })
        }
        if let circle = galleryModel.title.circleName, circle != artist {
            actions.append( UIPreviewAction(title: "Circle: \(circle)", style: .default) { (_, _) -> Void in
                self.delegate?.galleryDidSelectTag(text: "\(circle)" )
            })
        }
        if !galleryModel.isDownloaded && galleryModel.favorite == .none {
            actions.append( UIPreviewAction(title: "♥", style: .default) { (_, _) -> Void in
                RequestManager.shared.addGalleryToFavorite(gallery: self.galleryModel)
//                SVProgressHUD.show("♥".toIcon(), status: nil)
            })
        }
        return actions
    }
    
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
        
        let bottomOffset = self.collectionView!.contentSize.height - self.collectionView!.contentOffset.y

        if self.galleryModel.loadPageDirection == "up" {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
        }
        
        self.collectionView.performBatchUpdates({
            self.collectionView.insertItems(at: insertIndexPaths)
        }) {_ in
            if self.galleryModel.loadPageDirection == "up" {
                self.collectionView!.contentOffset = CGPoint.init(x: 0, y: self.collectionView!.contentSize.height - bottomOffset)
                CATransaction.commit()
            }
        }
        
        self.updateNavigationItems()
    }
    
}

extension GalleryVC: CommentVCDelegate {
    func commentVC(_ vc: CommentVC, didTap url: URL) {
        if url.absoluteString.contains(Defaults.URL.host) {
            if url.absoluteString.contains(Defaults.URL.host+"/g/"), url.absoluteString != galleryModel.url {
                //Gallery
                vc.dismiss(animated: true) {
//                    let d = GalleryModel(value: ["url": url.absoluteString])
//                    let vc = self.storyboard!.instantiateViewController(withIdentifier: "GalleryVC") as! GalleryVC
//                    vc.galleryModel = d
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            } else if url.absoluteString.contains(Defaults.URL.host+"/s/") {
                //Page
                if let page = galleryModel.shows.filter({ $0.url == url.absoluteString }).first,
                   let index = galleryModel.shows.index(of: page) {
                    vc.dismiss(animated: true) {
                        self.collectionView.scrollToItem(at: IndexPath(item: index, section: 0),
                            at: .top,
                            animated: false)
                    }
                }
            } else {
                vc.dismiss(animated: true) {
                    let webVC = self.storyboard?.instantiateViewController(withIdentifier: "WebVC") as! WebVC
                    webVC.url = url
                    let nvc = UINavigationController(rootViewController: webVC)
                    self.navigationController?.present(nvc, animated: true, completion: nil)
                }
            }
        } else {
            vc.dismiss(animated: true) {
                let sfVC = SFSafariViewController(url: url)
                self.navigationController?.present(sfVC, animated: true, completion: nil)
            }
        }
    }
}

protocol GalleryVCPreviewActionDelegate: class {
    func galleryDidSelectTag(text: String)
}

extension GalleryVC: UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout,
    UICollectionViewDataSourcePrefetching {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return galleryModel.shows.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ImageCell
        let showModel = galleryModel.shows[indexPath.item]
        
        cell.showModel = showModel
        cell.imageView.image = showModel.thumb ?? UIImage(named: "placeholder")
        
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale
        
        self.galleryModel.downloadThumb(indexPath.row)
        
        return cell
    }

    func isIndexPathSelected(indexPath: IndexPath) -> Bool {
        if let selecteds = collectionView.indexPathsForSelectedItems {
            return selecteds.contains(indexPath)
        }
        return false
    }

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            self.galleryModel.downloadThumb(indexPath.row)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard galleryModel.shows.count > 1 else {return}
        let vc = storyboard!.instantiateViewController(withIdentifier: "ViewerVC") as! ViewerVC
        self.galleryModel.readPage = self.galleryModel.shows[indexPath.item].index
        vc.selectedIndexPath = indexPath
        vc.galleryModel = self.galleryModel
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let width = (collectionView.bounds.width - flowLayout.sectionInset.left - flowLayout.sectionInset.right - flowLayout.minimumInteritemSpacing * CGFloat((rowCount - 1))) / CGFloat(rowCount)
        return CGSize(width: width, height: width * paperRatio)
    }
}

extension GalleryVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let visibleItems = collectionView.indexPathsForVisibleItems.sorted()
        let contentSizeHeight = scrollView.contentSize.height
        
        if contentSizeHeight == 0 || visibleItems.count == 0 {
            return
        }
        
        // Up loading
        if let indexPath = visibleItems.first,
           let cell = collectionView.cellForItem(at: indexPath) as? ImageCell,
           let showPage = cell.showModel,
           self.galleryModel.shows.firstIndex(of: showPage) == 0 {
            self.galleryModel.loadGalleryModel(direction: "up")
        }
        // down loading
        else if let indexPath = visibleItems.last,
                let cell = collectionView.cellForItem(at: indexPath) as? ImageCell,
                let showPage = cell.showModel,
                self.galleryModel.shows.lastIndex(of: showPage) == self.galleryModel.shows.count - 1 {
            self.galleryModel.loadGalleryModel(direction: "down")
        }
    }
}
