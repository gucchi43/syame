//
//  ChildContentViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/02.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit

class ChildContentViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    var models = Model.createModels()
    var items : NSArray = []
    private var searchResult = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commonInit()
        // Do any additional setup after loading the view.
    }
    
    func commonInit() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UINib(nibName: "PhotoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCollectionViewCell")
        collectionView.backgroundView?.backgroundColor = .green
    }
}

extension ChildContentViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return models.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath)
        if let cell = cell as? PhotoCollectionViewCell {
            cell.configure(model: models[indexPath.row])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        //　横幅を画面サイズの約半分にする
        let cellSize:CGFloat = self.view.bounds.width/2 - 0.5
        return CGSize(width: cellSize, height: cellSize)
    }
    
    // 水平方向におけるセル間のマージン
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.5
    }
    
    // 垂直方向におけるセル間のマージン
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.5
    }
}

extension ChildContentViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        var newValue = self.getModel(at: indexPath) as! Model
        newValue.isSelected = false
        models[indexPath.row] = newValue
        
        print("=========")
        print("call didDeselectItemAt")
        print("indexpath : ", indexPath)
        print("newValue : ", newValue)
        print("=========")
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell else {
            return //the cell is not visible
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
        self.collectionView.deselectItem(at: indexPath, animated: true)
        
//        var newValue = self.getModel(at: indexPath) as! Model
//        newValue.isSelected = false
//        models[indexPath.row] = newValue

        print("=========")
        print("call didSelectItemAt 解除モード")
        print("indexpath : ", indexPath)
        print("=========")
    }
    
    fileprivate func getModel(at indexPath: IndexPath) -> Model? {
        guard !self.models.isEmpty && indexPath.row >= 0 && indexPath.row < self.models.count else { return nil }
        return self.models[indexPath.row]
    }
}
