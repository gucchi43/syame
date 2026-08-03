//
//  ChildContentViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/02.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import PhotoKeyboardFramework
import RealmSwift

/// マイボード(端末に保存済みの画像)の一覧。
/// 公開フィードを廃止したため、データソースは Realm のみ。
class ChildContentViewController: UIViewController, RealmManagerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    var realmPhotos: Results<RealmPhoto>?
    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        realmPhotos = RealmManager.shared.realmData
        RealmManager.shared.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(reloadSaveState(notification:)), name: .updateSaveState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadAfterPost(notification:)), name: .allReload, object: nil)
        commonInit()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
        updateEmptyState()
    }

    func commonInit() {
        collectionView.dataSource = self
        collectionView.delegate = self
        setupCollectionView()
        collectionView.register(UINib(nibName: "PhotoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCollectionViewCell")
        collectionView.contentMode = .left
        collectionView.backgroundColor = .bgDark()
        refreshControl.addTarget(self, action: #selector(self
            .refresh(sender:)), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }

    //MARK: - CollectionView UI Setup
    func setupCollectionView(){
        let layout = createGridLayout()
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.alwaysBounceVertical = true
        collectionView.collectionViewLayout = layout
    }

    private static let gridSpacing: CGFloat = 8
    private static let gridColumns = 2
    /// セル下部の情報エリア(タイトル・保存数・saveボタン)の高さ。xibで固定されている値
    private static let cellInfoHeight: CGFloat = 68

    /// 1行の高さを求める。画像は正方形にし、その下に情報エリアを積む。
    /// 高さを可変(estimated)にすると、同じ行の2つのセルで高さが揃わず隙間ができる。
    static func gridMetrics(containerWidth: CGFloat) -> (itemWidth: CGFloat, rowHeight: CGFloat) {
        let columns = CGFloat(gridColumns)
        // 左右の余白と列間の間隔を引いた残りを列数で割る
        let available = containerWidth - gridSpacing * (columns + 1)
        let itemWidth = max((available / columns).rounded(.down), 1)
        return (itemWidth, itemWidth + cellInfoHeight)
    }

    private func createGridLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { _, environment in
            let spacing = ChildContentViewController.gridSpacing
            let metrics = ChildContentViewController.gridMetrics(
                containerWidth: environment.container.effectiveContentSize.width
            )

            // 幅を算出済みの絶対値で指定する。fractionalWidth や count 指定では
            // 列間の間隔ぶんが考慮されず、はみ出してしまう
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
                widthDimension: .absolute(metrics.itemWidth),
                heightDimension: .fractionalHeight(1.0)
            ))
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(metrics.rowHeight)
                ),
                subitems: Array(repeating: item, count: ChildContentViewController.gridColumns)
            )
            group.interItemSpacing = .fixed(spacing)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            section.contentInsets = NSDirectionalEdgeInsets(top: spacing,
                                                            leading: spacing,
                                                            bottom: 88.0,
                                                            trailing: spacing)
            return section
        }
    }

    func updateEmptyState() {
        guard (realmPhotos?.count ?? 0) == 0 else {
            collectionView.backgroundView = nil
            return
        }

        let emptyView = UIView(frame: collectionView.bounds)
        emptyView.backgroundColor = .bgDark()

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView()
        imageView.image = UIImage.fontAwesomeIcon(name: .grinTears, style: .solid, textColor: .acGreen(), size: CGSize(width: 80, height: 80))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 80).isActive = true

        let titleLabel = UILabel()
        titleLabel.attributedText = NSAttributedString(
            string: LocalizeKey.myBoardEmptyTitle.localizedString(),
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 19),
                .foregroundColor: UIColor.acGreen()
            ]
        )
        titleLabel.textAlignment = .center

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        emptyView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor, constant: -60)
        ])

        collectionView.backgroundView = emptyView
    }

    @objc func reloadAfterPost(notification: Notification) -> Void {
        collectionView.reloadData()
        updateEmptyState()
    }

    @objc func reloadSaveState(notification: Notification) -> Void {
        collectionView.reloadData()
        updateEmptyState()
    }

    func realmObjectDidChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.collectionView?.reloadData()
            self.updateEmptyState()
        }
    }

    @objc func refresh(sender: UIRefreshControl) {
        collectionView.reloadData {
            sender.endRefreshing()
        }
    }

    /// マイボードから画像を取り除く。
    /// 公開フィードが無くなったため、このボタンは「保存」ではなく「削除」の意味になった。
    @objc func tapCellRemoveButton(sender: UIButton) {
        // superviewを辿ると xib の階層を変えただけで壊れるため、座標からセルを引く
        let point = sender.convert(CGPoint.zero, to: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point),
              let photo = savedPhoto(at: indexPath.row) else {
            return
        }
        let id = photo.id
        RealmManager.shared.delete(docId: id, success: { () in
            NotificationCenter.default.post(name: .updateSaveState, object: nil, userInfo: ["id": id, "saveFlag": false])
        }) { (error) in
            print(error)
        }
    }

    private func savedPhoto(at index: Int) -> RealmPhoto? {
        guard let realmPhotos = realmPhotos, index >= 0, index < realmPhotos.count else { return nil }
        return realmPhotos[index]
    }

    func showPhotoDetail(rPhoto: RealmPhoto) {
        let sb = UIStoryboard(name: "PhotoDetail",bundle: nil)
        guard let vc = sb.instantiateInitialViewController() as? PhotoDetailViewController else { return }
        vc.rPhoto = rPhoto
        present(vc, animated: true, completion: nil)
    }
}

extension ChildContentViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return realmPhotos?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath)
        if let cell = cell as? PhotoCollectionViewCell {
            guard let photo = savedPhoto(at: indexPath.row) else { return cell }
            cell.configure(photo: photo, saved: true)
            cell.saveButton.tag = indexPath.row
            cell.saveButton.addTarget(self, action: #selector(self.tapCellRemoveButton(sender: )), for: .touchUpInside)
        }
        return cell
    }
}

extension ChildContentViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let photo = savedPhoto(at: indexPath.row) else { return }
        showPhotoDetail(rPhoto: photo)
    }
}
