
import UIKit

class UsersViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let service =  Service.shared
    var users = [CurentUser]()
     
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "UserCellTableViewCell", bundle: nil), forCellReuseIdentifier: UserCellTableViewCell.reuseId)
        // для вывода кол ячеек и их содержимое
        tableView.dataSource = self
        // для взаимодействия с ячейками
        tableView.delegate = self
        tableView.separatorStyle = .none
         
        getUsers()
    }
    func getUsers() {
        service.getAllUsers { users in
            self.users = users
            self.tableView.reloadData()
        }
    }
}

extension UsersViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserCellTableViewCell.reuseId, for: indexPath) as! UserCellTableViewCell
        cell.selectionStyle = .none
        let cellName = users[indexPath.row]
        cell.configCell(cellName.email)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userId = users[indexPath.row].id
        
        let vc = ChatViewController()
        vc.otherId = userId
        // открываем новый view
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

