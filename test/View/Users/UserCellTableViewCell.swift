
import UIKit

class UserCellTableViewCell: UITableViewCell {

    static let reuseId = "UserCellTableViewCell"
    
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        settingCell()
    }

    func configCell(_ name: String) {
        userName.text = name
    }
    
    func settingCell() {
        parentView.layer.cornerRadius = 15
        userImage.layer.cornerRadius = userImage.frame.width / 2
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

