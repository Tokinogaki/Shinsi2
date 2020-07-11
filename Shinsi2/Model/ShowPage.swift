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
    @objc dynamic var url = ""
    @objc dynamic var size = CGSize.zero
    @objc dynamic var thumbSize = CGSize.zero
    
    var underlyingImage: UIImage?
    var isLoading = false
    let imageCache = SDWebImageManager.shared().imageCache!
    
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
        fatalError("init() has not been implemented")
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
