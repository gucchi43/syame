//
//  MainTabViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/02.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import Tabman
import Pageboy
import PhotoKeyboardFramework
import Toast

struct TabHead {
    let title: String
    let imageText: String
    let badge: String?
}

class MainTabViewController: TabmanViewController {
    var tabHeads = GenreTagType.getAllGenreTags()
    var titles = [LocalizeKey.navMyBoard.localizedString(),
                  LocalizeKey.navNew.localizedString(),
                  LocalizeKey.navPopular.localizedString(),
                  LocalizeKey.navHumor.localizedString(),
                  LocalizeKey.navCool.localizedString(),
                  LocalizeKey.navCute.localizedString(),
                  LocalizeKey.navSerious.localizedString(),
                  LocalizeKey.navOther.localizedString()]
    lazy var viewControllers: [UIViewController] = {
        var viewControllers = [UIViewController]()
        for _ in 0 ..< 8 {
            viewControllers.append(makeChildViewController())
        }
        return viewControllers
    }()
    
    @IBOutlet weak var barMenuButton: UIBarButtonItem!
    
    var firstFlag = true
    
    var fabButton = UIButton(type: .custom)

    /// 起動時に最初に表示するページ。defaultPage(for:) と見出しの初期値で共有する。
    static let defaultPageIndex = 1
    
    let bar = TMBar.TabBar()


    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
    }

    func commonInit() {
        self.dataSource = self
        self.view.backgroundColor = .bgDark()
        bar.tintColor = .acGreen()
        bar.backgroundColor = .bgDark()
        bar.backgroundView.style = .clear
        bar.layout.transitionStyle = .snap
        addBar(bar, dataSource: self, at: .top)
        
        barMenuButton.title = String.fontAwesomeIcon(name: .bars)
        barMenuButton.setTitleTextAttributes([.font: UIFont.fontAwesome(ofSize: 24, style: .solid)], for: .normal)
        
        // 起動直後は pageboyPageIndex がまだ確定していないため defaultPage と同じ位置の見出しを出す
        let initialIndex = pageboyPageIndex ?? MainTabViewController.defaultPageIndex
        self.navigationItem.title = initialIndex < titles.count ? titles[initialIndex] : titles.first
        layoutFAB()
        NotificationCenter.default.addObserver(self, selector: #selector(finishToast(notification:)), name: .finishUpload, object: nil)
    }
        
    override func viewWillAppear(_ animated: Bool) {
        // PageboyViewController はここでページ位置の復元を行うため super の呼び出しが必須
        super.viewWillAppear(animated)
        bar.buttons.customize { (button) in
            button.selectedTintColor = .acGreen()
            button.tintColor = .white
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // viewWillAppear での present は遷移中に失敗するため viewDidAppear で行う
        presentOnboardingIfNeeded()
    }

    private func presentOnboardingIfNeeded() {
        guard presentedViewController == nil else { return }
        if GroupeDefaults.shared.isRegisterPush() {
            guard let vc = UIStoryboard(name: "Top", bundle: nil).instantiateInitialViewController() else { return }
            present(vc, animated: false, completion: nil)
        } else if GroupeDefaults.shared.isUsagePush() {
            guard let nvc = UIStoryboard(name: "Usage", bundle: nil).instantiateInitialViewController() else { return }
            present(nvc, animated: true, completion: nil)
        } else if GroupeDefaults.shared.isWelcomePush() {
            guard let nvc = UIStoryboard(name: "Welcome", bundle: nil).instantiateInitialViewController() else { return }
            present(nvc, animated: true, completion: nil)
        }
    }
    
    @objc func finishToast(notification: Notification) {
        // toast with a specific duration and position
        // create a new style
        var style = ToastStyle()
        style.messageColor = .white
        style.backgroundColor = UIColor.acGreen()
        style.cornerRadius = 20.0
        style.horizontalPadding = 20.0
        self.view.makeToast(LocalizeKey.doneUploadToast.localizedString(), duration: 3.0, position: .top, style: style)
        NotificationCenter.default.post(name: .allReload, object: nil, userInfo: nil)
    }
        
    func makeChildViewController() -> ChildContentViewController {
        let storyboard = UIStoryboard(name: "ChildContent", bundle: .main)
        return storyboard.instantiateInitialViewController() as! ChildContentViewController
    }
    
    func layoutFAB() {
        let size: CGFloat = 56
        fabButton.frame = CGRect(x: 0, y: 0, width: size, height: size)
        fabButton.backgroundColor = .acGreen()
        fabButton.layer.cornerRadius = size / 2
        fabButton.layer.shadowColor = UIColor.black.cgColor
        fabButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        fabButton.layer.shadowOpacity = 0.3
        fabButton.layer.shadowRadius = 4
        fabButton.setTitle("+", for: .normal)
        fabButton.setTitleColor(.white, for: .normal)
        fabButton.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .light)
        fabButton.addTarget(self, action: #selector(tapFAB), for: .touchUpInside)
        fabButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fabButton)
        NSLayoutConstraint.activate([
            fabButton.widthAnchor.constraint(equalToConstant: size),
            fabButton.heightAnchor.constraint(equalToConstant: size),
            fabButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            fabButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    @objc func tapFAB() {
        // 画像を選んでから投稿画面へ進む。画像未選択のままでは完了ボタンが有効にならない。
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }
    
    
    @IBAction func tapBarMenuButton(_ sender: Any) {
        (navigationController as? MainNavigationViewController)?.toggleSideMenu()
    }
    
    
    override func pageboyViewController(_ pageboyViewController: PageboyViewController,
                                        willScrollToPageAt index: PageboyViewController.PageIndex,
                                        direction: PageboyViewController.NavigationDirection,
                                        animated: Bool) {
        super.pageboyViewController(pageboyViewController,
                                    willScrollToPageAt: index,
                                    direction: direction,
                                    animated: animated)
    }
    
    override func pageboyViewController(_ pageboyViewController: PageboyViewController,
                                        didScrollTo position: CGPoint,
                                        direction: PageboyViewController.NavigationDirection,
                                        animated: Bool) {
        super.pageboyViewController(pageboyViewController,
                                    didScrollTo: position,
                                    direction: direction,
                                    animated: animated)
    }
    
    override func pageboyViewController(_ pageboyViewController: PageboyViewController,
                                        didScrollToPageAt index: PageboyViewController.PageIndex,
                                        direction: PageboyViewController.NavigationDirection,
                                        animated: Bool) {
        super.pageboyViewController(pageboyViewController,
                                    didScrollToPageAt: index,
                                    direction: direction,
                                    animated: animated)
        
        print("didScrollToPageAtIndex: \(index)")
        self.navigationItem.title = titles[index]
    }
    
    override func pageboyViewController(_ pageboyViewController: PageboyViewController,
                                        didReloadWith currentViewController: UIViewController,
                                        currentPageIndex: PageIndex) {
        super.pageboyViewController(pageboyViewController,
                                    didReloadWith: currentViewController,
                                    currentPageIndex: currentPageIndex)
    }
}

extension MainTabViewController: PageboyViewControllerDataSource, TMBarDataSource {
    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
    }
    
    func viewController(for pageboyViewController: PageboyViewController,
                        at index: PageboyViewController.PageIndex) -> UIViewController? {
        guard let vc = viewControllers[index] as? ChildContentViewController else { return nil }
        vc.tabPageIndex = index
        return vc
    }

    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return .at(index: MainTabViewController.defaultPageIndex)
    }
    
    func barItem(for bar: TMBar, at index: Int) -> TMBarItemable {
        let curretTabHead = tabHeads[index]
        let title = curretTabHead.getLocalizeString()
        let emojiLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        emojiLabel.text = curretTabHead.getEmoji()
        let image = UIImage.imageWithLabel(emojiLabel)
        let item = TMBarItem(title: title, image: image, badgeValue: nil)
        return item
    }
}


extension MainTabViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // 画像選択
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            picker.dismiss(animated: true)
            return
        }
        // dismissの完了を待たずにpresentすると遷移が失敗するため完了ハンドラで繋ぐ
        picker.dismiss(animated: true) { [weak self] in
            self?.presentAddViewController(with: image)
        }
    }

    private func presentAddViewController(with image: UIImage) {
        let sb = UIStoryboard(name: "Add", bundle: .main)
        guard let nvc = sb.instantiateInitialViewController() as? UINavigationController,
              let vc = nvc.viewControllers.first as? AddViewController else { return }
        vc.choiceImage = image
        present(nvc, animated: true)
    }
    //キャンセル
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}
