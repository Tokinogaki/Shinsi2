import Foundation

import Kanna
import UIColor_Hex_Swift



class TagModel: NSObject {
    @objc dynamic var name = ""
    var values = Array<String>()
    
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
    
}

