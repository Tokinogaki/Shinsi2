import Foundation

import Kanna
import UIColor_Hex_Swift

public extension Notification.Name {
    static let loadGalleryPage = Notification.Name("loadGalleryPage")
    static let coverDownloaded = Notification.Name("coverDownloaded")
}

class GalleryPage: NSObject {
    @objc dynamic var gid: Int = 0
    @objc dynamic var token = ""
    
    @objc dynamic var title = ""
    @objc dynamic var title_jpn = ""
    @objc dynamic var coverUrl = ""
    @objc dynamic var posted: Date = Date()
    @objc dynamic var parent = 0
    @objc dynamic var language = ""
    @objc dynamic var fileSize = ""
    @objc dynamic var `length` = 0
    @objc dynamic var favorited: Int = 0
    @objc dynamic var rating: Float = 0.0
    @objc dynamic var favorite = FavoriteEnum.none
    
    @objc dynamic var isDownloaded: Bool = false
    @objc dynamic var perPageCount: Int = 0
    @objc dynamic var updatedAt: Date = Date()
    @objc dynamic var createdAt: Date = Date()
    @objc private dynamic var _url = ""
    @objc private dynamic var _category = CategoryOptions.none.rawValue
    
    var stopLoadGalleryPage = false
    
    var tags: [Tag] = []
    var showPageList: [ShowPage] = []
    var comments: [Comment] = []
    
    var _readPage: Int = 0
    @objc var readPage: Int {
        get {
            if let readPage = UserDefaults.standard.value(forKey: "\(gid)_readPage") {
                _readPage = readPage as! Int
            }
            return _readPage
        }
        set {
            _readPage = newValue
            UserDefaults.standard.setValue(_readPage, forKey: "\(gid)_readPage")
        }
    }
    
    var _coverState: StateEnum = .none
    var coverState: StateEnum {
        get {
            if self.hasCover {
                return .downloaded
            }
            return _coverState
        }
        set {
            _coverState = newValue
        }
    }
    
    var localCover: URL {
        return kEximagesPath.appendingPathComponent("\(self.gid)/cover.jpg")
    }
    
    var hasCover: Bool {
        return FileManager.default.fileExists(atPath: self.localCover.path)
    }
    
    var cover: UIImage? {
        if self.hasCover {
            let data = try! Data(contentsOf: self.localCover)
            return UIImage(data: data)
        }
        return nil
    }
    
    var isLoadGalleryPageFinished: Bool {
        return self.showPageList.count == self.`length`
    }
    
    var url: String {
        get {
            return self._url
        }
        set {
            self._url = newValue
            if let url = URL(string: newValue) {
                self.gid = url.pathComponents.indices.contains(2) ? Int(url.pathComponents[2]) ?? 0 : 0
                self.token = url.pathComponents.indices.contains(3) ? url.pathComponents[3] : ""
            }
        }
    }
    
    var category: CategoryOptions {
        get {
            return CategoryOptions(rawValue: self._category)
        }
        set {
            self._category = newValue.rawValue
        }
    }
    
    var isIdTokenValide: Bool {
        return self.gid != 0 && token != ""
    }
    
    var nextPageIndex: Int {
        guard self.showPageList.count != 0 else {
            return 0
        }
        
        return self.showPageList.count / self.perPageCount
    }

    var canDownload: Bool {
        if isDownloaded {
            return false
        }
        
        if self.`length` == self.showPageList.count {
            return true
        }
        
        return false
    }
    
    static func galleryPage(indexPageItem element: XMLElement?) -> GalleryPage {
        let galleryPage = GalleryPage(indexPageItem: element)
        return galleryPage
    }
    
    static func galleryPageList(indexPage doc: HTMLDocument?) -> [GalleryPage] {
        var gPageList: [GalleryPage] = []
        for element in doc!.xpath("//div [@class='gl1t']") {
            let galleryPage = self.galleryPage(indexPageItem: element)
            gPageList.append(galleryPage)
        }
        return gPageList
    }
    
    static func getRating(with style: String?) -> Float {
        switch style {
        case "-80px -1px":
            return 0.0
        case "-64px -21px":
            return 0.5
        case "-64px -1px":
            return 1.0
        case "-48px -21px":
            return 1.5
        case "-48px -1px":
            return 2.0
        case "-32px -21px":
            return 2.5
        case "-32px -1px":
            return 3.0
        case "-16px -21px":
            return 3.5
        case "-16px -1px":
            return 4.0
        case "0px -21px":
            return 4.5
        case "0px -1px":
            return 5.0
        default:
            return 0.0
        }
    }
    
    override init() {
        super.init()
    }
    
    init(indexPageItem element: XMLElement?) {
        super.init()
        self.setInfo(indexPageItem: element)
    }
    
    func getTitle() -> String {
        return title_jpn.isEmpty ? title : title_jpn
    }
    
    func setInfo(indexPageItem element: XMLElement?) {
        var node = element?.at_css("div.gl3t a")
        let imgNode = node?.at_css("img")
        self.url = node?["href"] ?? ""
        self.title = imgNode?["title"] ?? ""
        self.coverUrl = imgNode?["src"] ?? ""
        
        node = element?.at_css("div[class*='cs']")
        self.category = CategoryOptions.category(with: node?.text ?? "")
        
        node = element?.at_css("div[id*='posted_']")
        let hexColor = node?["style"]?.matches(for: "#[0-9a-z]{3,6}").first ?? ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        self.posted = dateFormatter.date(from: node?.text ?? "") ?? Date()
        self.favorite = FavoriteEnum(hexColor: hexColor)
        
        node = element?.at_css("div.ir")
        let style = node?["style"]?.matches(for: "[0-9- px]{7,10}").first
        self.rating = GalleryPage.getRating(with: style)
        
        node = element?.css("div.gl5t>div>div")[3]
        self.`length` = Int(node?.text?.replacingOccurrences(of: " pages", with: "") ?? "0") ?? 0
    }
    
    func setInfo(galleryPage element: HTMLDocument) {
        if var rating = element.at_xpath("//td [@id='rating_label']")?.text {
            rating = rating.replacingOccurrences(of: "Average: ", with: "")
            self.rating = Float(rating) ?? 0.0
        }
        
        for tr in element.xpath("//div [@id='gdd'] //tr") {
            if let key = tr.at_css("td.gdt1")?.text,
               let value = tr.at_css("td.gdt2")?.text {
                switch key {
                case "Parent:":
                    self.parent = Int(value) ?? 0
                case "Language:":
                    self.language = value
                case "File Size:":
                    self.fileSize = value
                case "Favorited:":
                    self.favorited = Int(value.replacingOccurrences(of: " times", with: "")) ?? 0
                default:
                    break
                }
            }
        }
    }
    
    func setTags(_ element: HTMLDocument) {
        self.tags.removeAll()
        for t in element.xpath("//div [@id='taglist'] //tr") {
            self.tags.append(Tag(t))
        }
    }
    
    func setComments(_ element: HTMLDocument) {
        self.comments.removeAll()
        //Parse comments
        let commentDateFormatter = DateFormatter()
        commentDateFormatter.dateFormat = "dd MMMM  yyyy, HH:mm zzz"
        for c in element.xpath("//div [@id='cdiv'] //div [@class='c1']") {
            if let dateAndAuthor = c.at_xpath("div [@class='c2'] /div [@class='c3']")?.text,
                let author = c.at_xpath("div [@class='c2'] /div [@class='c3'] /a")?.text,
                let text = c.at_xpath("div [@class='c6']")?.innerHTML {
                let dateString = dateAndAuthor.replacingOccurrences(of: author, with: "").replacingOccurrences(of: "Posted on ", with: "").replacingOccurrences(of: " by:   ", with: "")
                let r = Comment(author: author, date: commentDateFormatter.date(from: dateString) ?? Date(), text: text)
                self.comments.append(r)
            }
        }
    }
    
    func setPages(_ element: HTMLDocument) {
        for link in element.xpath("//div [@class='gdtl'] //a") {
            if let url = link["href"] {
                if let imgNode = link.at_css("img"), let thumbUrl = imgNode["src"] {
                    let page = ShowPage()
                    page.thumbUrl = thumbUrl
                    page.url = url
                    self.showPageList.append(page)
                }
            }
        }
        if self.perPageCount == 0 {
            self.perPageCount = self.showPageList.count
        }
    }
    
}

extension GalleryPage {
    
    func setFavorite(index: Int) {
        self.favorite = FavoriteEnum(rawValue: index + 1) ?? .none
    }
    
    private func loadShowPageInGalleryPage() {
        if self.showPageList.count >= self.`length` || self.stopLoadGalleryPage {
            return
        }
        RequestManager.shared.getGalleryPage(galleryPage: self) {
            NotificationCenter.default.post(name: .loadGalleryPage, object: self)
            self.loadShowPageInGalleryPage()
        }
    }
    
    func startLoadGalleryPage() {
        self.stopLoadGalleryPage = false
        self.loadShowPageInGalleryPage()
    }
    
    func cancelLoadGalleryPage() {
        self.stopLoadGalleryPage = true
    }
    
    func downloadCover() {
        self.coverState = .downloading
        RequestManager.shared.downloadCover(galleryPage: self) { (result) in
            if let _ = result.value {
                self.coverState = .downloaded
                NotificationCenter.default.post(name: .coverDownloaded, object: self)
            } else {
                self.coverState = .none
            }
        }
    }
    
    func downloadImages(for index: Int) {
        for i in (index - 3)..<(index + 5) {
            guard i < self.showPageList.count else {
                break
            }
            guard i >= 0 else {
                continue
            }
            let showPage = self.showPageList[i]
            if showPage.imageState == .downloaded || showPage.imageState == .downloading {
                continue
            }
            
            RequestManager.shared.getShowPage(showPage: showPage) {
                showPage.imageState = .downloading
                RequestManager.shared.downloadImage(showPage: showPage) { (result) in
                    if let _ = result.value {
                        showPage.imageState = .downloaded
                        NotificationCenter.default.post(name: .imageDownloaded, object: showPage)
                    } else {
                        showPage.imageState = .none
                    }
                }
                
                NotificationCenter.default.post(name: .loadShowPage, object: self)
            }
        }
    }

    func downloadThumb(_ index: Int, recursive: Bool = false) {
        if self.showPageList.count == 0 || self.showPageList.count == index {
            return
        }
        
        let showPage = self.showPageList[index]
        if showPage.thumbState == .downloaded || showPage.thumbState == .downloading {
            return
        }
        RequestManager.shared.downloadThumb(showPage: showPage) { (result) in
            if let _ = result.value {
                showPage.thumbState = .downloaded
                NotificationCenter.default.post(name: .thumbDownloaded, object: showPage)
            } else {
                showPage.thumbState = .none
            }
            if recursive {
                self.downloadThumb(index + 1)
            }
        }
    }
    
}
