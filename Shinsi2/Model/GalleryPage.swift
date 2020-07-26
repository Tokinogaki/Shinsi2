import Foundation
import RealmSwift
import Kanna
import UIColor_Hex_Swift
import SDWebImage

public extension Notification.Name {
    static let updateCalleryPage = Notification.Name("updateCalleryPage")
    static let loadGalleryPage = Notification.Name("loadGalleryPage")
    static let loadShowPage = Notification.Name("loadShowPage")
}

class GalleryPage: Object {
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
    @objc dynamic var readPage: Int = 0
    @objc dynamic var perPageCount: Int = 0
    @objc dynamic var createdAt: Date = Date()
    @objc private dynamic var _url = ""
    @objc private dynamic var _category = CategoryOptions.none.rawValue
    
    let tags = List<Tag>()
    let showPageList = List<ShowPage>()
    let comments = List<Comment>()
    
    private var _loadShowPageQueue: OperationQueue?
    var loadShowPageQueue: OperationQueue {
        if _loadShowPageQueue == nil {
            _loadShowPageQueue = OperationQueue()
            _loadShowPageQueue!.maxConcurrentOperationCount = 25
            _loadShowPageQueue!.name = self.url
        }
        
        return _loadShowPageQueue!
    }
    
    private var _downloadImageQueue: OperationQueue?
    var downloadImageQueue: OperationQueue {
        if _downloadImageQueue == nil {
            _downloadImageQueue = OperationQueue()
            _downloadImageQueue!.maxConcurrentOperationCount = 25
            _downloadImageQueue!.name = self.url
        }
        
        return _downloadImageQueue!
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
    
    var isLoading: Bool {
        return self.showPageList.count != self.`length`
    }

    override class func primaryKey() -> String? {
        return "gid"
    }
    
    override class func ignoredProperties() -> [String] {
        return []
    }
    
    static func galleryPage(indexPageItem element: XMLElement?) -> GalleryPage {
        let galleryPage = GalleryPage(indexPageItem: element)
        if let gp = RealmManager.shared.getGalleryPage(galleryPage.gid) {
            RealmManager.shared.updateGalleryPage(galleryPage)
            return gp
        }
        RealmManager.shared.addGalleryPage(galleryPage)
        return galleryPage
    }
    
    static func galleryPageList(indexPage doc: HTMLDocument?) -> List<GalleryPage> {
        let gPageList = List<GalleryPage>()
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
    
    required init() {
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
        try! RealmManager.shared.realm.write {
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
    }
    
    func setInfo(galleryPage element: HTMLDocument) {
        try! RealmManager.shared.realm.write {
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
    }
    
    func setTags(_ element: HTMLDocument) {
        try! RealmManager.shared.realm.write {
            self.tags.removeAll()
            for t in element.xpath("//div [@id='taglist'] //tr") {
                self.tags.append(Tag(t))
            }
        }
    }
    
    func setComments(_ element: HTMLDocument) {
        try! RealmManager.shared.realm.write {
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
    }
    
    func setPages(_ element: HTMLDocument) {
        guard self.isLoading else { return }
        try! RealmManager.shared.realm.write {
            for link in element.xpath("//div [@class='gdtl'] //a") {
                if let url = link["href"] {
                    if let imgNode = link.at_css("img"), let thumbUrl = imgNode["src"] {
                        let page = ShowPage(value: ["thumbUrl": thumbUrl, "url": url])
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
    
}

class Tag: Object {
    @objc dynamic var name = ""
    let values = List<String>()
    
    init(_ element: XMLElement) {
        super.init()
        
        var index = 0
        for td in element.xpath("td") {
            if index == 0 {
                if var name = td.text {
                    name.removeLast()
                    self.name = name
                }
            } else {
                for i in td.xpath("div //a") {
                    if let text = i.text { self.values.append(text) }
                }
            }
            index += 1
        }
    }
    
    required init() {
        super.init()
    }
}

class Comment: Object {
    var author: String = ""
    var date: Date = Date()
    var text: String = ""
    var htmlAttributedText: NSAttributedString?
    init(author: String, date: Date, text: String) {
        super.init()
        self.author = author
        self.date = date
        self.text = text
        self.htmlAttributedText = text.htmlAttribute
    }
    
    required init() {
        super.init()
    }
}

struct CategoryOptions: OptionSet {
    let rawValue: Int
    
    static func category(with stringValue: String) -> CategoryOptions {
        var string = stringValue.lowercased()
        let regex = try! NSRegularExpression(pattern: "[ -]+", options: NSRegularExpression.Options.caseInsensitive)
        let range = NSMakeRange(0, string.count)
        string = regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "")
        switch string {
        case "doujinshi":
            return .doujinshi
        case "manga":
            return .manga
        case "artistcg":
            return .artistCG
        case "gamecg":
            return .gameCG
        case "western":
            return .western
        case "nonh":
            return .nonH
        case "imageset":
            return .imageSet
        case "cosplay":
            return .cosplay
        case "asianporn":
            return .asianPorn
        case "misc":
            return .misc
        default:
            return .none
        }
    }
    
    static let none = CategoryOptions([])
    static let doujinshi = CategoryOptions(rawValue: 0x0001)
    static let manga = CategoryOptions(rawValue: 0x0002)
    static let artistCG = CategoryOptions(rawValue: 0x0004)
    static let gameCG = CategoryOptions(rawValue: 0x0008)
    static let western = CategoryOptions(rawValue: 0x0010)
    static let nonH = CategoryOptions(rawValue: 0x0020)
    static let imageSet = CategoryOptions(rawValue: 0x0040)
    static let cosplay = CategoryOptions(rawValue: 0x0080)
    static let asianPorn = CategoryOptions(rawValue: 0x0100)
    static let misc = CategoryOptions(rawValue: 0x0200)
    static let all = CategoryOptions([.doujinshi, .manga, .artistCG, .gameCG, .western, .nonH, .imageSet, .cosplay, .asianPorn, .misc])

    var color: UIColor {
        switch self {
        case .doujinshi:
            return UIColor(red: 255, green: 59, blue: 59, alpha: 1)
        case .manga:
            return UIColor(red: 255, green: 186, blue: 59, alpha: 1)
        case .artistCG:
            return UIColor(red: 234, green: 220, blue: 59, alpha: 1)
        case .gameCG:
            return UIColor(red: 59, green: 157, blue: 59, alpha: 1)
        case .western:
            return UIColor(red: 164, green: 255, blue: 76, alpha: 1)
        case .nonH:
            return UIColor(red: 76, green: 180, blue: 255, alpha: 1)
        case .imageSet:
            return UIColor(red: 59, green: 59, blue: 255, alpha: 1)
        case .cosplay:
            return UIColor(red: 117, green: 59, blue: 159, alpha: 1)
        case .asianPorn:
            return UIColor(red: 243, green: 176, blue: 243, alpha: 1)
        case .misc:
            return UIColor(red: 212, green: 212, blue: 212, alpha: 1)
        default:
            return UIColor(red: 255, green: 255, blue: 255, alpha: 1)
        }
    }
    
    var text: String {
        switch self {
        case .doujinshi:
            return "Doujinshi"
        case .manga:
            return "manga"
        case .artistCG:
            return "Artist CG"
        case .gameCG:
            return "Game CG"
        case .western:
            return "Western"
        case .nonH:
            return "Non-H"
        case .imageSet:
            return "Image Set"
        case .cosplay:
            return "Cosplay"
        case .asianPorn:
            return "Asian Porn"
        case .misc:
            return "Misc"
        default:
            return "None"
        }
    }
}

@objc enum FavoriteEnum: Int, RealmEnum {
    case none, favorite0, favorite1, favorite2, favorite3, favorite4, favorite5, favorite6, favorite7, favorite8, favorite9
    
    init(text stringValue: String) {
        switch stringValue.lowercased() {
        case "favorites 0":
            self = .favorite0
        case "favorites 1":
            self = .favorite1
        case "favorites 2":
            self = .favorite2
        case "favorites 3":
            self = .favorite3
        case "favorites 4":
            self = .favorite4
        case "favorites 5":
            self = .favorite5
        case "favorites 6":
            self = .favorite6
        case "favorites 7":
            self = .favorite7
        case "favorites 8":
            self = .favorite8
        case "favorites 9":
            self = .favorite9
        default:
            self = .none
        }
    }
    
    init(hexColor stringValue: String) {
        if stringValue == "" {
            self = .none
            return
        }
        let colorValue = UIColor(stringValue)
        switch colorValue.hexString() {
        case FavoriteEnum.favorite0.color.hexString():
            self = .favorite0
        case FavoriteEnum.favorite1.color.hexString():
            self = .favorite1
        case FavoriteEnum.favorite2.color.hexString():
            self = .favorite2
        case FavoriteEnum.favorite3.color.hexString():
            self = .favorite3
        case FavoriteEnum.favorite4.color.hexString():
            self = .favorite4
        case FavoriteEnum.favorite5.color.hexString():
            self = .favorite5
        case FavoriteEnum.favorite6.color.hexString():
            self = .favorite6
        case FavoriteEnum.favorite7.color.hexString():
            self = .favorite7
        case FavoriteEnum.favorite8.color.hexString():
            self = .favorite8
        case FavoriteEnum.favorite9.color.hexString():
            self = .favorite9
        default:
            self = .none
        }
    }
    
    var color: UIColor {
        switch self {
        case .favorite0:
            return UIColor("#000")
        case .favorite1:
            return UIColor("#f00")
        case .favorite2:
            return UIColor("#fa0")
        case .favorite3:
            return UIColor("#dd0")
        case .favorite4:
            return UIColor("#080")
        case .favorite5:
            return UIColor("#9f4")
        case .favorite6:
            return UIColor("#4bf")
        case .favorite7:
            return UIColor("#00f")
        case .favorite8:
            return UIColor("#508")
        case .favorite9:
            return UIColor("#e8e")
        default:
            return UIColor("#fff")
        }
    }
}

extension GalleryPage {
    
    func setFavorite(index: Int) {
        try! RealmManager.shared.realm.write {
            self.favorite = FavoriteEnum(rawValue: index + 1) ?? .none
        }
    }
    
    func updateCalleryPage() {
        guard !self.isLoading else { return }
        RequestManager.shared.getGalleryPage(galleryPage: self) {
            NotificationCenter.default.post(name: .updateCalleryPage, object: self)
        }
        self.loadShowPage()
    }
    
    func loadGalleryPage() {
        guard self.isLoading else { return }
        RequestManager.shared.getGalleryPage(galleryPage: self) {
            NotificationCenter.default.post(name: .updateCalleryPage, object: self)
            
            if self.isLoading {
                self.loadGalleryPage()
            } else {
                self.loadShowPage()
            }
        }
    }
    
    func startDownloadImage() {
        self.downloadImageQueue.addOperation {
            DispatchQueue.main.async {
                for showPage in self.showPageList {
                    guard !showPage.isDownload else {
                        continue
                    }
                    showPage.dowloadImage()
                }
            }
        }
    }
    
    func cancelDownloadImage() {
        self.downloadImageQueue.cancelAllOperations()
    }
    
    private func loadShowPage() {
        self.loadShowPageQueue.addOperation {
            DispatchQueue.main.async {
                for showPage in  self.showPageList {
                    guard !showPage.isDownload else {
                        continue
                    }
                    RequestManager.shared.getShowPage(showPage: showPage) {
                        NotificationCenter.default.post(name: .loadShowPage, object: self)
                    }
                }
            }
        }
    }
    
}
