import UIKit
import AloeStackView
import SVProgressHUD
import WebKit

extension Notification.Name {
    static let settingChanged = Notification.Name("SS_SETTING_CHANGED")
}

class SettingVC: BaseViewController {
    
    let stackView = AloeStackView()
    
    let passcodeSwitch = UISwitch()

    let upPrefetchArray = ["1", "2", "3", "5", "10"]
    let downPrefetchArray = ["1", "2", "3", "5", "10"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.barTintColor = UIColor(white: 0, alpha: 0.5)
        
        view.addSubview(stackView)
        stackView.frame = view.bounds
        stackView.hidesSeparatorsByDefault = true
        stackView.separatorInset = .zero
        stackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        //Host
        addTitle("Host")
        let hostStackView = UIStackView()
        hostStackView.distribution = .fillEqually
        hostStackView.spacing = 4
        
        let hostSeg = UISegmentedControl(items: ["E-Hentai", "EX-Hentai"])
        hostSeg.selectedSegmentIndex = Defaults.URL.host == kHostEHentai ? 0 : 1
        hostSeg.addTarget(self, action: #selector(hostSegmentedControlVauleChanged(sender:)), for: .valueChanged)
        stackView.addRow(hostSeg)
        
        //Search Filter
        addTitle("Search Filter")
        
        let categoryStackViews: [UIStackView] = [UIStackView(), UIStackView(), UIStackView(), UIStackView(), UIStackView()]
        categoryStackViews.forEach({
            $0.distribution = .fillEqually
            $0.spacing = 4
        })
        for (i, c) in Defaults.Search.categories.enumerated() {
            let b = RadioButton(type: .custom)
            b.tag = i
            b.setTitle(c, for: .normal)
            b.isSelected = UserDefaults.standard.bool(forKey: Defaults.Search.categories[b.tag])
            b.addTarget(self, action: #selector(categoryButtonDidClick(button:)), for: .touchUpInside)
            categoryStackViews[Int(i/2)].addArrangedSubview(b)
        }
        categoryStackViews.forEach({
            stackView.addRow($0)
            if $0 == categoryStackViews.first {
                stackView.setInset(forRow: $0, inset: UIEdgeInsets(top: 12, left: 12, bottom: 2, right: 12))
            } else if $0 == categoryStackViews.last {
                stackView.setInset(forRow: $0, inset: UIEdgeInsets(top: 2, left: 12, bottom: 12, right: 12))
            } else {
                stackView.setInset(forRow: $0, inset: UIEdgeInsets(top: 2, left: 12, bottom: 2, right: 12))
            }
        })
        
        addSubTitle("Minimum Rating")
        let ratingSeg = UISegmentedControl(items: ["All", "2", "3", "4", "5"])
        ratingSeg.selectedSegmentIndex = Defaults.Search.rating
        ratingSeg.addTarget(self, action: #selector(ratingSegmentedControlVauleChanged(sender:)), for: .valueChanged)
        stackView.addRow(ratingSeg)
        
        // Settings
        addTitle("My Settings")
        
        let ehSetting = createTextLable("E-Hentai settings")
        ehSetting.isUserInteractionEnabled = true
        stackView.addRow(ehSetting)
        stackView.setTapHandler(forRow: ehSetting) { [weak self] _ in
            self?.presentWebViewController(url: Defaults.URL.configEH)
        }
        
        let exSetting = createTextLable("EX-Hentai settings")
        exSetting.isUserInteractionEnabled = true
        stackView.addRow(exSetting)
        stackView.setTapHandler(forRow: exSetting) { [weak self] _ in
            self?.presentWebViewController(url: Defaults.URL.configEX)
        }
        
        //UI
        addTitle("List")
        
        let titleLabel = createSubTitleLabel("Hide Title")
        let titleSwitch = UISwitch()
        titleSwitch.isOn = Defaults.List.isHideTitle
        titleSwitch.addTarget(self, action: #selector(listTitleSwitchVauleChanged(sender:)), for: .valueChanged)
        stackView.addRow(createStackView([titleLabel, titleSwitch]))
        
        let tagLabel = createSubTitleLabel("Hide Info")
        let tagSwitch = UISwitch()
        tagSwitch.isOn = Defaults.List.isHideInfo
        tagSwitch.addTarget(self, action: #selector(listInfoSwitchVauleChanged(sender:)), for: .valueChanged)
        stackView.addRow(createStackView([tagLabel, tagSwitch]))
        
        let listFavLabel = createSubTitleLabel("Show Favorites List")
        let listFavSwitch = UISwitch()
        listFavSwitch.isOn = Defaults.List.isShowFavoriteList
        listFavSwitch.addTarget(self, action: #selector(listFavoriteSwitchVauleChanged(sender:)), for: .valueChanged)
        stackView.addRow(createStackView([listFavLabel, listFavSwitch]))
        
        //Gallery
        addTitle("Gallery")
        
        let galleryFavLabel = createSubTitleLabel("Show Favorites List")
        let galleryFavSwitch = UISwitch()
        galleryFavSwitch.isOn = Defaults.Gallery.isShowFavoriteList
        galleryFavSwitch.addTarget(self, action: #selector(galleryFavoriteSwitchVauleChanged(sender:)), for: .valueChanged)
        stackView.addRow(createStackView([galleryFavLabel, galleryFavSwitch]))
        
        let autoScrollLabel = createSubTitleLabel("Continue Reading")
        let autoScrollSwitch = UISwitch()
        autoScrollSwitch.isOn = Defaults.Gallery.isAutomaticallyScrollToHistory
        autoScrollSwitch.addTarget(self, action: #selector(galleryAutoScrollToHistorySwitchVauleChanged(sender:)), for: .valueChanged)
        stackView.addRow(createStackView([autoScrollLabel, autoScrollSwitch]))
        
        let quickScrollLabel = createSubTitleLabel("Show Quick Scroll")
        let quickScrollSwitch = UISwitch()
        quickScrollSwitch.isOn = Defaults.Gallery.isShowQuickScroll
        quickScrollSwitch.addTarget(self, action: #selector(galleryQuickScrollSwitchVauleChanged(sender:)), for: .valueChanged)
        stackView.addRow(createStackView([quickScrollLabel, quickScrollSwitch]))
        
        //Viewer
        addTitle("Viewer")
        addSubTitle("Scroll Direction")
        let viewerModeSeg = UISegmentedControl(items: ["Horizontal", "Vertical"])
        viewerModeSeg.selectedSegmentIndex = Defaults.Viewer.mode == .horizontal ? 0 : 1
        viewerModeSeg.addTarget(self, action: #selector(viewerModeSegmentedControlVauleChanged(sender:)), for: .valueChanged)
        stackView.addRow(viewerModeSeg)
        
        addSubTitle("Up Prefetch")
        let upPrefetchSeg = UISegmentedControl(items: upPrefetchArray)
        upPrefetchSeg.selectedSegmentIndex = upPrefetchArray.firstIndex{ $0 == "\(Defaults.Viewer.upPrefetch)"} ?? 1
        upPrefetchSeg.addTarget(self, action: #selector(upPrefetchSegmentedControlVauleChanged(sender:)), for: .valueChanged)
        stackView.addRow(upPrefetchSeg)
        
        addSubTitle("Down Prefetch")
        let downPrefetchSeg = UISegmentedControl(items: downPrefetchArray)
        downPrefetchSeg.selectedSegmentIndex = downPrefetchArray.firstIndex{ $0 == "\(Defaults.Viewer.downPrefetch)"} ?? 3
        downPrefetchSeg.addTarget(self, action: #selector(downPrefetchSegmentedControlVauleChanged(sender:)), for: .valueChanged)
        stackView.addRow(downPrefetchSeg)
        
        addTitle("General Settings")
        let autorotateLabel = createSubTitleLabel("Autorotate")
        let autorotateSwitch = UISwitch()
        autorotateSwitch.isOn = Defaults.GeneralSetting.isAutorotate
        autorotateSwitch.addTarget(self, action: #selector(generalSettingAutorotateSwitchVauleChanged(sender:)), for: .valueChanged)
        stackView.addRow(createStackView([autorotateLabel, autorotateSwitch]))
        
        if BiometricsManager.canSupported() {
            let touchLabel = createSubTitleLabel(BiometricsManager.getBiometryType())
            let touchSwitch = UISwitch()
            touchSwitch.isOn = Defaults.GeneralSetting.isUseBiometrics
            touchSwitch.addTarget(self, action: #selector(listTouchSwitchVauleChanged(sender:)), for: .valueChanged)
            stackView.addRow(createStackView([touchLabel, touchSwitch]))
            
            let passcodeLabel = createSubTitleLabel("Passcode Fallback")
            passcodeSwitch.isOn = Defaults.GeneralSetting.isUsePasscode
            passcodeSwitch.isEnabled = Defaults.GeneralSetting.isUseBiometrics
            passcodeSwitch.addTarget(self, action: #selector(listPasscodeSwitchVauleChanged(sender:)), for: .valueChanged)
            stackView.addRow(createStackView([passcodeLabel, passcodeSwitch]))
        }
        
        //Cache+
        addTitle("Cache")
        let cacheSizeLable = createSubTitleLabel("size: counting...")
        stackView.addRow(cacheSizeLable)
        //TODO: xxxx
//        ImageCache.default.calculateDiskStorageSize(completion: { (result) in
//            var cacheSize = 0.0;
//            switch result {
//            case .success(let value):
//                cacheSize = Double(value / 1024 / 1024)
//            case .failure(_):
//                cacheSize = 0
//            }
//            DispatchQueue.main.async { [weak self, weak cacheSizeLable] in
//                guard let self = self, let cacheSizeLable = cacheSizeLable else {return}
//                cacheSizeLable.text = String(format: "size: %.1fmb", cacheSize)
//                
//                let clear = self.createTextLable("Delete All Cache")
//                clear.heightAnchor.constraint(equalToConstant: 50).isActive = true
//                clear.textAlignment = .right
//                clear.textColor = kMainColor
//                clear.isUserInteractionEnabled = true
//                self.stackView.insertRow(clear, after: cacheSizeLable)
//                self.stackView.setTapHandler(forRow: clear) { _ in
//                    KingfisherManager.shared.cache.cleanExpiredDiskCache {
//                        cacheSizeLable.text = "size: 0mb"
//                    }
//                }
//            }
//        })
        
        //Info
        addWhiteSpace(height: 60)
        let version = addSubTitle("version: \(Defaults.App.version)")
        version.textAlignment = .right
        
        //Logout
        let logout = createTextLable("Logout")
        logout.textAlignment = .center
        logout.backgroundColor = kMainColor
        logout.textColor = .white 
        logout.layer.cornerRadius = 4
        logout.clipsToBounds = true
        logout.heightAnchor.constraint(equalToConstant: 50).isActive = true
        logout.isUserInteractionEnabled = true
        stackView.addRow(logout)
        stackView.setTapHandler(forRow: logout) { [weak self] _ in
            guard let parent = self?.navigationController?.presentingViewController as? UINavigationController else {return}
            HTTPCookieStorage.shared.cookies?.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
            let vc = self?.storyboard?.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
            parent.dismiss(animated: true, completion: {
                parent.setViewControllers([vc], animated: false)
            })
            let dataStore = WKWebsiteDataStore.default()
            dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { (records) in
                for record in records {
                    dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: [record], completionHandler: {})
                }
            }
        }
    }

    @objc func categoryButtonDidClick(button: RadioButton) {
        button.isSelected.toggle()
        let key = Defaults.Search.categories[button.tag]
        UserDefaults.standard.set(button.isSelected, forKey: key)
    }
    
    @objc func hostSegmentedControlVauleChanged(sender: UISegmentedControl) {
        Defaults.URL.host = sender.selectedSegmentIndex == 0 ? kHostEHentai : kHostExHentai
    }
    
    @objc func ratingSegmentedControlVauleChanged(sender: UISegmentedControl) {
        Defaults.Search.rating = sender.selectedSegmentIndex
    }
    
    @objc func upPrefetchSegmentedControlVauleChanged(sender: UISegmentedControl) {
        Defaults.Viewer.upPrefetch = Int(upPrefetchArray[sender.selectedSegmentIndex]) ?? 1
    }
    
    @objc func downPrefetchSegmentedControlVauleChanged(sender: UISegmentedControl) {
        Defaults.Viewer.downPrefetch = Int(downPrefetchArray[sender.selectedSegmentIndex]) ?? 3
    }
    
    @objc func listInfoSwitchVauleChanged(sender: UISwitch) {
        Defaults.List.isHideInfo = sender.isOn
        NotificationCenter.default.post(name: .settingChanged, object: nil)
    }
    
    @objc func listTitleSwitchVauleChanged(sender: UISwitch) {
        Defaults.List.isHideTitle = sender.isOn
        NotificationCenter.default.post(name: .settingChanged, object: nil)
    }
    
    @objc func generalSettingAutorotateSwitchVauleChanged(sender: UISwitch) {
        Defaults.GeneralSetting.isAutorotate = sender.isOn
        NotificationCenter.default.post(name: .settingChanged, object: nil)
    }
    
    @objc func listTouchSwitchVauleChanged(sender: UISwitch) {
        Defaults.GeneralSetting.isUseBiometrics = sender.isOn
        passcodeSwitch.isEnabled = Defaults.GeneralSetting.isUseBiometrics
    }
    
    @objc func listPasscodeSwitchVauleChanged(sender: UISwitch) {
        Defaults.GeneralSetting.isUsePasscode = sender.isOn
    }
    
    @objc func listFavoriteSwitchVauleChanged(sender: UISwitch) {
        Defaults.List.isShowFavoriteList = sender.isOn
    }
    
    @objc func galleryQuickScrollSwitchVauleChanged(sender: UISwitch) {
        Defaults.Gallery.isShowQuickScroll = sender.isOn
    }
    
    @objc func galleryFavoriteSwitchVauleChanged(sender: UISwitch) {
        Defaults.Gallery.isShowFavoriteList = sender.isOn
    }
    
    @objc func galleryAutoScrollToHistorySwitchVauleChanged(sender: UISwitch) {
        Defaults.Gallery.isAutomaticallyScrollToHistory = sender.isOn
    }
    
    @objc func viewerModeSegmentedControlVauleChanged(sender: UISegmentedControl) {
        Defaults.Viewer.mode = sender.selectedSegmentIndex == 0 ? .horizontal : .vertical
    }
    
    func presentWebViewController(url: URL) {
        guard let parent = navigationController?.presentingViewController else {return}
        let vc = storyboard?.instantiateViewController(withIdentifier: "WebVC") as! WebVC
        vc.url = url
        let nvc = UINavigationController(rootViewController: vc)
        parent.dismiss(animated: true, completion: {
            parent.present(nvc, animated: true, completion: nil)
        })
    }
    
    func createTitleLable(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textColor = UIColor.darkGray
        return label
    }
    
    @discardableResult func addTitle(_ text: String, showSeperator: Bool = true) -> UILabel {
        let view = createTitleLable(text)
        stackView.addRow(view)
        if showSeperator {
            stackView.showSeparator(forRow: view)
        }
        return view
    }
    
    func createTextLable(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        return label
    }
    
    func createSubTitleLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor.init(white: 0.5, alpha: 1)
        return label
    }
    
    @discardableResult func addSubTitle(_ text: String) -> UILabel {
        let label = createSubTitleLabel(text)
        stackView.addRow(label)
        stackView.setInset(forRow: label, inset: UIEdgeInsets(top: 12, left: 15, bottom: 0, right: 15))
        return label
    }
    
    func createStackView(_ views: [UIView], axis: NSLayoutConstraint.Axis = .horizontal, distribution: UIStackView.Distribution = .fill) -> UIStackView {
        let s = UIStackView(arrangedSubviews: views)
        s.axis = axis
        s.distribution = distribution
        return s
    }
    
    func addWhiteSpace(height: CGFloat) {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        stackView.addRow(view)
    }
}

class RadioButton: UIButton {

    override var isSelected: Bool { didSet { setNeedsDisplay() } }
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let p = UIBezierPath(roundedRect: rect, cornerRadius: 4)
        let color: UIColor = isSelected ?  tintColor : UIColor(white: 0.8, alpha: 1)
        color.set()
        p.fill()
    }

}
