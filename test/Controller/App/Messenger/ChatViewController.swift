import UIKit
import MessageKit
import InputBarAccessoryView
import FirebaseAuth

struct Sender: SenderType {
    var senderId: String
    var displayName: String
}

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

class ChatViewController: MessagesViewController {
    
    var chatID: String?
    var otherId: String?
    let service = Service.shared
    
    let selfSender = Sender(senderId: "1", displayName: "")
    let otherSender = Sender(senderId: "2", displayName: "")
    
    var messages = [Message]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        messageInputBar.delegate = self
        showMessageTimestampOnSwipeLeft = true
        
        if let chatID = chatID {
            getMessages(convoId: chatID)
        } else if let otherId = otherId {
            service.getConvoId(otherId: otherId) { [weak self] chatId in
                self?.chatID = chatId
                self?.getMessages(convoId: chatId)
            }
        }
        // Настраиваем текст кнопки отправки
        configureInputBar()
        
        // Добавляем кнопку удаления сообщений
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteLastMessage))
        
    }
    // Изменяем текст на кнопке отправки
    private func configureInputBar() {
        messageInputBar.sendButton.setTitle("Ввод", for: .normal)
        messageInputBar.sendButton.setTitleColor(.systemBlue, for: .normal)
        messageInputBar.sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        
        messageInputBar.inputTextView.placeholder = "Введите сообщение..."
        messageInputBar.inputTextView.tintColor = .gray
        
    }

    
    @objc private func deleteLastMessage() {
        guard let chatID = chatID else {
            print("Chat ID is nil")
            return
        }

        // Находим последнее сообщение текущего пользователя
        if let lastMessage = messages.last(where: { $0.sender.senderId == selfSender.senderId }) {
            service.deleteMessage(messageId: lastMessage.messageId, chatId: chatID) { [weak self] success in
                if success {
                    // Успешно удалено, обновляем интерфейс
                    if let index = self?.messages.firstIndex(where: { $0.messageId == lastMessage.messageId }) {
                        self?.messages.remove(at: index)
                        self?.messagesCollectionView.reloadData()
                    }
                    print("Сообщение успешно удалено из Firebase")
                } else {
                    print("Не удалось удалить сообщение из Firebase")
                }
            }
        } else {
            print("Нет сообщений текущего пользователя для удаления")
        }
    }
    
    // Вывод сообщений между чатами
    func getMessages(convoId: String) {
        service.getAllMessages(chatId: convoId) { [weak self] messages in
            self?.messages = messages
            DispatchQueue.main.async {
                self?.messagesCollectionView.reloadData()
            }
        }
    }
}

extension ChatViewController: MessagesDisplayDelegate, MessagesLayoutDelegate, MessagesDataSource {
    var currentSender: SenderType {
        return selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        // Настройка внешнего вида аватарки
        avatarView.layer.cornerRadius = avatarView.bounds.width / 2
        avatarView.clipsToBounds = true
        avatarView.backgroundColor = .white
        avatarView.image = UIImage(named: "default_avatar")
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    // Отправка сообщения
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let msg = Message(sender: selfSender, messageId: UUID().uuidString, sentDate: Date(), kind: .text(text))
        
        // Добавляем новое сообщение в массив сообщений
        messages.append(msg)
        
        service.sendMessage(otherId: self.otherId, convoId: self.chatID, text: text) { [weak self] convoId in
            DispatchQueue.main.async {
                inputBar.inputTextView.text = nil
                self?.messagesCollectionView.reloadData()
            }
            self?.chatID = convoId
        }
    }
}
