import Foundation
import RealmSwift
import Kanna
import UIColor_Hex_Swift
import SDWebImage

class GalleryPage: Object {
    @objc dynamic var gid: Int = 0
    @objc dynamic var token = ""
    @objc dynamic var title = ""
    @objc dynamic var title_jpn = ""
    @objc dynamic var coverUrl = ""
    @objc dynamic var filecount = 0
    @objc dynamic var rating: Float = 0.0
    @objc dynamic var lastUpdateTime = ""
    @objc dynamic var isDownloaded = false
    @objc dynamic var readPage: UInt = 0
    @objc dynamic var createdAt: Date = Date()
    @objc dynamic var updatedAt: Date = Date()
    @objc private dynamic var _url = ""
    @objc private dynamic var _category = CategoryOptions.none.rawValue
    @objc private dynamic var _favorite = FavoriteEnum.none.rawValue
    @objc private dynamic var _status = StatusEnum.none.rawValue
    
    let tags = List<Tag>()
    let pages = List<ShowPage>()
    let comments = List<Comment>()
    var perPageCount: Int?
    
    var url: String {
        get {
            return self._url
        }
        set {
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
    
    var favorite: FavoriteEnum {
        get {
            return FavoriteEnum(rawValue: self._favorite) ?? .none
        }
        set {
            self._favorite = newValue.rawValue
        }
    }
    
    var status: StatusEnum {
        get {
            return StatusEnum(rawValue: self._status) ?? .none
        }
        set {
            self._status = newValue.rawValue
        }
    }
    
    var isIdTokenValide: Bool {
        return self.gid == 0 && token != ""
    }

    var canDownload: Bool {
        if isDownloaded {
            return false
        }
        else if self.filecount == self.pages.count {
            return true
        }
        else if self.status.rawValue >= StatusEnum.galleryEnd.rawValue {
            return true
        }
        return false
    }

    override static func primaryKey() -> String? {
        return "gid"
    }
    
    static func gPage(iPageItem element: XMLElement?) -> GalleryPage {
        let gPage = GalleryPage(iPageItem: element)
        return gPage
    }
    
    static func gPageList(iPage doc: HTMLDocument?) -> List<GalleryPage> {
        let gPageList = List<GalleryPage>()
        for element in doc!.xpath("//div [@class='gl1t']") {
            gPageList.append(gPage(iPageItem: element))
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
    
    init(iPageItem element: XMLElement?) {
        super.init()
        var node = element?.at_css("div.gl3t a")
        let imgNode = node?.at_css("img")
        self.url = node?["href"] ?? ""
        self.title = imgNode?["title"] ?? ""
        self.coverUrl = imgNode?["src"] ?? ""
        
        node = element?.at_css("div[class*='cs']")
        self.category = CategoryOptions.category(with: node?.text ?? "")
        
        node = element?.at_css("div[id*='posted_']")
        let hexColor = node?["style"]?.matches(for: "#[0-9a-z]{3,6}").first ?? ""
        self.lastUpdateTime = node?.text ?? ""
        self.favorite = FavoriteEnum(hexColor: hexColor)
        
        node = element?.at_css("div.ir")
        let style = node?["style"]?.matches(for: "[0-9- px]{7,10}").first
        self.rating = GalleryPage.getRating(with: style)
        
        node = element?.css("div.gl5t>div>div")[3]
        self.filecount = Int(node?.text?.replacingOccurrences(of: " pages", with: "") ?? "0") ?? 0
    }
    
    func getTitle() -> String {
        return title_jpn.isEmpty ? title : title_jpn
    }
    
    func setTags(with element: XMLElement?) {
        self.tags.removeAll()
        
    }
    
    func setComments(with element: XMLElement?) {
        self.comments.removeAll()
    }
    
    func setPage(sPage element: XMLElement?) {
        if self.pages.count == self.filecount {
            return;
        }
    }
    
}

class Tag : Object {
    @objc dynamic var name = ""
    let values = List<String>()
    
    init(_ element: XMLElement?) {
        super.init()
    }
    
    required init() {
        super.init()
    }
}

class Comment: Object {
    var author: String
    var date: Date
    var text: String
    var htmlAttributedText: NSAttributedString?
    init(author: String, date: Date, text: String) {
        self.author = author
        self.date = date
        self.text = text
        self.htmlAttributedText = text.htmlAttribute
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
}

struct CategoryOptions : OptionSet {
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

enum FavoriteEnum : Int {
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

enum StatusEnum : Int {
    case none, indexStart, indexEnd, galleryStart, galleryEnd, showStart, showEnd, downloadStart, downloadEnd
}
