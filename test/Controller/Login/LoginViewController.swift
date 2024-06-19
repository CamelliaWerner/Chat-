
import UIKit
import FirebaseAuth

struct SliderItem {
    var color: UIColor
    var title: String
    var text: String
    var animationName: String
}

// делегат для кнопок регистрации и входа
protocol LoginViewControllerDelegate {
    func openRegVC()
    func openAuthVC()
}

class LoginViewController: UIViewController, AuthViewControllerDelegate {
    
    weak var delegate: AuthViewControllerDelegate?
    
    private let sliderData: [SliderItem] = [
            SliderItem(color: .brown, title: "Добро пожаловать!", text: "Начните общение прямо сейчаc.", animationName: "a1"),
            SliderItem(color: .orange, title: "Легкое общение", text: "Отправляйте сообщения быстро и удобно.", animationName: "a2"),
            SliderItem(color: .gray, title: "Начните беседу", text: "Будьте на связи с друзьями и близкими,\nдаже на расстоянии.", animationName: "a3")
        ]
    
    lazy var collectionView: UICollectionView! = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.frame.width, height: view.frame.height)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.delegate = self
        collection.dataSource = self
        collection.register(SlideCell.self, forCellWithReuseIdentifier: "cell")
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.isPagingEnabled = true
        
        return collection
        
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configCollectionView()
        setControll()
        setShape()
        setupButtons()  // вызов метода для настройки кнопок
    }
    
    lazy var skipButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("Skip", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        
        return btn
    }()
    
    lazy var vStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 5
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    lazy var hStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 0
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let shape = CAShapeLayer()
    
    private var curentPageIndex: CGFloat = 0
    
    private var fromValue: CGFloat = 0
    
    private var pagers: [UIView] = []
    private var curentSlide = 0
    private var widthAnchor: NSLayoutConstraint?
    
    lazy var nextButton: UIView = {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(nextSlide))
        
        let nextImg = UIImageView()
        nextImg.image = UIImage(systemName: "chevron.right.circle.fill")
        nextImg.tintColor = .white
        nextImg.contentMode = .scaleAspectFit
        nextImg.translatesAutoresizingMaskIntoConstraints = false
        
        nextImg.widthAnchor.constraint(equalToConstant: 45).isActive = true
        nextImg.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        let btn = UIView()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 50).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        btn.isUserInteractionEnabled = true
        btn.addGestureRecognizer(tapGesture)
        btn.addSubview(nextImg)
        
        nextImg.centerXAnchor.constraint(equalTo: btn.centerXAnchor).isActive = true
        nextImg.centerYAnchor.constraint(equalTo: btn.centerYAnchor).isActive = true
        return btn
    }()
    
    private func setShape() {
        
        curentPageIndex = CGFloat(1) / CGFloat(sliderData.count) // (0.33333)
        let centerX = UIScreen.main.bounds.width / 3.81
        let nextStroke = UIBezierPath(arcCenter: CGPoint(x: centerX, y: 25.5), radius: 23, startAngle: -(.pi/2), endAngle: 5, clockwise: true)

        let trackShape = CAShapeLayer()
        trackShape.path = nextStroke.cgPath
        trackShape.fillColor = UIColor.clear.cgColor
        trackShape.lineWidth = 3
        trackShape.strokeColor = UIColor.white.cgColor
        trackShape.opacity = 0.2
        nextButton.layer.addSublayer(trackShape)
        
        shape.path = nextStroke.cgPath
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = UIColor.white.cgColor
        shape.lineWidth = 3
        shape.lineCap = .round
        shape.strokeStart = 0
        shape.strokeEnd = 0
        
        nextButton.layer.addSublayer(shape)
    }
    
    private func setControll() {
        
        view.addSubview(hStack)
        
        let pagerStack = UIStackView()
        pagerStack.axis = .horizontal
        pagerStack.spacing = 5
        pagerStack.alignment = .center
        pagerStack.distribution = .fill
        pagerStack.translatesAutoresizingMaskIntoConstraints = false
        
        for tag in 1...sliderData.count {
            let pager = UIView()
            pager.tag = tag
            pager.translatesAutoresizingMaskIntoConstraints = false
            pager.backgroundColor = .white
            pager.layer.cornerRadius = 5
            pager.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(scrollToSlide)))
            
            self.pagers.append(pager)
            pagerStack.addArrangedSubview(pager)
        }
        
        vStack.addArrangedSubview(pagerStack)
        vStack.addArrangedSubview(skipButton)
        
        hStack.addArrangedSubview(vStack)
        hStack.addArrangedSubview(nextButton)
        
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            hStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 50),
            hStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
        ])
    }
    
    func configCollectionView() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    @objc func scrollToSlide(sender: UIGestureRecognizer) {
        if let index = sender.view?.tag {
            collectionView.scrollToItem(at: IndexPath(item: index - 1, section: 0), at: .centeredHorizontally, animated: true)
            
            curentSlide = index - 1
        }
    }
    
    @objc func nextSlide() {
        let maxSlide = sliderData.count
        
        if curentSlide < maxSlide - 1 {
            curentSlide += 1
            collectionView.scrollToItem(at: IndexPath(item: curentSlide, section: 0), at: .centeredHorizontally, animated: true)
        }
    }
}

extension LoginViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sliderData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? SlideCell {
            cell.contentView.backgroundColor = sliderData[indexPath.item].color
            cell.titleLabel.text = sliderData[indexPath.item].title
            cell.textLabel.text = sliderData[indexPath.item].text
            
            cell.animationSetup(animationName: sliderData[indexPath.item].animationName)
            return cell
        }
        return UICollectionViewCell()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.view.frame.size
        
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        curentSlide = indexPath.item
        
        pagers.forEach { page in
            let tag = page.tag
            let viewTag = indexPath.row + 1
            
            page.constraints.forEach { counts in
                page.removeConstraint(counts)
            }
            
            if viewTag == tag {
                page.layer.opacity = 1
                widthAnchor = page.widthAnchor.constraint(equalToConstant: 19)
            } else {
                page.layer.opacity = 0.5
                widthAnchor = page.widthAnchor.constraint(equalToConstant: 10)
            }
            widthAnchor?.isActive = true
            page.heightAnchor.constraint(equalToConstant: 10).isActive = true
            
        }
        
        let curentIndex = curentPageIndex * CGFloat(indexPath.item + 1)
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = fromValue
        animation.toValue = curentIndex
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.duration = 0.5
        shape.add(animation, forKey: "animation")
        
        fromValue = curentIndex
        
        // Показ кнопок на последнем слайде
        if indexPath.item == sliderData.count - 1 {
            view.subviews.forEach { subview in
                if let button = subview as? UIButton {
                    button.isHidden = false
                }
            }
        } else {
            view.subviews.forEach { subview in
                if let button = subview as? UIButton {
                    button.isHidden = true
                }
            }
        }
    }
    
    //Register" и "Login"
    private func setupButtons() {
        let registerButton = UIButton(type: .system)
        registerButton.setTitle("Регистрация", for: .normal)
        registerButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17.0)
        registerButton.backgroundColor = .white
        registerButton.setTitleColor(.black, for: .normal)
        registerButton.layer.cornerRadius = 20  // Устанавливаем радиус для закругленных углов
        registerButton.layer.masksToBounds = true
        registerButton.addTarget(self, action: #selector(openRegVC), for: .touchUpInside)
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        
        let loginButton = UIButton(type: .system)
        loginButton.setTitle("Вход", for: .normal)
        loginButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17.0)
        loginButton.backgroundColor = .white
        loginButton.setTitleColor(.black, for: .normal)
        loginButton.layer.cornerRadius = 20  // Устанавливаем радиус для закругленных углов
        loginButton.layer.masksToBounds = true
        loginButton.addTarget(self, action: #selector(openAuthVC), for: .touchUpInside)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        
        registerButton.addTarget(self, action: #selector(openRegVC), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(openAuthVC), for: .touchUpInside)
        
        view.addSubview(registerButton)
        view.addSubview(loginButton)
        
        NSLayoutConstraint.activate([
            registerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            registerButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -140),
            registerButton.widthAnchor.constraint(equalToConstant: 120),
            registerButton.heightAnchor.constraint(equalToConstant: 40),
            
            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            loginButton.widthAnchor.constraint(equalToConstant: 120),
            loginButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Скрываем кнопки по умолчанию
        registerButton.isHidden = true
        loginButton.isHidden = true
    }
    
    @objc func openRegVC() {
        let regVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RegViewController") as! RegViewController
        regVC.modalPresentationStyle = .fullScreen
        present(regVC, animated: true, completion: nil)
    }
    
    @objc func openAuthVC() {
        let authVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AuthViewController") as! AuthViewController
        authVC.modalPresentationStyle = .fullScreen
        present(authVC, animated: true, completion: nil)
    }
}
extension LoginViewController: LoginViewControllerDelegate {
    func startApp() {
    }
    
    func authViewControllerDidFinish() {
        dismiss(animated: true, completion: nil)
    }
}



  



