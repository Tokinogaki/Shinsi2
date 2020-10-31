import Foundation

import Kanna
import UIColor_Hex_Swift


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
