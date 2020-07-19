import Foundation
import RealmSwift
import Kanna
import UIColor_Hex_Swift
import SDWebImage

public extension Notification.Name {
    static let photoLoaded = Notification.Name("SSPHOTO_LOADING_DID_END_NOTIFICATION")
}

class ShowPage: Object {
    @objc dynamic var thumbUrl = ""
    @objc dynamic var imageUrl = ""
    @objc dynamic var originUrl = ""
    @objc dynamic var webUrl = ""
    @objc dynamic private var _sizeWidth: Float = 0
    @objc dynamic private var _sizeHeight: Float = 0
    @objc dynamic private var _thumbSizeWidth: Float = 0
    @objc dynamic private var _thumbSizeHeight: Float = 0
    
    var underlyingImage: UIImage?
    var isLoading = false
    let imageCache = SDWebImageManager.shared().imageCache!
    
    var size: CGSize {
        get {
            return CGSize(width: CGFloat(self._sizeWidth), height: CGFloat(self._sizeHeight));
        }
        set {
            self._sizeWidth = Float(newValue.width)
            self._sizeHeight = Float(newValue.height)
        }
    }
    
    var thumbSize: CGSize {
        get {
            return CGSize(width: CGFloat(self._thumbSizeWidth), height: CGFloat(self._thumbSizeHeight));
        }
        set {
            self._thumbSizeWidth = Float(newValue.width)
            self._thumbSizeHeight = Float(newValue.height)
        }
    }
    
    var imageRatio: CGFloat {
        if self.thumbSize != CGSize.zero {
            return self.thumbSize.width / self.thumbSize.height
        }
        if self.size != CGSize.zero {
            return self.size.width / self.size.height
        }
        return 0.0
    }
    
    var urlString: String {
        get {
            self.thumbUrl
        }
    }
    
    required init() {
        super.init()
    }
    
    func loadUnderlyingImageAndNotify() {
        guard isLoading == false, underlyingImage == nil else { return }
        isLoading = true
        
        RequestManager.shared.getPageImageUrl(url: urlString) { [weak self] url in
            guard let self = self else { return }
            guard let url = url else {
                self.imageLoadComplete()
                return
            }
            SDWebImageDownloader.shared().downloadImage( with: URL(string: url)!, options: [.highPriority, .handleCookies, .useNSURLCache], progress: nil, completed: { [weak self] image, _, _, _ in
                guard let self = self else { return }
                self.imageCache.store(image, forKey: self.urlString)
                self.underlyingImage = image
                DispatchQueue.main.async {
                    self.imageLoadComplete()
                }
            })
        }
    }

    func checkCache() {
        if let memoryCache = imageCache.imageFromMemoryCache(forKey: urlString) {
            underlyingImage = memoryCache
            imageLoadComplete()
            return
        }
        
        imageCache.queryCacheOperation(forKey: urlString) { [weak self] image, _, _ in
            if let diskCache = image, let self = self {
                self.underlyingImage = diskCache
                self.imageLoadComplete()
            }
        }
    }

    func imageLoadComplete() {
        isLoading = false
        NotificationCenter.default.post(name: .photoLoaded, object: self)
    }
    
    var aspectRatio: Float {
        if self.size != CGSize.zero {
            return Float(self.size.width / self.size.height)
        }
        if self.thumbSize != CGSize.zero {
            return Float(self.thumbSize.width / self.thumbSize.height)
        }
        return 1.0
    }
    
    var localUrl: URL {
        return documentURL.appendingPathComponent(thumbUrl)
    }
    var localImage: UIImage? {
        return UIImage(contentsOfFile: localUrl.path)
    }
    static func blankPage() -> ShowPage {
        let p = ShowPage()
        return p
    }
}
