import Foundation

import Kanna
import UIColor_Hex_Swift


class CommentModel: NSObject {
    @objc dynamic var author: String = ""
    @objc dynamic var date: Date = Date()
    @objc dynamic var text: String = ""
    init(author: String, date: Date, text: String) {
        super.init()
        self.author = author
        self.date = date
        self.text = text
    }

}
