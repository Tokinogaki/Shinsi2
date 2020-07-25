import Foundation
import RealmSwift
import Kanna
import UIColor_Hex_Swift
import SDWebImage

public extension Notification.Name {
    static let photoLoaded = Notification.Name("SSPHOTO_LOADING_DID_END_NOTIFICATION")
}

class ShowPage: Object {
    @objc dynamic var index = 0
    @objc dynamic var imageKey = ""
    @objc dynamic var thumbUrl = ""
    @objc dynamic var imageUrl = ""
    @objc dynamic var originUrl = ""
    @objc dynamic var fileSize = ""
    @objc dynamic private var _url: String = ""
    @objc dynamic private var _sizeWidth: Float = 0
    @objc dynamic private var _sizeHeight: Float = 0
    
    var isLoading: Bool {
        return !self.imageUrl.isEmpty
    }
    
    var isDownload: Bool {
        return SDImageCache.shared().diskImageDataExists(withKey: self.imageUrl)
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
    
    var currentUrl: String {
        return self.imageUrl.isEmpty ? self.thumbUrl : self.imageUrl
    }
    
    var aspectRatio: Float {
        if self.size != CGSize.zero {
            return Float(self.size.width / self.size.height)
        }
        return 1.0
    }

    var image: UIImage? {
        return self.isDownload
            ? SDImageCache.shared().imageFromMemoryCache(forKey: self.imageUrl)
            : SDImageCache.shared().imageFromMemoryCache(forKey: self.thumbUrl)
   }
    
    required init() {
        super.init()
    }
    
    func setInfo(showPage doc: HTMLDocument) {
        try! RealmManager.shared.realm.write {
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
    
    func dowloadImage() {
        guard !self.isDownload else { return }
        SDWebImageDownloader.shared().downloadImage(with: URL(string: self.imageUrl), options: [.highPriority, .handleCookies, .useNSURLCache], progress: nil) { (image, _, _, _) in
            if let image = image {
                SDImageCache.shared().store(image, forKey: self.imageUrl)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .photoLoaded, object: self)
                }
            }
        }
    }
    
    override class func primaryKey() -> String? {
        return "imageKey"
    }

}
