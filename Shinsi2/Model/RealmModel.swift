import Foundation
import RealmSwift
import Kanna
import UIColor_Hex_Swift

class BrowsingHistory: Object {
    @objc dynamic var doujinshi: Doujinshi?
    @objc dynamic var currentPage: Int = 0
    @objc dynamic var id: Int = 999999999
    @objc dynamic var createdAt: Date = Date()
    @objc dynamic var updatedAt: Date = Date()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class Doujinshi: Object {
    @objc dynamic var coverUrl = ""
    @objc dynamic var title = ""
    @objc dynamic var url = ""
    @objc dynamic var gid = ""
    @objc dynamic var filecount = 0
    @objc dynamic var rating: Float = 0.0
    @objc dynamic var title_jpn = ""
    @objc dynamic var isDownloaded = false
    @objc dynamic var lastUpdateTime = ""
    @objc dynamic var date = Date()
    @objc dynamic var gdata: GData?
    
    dynamic var category: CategoryOptions = .none
    dynamic var favorite: FavoriteEnum = .none
    
    func setGData(gdata: GData?) {
        self.gid = gdata?.gid ?? ""
        self.filecount = gdata?.filecount ?? 0
        self.rating = gdata?.rating ?? 0.0
        self.title = gdata?.title ?? ""
        self.title_jpn = gdata?.title_jpn ?? ""
        self.coverUrl = gdata?.coverUrl ?? ""
        self.tags = gdata?.tags ?? List<Tag>()
        self.gdata = gdata
    }
    
    let pages = List<Page>()
    var perPageCount: Int?
    var comments: [Comment] = []   //Won't store
    var element: XMLElement? {
        get {
            return nil
        }
        set {
            var node = newValue?.at_css("div.gl3t a")
            let imgNode = node?.at_css("img")
            self.url = node?["href"] ?? ""
            self.title = imgNode?["title"] ?? ""
            self.coverUrl = imgNode?["src"] ?? ""
            
            node = newValue?.at_css("div[class*='cs']")
            self.category = CategoryOptions.`init`(with: node?.text ?? "")
            
            node = newValue?.at_css("div[id*='posted_']")
            let hexColor = node?["style"]?.matches(for: "#[0-9a-z]{3,6}").first ?? ""
            self.lastUpdateTime = node?.text ?? ""
            self.favorite = FavoriteEnum(hexColor: hexColor)
            
            node = newValue?.at_css("div.ir")
            let style = node?["style"]?.matches(for: "[0-9- px]{7,10}").first
            self.rating = Doujinshi.getRating(with: style)
            
            node = newValue?.css("div.gl5t>div>div")[3]
            self.filecount = Int(node?.text?.replacingOccurrences(of: " pages", with: "") ?? "0") ?? 0
        }
    }
    
    public static func `init`(element: XMLElement) -> Doujinshi {
        let doujinshi = Doujinshi()
        doujinshi.element = element
        return doujinshi
    }
    
    func getTitle() -> String {
        return title_jpn.isEmpty ? title : title_jpn
    }
    
    var tags = List<Tag>()
    lazy var gTag: GTag = {
        var g = GTag()
        let keys = g.allProperties().keys
        tags.forEach {
            if $0.name.contains(":"), let key = $0.name.components(separatedBy: ":").first, keys.contains(key) {
                g[key].append($0.name.replacingOccurrences(of: "\(key):", with: ""))
            } else {
                g["misc"].append($0.name)
            }
        }
        return g
    }()
    
    //Computed property
    var id: Int { 
        guard let u = URL(string: url), u.pathComponents.indices.contains(2), let d = Int(u.pathComponents[2]) else {return 999999999}
        return d
    }
    var token: String {
        guard let u = URL(string: url), u.pathComponents.indices.contains(3) else {return "invalid_token"}
        return u.pathComponents[3]
    }
    var isIdTokenValide: Bool {
        return id != 999999999 && token != "invalid_token"
    }
    var canDownload: Bool {
        if isDownloaded {
            return false
        } else if let gdata = gdata, gdata.filecount == pages.count {
            return true
        }
        return false
    }
    
    public static func getRating(with style: String?) -> Float {
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
    
    override static func ignoredProperties() -> [String] {
        return ["comments", "commentScrollPosition", "perPageCount", "gTag"]
    }
}

class Page: Object {
    @objc dynamic var thumbUrl = ""
    @objc dynamic var url = ""
    var photo: SSPhoto!
    var localUrl: URL {
        return documentURL.appendingPathComponent(thumbUrl)
    }
    var localImage: UIImage? {
        return UIImage(contentsOfFile: localUrl.path)
    }
    static func blankPage() -> Page {
        let p = Page()
        p.photo = SSPhoto(URL: "")
        return p
    }
}

class GData: Object {
    @objc dynamic var gid = ""
    @objc dynamic var filecount = 0
    @objc dynamic var rating: Float = 0.0
    @objc dynamic var title = ""
    @objc dynamic var title_jpn = ""
    func getTitle() -> String {
        return title_jpn.isEmpty ? title : title_jpn
    }
    @objc dynamic var coverUrl = ""
    let tags = List<Tag>()
    lazy var gTag: GTag = {
        var g = GTag()
        let keys = g.allProperties().keys
        tags.forEach {
            if $0.name.contains(":"), let key = $0.name.components(separatedBy: ":").first, keys.contains(key) {
                g[key].append($0.name.replacingOccurrences(of: "\(key):", with: ""))
            } else {
                g["misc"].append($0.name)
            }
        }
        return g
    }()
    
    override static func ignoredProperties() -> [String] {
        return ["gTag"]
    }
}

class Tag: Object {
    @objc dynamic var name = ""
}

class SearchHistory: Object {
    @objc dynamic var text: String = ""
    @objc dynamic var date: Date = Date()
}

struct Comment {
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
}

struct GTag: PropertyLoopable {
    var language: [String] = []
    var artist: [String] = []
    var group: [String] = []
    var parody: [String] = []
    var character: [String] = []
    var male: [String] = []
    var female: [String] = []
    var misc: [String] = []
    
    subscript(key: String) -> [String] {
        get {
            switch key {
            case "language":
                return language
            case "artist":
                return artist
            case "group":
                return group
            case "parody":
                return parody
            case "character":
                return character
            case "male":
                return male
            case "female":
                return female
            case "misc":
                return misc
            default:
                return []
            }
        }
        set(newValue) {
            switch key {
            case "language":
                language = newValue
            case "artist":
                artist = newValue
            case "group":
                group = newValue
            case "parody":
                parody = newValue
            case "character":
                character = newValue
            case "male":
                male = newValue
            case "female":
                female = newValue
            case "misc":
                misc = newValue
            default:
                break
            }
        }
    }
}

struct CategoryOptions : OptionSet {
    let rawValue: Int
    
    static func `init`(with stringValue: String) -> CategoryOptions {
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

enum FavoriteEnum {
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
            self = .favorite0
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
            self = .favorite0
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
