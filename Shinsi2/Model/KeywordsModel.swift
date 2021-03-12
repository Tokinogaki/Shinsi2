import Foundation

class KeywordsModel : NSObject, NSCoding {
    @objc dynamic var namespace: String = ""
    @objc dynamic var namespaceT: String = ""
    @objc dynamic var origin: String = ""
    @objc dynamic var text: String = ""
    @objc dynamic var intro: String = ""
    @objc dynamic var date: Date = Date()
    
    override init() {
        super.init()
    }
    
    init(text: String) {
        super.init()
        self.text = text
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.namespace, forKey: "namespace")
        coder.encode(self.namespaceT, forKey: "namespaceT")
        coder.encode(self.origin, forKey: "origin")
        coder.encode(self.text, forKey: "text")
        coder.encode(self.intro, forKey: "intro")
        coder.encode(self.date, forKey: "date")
        
    }
    
    required init?(coder: NSCoder) {
        super.init()
        self.namespace = coder.decodeObject(forKey: "namespace") as! String
        self.namespaceT = coder.decodeObject(forKey: "namespaceT") as! String
        self.origin = coder.decodeObject(forKey: "origin") as! String
        self.text = coder.decodeObject(forKey: "text") as! String
        self.intro = coder.decodeObject(forKey: "intro") as! String
        self.date = coder.decodeObject(forKey: "date") as! Date
    }
    
    func contains(find: String) -> Bool {
        return "\(namespace):\"\(origin)$\"".contains(find) ||
               "\(namespaceT):\(text)".contains(find)
    }
    
}
