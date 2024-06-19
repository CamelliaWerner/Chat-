
import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import MessageKit

class Service {
    static let shared = Service()
    
    init() {}
    
    // MARK: - Управление пользователями
    
    func createNewUser(_ data: LoginField, completion: @escaping (AuthResponce) -> ())  {
        Auth.auth().createUser(withEmail: data.email, password: data.password) { result, err in
            if let err = err {
                print("Ошибка при создании пользователя: \(err.localizedDescription)")
                completion(.error)
                return
            }
            guard let result = result else {
                completion(.error)
                return
            }
            
            // Добавление пользователя в Firestore
            let userId = result.user.uid
            let email = data.email
            let data: [String: Any] = ["email": email]
            
            // выбор коллекции в fs, добавление и устанока данных
            Firestore.firestore().collection("users").document(userId).setData(data) { err in
                if let err = err {
                    print("Ошибка при добавлении пользователя в Firestore: \(err.localizedDescription)")
                    completion(.error)
                } else {
                    completion(.success)
                }
            }
        }
    }
    // Отправляет письмо с подтверждением на текущий email пользователя.
    func confirmEmail() {
        Auth.auth().currentUser?.sendEmailVerification { err in
            if err != nil {
                print(err!.localizedDescription)
            }
        }
    }
    // Аутентифицирует пользователя с указанными email и паролем.
    func authInApp(_ data: LoginField, completion: @escaping (AuthResponce) -> () ) {
        Auth.auth().signIn(withEmail: data.email, password: data.password) { result, err in
            if let err = err {
                print("Ошибка при входе: \(err.localizedDescription)")
                completion(.error)
                return
            }
            
            guard result != nil else {
                completion(.error)
                return
            }
            completion(.success)
//             проверка подтверждения почты
            if ((result?.user.isEmailVerified) != nil) {
                completion(.success)
            } else {
                self.confirmEmail()
                completion(.noVerify)
            }
        }
    }
    
    func getUserStatus(completion: @escaping (AuthResponce) -> ()) {
        if let user = Auth.auth().currentUser {
            user.reload { error in
                if let error = error {
                    print("Ошибка при обновлении пользователя: \(error.localizedDescription)")
                    completion(.error)
                    return
                }
                
                if user.isEmailVerified {
                    completion(.success)
                } else {
                    completion(.noVerify)
                }
            }
        } else {
            completion(.error) // Вызываем .error, если пользователь не найден
        }
    }
    
    
    // TODO: - сделать имя и фамилию CurentUser(firstName: userFirstname, lastName: userLastName))
    // получение массива пользователей из firebase
    func getAllUsers(completion: @escaping ([CurentUser]) -> ()) {
        guard let email = Auth.auth().currentUser?.email else { return }
        
        var curentUsers = [CurentUser]()
        
        Firestore.firestore().collection("users")
            .whereField("email", isNotEqualTo: email)
            .getDocuments { snap, err in
                if let err = err {
                    print("Ошибка при получении пользователей: \(err.localizedDescription)")
                    return
                }
                
                if let docs = snap?.documents {
                    for doc in docs {
                        let data = doc.data()
                        // суда firstName...
                        let userId = doc.documentID
                        let userEmail = data["email"] as! String
                        
                        curentUsers.append(CurentUser(id: userId, email: userEmail))
                        
                    }
                }
                completion(curentUsers)
            }
    }
    
    //MARK: -  Messanger
    
    func sendMessage(otherId: String?, convoId: String?, text: String, completion: @escaping (String) -> ()) {
        let db = Firestore.firestore()
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Ошибка: не удалось получить текущий идентификатор пользователя")
            return
        }
        
        guard let otherId = otherId else {
            print("Ошибка: otherId пустой")
            return
        }
        // !!!!!
        if convoId == nil {
            // создаем новую переписку
            let convoId = UUID().uuidString
            
            let selfData: [String: Any] = [
                "date": Date(),
                "otherId": otherId
            ]
            
            let otherData: [String: Any] = [
                "date": Date(),
                "otherId": uid
            ]
            
            // у текущего пользователя есть переписка с X
            db.collection("users")
                .document(uid)
                .collection("conversations")
                .document(convoId)
                .setData(selfData) { err in
                    if let err = err {
                        print("Ошибка при создании переписки у текущего пользователя: \(err.localizedDescription)")
                        return
                    } else {
                        print("Переписка у текущего пользователя создана успешно")
                    }
                    
                    // создание переписки у другого пользователя
                    db.collection("users")
                        .document(otherId)
                        .collection("conversations")
                        .document(convoId)
                        .setData(otherData) { err in
                            if let err = err {
                                print("Ошибка при создании переписки у другого пользователя: \(err.localizedDescription)")
                                return
                            } else {
                                print("Переписка у другого пользователя создана успешно")
                            }
                            
                            let msg: [String: Any] = [
                                "date": Date(),
                                "sender": uid,
                                "text": text
                            ]
                            
                            let convoInfo: [String: Any] = [
                                "date": Date(),
                                "selfSender": uid,
                                "otherSender": otherId
                            ]
                            
                            db.collection("conversations")
                                .document(convoId)
                                .setData(convoInfo) { err in
                                    if let err = err {
                                        print("Ошибка при создании документа беседы: \(err.localizedDescription)")
                                        return
                                    } else {
                                        print("Документ беседы создан успешно")
                                    }
                                    
                                    db.collection("conversations")
                                        .document(convoId)
                                        .collection("messages")
                                        .addDocument(data: msg) { err in
                                            if let err = err {
                                                print("Ошибка при добавлении сообщения: \(err.localizedDescription)")
                                            } else {
                                                print("Сообщение добавлено успешно")
                                                completion(convoId)
                                            }
                                        }
                                }
                        }
                }
        } else {
            let msg: [String: Any] = [
                "date": Date(),
                "sender": uid,
                "text": text
            ]
            
            Firestore.firestore()
                .collection("conversations")
                .document(convoId!)
                .collection("messages")
                .addDocument(data: msg) { err in
                    if let err = err {
                        print("Ошибка при добавлении сообщения: \(err.localizedDescription)")
                    } else {
                        print("Сообщение добавлено успешно")
                        completion(convoId!)
                    }
                }
        }
    }
    
    func getConvoId(otherId: String, completion: @escaping (String) -> ()) {
        if let uid = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            
            db.collection("users")
                .document(uid)
                .collection("conversations")
                .whereField("otherId", isEqualTo: otherId)
                .getDocuments { snap, err in
                    if  err != nil {
                        return
                    }
                    
                    if let snap = snap, !snap.documents.isEmpty {
                        let doc = snap.documents.first
                        if let convoId = doc?.documentID {
                            completion(convoId)
                        }
                    }
                }
        }
    }
    
    func getAllMessages(chatId: String, completion: @escaping ([Message]) -> ()) {
        if let uid = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            db.collection("conversations")
                .document(chatId)
                .collection("messages")
                .limit(to: 50)
                .order(by: "date", descending: false)
                .addSnapshotListener { snap, err in
                    if  err != nil {
                        print("Ошибка при получении сообщений: \(err!.localizedDescription)")
                        return
                    }
                    
                    if let snap = snap,  !snap.documents.isEmpty {
                        var msgs = [Message]()
                        var sender = Sender(senderId: uid, displayName: "Me")
                        
                        for doc in snap.documents{
                            let data = doc.data()
                            let userId = data["sender"] as! String
                            let messageId = doc.documentID
            
                            let date = data["date"] as! Timestamp
                            let sentDate = date.dateValue()
                            let text = data["text"] as! String
                            
                            if userId == uid {
                                sender = Sender(senderId: "1", displayName: "1")
                            } else {
                                sender = Sender(senderId: "2", displayName: "2")
                            }
                            
                            msgs.append(Message(sender: sender, messageId: messageId, sentDate: sentDate, kind: .text(text)))
                        }
                        completion(msgs)
                        
                    }
                    
                }
        }
    }
    // список действующий чатов
    func getChatsForCurrentUser(completion: @escaping ([Chat]) -> Void) {
        var chats = [Chat]()
        
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(chats)
            return
        }
        
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).collection("conversations").getDocuments { (snapshot, error) in
            if let error = error {
                print("Ошибка при получении чатов: \(error.localizedDescription)")
                completion(chats)
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("Нет документов")
                completion(chats)
                return
            }
            
            let dispatchGroup = DispatchGroup()
            
            for document in documents {
                dispatchGroup.enter()
                
                let data = document.data()
                let chatId = document.documentID
                let otherUserId = data["otherId"] as? String ?? ""
                
                db.collection("users").document(otherUserId).getDocument { userSnapshot, error in
                    guard let userData = userSnapshot?.data(), let otherUserName = userData["email"] as? String else {
                        dispatchGroup.leave()
                        return
                    }
                    
                    let chat = Chat(chatId: chatId, otherUserName: otherUserName, otherUserId: otherUserId)
                    chats.append(chat)
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(chats)
            }
        }
    }
    
    // Удаление сообщения
      func deleteMessage(messageId: String, chatId: String, completion: @escaping (Bool) -> Void) {
          let db = Firestore.firestore()
          
          // Удаляем сообщение из коллекции messages в конкретном чате
          db.collection("conversations")
              .document(chatId)
              .collection("messages")
              .document(messageId)
              .delete { error in
                  if let error = error {
                      print("Ошибка при удалении сообщения: \(error.localizedDescription)")
                      completion(false)
                  } else {
                      print("Сообщение успешно удалено")
                      completion(true)
                  }
              }
      }
        
}

