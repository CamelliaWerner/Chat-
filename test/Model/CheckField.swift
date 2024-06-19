
import UIKit

//валидация форм (процесс проверки данных на соответствие заданным правилам или условиям.)
class CheckField{

static let shared = CheckField()
init() { }

//проверка на соответствие строки 
private func isValid(_ type: String, _ data: String) -> Bool{
    var dataRegEx = ""
    switch type {
    case "e":
        dataRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    default:
        dataRegEx = "(?=.*[A-Z0-9a-z]).{6,}"
    }
    
    let dataPred = NSPredicate(format:"SELF MATCHES %@", dataRegEx)
    return dataPred.evaluate(with: data)
}

//validField
func validField(_ parentView: UIView, _ field: UITextField) -> Bool{
    let id = field.restorationIdentifier
    
    switch id {
    case "name":
        if field.text?.count ?? 0 < 3{
            validView(parentView, field, false)
            return false
        } else {
            validView(parentView, field, true)
             return true
        }
    case "email":
        if isValid("e", field.text!) {
           validView(parentView, field, true)
            return true
        } else {
            validView(parentView, field, false)
            return false
        }
    case "password":
        if isValid("p", field.text!) {
            validView(parentView, field, true)
            return true
        } else {
            validView(parentView, field, false)
            return false
        }
    default:
        if field.text?.count ?? 0 < 2{
            validView(parentView, field, false)
            return false
        } else {
            validView(parentView, field, true)
             return true
        }
    }
}

    //вид текстового поля 
    private func validView(_ parentView: UIView, _ field: UITextField, _ valid: Bool){
    if valid{
        field.backgroundColor = #colorLiteral(red: 0.9410838485, green: 0.9412415624, blue: 0.9410631061, alpha: 1)
        parentView.backgroundColor = #colorLiteral(red: 0.9410838485, green: 0.9412415624, blue: 0.9410631061, alpha: 1)

    } else {
        field.backgroundColor = #colorLiteral(red: 1, green: 0.2566739321, blue: 0.3427716792, alpha: 1)
        parentView.backgroundColor = #colorLiteral(red: 1, green: 0.2566739321, blue: 0.3427716792, alpha: 1)
    }
}
}


