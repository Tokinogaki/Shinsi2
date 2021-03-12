
import UIKit

private let kHistorySearchList = "historySearchList"
private let kHotwordsList = "hotwordsList"

public extension Notification.Name {
    static let searchHistoryUpdate = Notification.Name("searchHistoryUpdate")
    static let hotwordsUpdate = Notification.Name("hotwordsUpdate")
}

class SearchManager: NSObject {

    static let shared = SearchManager()
    
    private var _searchText: String = ""
    var searchText: String {
        get {
            return _searchText.count > 0 ? _searchText : Defaults.List.lastSearchKeyword
        }
        set {
            Defaults.List.lastSearchKeyword = newValue
            _searchText = newValue
            let t = self.getSearchKeywords().trimmingCharacters(in: .whitespacesAndNewlines)
            
            _searchList.removeAll()
            
            for search in self.chineseKeywordsList {
                if search.contains(find: t.lowercased()) {
                    _searchList.append(search)
                }
            }
        }
    }
    
    private var _searchList: [KeywordsModel] = []
    var searchList: [KeywordsModel] {
        return _searchList
    }
    
    var chineseKeywordsList: [KeywordsModel] = []
    var historySearchList: [[String: Any]] = []
    var hotwordsList: [[String: Any]] = []
    
    override init() {
        super.init()
        self.loadHistorySearchList()
        self.loadChineseSearchList()
        self.loadHotwordsList()
    }
    
    func addKeywords(search: KeywordsModel) {
        let items = self.getSearchKeywordsList()
        let text = "\(search.namespace):\"\(search.origin)$\" "
        _searchList = []
        _searchText = ""
        for item in items {
            _searchText += "\(item[0]):\"\(item[1])$\" "
        }
        
        if !_searchText.contains(text) {
            _searchText += text
        }
        self.searchText = _searchText
    }
    
    func addSearch(text: String?) {
        if nil != text && !text!.isEmpty {
            if let index = historySearchList.firstIndex(where: { return $0["text"] as! String == text!}) {
                historySearchList.remove(at: index)
            }
            historySearchList.insert(["text": text!, "date": Date()], at: 0)
            
            if historySearchList.count > 100 {
                self.historySearchList = Array(self.historySearchList[0...100])
            }
            
            self.saveHistorySearchList()
        }
    }
    
    func deleteSearch(index: Int) {
        historySearchList.remove(at: index)
        self.saveHistorySearchList()
    }
 
    func addStatistics(text: String?) {
        if nil != text && !text!.isEmpty {
            if let index = hotwordsList.firstIndex(where: { return $0["text"] as! String == text!}) {
                hotwordsList[index]["count"] = hotwordsList[index]["count"] as! Int + 1
            } else {
                hotwordsList.append(["text": text!, "count": 1])
            }
            
            hotwordsList.sort(by: { return $0["count"] as! Int > $1["count"] as! Int })
            
            if hotwordsList.count > 100 {
                self.hotwordsList = Array(self.hotwordsList[0...100])
            }
            
            self.saveHotwordsList()
        }
    }

    private func getSearchKeywordsList() -> [[String]] {
        var data: [[String]] = []
        let components = _searchText.components(separatedBy: "$\" ")
        for str in components {
            let list = str.components(separatedBy: ":\"")
            if list.count == 2 {
                data.append(list)
            }
        }
        return data
    }
    
    private func getSearchKeywords() -> String {
        var text = ""
        let components = _searchText.components(separatedBy: "$\" ")
        for str in components {
            let list = str.components(separatedBy: ":\"")
            if list.count != 2 {
                text += str
            }
        }
        return text
    }
    
    private func loadHistorySearchList() {
        if let decoded = UserDefaults.standard.object(forKey: kHistorySearchList) as? NSData {
            self.historySearchList = NSKeyedUnarchiver.unarchiveObject(with: decoded as Data) as! [[String: Any]]
        }
    }
    
    private func saveHistorySearchList() {
        do {
            let encodedData = try NSKeyedArchiver.archivedData(withRootObject: self.historySearchList, requiringSecureCoding: false)
            UserDefaults.standard.set(encodedData, forKey: kHistorySearchList)
        } catch {
            print(error)
        }
        NotificationCenter.default.post(name: .searchHistoryUpdate, object: self)
    }
    
    private func loadHotwordsList() {
        if let decoded = UserDefaults.standard.object(forKey: kHotwordsList) as? NSData {
            self.hotwordsList = NSKeyedUnarchiver.unarchiveObject(with: decoded as Data) as! [[String: Any]]
        }
    }
    
    private func saveHotwordsList() {
        do {
            let encodedData = try NSKeyedArchiver.archivedData(withRootObject: self.hotwordsList, requiringSecureCoding: false)
            UserDefaults.standard.set(encodedData, forKey: kHotwordsList)
        } catch {
            print(error)
        }
        NotificationCenter.default.post(name: .hotwordsUpdate, object: self)
    }
    
    private func loadChineseSearchList() {
        let path = Bundle.main.path(forResource: "db.text", ofType: "json")
        let url = URL(fileURLWithPath: path!)
        do {
            let data = try Data(contentsOf: url)
            let jsonData = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: Any]
            let tagList = jsonData["data"] as! [[String: Any]]
            for index in 2...tagList.count-1 {
                let frontMatters = tagList[index]["frontMatters"] as! [String: Any]
                let tagData = tagList[index]["data"] as! [String: [String: String]]
                for (origin, tag) in tagData {
                    let searchModel = KeywordsModel()
                    searchModel.namespace = tagList[index]["namespace"] as! String
                    searchModel.namespaceT = frontMatters["name"] as! String
                    searchModel.origin = origin
                    searchModel.text = tag["name"]!
                    searchModel.intro = tag["intro"]!
                    self.chineseKeywordsList.append(searchModel)
                }
            }
        } catch let error {
            print("读取本地数据出现错误!", error)
        }
    }
    
}
