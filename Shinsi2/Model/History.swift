import Foundation
import RealmSwift
import Kanna
import UIColor_Hex_Swift
import SDWebImage

class SearchHistory : Object {
    @objc dynamic var text: String = ""
    @objc dynamic var date: Date = Date()
}
