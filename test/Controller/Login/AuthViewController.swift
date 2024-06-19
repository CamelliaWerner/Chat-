
import UIKit
import Firebase

protocol AuthViewControllerDelegate: AnyObject {
    func authViewControllerDidFinish()
}

class AuthViewController: UIViewController {
    
    var checkField = CheckField.shared
    var service = Service.shared
    var tapGest: UITapGestureRecognizer?
    var userDefault =  UserDefaults.standard
    
    @IBOutlet weak var visibleButton: UIButton!
    var isTextVisible = true
    
    @IBOutlet weak var mainView: UIView!
    
    @IBOutlet weak var emailView: UIView!
    @IBOutlet weak var emailField: UITextField!
   
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tapGest = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        mainView.addGestureRecognizer(tapGest!)
        // Устанавливаем символ для кнопки
        visibleButton.setImage(UIImage(systemName: "eye.fill"), for: .normal)
        visibleButton.tintColor = .black // Цвет символа
        
    }
    
    @objc func endEditing() {
        self.view.endEditing(true)
    }
    
    @IBAction func closeVC(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func authButton(_ sender: Any) {
        if checkField.validField(emailView, emailField),
           checkField.validField(passwordView, passwordField) {
            
            let authData = LoginField(email: emailField.text!, password: passwordField.text!)
            
            service.authInApp(authData) { [ weak self] responce in
                switch responce {
                case .success:
                    self?.userDefault.set(true, forKey: "isLogin")
                    
                    // Не удалось загрузить RegViewController из storyboard
                    guard let appVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AppViewController") as? AppViewController else {
                        return
                    }
                    appVC.modalPresentationStyle = .fullScreen
                    self?.dismiss(animated: true) {
                        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                            rootViewController.present(appVC, animated: true, completion: nil)
                        }
                    }
                    
                case .noVerify:
                    let alert = self?.alertAction("Error", "Вы не верефицировали свой Email. На вашу почту отправлена ссылка.")
                    //upt еще 1 письмо
                    let verifyButton = UIAlertAction(title: "Отправить еще раз", style: .default) { _ in
                        self?.sendVerificationEmail()
                    }
                    let okButton = UIAlertAction(title: "Ok", style: .cancel)
                    
                    alert?.addAction(verifyButton)
                    alert?.addAction(okButton)
                    self?.present(alert!, animated: true)
                    
                case .error:
                    let alert = self?.alertAction("Error", "Email или пароль не верны")
                    let verifyButton = UIAlertAction(title: "Ok", style:  .cancel)
                    alert?.addAction(verifyButton)
                    self?.present(alert!, animated: true)
                }
            }
        } else {
            let alert = self.alertAction("Error", "Проверьте введенные данные")
            let verifyButton = UIAlertAction(title: "Ok", style:  .cancel)
            alert.addAction(verifyButton)
            self.present(alert, animated: true)
        }
    }
    // Метод для отправки письма с подтверждением
    func sendVerificationEmail() {
        guard let user = Auth.auth().currentUser else { return }
        
        user.sendEmailVerification { error in
            if let error = error {
                print("Ошибка отправки письма с подтверждением: \(error.localizedDescription)")
                } else {
                    print("Письмо с подтверждением отправлено")
            }
        }
    }
    
    func alertAction(_ header: String?, _ message: String?) -> UIAlertController {
        let alert = UIAlertController(title: header, message: message, preferredStyle: .alert)
        return alert
    }
 
    @IBAction func resetPassword(_ sender: UIButton) {
        guard let email = emailField.text, !email.isEmpty else {
            // Пользователь не ввел email, показываем предупреждение
            self.showAlert(title: "Ошибка", message: "Пожалуйста, введите ваш email.")
            return
        }
        
        // Отправляем запрос на сброс пароля через Firebase
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                // Ошибка при сбросе пароля, показываем предупреждение с текстом ошибки
                self.showAlert(title: "Ошибка", message: error.localizedDescription)
            } else {
                // Сброс пароля успешно выполнен, показываем сообщение об успехе
                self.showAlert(title: "Успешно", message: "Письмо с инструкциями по сбросу пароля отправлено на ваш emai.")
            }
        }
    }
    
    // Функция для отображения предупреждения
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // Отображение видимости пароля
    @IBAction func toggleTextVisibility(_ sender: Any) {
        if isTextVisible {
            // Если текст видим, скрываем его
            passwordField.isSecureTextEntry = true
            visibleButton.setImage(UIImage(systemName: "eye.fill"), for: .normal)
            visibleButton.tintColor = .black
        } else {
            // Если текст скрыт, делаем его видимым
            passwordField.isSecureTextEntry = false
            visibleButton.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        }
        
        isTextVisible = !isTextVisible
        
    }
    
    @IBAction func noAccountButton(_ sender: Any) {
        guard let regVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RegViewController") as? RegViewController else {
            // Не удалось загрузить RegViewController из storyboard
            return
        }
        regVC.modalPresentationStyle = .fullScreen
        
        // Используем completion блок для present после dismiss
        dismiss(animated: false) {
            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                rootViewController.present(regVC, animated: true, completion: nil)
            }
        }
    }
}
