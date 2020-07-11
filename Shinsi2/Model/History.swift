import Foundation
import RealmSwift
import Kanna
import UIColor_Hex_Swift
import SDWebImage

class BrowsingHistory : Object {
    @objc dynamic var doujinshi: GalleryPage?
    @objc dynamic var currentPage: Int = 0
    @objc dynamic var id: Int = Int(INT32_MAX)
    @objc dynamic var createdAt: Date = Date()
    @objc dynamic var updatedAt: Date = Date()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class SearchHistory : Object {
    @objc dynamic var text: String = ""
    @objc dynamic var date: Date = Date()
}
