
import UIKit

private let kSearchList = "SearchList"
private let kStatisticsList = "StatisticsList"

public extension Notification.Name {
    static let searchHistoryUpdate = Notification.Name("addSearchText")
}

class SearchManager: NSObject {

    static let shared = SearchManager()
    
    var searchList: [[String: Any]] = []
    
    var statisticsList: [[String: Any]] = []
    
    override init() {
        super.init()
        if let searchList = UserDefaults.standard.value(forKey: kSearchList) as? [[String: Any]] {
            self.searchList = searchList
        }
        UserDefaults.standard.removeObject(forKey: kStatisticsList)
        if let statisticsList = UserDefaults.standard.value(forKey: kStatisticsList) as? [[String: Any]] {
            self.statisticsList = statisticsList
        }
    }
    
    func addSearch(text: String?) {
        if nil != text && !text!.isEmpty {
            if let index = searchList.firstIndex(where: { return $0["text"] as! String == text!}) {
                searchList.remove(at: index)
            }
            searchList.insert(["text": text!, "date": Date()], at: 0)
            
            if searchList.count > 100 {
                self.searchList = Array(self.searchList[0...100])
            }
            
            UserDefaults.standard.setValue(searchList, forKey: kSearchList)
            NotificationCenter.default.post(name: .searchHistoryUpdate, object: self)
        }
    }
    
    func deleteSearch(index: Int) {
        searchList.remove(at: index)
        UserDefaults.standard.setValue(searchList, forKey: kSearchList)
        NotificationCenter.default.post(name: .searchHistoryUpdate, object: self)
    }
 
    func addStatistics(text: String?) {
        if nil != text && !text!.isEmpty {
            if let index = statisticsList.firstIndex(where: { return $0["text"] as! String == text!}) {
                statisticsList[index]["count"] = statisticsList[index]["count"] as! Int + 1
            } else {
                statisticsList.append(["text": text!, "count": 1])
            }
            
            statisticsList.sort(by: { return $0["count"] as! Int > $1["count"] as! Int })
            
            UserDefaults.standard.setValue(statisticsList, forKey: kStatisticsList)
            NotificationCenter.default.post(name: .searchHistoryUpdate, object: self)
        }
    }
    
}
