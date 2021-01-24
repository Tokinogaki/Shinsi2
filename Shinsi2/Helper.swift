import UIKit

extension String {    
    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            var rs = [String]()
            for m in results {
                if let range = Range(m.range, in: self) {
                    rs.append(String(self[range]))
                }
            }
            return rs
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    func removeSymbol() -> String {
        let set = CharacterSet(charactersIn: "()[]")
        return self.trimmingCharacters(in: set)
    }
    
    func isDoujinshi() -> Bool {
        return true
        //Need more research
        //let doujinshiPattern = "^\\(.*\\).*\\[.*\\].*\\(.*\\)"
        //return self.matches(for: doujinshiPattern).count != 0
    }
    
    var conventionName: String? {
        guard isDoujinshi() else { return nil }
        let pattern = "^\\([^\\(]*\\)"
        return self.matches(for: pattern).first?.removeSymbol() ?? nil
    }
    
    var circleName: String? {
        guard isDoujinshi() else { return nil }
        let pattern = "\\[[^\\]]*\\]"
        let matches = self.matches(for: pattern)
        if let m = matches.first {
            let p = "\\(.*\\)"
            if let n = m.matches(for: p).first {
                return m.replacingOccurrences(of: n, with: "").removeSymbol()
            }
        }
        return matches.first?.removeSymbol() ?? nil
    }
    
    var artist: String? {
        guard isDoujinshi() else { return nil }
        let pattern = "\\[[^\\]]*\\]"
        let matches = self.matches(for: pattern)
        if let m = matches.first {
            let p = "\\(.*\\)"
            if let r = m.matches(for: p).first {
                return r.removeSymbol()
            }
        }
        return matches.first?.removeSymbol() ?? nil
    }
    
    var language: String? {
        let pattern = "\\[[^\\[]+訳\\]"
        if let match = self.matches(for: pattern).first?.removeSymbol() {
            return match
        } else {
            let ls = ["albanian", "arabic", "bengali", "catalan", "chinese", "czech", "danish", "dutch", "english", "esperanto",
                      "estonian", "finnish", "french", "german", "greek", "hebrew", "hindi", "hungarian", "indonesian", "italian",
                      "japanese", "korean", "latin", "mongolian", "polish", "portuguese", "romanian", "russian", "slovak",
                      "slovenian", "spanish", "swedish", "tagalog", "thai", "turkish", "ukrainian", "vietnamese"]
            for l in ls {
                if self.lowercased().contains(l) {
                    return l
                }
            }
            return nil
        }
    }
    
    func toIcon(size: CGSize = CGSize(width: 44, height: 44), color: UIColor = UIColor.white, font: UIFont = UIFont.boldSystemFont(ofSize: 40)) -> UIImage {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.textColor = color
        label.font = font
        label.text = self
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        if let currentContext = UIGraphicsGetCurrentContext() {
            label.layer.render(in: currentContext)
            let nameImage = UIGraphicsGetImageFromCurrentImageContext()
            return nameImage ?? UIImage()
        }
        return UIImage()
    }
    
    var htmlAttribute: NSAttributedString {
        let font = UIFont.systemFont(ofSize: 14) 
        let css = "<style>body{font-family: '-apple-system', 'HelveticaNeue'; font-size: \(font.pointSize); color: #222222;}</style>%@"
        let modified = String(format: css, self)
        if let htmlData = modified.data(using: String.Encoding.unicode), let html = try? NSAttributedString(data: htmlData, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
            return html
        }
        return NSAttributedString(string: self)
    }
}

protocol PropertyLoopable {
    func allProperties() -> [String: Any]
}

extension PropertyLoopable {
    func allProperties() -> [String: Any] {
        var result: [String: Any] = [:]
        let mirror = Mirror(reflecting: self)
        guard let style = mirror.displayStyle, (style == .struct || style == .class) else {
            return result
        }
        for (labelMaybe, valueMaybe) in mirror.children {
            guard let label = labelMaybe else { continue }
            result[label] = valueMaybe
        }
        return result
    }
}

extension UIImage {
    var isContentModeFill: Bool {
        return (paperRatio * 0.8)...(paperRatio * 1.2) ~= size.height / size.width
    }
    
    var preferContentMode: UIView.ContentMode {
        return isContentModeFill ? .scaleAspectFill : .scaleAspectFit
    }
}

extension HTTPCookieStorage {
    func cookies(stringFor URL: URL) -> String? {
        var cookies = ""
        self.cookies(for: URL)?.forEach {
            if let properties = $0.properties {
                for (key, value) in properties {
                    cookies += "\(key.rawValue)=\(value); "
                }
            }
        }
        return cookies.isEmpty ? nil : cookies
    }
}
