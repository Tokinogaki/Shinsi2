import Foundation
import RealmSwift

class RealmManager {
    static let shared = RealmManager()
    let realm: Realm = {
        let config = Realm.Configuration( schemaVersion: 7, migrationBlock: { _, _ in
            
        })
        Realm.Configuration.defaultConfiguration = config
        return try! Realm()
    }()
    
    lazy var searchHistory: Results<SearchHistory> = {
        return self.realm.objects(SearchHistory.self).sorted(byKeyPath: "date", ascending: false)
    }()
    
    lazy var downloaded: Results<GalleryPage> = {
        return self.realm.objects(GalleryPage.self).filter("isDownloaded == true").sorted(byKeyPath: "date", ascending: false)
    }()
    
    func browsingHistory(for doujinshi: GalleryPage) -> BrowsingHistory? {
        return realm.objects(BrowsingHistory.self).filter("id == %d", doujinshi.gid).first
    }
    
    func createBrowsingHistory(for doujinshi: GalleryPage) {
        try! realm.write {
            realm.create(BrowsingHistory.self, value: ["doujinshi": doujinshi, "id": doujinshi.gid], update: .modified)
        }
    }
    
    func updateBrowsingHistory(_ browsingHistory: BrowsingHistory, currentPage: Int) {
        try! realm.write {
            browsingHistory.updatedAt = Date()
            browsingHistory.currentPage = currentPage
        }
    }
    
    var browsedDoujinshi: [GalleryPage] {
        let hs = realm.objects(BrowsingHistory.self).sorted(byKeyPath: "updatedAt", ascending: false)
        var results: [GalleryPage] = []
        let maxHistory = min(30, hs.count)
        for i in 0..<maxHistory {
            if let d = hs[i].doujinshi {
                results.append(GalleryPage(value: d))
            }
        }
        return results
    }
    
    func saveSearchHistory(text: String?) {
        guard let text = text else {return}
        guard text.replacingOccurrences(of: " ", with: "").count != 0 else {return}
        if let obj = realm.objects(SearchHistory.self).filter("text = %@", text).first {
            try! realm.write {
                obj.date = Date()
            }
        } else {
            try! realm.write {
                let h = SearchHistory()
                h.text = text
                realm.add(h)
            }
        }
    }
    
    func deleteAllSearchHistory() {
        try! realm.write {
            realm.delete(realm.objects(SearchHistory.self))
        }
    }
    
    func deleteSearchHistory(history: SearchHistory) {
        try! realm.write {
            realm.delete(history)
        }
    }
    
    func saveDownloadedDoujinshi(book: GalleryPage) {
        book.showPageList.removeAll()
        for i in 0..<book.`length` {
            let p = ShowPage()
            p.thumbUrl = String(format: String(book.gid) + "/%04d.jpg", i)
            book.showPageList.append(p)
        }
        if let first = book.showPageList.first {
            book.coverUrl = first.thumbUrl
        }
        book.isDownloaded = true
        
        DispatchQueue.main.async {
            try! self.realm.write {
                self.realm.add(book)
            }
        }
    }
    
    func deleteDoujinshi(book: GalleryPage) {
        try! realm.write {
            realm.delete(book)
        }
    }
    
    func isDounjinshiDownloaded(galleryPage: GalleryPage) -> Bool {
        return downloaded.filter("gdata.gid = '\(galleryPage.gid)'").count != 0
    }
}

extension RealmManager {
    
    func updateGalleryPage(_ galleryPage: GalleryPage) {
        if let gp = RealmManager.shared.getGalleryPage(galleryPage.gid) {
            try! self.realm.write {
                gp.title = galleryPage.title
                gp.coverUrl = galleryPage.coverUrl
                gp.category = galleryPage.category
                gp.posted = galleryPage.posted
                gp.favorite = galleryPage.favorite
                gp.rating = galleryPage.rating
            }
        }
    }
    
    func addGalleryPage(_ galleryPage: GalleryPage) {
        try! self.realm.write {
            self.realm.add(galleryPage, update: .all)
        }
    }
    
    func getGalleryPage(_ gid: Int) -> GalleryPage? {
        let resultList = self.realm.objects(GalleryPage.self).filter("gid=\(gid)")
        return resultList.first
    }
}
