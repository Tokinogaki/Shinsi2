import UIKit

class SearchHistoryVC: UITableViewController {
    weak var searchController: UISearchController!
    var selectBlock: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateNotification(notification:)), name: .searchHistoryUpdate, object: nil)
        
        let blurview = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        tableView.backgroundView = blurview
    }
    
    @objc func handleUpdateNotification(notification: Notification) {
        self.tableView.reloadData()
    }
    
    @IBAction private func shortcutButtonDidClick(sender: UIButton) {
        SearchManager.shared.searchText = sender.titleLabel?.text ?? ""
        selectBlock?(SearchManager.shared.searchText)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SearchManager.shared.searchList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let r = SearchManager.shared.searchList[indexPath.row]
        cell.textLabel?.text = "\(r.namespaceT):\(r.text)"
        cell.detailTextLabel?.text = "\(r.namespace):\(r.origin)"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let search = SearchManager.shared.searchList[indexPath.row]
        SearchManager.shared.addKeywords(search: search)
        selectBlock?(SearchManager.shared.searchText)
        tableView.reloadData()
    }

}
