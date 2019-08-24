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
import ENSwiftSideMenu
import FontAwesome_swift
import PhotoKeyboardFramework
import Floaty
import Realm
import RealmSwift

struct TabHead {
    let title: String
    let imageText: String
    let badge: String?
}

class MainTabViewController: TabmanViewController, FloatyDelegate {
    var tabHeads = GenreTagType.getAllGenreTags()
    var titles = ["私の宝物！", "おニュー", "キラキラ〜", "ぷぷぷっ", "ふっ", "プリプリ〜", "ぞわぞわっ", "色々あるよん"]
    lazy var viewControllers: [UIViewController] = {
        var viewControllers = [UIViewController]()
        for _ in 0 ..< 8 {
            viewControllers.append(makeChildViewController())
        }
        return viewControllers
    }()
    
    @IBOutlet weak var barMenuButton: UIBarButtonItem!
    
    var firstFlag = true
    
    var floaty = Floaty()
    
    let bar = TMBar.TabBar()
//    let bar = TMBar.ButtonBar()
    
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
        
        if let pageboyPageIndex = pageboyPageIndex {
            self.navigationItem.title = titles[pageboyPageIndex]
        } else {
            self.navigationItem.title = titles.first
        }
        layoutFAB()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        bar.buttons.customize { (button) in
            button.selectedTintColor = .acGreen()
            button.tintColor = .white
        }
        
        if firstFlag {
            firstFlag = false
            let sb = UIStoryboard(name: "Usage",bundle: nil)
            let nvc = sb.instantiateInitialViewController() as! UINavigationController
            //            let vc = nvc.viewControllers.first as! UsageViewController
            present(nvc, animated: true, completion: nil)
        }
        
//        if GroupeDefaults.shared.isUsagePush() {
//            let sb = UIStoryboard(name: "Usage",bundle: nil)
//            let nvc = sb.instantiateInitialViewController() as! UINavigationController
////            let vc = nvc.viewControllers.first as! UsageViewController
//            present(nvc, animated: true, completion: nil)
//
////            let sb: UIStoryboard = UIStoryboard(name: "Usage",bundle: nil)
////            let vc = sb.instantiateViewController(withIdentifier: "UsageViewController") as! UsageViewController
////            present(vc, animated: true, completion: nil)
//        }
        
    }
    
    func allListButtonUpdate() {
        
        print("call me allListButtonUpdate")
        
//        for vc in viewControllers {
//            let cvc = vc as! ChildContentViewController
//            if cvc.firePhotos  != nil {
//                cvc.collectionView.reloadData()
//            }
//        }
    }
    
    func makeChildViewController() -> ChildContentViewController {
        let storyboard = UIStoryboard(name: "ChildContent", bundle: .main)
        return storyboard.instantiateInitialViewController() as! ChildContentViewController
    }
    
    func layoutFAB() {
        floaty.buttonColor = .acGreen()
        floaty.plusColor = .white
        floaty.sticky = true
        floaty.hasShadow = true
        let cameraImage = UIImage.fontAwesomeIcon(name: .camera, style: .solid, textColor: .acGreen(), size: CGSize(width: 20, height: 20))
        floaty.addItem(icon: cameraImage) { (item) in
            if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
                let picker = UIImagePickerController()
                picker.sourceType = .camera
                picker.delegate = self
                self.present(picker, animated: true, completion: {
                    self.floaty.close()
                })
            } else {
                self.floaty.close()
            }
        }
        let photoImage = UIImage.fontAwesomeIcon(name: .images, style: .solid, textColor: .acGreen(), size: CGSize(width: 20, height: 20))
        floaty.addItem(icon: photoImage) { (item) in
            if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
                let picker = UIImagePickerController()
                picker.sourceType = .photoLibrary
                picker.delegate = self
                self.present(picker, animated: true, completion: {
                    self.floaty.close()
                })
            } else {
                self.floaty.close()
            }
        }
        self.view.addSubview(floaty)
    }
    
    // MARK: - Floaty Delegate Methods
    func floatyWillOpen(_ floaty: Floaty) {
        
        print("Floaty Will Open")
        let sb = UIStoryboard(name: "Add", bundle: .main)
        let vc = sb.instantiateInitialViewController() as! AddViewController
        present(vc, animated: true) {
        }
    }
    
    func floatyDidOpen(_ floaty: Floaty) {
        print("Floaty Did Open")
    }
    
    func floatyWillClose(_ floaty: Floaty) {
        print("Floaty Will Close")
    }
    
    func floatyDidClose(_ floaty: Floaty) {
        print("Floaty Did Close")
    }
    
    
    @IBAction func tapBarMenuButton(_ sender: Any) {
        toggleSideMenuView()
    }
    
    
    override func pageboyViewController(_ pageboyViewController: PageboyViewController,
                                        willScrollToPageAt index: PageboyViewController.PageIndex,
                                        direction: PageboyViewController.NavigationDirection,
                                        animated: Bool) {
        super.pageboyViewController(pageboyViewController,
                                    willScrollToPageAt: index,
                                    direction: direction,
                                    animated: animated)
        //        print("willScrollToPageAtIndex: \(index)")
    }
    
    override func pageboyViewController(_ pageboyViewController: PageboyViewController,
                                        didScrollTo position: CGPoint,
                                        direction: PageboyViewController.NavigationDirection,
                                        animated: Bool) {
        super.pageboyViewController(pageboyViewController,
                                    didScrollTo: position,
                                    direction: direction,
                                    animated: animated)
        //        print("didScrollToPosition: \(position)")
        
        let relativePosition = navigationOrientation == .vertical ? position.y : position.x
//        gradient?.gradientOffset = gradientOffset(for: relativePosition)
//        statusView.currentPosition = relativePosition
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
        let vc = viewControllers[index] as! ChildContentViewController
        vc.tabPageIndex = index
        return vc
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return nil
    }
    
    func barItem(for bar: TMBar, at index: Int) -> TMBarItemable {
        let curretTabHead = tabHeads[index]
        let title = curretTabHead.rawValue
        let emojiLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        emojiLabel.text = curretTabHead.getEmoji()
        let image = UIImage.imageWithLabel(emojiLabel)
        // TODO: 今後つけるかも
//        let badge = nil
        let item = TMBarItem(title: title, image: image, badgeValue: nil)
        return item
    }
}

extension MainTabViewController: ENSideMenuDelegate {
    func sideMenuWillOpen() {
        print("sideMenuWillOpen")
    }
    
    func sideMenuWillClose() {
        print("sideMenuWillClose")
    }
    
    func sideMenuShouldOpenSideMenu() -> Bool {
        print("sideMenuShouldOpenSideMenu")
        return true
    }
    
    func sideMenuDidClose() {
        print("sideMenuDidClose")
    }
    
    func sideMenuDidOpen() {
        print("sideMenuDidOpen")
    }
}

extension MainTabViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // 画像選択
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.originalImage] as! UIImage
        
        // カメラロールに保存する
        // UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        self.dismiss(animated: true)
        
        let sb = UIStoryboard(name: "Add", bundle: nil)
        let nvc = sb.instantiateInitialViewController() as! UINavigationController
        let vc = nvc.viewControllers.first as! AddViewController
        vc.choiceImage = image
        present(nvc, animated: true) {
            
        }
    }
    //キャンセル
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}
