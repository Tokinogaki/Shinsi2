import Foundation

import Kanna
import UIColor_Hex_Swift

public extension Notification.Name {
    static let loadGalleryModel = Notification.Name("loadGalleryModel")
    static let loadGalleryModelNull = Notification.Name("loadGalleryModelNull")
    static let coverDownloaded = Notification.Name("coverDownloaded")
}

class GalleryModel: NSObject, NSCoding {
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
    
    @objc dynamic var updatedAt: Date = Date()
    @objc dynamic var createdAt: Date = Date()
    @objc private dynamic var _url = ""
    @objc private dynamic var _category = CategoryOptions.none.rawValue
    
    var isDownloaded: Bool = false
    var isLoadGalleryModel: Bool = false
    var loadPageDirection = "down"
    
    var tags: [TagModel] = []
    var shows: [ShowModel] = []
    var comments: [CommentModel] = []
    
    private var _readPage: Int = 0
    @objc var readPage: Int {
        get {
            if let readPage = UserDefaults.standard.value(forKey: "\(gid)_readPage") {
                _readPage = readPage as! Int
            }
            return _readPage
        }
        set {
            if _readPage == 0 || newValue != 1 {
                _readPage = newValue
            }
            UserDefaults.standard.setValue(_readPage, forKey: "\(gid)_readPage")
        }
    }
    
    private var _perPageCount: Int = 20
    @objc var perPageCount: Int {
        get {
            if let perPageCount = UserDefaults.standard.value(forKey: "PerPageCount") {
                _perPageCount = perPageCount as! Int
            }
            return _perPageCount
        }
        set {
            _perPageCount = newValue
            UserDefaults.standard.setValue(_perPageCount, forKey: "PerPageCount")
        }
    }
    
    var _coverState: DownloadStateEnum = .none
    var coverState: DownloadStateEnum {
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
        return kEximagesPath.appendingPathComponent("\(self.gid)_cover.jpg")
    }
    
    var hasCover: Bool {
        return FileManager.default.fileExists(atPath: self.localCover.path)
    }
    
    var cover: UIImage? {
        if self.hasCover {
            guard let data = try? Data(contentsOf: self.localCover) else { return nil }
            return UIImage(data: data)
        }
        return nil
    }
    
    var isLoadGalleryModelFinished: Bool {
        return self.shows.count == self.`length`
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
    
    var loadPageIndex: Int? {
        if self.shows.count == 0 {
            return (self.readPage - 1) / self.perPageCount
        }
        
        if self.loadPageDirection == "up" {
            if self.shows.first!.index == 1 {
                return nil
            }
            return self.shows.first!.index / self.perPageCount - 1
        }
        
        if self.shows.last!.index >= self.`length` {
            return nil
        }
        return self.shows.last!.index / self.perPageCount
    }

    var canDownload: Bool {
        if isDownloaded {
            return false
        }
        
        if self.`length` == self.shows.count {
            return true
        }
        
        return false
    }
    
    static func galleryModel(indexPageItem element: XMLElement?) -> GalleryModel {
        let galleryModel = GalleryModel(indexPageItem: element)
        return galleryModel
    }
    
    static func galleryModelList(indexPage doc: HTMLDocument?) -> [GalleryModel] {
        var gPageList: [GalleryModel] = []
        for element in doc!.xpath("//div [@class='gl1t']") {
            let galleryModel = self.galleryModel(indexPageItem: element)
            gPageList.append(galleryModel)
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
    
    func encode(with coder: NSCoder) {
        coder.encode(self.gid, forKey: "gid")
        coder.encode(self.token, forKey: "token")

        coder.encode(self.title, forKey: "title")
        coder.encode(self.title_jpn, forKey: "title_jpn")
        coder.encode(self.coverUrl, forKey: "coverUrl")
        coder.encode(self.posted, forKey: "posted")
        coder.encode(self.parent, forKey: "parent")
        coder.encode(self.language, forKey: "language")
        coder.encode(self.fileSize, forKey: "fileSize")
        coder.encode(self.`length`, forKey: "`length`")
        coder.encode(self.favorited, forKey: "favorited")
        coder.encode(self.rating, forKey: "rating")
        coder.encode(self.favorite.rawValue, forKey: "favorite")

        coder.encode(self.updatedAt, forKey: "updatedAt")
        coder.encode(self.createdAt, forKey: "createdAt")
        coder.encode(self._url, forKey: "_url")
        coder.encode(self._category, forKey: "_category")
    }
    
    required init?(coder: NSCoder) {
        super.init()
        self.gid = coder.decodeInteger(forKey: "gid")
        self.token = coder.decodeObject(forKey: "token") as! String

        self.title = coder.decodeObject(forKey: "title") as! String
        self.title_jpn = coder.decodeObject(forKey: "title_jpn") as! String
        self.coverUrl = coder.decodeObject(forKey: "coverUrl") as! String
        self.posted = coder.decodeObject(forKey: "posted") as! Date
        self.parent = coder.decodeInteger(forKey: "parent")
        self.language = coder.decodeObject(forKey: "language") as! String
        self.fileSize = coder.decodeObject(forKey: "fileSize") as! String
        self.`length` = coder.decodeInteger(forKey: "`length`")
        self.favorited = coder.decodeInteger(forKey: "favorited")
        self.rating = coder.decodeFloat(forKey: "rating")
        self.favorite = FavoriteEnum(rawValue: coder.decodeInteger(forKey: "favorite")) ?? .none

        self.updatedAt = coder.decodeObject(forKey: "updatedAt") as! Date
        self.createdAt = coder.decodeObject(forKey: "createdAt") as! Date
        self._url = coder.decodeObject(forKey: "_url") as! String
        self._category = coder.decodeInteger(forKey: "_category")
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
        self.rating = GalleryModel.getRating(with: style)
        
        node = element?.css("div.gl5t>div>div")[3]
        self.`length` = Int(node?.text?.replacingOccurrences(of: " pages", with: "") ?? "0") ?? 0
    }
    
    func setInfo(galleryModel element: HTMLDocument) {
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
        if self.tags.count > 0 {
            return
        }
        for t in element.xpath("//div [@id='taglist'] //tr") {
            let tagModel = TagModel(t)
            self.tags.append(tagModel)
            for value in tagModel.values {
                SearchManager.shared.addStatistics(text: "\(tagModel.name):\(value)")
            }
        }
    }
    
    func setComments(_ element: HTMLDocument) {
        if self.comments.count > 0 {
            return
        }
        //Parse comments
        let commentDateFormatter = DateFormatter()
        commentDateFormatter.dateFormat = "dd MMMM yyyy, HH:mm"
        for c in element.xpath("//div [@id='cdiv'] //div [@class='c1']") {
            if let dateAndAuthor = c.at_xpath("div [@class='c2'] /div [@class='c3']")?.text,
                let author = c.at_xpath("div [@class='c2'] /div [@class='c3'] /a")?.text,
                let text = c.at_xpath("div [@class='c6']")?.innerHTML {
                let dateString = dateAndAuthor.replacingOccurrences(of: author, with: "").replacingOccurrences(of: "Posted on ", with: "").replacingOccurrences(of: " by:   ", with: "")
                let r = CommentModel(author: author, date: commentDateFormatter.date(from: dateString) ?? Date(), text: text)
                self.comments.append(r)
            }
        }
    }
    
    func setPages(_ element: HTMLDocument) {
        var shows: [ShowModel] = []
        for link in element.xpath("//div [@class='gdtl'] //a") {
            if let url = link["href"] {
                if let imgNode = link.at_css("img"), let thumbUrl = imgNode["src"] {
                    let page = ShowModel()
                    page.thumbUrl = thumbUrl
                    page.url = url
                    shows.append(page)
                }
            }
        }
        
        if self.shows.last?.index ?? 0 > shows.first!.index {
            self.shows = shows + self.shows
        } else {
            self.shows += shows
        }
        
        if element.at_xpath("//div[@id='gdo4'] //div")?["onclick"] == nil {
            self.perPageCount = 40
        } else {
            self.perPageCount = 20
        }
    }
    
}

extension GalleryModel {
    
    func setFavorite(index: Int) {
        self.favorite = FavoriteEnum(rawValue: index + 1) ?? .none
    }
    
    func loadGalleryModel(direction: String) {
        self.loadPageDirection = direction
        
        if self.loadPageIndex == nil || self.isLoadGalleryModel {
            return
        }
        self.isLoadGalleryModel = true
        RequestManager.shared.getGalleryModel(galleryModel: self) {
            NotificationCenter.default.post(name: .loadGalleryModel, object: self)
            self.isLoadGalleryModel = false
        }
    }
    
    func downloadCover() {
        self.coverState = .downloading
        RequestManager.shared.downloadCover(galleryModel: self) { (error) in
            if error == nil {
                self.coverState = .downloaded
                NotificationCenter.default.post(name: .coverDownloaded, object: self)
            } else {
                self.coverState = .none
            }
        }
    }
    
    func downloadImages(for index: Int) {
        let upPrefetch = Defaults.Viewer.upPrefetch
        let downPrefetch = Defaults.Viewer.downPrefetch
        for i in (index - upPrefetch)..<(index + downPrefetch) {
            guard i < self.shows.count else {
                break
            }
            guard i >= 0 else {
                continue
            }
            let showModel = self.shows[i]
            if showModel.imageState == .downloaded || showModel.imageState == .downloading {
                continue
            }
            
            RequestManager.shared.getShowModel(showModel: showModel) {
                showModel.imageState = .downloading
                RequestManager.shared.downloadImage(showModel: showModel) { (error) in
                    if error == nil {
                        showModel.imageState = .downloaded
                        NotificationCenter.default.post(name: .imageDownloaded, object: showModel)
                    } else {
                        showModel.imageState = .none
                    }
                }
                
                NotificationCenter.default.post(name: .loadShowModel, object: self)
            }
        }
    }

    func downloadThumb(_ index: Int, recursive: Bool = false) {
        if self.shows.count == 0 || self.shows.count == index {
            return
        }
        
        let showModel = self.shows[index]
        if showModel.thumbState == .downloaded || showModel.thumbState == .downloading {
            return
        }
        RequestManager.shared.downloadThumb(showModel: showModel) { (error) in
            if error == nil {
                showModel.thumbState = .downloaded
                NotificationCenter.default.post(name: .thumbDownloaded, object: showModel)
            } else {
                showModel.thumbState = .none
            }
            if recursive {
                self.downloadThumb(index + 1)
            }
        }
    }
    
}
