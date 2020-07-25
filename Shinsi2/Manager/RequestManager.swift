import Alamofire
import RealmSwift
import Kanna

class RequestManager {
    
    static let shared = RequestManager()
    
    func login(username name: String, password pw: String, completeBlock block: (() -> Void)? ) {
        let url = Defaults.URL.login.absoluteString + "&CODE=01"
        let parameters: [String: String] = [
            "CookieDate": "1",
            "b": "d",
            "bt": "1-1",
            "UserName": name,
            "PassWord": pw,
            "ipb_login_submit": "Login!"]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: URLEncoding(), headers: nil).responseString { _ in
            block?()
        }
    }

    func getIndexPage(page: Int, search keyword: String? = nil, completeBlock block: ((List<GalleryPage>) -> Void)?) {
        let categoryFilters = Defaults.Search.categories.map {"f_\($0)=\(UserDefaults.standard.bool(forKey: $0) ? 1 : 0)"}.joined(separator: "&")
        var url = Defaults.URL.host + "/?"
        url += "\(categoryFilters)&f_apply=Apply+Filter" //Apply category filters
        url += "&advsearch=1&f_sname=on&f_stags=on&f_sh=on" //Advance search
        url += "&inline_set=dm_t" //Set mode to Thumbnail View
        
        if Defaults.Search.rating != 0 {
            url += "&f_sr=on&f_srdd=\(String(Defaults.Search.rating + 1))"
        }
        
        if var keyword = keyword?.lowercased() {
            if keyword.contains("favorites") {
                url = Defaults.URL.host + "/favorites.php?page=\(page)"
                if let number = Int(keyword.replacingOccurrences(of: "favorites", with: "")) {
                    url += "&favcat=\(number)"
                }
            } else if keyword.contains("popular") {
                if page == 0 {
                    url = Defaults.URL.host + "/popular"
                } else {
                    block?(List())
                    return
                }
            } else if keyword.contains("watched") {
                 url = Defaults.URL.host + "/watched?page=\(page)"
            } else {
                var skipPage = 0
                if let s = keyword.matches(for: "p:[0-9]+").first, let p = Int(s.replacingOccurrences(of: "p:", with: "")) {
                    keyword = keyword.replacingOccurrences(of: s, with: "")
                    skipPage = p
                }
                url += "&f_search=\(keyword.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)"
                url += "&page=\(page + skipPage)"
            }
        } else {
            url += "&page=\(page)"
        }
        
        Alamofire.request(url, method: .get).responseString { response in
            guard let html = response.result.value else { block?(List()); return }
            if let doc = try? Kanna.HTML(html: html, encoding: .utf8) {
                let items = GalleryPage.galleryPageList(indexPage: doc)
                block?(items)
            } else {
                block?(List())
            }
        }
    }
    
    func getGalleryPage(galleryPage: GalleryPage, completeBlock block: (() -> Void)?) {
        print(#function)
        let page = galleryPage.nextPageIndex
        var url = galleryPage.url + "?p=\(page)"
        url += "&inline_set=ts_l" //Set thumbnal size to large
        Alamofire.request(url, method: .get).responseString { response in
            if let html = response.result.value,
               let doc = try? Kanna.HTML(html: html, encoding: String.Encoding.utf8) {
                galleryPage.setPages(doc)
                galleryPage.setComments(doc)
                galleryPage.setTags(doc)
            }
            block?()
        }
    }

    func getShowPage_bak(url: String, completeBlock block: ( (_ imageURL: String?) -> Void )?) {
        print(#function)
        Alamofire.request(url, method: .get).responseString { response in
            guard let html = response.result.value else {
                block?(nil)
                return
            }
            if let doc = try? Kanna.HTML(html: html, encoding: String.Encoding.utf8) {
                if let imageNode = doc.at_xpath("//img [@id='img']") {
                    if let imageURL = imageNode["src"] {
                        block?(imageURL)
                        return
                    }
                }
            }
            block?(nil)
        }
    }
    
    func getShowPage(showPage: ShowPage, completeBlock block: (() -> Void)?) {
        print(#function)
        Alamofire.request(showPage.url, method: .get).responseString { response in
            guard let html = response.result.value else {
                block?()
                return
            }
            if let doc = try? Kanna.HTML(html: html, encoding: String.Encoding.utf8) {
                showPage.setInfo(showPage: doc)
            }
            block?()
        }
    }

    func addGalleryToFavorite(gallery: GalleryPage, category: Int = 0) {
        guard gallery.isIdTokenValide else {return}
        gallery.favorite = .favorite0
        let url = Defaults.URL.host + "/gallerypopups.php?gid=\(gallery.gid)&t=\(gallery.token)&act=addfav"
        let parameters: [String: String] = ["favcat": "\(category)", "favnote": "", "apply": "Add to Favorites", "update": "1"]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: URLEncoding(), headers: nil).responseString { _ in
        }
    }

    func deleteFavorite(gallery: GalleryPage) {
        guard gallery.isIdTokenValide else {return}
        let url = Defaults.URL.host + "/favorites.php"
        let parameters: [String: Any] = ["ddact": "delete", "modifygids[]": gallery.gid, "apply": "Apply"]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: URLEncoding(), headers: nil).responseString { _ in
        }
    }
    
    func moveFavorite(gallery: GalleryPage, to catogory: Int) {
        guard 0...9 ~= catogory else {return}
        guard gallery.isIdTokenValide else {return}
        let url = Defaults.URL.host + "/favorites.php"
        let parameters: [String: Any] = ["ddact": "fav\(catogory)", "modifygids[]": gallery.gid, "apply": "Apply"]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: URLEncoding(), headers: nil).responseString { _ in
        }
    }
}

extension RequestManager {
    
    func getGData( doujinshi: GalleryPage, completeBlock block: ((GalleryPage?) -> Void)? ) {
        print(#function)
        //Api http://ehwiki.org/wiki/API
        guard doujinshi.isIdTokenValide else { block?(nil); return}
        
        let p: [String: Any] = [
            "method": "gdata",
            "gidlist": [ [ doujinshi.gid, doujinshi.token ] ],
            "namespace": 1
        ]
        
        Alamofire.request(Defaults.URL.host + "/api.php", method: .post, parameters: p, encoding: JSONEncoding(), headers: nil).responseJSON { response in
            if let dic = response.result.value as? NSDictionary {
                if let metadatas = dic["gmetadata"] as? NSArray {
                    if let metadata = metadatas[0] as? NSDictionary {
                        if let count = metadata["filecount"]  as? String,
                            let rating = metadata["rating"] as? String,
                            let title = metadata["title"] as? String,
                            let title_jpn = metadata["title_jpn"] as? String,
                            let tags = metadata["tags"] as? [String],
                            let thumb = metadata["thumb"] as? String,
                            let gid = metadata["gid"] as? Int {
                            let gdata = GalleryPage(value: ["filecount": Int(count)!, "rating": Float(rating)!, "title": title.isEmpty ? doujinshi.title : title, "title_jpn": title_jpn.isEmpty ? doujinshi.title: title_jpn, "coverUrl": thumb, "gid": String(gid)])
                            for t in tags {
                                gdata.tags.append(Tag(value: ["name": t]))
                            }
                            block?(gdata)
                            //Cache
                            let cachedURLResponse = CachedURLResponse(response: response.response!, data: response.data!, userInfo: nil, storagePolicy: .allowed)
                            URLCache.shared.storeCachedResponse(cachedURLResponse, for: response.request!)
                            
                            return
                        }
                    }
                }
                block?(nil)
            }
            block?(nil)
        }
    }
    
}
