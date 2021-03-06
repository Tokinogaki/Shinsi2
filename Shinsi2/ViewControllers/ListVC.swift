import UIKit

import SVProgressHUD
import UIColor_Hex_Swift

class ListVC: BaseViewController {
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if Defaults.GeneralSetting.isAutorotate {
            return .all
        }
        return [.portrait, .portraitUpsideDown]
    }

    @IBOutlet weak var collectionView: UICollectionView!
    private(set) lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: searchHistoryVC)
        searchHistoryVC.searchController = searchController
        return searchController
    }()
    private lazy var searchHistoryVC: SearchHistoryVC = {
        return self.storyboard!.instantiateViewController(withIdentifier: "SearchHistoryVC") as! SearchHistoryVC
    }()
    private var galleryModelArray: [GalleryModel] = []
    private var currentPage = -1
    private var loadingPage = -1
    private var rowCount: Int { return min(5, max(2, Int(floor(collectionView.bounds.width / Defaults.List.cellWidth)))) }
    @IBOutlet weak var loadingView: LoadingView!
    
    enum Mode: String {
        case normal = "normal"
        case favorite = "favorites"
        case history = "history"
    }
    private var mode: Mode {
        let text = searchController.searchBar.text?.lowercased() ?? ""
        if text == Mode.history.rawValue {
            return .history
        } else if text.contains("favorites") {
            return .favorite
        } else {
            return .normal
        }
    }
    private var favoriteCategory: Int? {
        guard mode == .favorite else { return nil }
        let text = searchController.searchBar.text?.lowercased() ?? ""
        return text == "favorites" ? -1 : Int(text.replacingOccurrences(of: "favorites", with: ""))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "title_icon"))
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: collectionView)
        }
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress(ges:)))
        longPressGesture.delaysTouchesBegan = true
        collectionView.addGestureRecognizer(longPressGesture)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(ges:)))
        collectionView.addGestureRecognizer(pinchGesture)
        
        searchController.delegate = self
        if navigationController?.viewControllers.count == 1 {
            searchController.searchBar.text = Defaults.List.lastSearchKeyword
        } else {
            Defaults.List.lastSearchKeyword = searchController.searchBar.text ?? ""
        }

        searchHistoryVC.searchController = searchController
        searchHistoryVC.selectBlock = {[unowned self] text in
            self.searchController.isActive = false
            self.searchController.searchBar.text = text
            self.reloadData()
        }
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.showsCancelButton = false
        searchController.searchBar.enablesReturnKeyAutomatically = false
        searchController.searchBar.tintColor = view.tintColor
        definesPresentationContext = true
        
        loadNextPage()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(settingChanged(notification:)), name: .settingChanged, object: nil)
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        view.layoutIfNeeded()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if searchController.isActive {
            searchController.dismiss(animated: false, completion: nil)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let indexPath = collectionView.indexPathsForVisibleItems.first
        collectionView?.collectionViewLayout.invalidateLayout()
        coordinator.animate(alongsideTransition: { _ in
            if let indexPath = indexPath {
                self.collectionView!.scrollToItem(at: indexPath, at: .top, animated: true)
            }
        })
    }
    
    private var initCellWidth = Defaults.List.defaultCellWidth
    @objc func pinch(ges: UIPinchGestureRecognizer) {
        if ges.state == .began {
            initCellWidth = collectionView.visibleCells.first?.frame.size.width ?? Defaults.List.defaultCellWidth
        } else if ges.state == .changed {
            let scale = ges.scale - 1
            let dx = initCellWidth * scale
            let width = min(max(initCellWidth + dx, 80), view.bounds.width)
            if width != Defaults.List.cellWidth {
                Defaults.List.cellWidth = width
                collectionView.performBatchUpdates({
                    collectionView.collectionViewLayout.invalidateLayout() 
                }, completion: nil)
            }
        }
    }

    func loadNextPage() {
        if mode == .history {
            loadingView.hide()
            galleryModelArray = HistoryManager.shared.historyList
            collectionView.reloadData()
        } else {
            guard loadingPage != currentPage + 1 else {return}
            loadingPage = currentPage + 1
            if loadingPage == 0 { loadingView.show() }
            RequestManager.shared.getIndexPage(page: loadingPage, search: SearchManager.shared.searchText) {[weak self] galleryModelArray in
                guard let self = self else {return}
                self.loadingView.hide()
                guard galleryModelArray.count > 0 else {return}
                var list = galleryModelArray
                for page in self.galleryModelArray {
                    list.removeAll(where: { $0.gid == page.gid })
                }
                
                let lastIndext = max(0, self.galleryModelArray.count - 1)
                let insertIndexPaths = list.enumerated().map { IndexPath(item: $0.offset + lastIndext, section: 0) }
                self.galleryModelArray += list
                self.collectionView.performBatchUpdates({
                    self.collectionView.insertItems(at: insertIndexPaths)
                }, completion: nil)
                self.currentPage += 1
                self.loadingPage = -1
            }
        }
    }
    
    func reloadData() {
        currentPage = -1
        loadingPage = -1
        let deleteIndexPaths = galleryModelArray.enumerated().map { IndexPath(item: $0.offset, section: 0)}
        galleryModelArray = []
        collectionView.performBatchUpdates({
            self.collectionView.deleteItems(at: deleteIndexPaths)
        }, completion: { _ in
            self.loadNextPage()
        })
    }

    @IBAction func showFavorites(sender: UIBarButtonItem) {
        guard navigationController?.presentedViewController == nil else {return}
        if Defaults.List.isShowFavoriteList {
            let sheet = UIAlertController(title: "Favorites", message: nil, preferredStyle: .actionSheet)
            let all = UIAlertAction(title: "ALL", style: .default, handler: { (_) in
                self.showSearch(with: "favorites")
            })
            sheet.addAction(all)
            Defaults.List.favoriteTitles.enumerated().forEach { f in
                let a = UIAlertAction(title: f.element, style: .default, handler: { (_) in
                    self.showSearch(with: "favorites\(f.offset)")
                })
                sheet.addAction(a)
            }
            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            sheet.popoverPresentationController?.barButtonItem = sender
            present(sheet, animated: true, completion: nil)
        } else {
            showSearch(with: "favorites")
        } 
    }
    
    func showSearch(with shotcut: String) {
        searchController.searchBar.text = shotcut
        if searchController.isActive {
            searchController.dismiss(animated: false, completion: nil)
        }
        reloadData()
    }

    @objc func longPress(ges: UILongPressGestureRecognizer) {
        guard mode == .favorite else {return}
        guard ges.state == .began, let indexPath = collectionView.indexPathForItem(at: ges.location(in: collectionView)) else {return}

        let doujinshi = galleryModelArray[indexPath.item]
        let title = "Action"
        let actionTitle = "Remove"
        let alert = UIAlertController(title: title, message: doujinshi.title, preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: actionTitle, style: .destructive) { _ in
            if self.mode == .favorite {
                RequestManager.shared.deleteFavorite(gallery: doujinshi)
                self.galleryModelArray.remove(at: indexPath.item)
                self.collectionView.performBatchUpdates({
                    self.collectionView.deleteItems(at: [indexPath])
                }, completion: nil)
            }
        }
        if mode == .favorite {
            let moveAction = UIAlertAction(title: "Move", style: .default) { (_) in
                self.showFavoriteMoveSheet(with: indexPath)
            }
            alert.addAction(moveAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    @objc func showFavoriteMoveSheet(with indexPath: IndexPath) {
        let doujinshi = galleryModelArray[indexPath.item]
        let sheet = UIAlertController(title: "Move to", message: doujinshi.title, preferredStyle: .actionSheet)
        let displayingFavCategory = favoriteCategory ?? -1
        Defaults.List.favoriteTitles.enumerated().forEach { f in
            if displayingFavCategory != f.offset {
                let a = UIAlertAction(title: f.element, style: .default, handler: { (_) in
                    RequestManager.shared.moveFavorite(gallery: doujinshi, to: f.offset)
                    if displayingFavCategory != -1 {
                        self.galleryModelArray.remove(at: indexPath.item)
                        self.collectionView.performBatchUpdates({
                            self.collectionView.deleteItems(at: [indexPath])
                        }, completion: nil)
                    } else {
                        SVProgressHUD.show("→".toIcon(), status: nil)
                        SVProgressHUD.dismiss(withDelay: 1)
                    }
                })
                sheet.addAction(a)
            }
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        let sourceView = collectionView.cellForItem(at: indexPath)
        sheet.popoverPresentationController?.sourceView = sourceView
        sheet.popoverPresentationController?.sourceRect = CGRect(x: 0, y: sourceView!.bounds.height/2, width: sourceView!.bounds.width, height: 0)
        present(sheet, animated: true, completion: nil)
    }
    
    @objc func settingChanged(notification: Notification) {
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        UIViewController.attemptRotationToDeviceOrientation()
        if Defaults.GeneralSetting.isAutorotate {
            Tools.orientation(UIInterfaceOrientation.landscapeLeft)
        } else {
            Tools.orientation(UIInterfaceOrientation.portrait)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: self)
        if segue.identifier == "showSetting" {
        }
    }
}

extension ListVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return galleryModelArray.count
    } 
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ListCell
        
        let galleryModel = galleryModelArray[indexPath.item]
        galleryModel.downloadCover()
        cell.galleryModel = galleryModel
        cell.imageView.contentMode = .scaleAspectFill
        cell.imageView.image = galleryModel.cover ?? UIImage(named: "placeholder")

        var infoText = galleryModel.category.text
        let df = DateFormatter()
        df.dateFormat = "yyyy/MM/dd HH:mm"
        let posted = df.string(from: galleryModel.posted)
        infoText += "\n\(posted)"
        infoText += "\n\(galleryModel.rating)"
        infoText += "\n\(galleryModel.readPage)/\(galleryModel.`length`)"
        
        cell.infoLabel.text = infoText
        cell.titleLabel?.text = galleryModel.title
        
        if galleryModel.favorite != .none {
            cell.infoLabel.layer.borderWidth = 2
            cell.infoLabel.layer.borderColor = galleryModel.favorite.color.cgColor
            cell.infoLabel.backgroundColor = galleryModel.favorite.color.withAlphaComponent(0.3)
        } else {
            cell.infoLabel.backgroundColor = UIColor(hex3: 0, alpha: 0.3)
            cell.infoLabel.layer.borderWidth = 0
        }

        cell.infoLabel.isHidden = Defaults.List.isHideInfo
        cell.titleLabel?.isHidden = Defaults.List.isHideTitle
        
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.main.scale
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let galleryModel = self.galleryModelArray[indexPath.row]
            galleryModel.downloadCover()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = storyboard!.instantiateViewController(withIdentifier: "GalleryVC") as! GalleryVC
        vc.galleryModel = galleryModelArray[indexPath.item]
        vc.galleryModel.readPage = 1
        HistoryManager.shared.addHistory(galleryModel: vc.galleryModel)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let width = (collectionView.bounds.width - flowLayout.sectionInset.left - flowLayout.sectionInset.right - flowLayout.minimumInteritemSpacing * CGFloat((rowCount - 1))) / CGFloat(rowCount)
        return CGSize(width: width, height: width * paperRatio)
    }
}

extension ListVC: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView.indexPathForItem(at: location) else {return nil}
        let vc = storyboard!.instantiateViewController(withIdentifier: "GalleryVC") as! GalleryVC
        let item = galleryModelArray[indexPath.item]
        vc.galleryModel = item
        vc.delegate = self
        return vc
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        navigationController?.pushViewController(viewControllerToCommit, animated: true)
    }
}

extension ListVC: GalleryVCPreviewActionDelegate {
    
    func galleryDidSelectTag(text: String) {
        pushToListVC(with: text)
    }
    
    func pushToListVC(with tag: String) {
        let vc = storyboard!.instantiateViewController(withIdentifier: "ListVC") as! ListVC
        vc.searchController.searchBar.text = tag
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension ListVC: UISearchBarDelegate, UISearchControllerDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = true }
        searchController.dismiss(animated: true, completion: nil)
        SearchManager.shared.addSearch(text: SearchManager.shared.searchText)
        reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        SearchManager.shared.searchText = searchText
        searchHistoryVC.tableView.reloadData()
        DispatchQueue.main.async {
            self.searchController.searchResultsController?.view.isHidden = false
        }
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = false }
        DispatchQueue.main.async {
            searchController.searchResultsController?.view.isHidden = false
        }
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        searchController.searchResultsController?.view.isHidden = false
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = true }
    }
}

extension ListVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        switch mode {
        case .favorite, .normal:
            if let indexPath = collectionView.indexPathsForVisibleItems.sorted().last,
                indexPath.item > galleryModelArray.count - max(rowCount * 2, 10) {
                loadNextPage()
            }
        default:
            break
        }
        
    }
} 
