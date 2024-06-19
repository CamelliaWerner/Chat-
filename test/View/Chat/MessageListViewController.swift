
import UIKit
import FirebaseAuth
import FirebaseFirestore

struct Chat {
    let chatId: String
    let otherUserName: String
    let otherUserId: String
}

class MessageListViewController: UIViewController {
 
    @IBOutlet weak var tableView: UITableView!
    
    var chats = [Chat]()
    let service = Service.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        
        loadChats()
        observeChats() // Начинаем наблюдение за чатами при загрузке контроллера

    }
    
    func loadChats() {
        print("Loading chats...")
        service.getChatsForCurrentUser { [weak self] chats in
            guard let self = self else { return }
            self.chats = chats
            print("Loaded chats: \(chats)")
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func observeChats() {
        let db = Firestore.firestore()
        let currentUserID = Auth.auth().currentUser?.uid ?? ""
        
        db.collection("users").document(currentUserID).collection("conversations")
            .addSnapshotListener { [weak self] (snapshot, error) in
                guard let snapshot = snapshot else {
                    print("Error fetching chats: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                var chats = [Chat]()
                for document in snapshot.documents {
                    let data = document.data()
                    let chatID = document.documentID
                    let otherUserID = data["otherId"] as? String ?? ""
                    
                    // Получение имени другого пользователя из его документа
                    db.collection("users").document(otherUserID).getDocument { (userSnapshot, error) in
                        if let userData = userSnapshot?.data(), let otherUserName = userData["email"] as? String {
                            let chat = Chat(chatId: chatID, otherUserName: otherUserName, otherUserId: otherUserID)
                            chats.append(chat)
                            
                            // Перезагрузка таблицы после получения всех чатов
                            if chats.count == snapshot.documents.count {
                                self?.chats = chats
                                self?.tableView.reloadData()
                            }
                        }
                    }
                }
            }
    }

}

extension MessageListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let chat = chats[indexPath.row]
        cell.textLabel?.text = chat.otherUserName
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chat = chats[indexPath.row]
        
        let vc = ChatViewController()
        vc.chatID = chat.chatId
        vc.otherId = chat.otherUserId
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
}



