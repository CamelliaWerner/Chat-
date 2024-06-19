import UIKit

class RegViewController: UIViewController {
    
    // Жест
    var tapGest: UITapGestureRecognizer?
    var checkField = CheckField.shared
    var service = Service.shared
    @IBAction func firstToggleButtonTapped(_ sender: UIButton) {
        toggleTextVisibility(for: passwordField, button: sender)
    }
    
    @IBAction func secondToggleButtonTapped(_ sender: UIButton) {
        toggleTextVisibility(for: rePasswordField, button: sender)
    }

    @IBOutlet weak var mainView: UIView!

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var emailView: UIView!
    
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var passwordView: UIView!
    
    @IBOutlet weak var rePasswordField: UITextField!
    @IBOutlet weak var rePasswordView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Выход
        tapGest = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        mainView.addGestureRecognizer(tapGest!)
        
        // Отключаем автозаполнение
        disableAutoFillForTextFields()
        
    }
    
    func disableAutoFillForTextFields() {
        passwordField.disableAutoFill()
        rePasswordField.disableAutoFill()
    }
    
    @IBAction func closeVC(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    // Завершение редактирования во всем родительском view
    @objc func endEditing() {
        self.view.endEditing(true)
    }
    
    func alertAction(_ header: String?, _ message: String?) -> UIAlertController {
        let alert = UIAlertController(title: header, message: message, preferredStyle: .alert)
        return alert
    }
    
    @IBAction func regButtonClick(_ sender: Any) {
        // Проверяем валидность email
            let isEmailValid = checkField.validField(emailView, emailField)
            if !isEmailValid {
                let alert = self.alertAction("Ошибка", "Почта должна быть формата username@example.com")
                let verifyButton = UIAlertAction(title: "Ok", style:  .cancel)
                alert.addAction(verifyButton)
                self.present(alert, animated: true)
                print("Ошибка валидации email")
                return
            }
            
            // Проверяем валидность пароля
            let isPasswordValid = checkField.validField(passwordView, passwordField)
            if !isPasswordValid {
                let alert = self.alertAction("Ошибка", "Пароль должен быть не менее 6 символов")
                let verifyButton = UIAlertAction(title: "Ok", style:  .cancel)
                alert.addAction(verifyButton)
                self.present(alert, animated: true)
                print("Ошибка валидации пароля")
                return
            }
            
            // Проверяем совпадение паролей
            guard passwordField.text == rePasswordField.text else {
                let alert = self.alertAction("Проверьте введенные данные", "Пароли не совпадают")
                let verifyButton = UIAlertAction(title: "Ok", style:  .cancel)
                alert.addAction(verifyButton)
                self.present(alert, animated: true)

                return
            }
            
            // Все данные введены корректно, создаем пользователя
            service.createNewUser(LoginField(email: emailField.text!, password: passwordField.text!)) { [weak self] response in
                switch response {
                case .error:
                    print("Произошла ошибка регистрации")
                case .success:
                    print("Успешно зарегистрировались")
                    self?.service.confirmEmail()
                    
                    let alert = UIAlertController(title: "OK", message: "Success", preferredStyle: .alert)
                    let okeyButton = UIAlertAction(title: "Auth", style: .default) { _ in
                        // Переход на экран AuthViewController
                        self?.navigateToAuthViewController()
                    }
                    alert.addAction(okeyButton)
                    self?.present(alert, animated: true)
                case .noVerify:
                    print("Email не подтвержден")
                default:
                    print("Неизвестная ошибка")
                }
            }
        }
    
    func navigateToAuthViewController() {
        guard let authVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController else {
            return
        }
        authVC.modalPresentationStyle = .fullScreen
        
        // Используем completion блок для present после dismiss
        dismiss(animated: true) {
            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                rootViewController.present(authVC, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func haveAccount(_ sender: Any) {
        self.navigateToAuthViewController()
    }
        // переключение состояний видимости
        func toggleTextVisibility(for textField: UITextField, button: UIButton) {
            textField.isSecureTextEntry.toggle()
            let imageName = textField.isSecureTextEntry ? "eye.fill" : "eye.slash.fill"
            if let image = UIImage(systemName: imageName) {
                // Устанавливаем изображение на кнопку
                button.setImage(image, for: .normal)
                // Устанавливаем цвет символа
                button.tintColor = .black
            }
        }
   
}

// - автозаполнение паролей
extension UITextField {
    func disableAutoFill() {
        if #available(iOS 12, *) {
            textContentType = .oneTimeCode
        } else {
            textContentType = .init(rawValue: "")
        }
    }
}

