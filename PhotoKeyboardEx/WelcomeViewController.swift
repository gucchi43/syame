//
//  WelcomeViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/23.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import DynamicColor
import SwiftyAttributes

class WelcomeViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var thirdLabel: UILabel!
    @IBOutlet weak var fourthLabel: UILabel!
    
    @IBOutlet weak var explainLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        commonInit()
        settext()
        
    }
    
    func commonInit() {
        self.view.backgroundColor = .bgDark()
        titleLabel.textColor = .white
        firstLabel.textColor = .white
        secondLabel.textColor = .white
        thirdLabel.textColor = .white
        fourthLabel.textColor = .white
        explainLabel.textColor = .white
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 8.0
        nextButton.backgroundColor = .acGreen()
    }
    
    func settext() {
        titleLabel.attributedText = "PKB!".withTextColor(.acGreen()).withFont(Font.systemFont(ofSize: 40.0, weight: .bold))
        firstLabel.attributedText = "P".withTextColor(.acGreen()).withFont(Font.systemFont(ofSize: 32.0, weight: .bold)) + "hoto".withTextColor(.white).withFont(Font.systemFont(ofSize: 32.0, weight: .bold)) + "を".withTextColor(.white).withFont(Font.systemFont(ofSize: 32.0, weight: .bold))
        secondLabel.attributedText = "K".withTextColor(.acGreen()).withFont(Font.systemFont(ofSize: 32.0, weight: .bold)) + "eyboard".withTextColor(.white).withFont(Font.systemFont(ofSize: 32.0, weight: .bold)) + "で".withTextColor(.white).withFont(Font.systemFont(ofSize: 32.0, weight: .bold))
        thirdLabel.attributedText = "B".withTextColor(.acGreen()).withFont(Font.systemFont(ofSize: 32.0, weight: .bold)) + "akyu~~~~n".withTextColor(.white).withFont(Font.systemFont(ofSize: 32.0, weight: .bold)) + "!".withTextColor(.white).withFont(Font.systemFont(ofSize: 32.0, weight: .bold))
        fourthLabel.attributedText =  "ひ〜〜〜〜いぁ!!!".withTextColor(.white).withFont(Font.systemFont(ofSize: 32.0, weight: .bold))
        explainLabel.text = "PKBへようこそ！\nPKBはみんなが投稿した画像をスタンプみたいにバキュ〜〜ンと簡単に送れるキーボードアプリです。\nまずは誰かが投稿した画像をsaveしてマイキーボードに追加してみましょう！"
        explainLabel.numberOfLines = 0

    }
    
    
    @IBAction func tapNextButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
//        self.navigationController?.popToRootViewController(animated: true)
    }
}
