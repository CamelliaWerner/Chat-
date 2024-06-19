
import UIKit

enum AuthResponce {
    case success
    case error
    case noVerify
}

struct Slides {
    var id: Int
    var text: String
    var img: UIImage
}

struct LoginField {
    var email: String
    var password: String
}

struct CurentUser {
    var id: String
    var email: String
}

