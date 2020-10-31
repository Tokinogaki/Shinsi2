import Foundation

import Kanna
import UIColor_Hex_Swift


@objc enum FavoriteEnum: Int {
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

