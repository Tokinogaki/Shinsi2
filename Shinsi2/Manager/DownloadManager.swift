import Foundation
import RealmSwift
import Kingfisher
import Alamofire

class SSOperation: Operation {
    enum State {
        case ready, executing, finished
        var keyPath: String {
            switch self {
            case .ready:
                return "isReady"
            case .executing:
                return "isExecuting"
            case .finished:
                return "isFinished"
            }
        }
    }
    var state = State.ready {
        willSet {
            willChangeValue(forKey: newValue.keyPath)
            willChangeValue(forKey: state.keyPath)
        }
        didSet {
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: state.keyPath)
        }
    }
    override var isReady: Bool { return super.isReady && state == .ready }
    override var isExecuting: Bool { return state == .executing }
    override var isFinished: Bool { return state == .finished }
    override var isAsynchronous: Bool { return true }
}

class PageDownloadOperation: SSOperation {
    var url: String
    var folderPath: String
    var pageNumber: Int

    init(url: String, folderPath: String, pageNumber: Int) {
        self.url = url
        self.folderPath = folderPath
        self.pageNumber = pageNumber
    }
    
    override func start() {
        guard !isCancelled else {
            state = .finished
            return
        }
        state = .executing
        main()
    }
    
    override func main() {
        RequestManager.shared.getShowPage_bak(url: url) { imageUrl in
            if let imageUrl = imageUrl {
                let documentsURL = URL(fileURLWithPath: self.folderPath)
                let fileURL = documentsURL.appendingPathComponent(String(format: "%04d.jpg", self.pageNumber))
                let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                    return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
                }
                Alamofire.download(imageUrl, to: destination).response { _ in
                    self.state = .finished
                    if let image = UIImage(contentsOfFile: fileURL.path) {
//                        SDWebImageManager.shared.imageCache?.store(image, forKey: imageUrl, completion: nil)
                    }
                    if self.isCancelled {
                        try? FileManager.default.removeItem(at: documentsURL)
                    }
                }
            } else {
                self.state = .finished
            }
        }
    }
}

class DownloadManager: NSObject {
    static let shared = DownloadManager()
    var queues: [OperationQueue] = []
    var books: [String: GalleryPage] = [:]
    
    let modifier = AnyModifier { request in
        var r = request
        r.httpShouldHandleCookies = true
        r.setValue(HTTPCookieStorage.shared.cookies(stringFor: Defaults.URL.exHentai), forHTTPHeaderField: "Cookie")
        return r
    }
    
    func download(galleryPage: GalleryPage) {
        guard galleryPage.showPageList.count != 0 else {return}
        let folderName = String(galleryPage.gid)
        let path = documentURL.appendingPathComponent(folderName).path
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 3
        queue.isSuspended = queues.count != 0
        queue.name = folderName
        queues.append(queue)
        books[folderName] = galleryPage
        
        for (i, p) in galleryPage.showPageList.enumerated() {
            let o = PageDownloadOperation(url: p.url, folderPath: path, pageNumber: i)
            queue.addOperation(o)
        }
        queue.addObserver(self, forKeyPath: "operationCount", options: [.new], context: nil)
    }
    
    func cancelAllDownload() {
        let fileManager = FileManager.default
        for q in queues {
            q.removeObserver(self, forKeyPath: "operationCount")
            q.cancelAllOperations()
            let url = documentURL.appendingPathComponent(q.name!)
            try? fileManager.removeItem(at: url)
        }
        queues.removeAll()
        books.removeAll()
    }
    
    func deleteDownloaded(doujinshi: GalleryPage) {
        try? FileManager.default.removeItem(at: documentURL.appendingPathComponent(String(doujinshi.gid)))
        RealmManager.shared.deleteDoujinshi(book: doujinshi)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath, keyPath == "operationCount",
              let change = change, let count = change[.newKey] as? Int,
              let queue = object as? OperationQueue
        else {return}
        
        if count == 0 {
            print("\(queue.name!): Finished!!!")
            RealmManager.shared.saveDownloadedDoujinshi(book: books[queue.name!]!)
            queues.remove(at: queues.firstIndex(of: queue)!)
            queue.removeObserver(self, forKeyPath: "operationCount")
            books.removeValue(forKey: queue.name!)
            if let nextQueue = queues.first {
                nextQueue.isSuspended = false
                print("Start Next queue: \(nextQueue.name!)")
            }
        }
    }
}
