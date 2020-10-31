import Foundation

import Kanna
import UIColor_Hex_Swift

public extension Notification.Name {
    static let loadShowPage = Notification.Name("loadShowPage")
    static let imageDownloaded = Notification.Name("imageDownloaded")
    static let thumbDownloaded = Notification.Name("thumbDownloaded")
}

enum StateEnum: Int {
    case none, downloading, downloaded
}

class ShowPage: NSObject {
    @objc dynamic var index = 0
    @objc dynamic var imageKey = ""
    @objc dynamic var thumbUrl = ""
    @objc dynamic var imageUrl = ""
    @objc dynamic var originUrl = ""
    @objc dynamic var fileSize = ""
    @objc dynamic private var _url: String = ""
    @objc dynamic private var _sizeWidth: Float = 0
    @objc dynamic private var _sizeHeight: Float = 0
    
    var _imageState: StateEnum = .none
    var imageState: StateEnum {
        get {
            if self.hasImage {
                return .downloaded
            }
            return _imageState
        }
        set {
            _imageState = newValue
        }
    }
    
    var _thumbState: StateEnum = .none
    var thumbState: StateEnum {
        get {
            if self.hasThumb {
                return .downloaded
            }
            return _thumbState
        }
        set {
            _thumbState = newValue
        }
    }
    
    var localImage: URL {
        return kEximagesPath.appendingPathComponent("\(self.imageKey)_image.jpg")
    }
    
    var localThumb: URL {
        return kEximagesPath.appendingPathComponent("\(self.imageKey)_thumb.jpg")
    }
    
    var hasImage: Bool {
        return FileManager.default.fileExists(atPath: self.localImage.path)
    }
    
    var hasThumb: Bool {
        return FileManager.default.fileExists(atPath: self.localThumb.path)
    }
    
    var image: UIImage? {
        if self.hasImage {
            let data = try! Data(contentsOf: self.localImage)
            return UIImage(data: data)
        }
        return nil
    }
    
    var thumb: UIImage? {
        if self.hasThumb {
            let data = try! Data(contentsOf: self.localThumb)
            return UIImage(data: data)
        }
        return nil
    }
    
    var url: String {
        get {
            return self._url
        }
        set {
            self._url = newValue
            if let url = URL(string: newValue) {
                self.imageKey = url.pathComponents.indices.contains(2) ? url.pathComponents[2] : ""
            }
        }
    }

    var size: CGSize {
        get {
            return CGSize(width: CGFloat(self._sizeWidth), height: CGFloat(self._sizeHeight))
        }
        set {
            self._sizeWidth = Float(newValue.width)
            self._sizeHeight = Float(newValue.height)
        }
    }
    
    var imageRatio: CGFloat {
        if self.size != CGSize.zero {
            return self.size.width / self.size.height
        }
        return 0.0
    }
    
    var aspectRatio: Float {
        if self.size != CGSize.zero {
            return Float(self.size.width / self.size.height)
        }
        return 1.0
    }
    
    func setInfo(showPage doc: HTMLDocument) {
        if let img = doc.at_xpath("//img [@id='img']"),
            let imageUrl = img["src"] {
            self.imageUrl = imageUrl
        }
        
        if let text = doc.at_xpath("//div [@id='i2'] //div //span")?.text,
           let index = Int(text) {
            self.index = index
        }
        
        if let origin = doc.at_xpath("//div [@id='i7'] //a"),
           let originUrl = origin["href"],
           let imgInfo = origin.text {
            self.originUrl = originUrl
            let imgInfoArray = imgInfo.components(separatedBy: " ")
            if imgInfoArray.count == 8 {
                self._sizeWidth = Float(imgInfoArray[2]) ?? 0
                self._sizeHeight = Float(imgInfoArray[4]) ?? 0
                self.fileSize = imgInfoArray[5] + imgInfoArray[6]
            }
        }
    }

}
