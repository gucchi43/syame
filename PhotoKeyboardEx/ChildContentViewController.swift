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
import Toast

/// マイボード(端末に保存済みの画像)の一覧。
/// 公開フィードを廃止したため、データソースは Realm のみ。
class ChildContentViewController: UIViewController, RealmManagerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!

    /// 「次にやること」の常設案内。モーダルを閉じても手がかりが残るようにする
    private let onboardingHint = OnboardingHintView()
    private var onboardingStep: OnboardingStep = .done
    var realmPhotos: Results<RealmPhoto>?
    private let refreshControl = UIRefreshControl()

    /// いま並べているマス。写真の枚数と上限から決め、reload のたびに引き直す
    private(set) var slots: [BoardSlot] = []

    private func rebuildSlots() {
        slots = BoardSlots.make(photoCount: realmPhotos?.count ?? 0, limit: RealmManager.photoLimit)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        realmPhotos = RealmManager.shared.realmData
        RealmManager.shared.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(reloadSaveState(notification:)), name: .updateSaveState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadAfterPost(notification:)), name: .allReload, object: nil)
        commonInit()
        // 表示前でも並びが決まっているようにする。データソースは viewWillAppear に頼らない
        rebuildSlots()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        rebuildSlots()
        collectionView.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 案内行が出ている間は、その高さぶん一覧を下げてヘッダと重ねない
        let inset = onboardingHint.isHidden ? 0 : onboardingHint.frame.maxY - view.safeAreaInsets.top + Spacing.s
        if collectionView.contentInset.top != inset {
            let previousInset = collectionView.contentInset.top
            collectionView.contentInset.top = inset
            collectionView.verticalScrollIndicatorInsets.top = inset
            // contentInset を後から変えても、確定済みの contentOffset は自動で追従しない。
            // 案内行がすでに表示済みの状態(2回目以降のレイアウト)でこの inset が変わると、
            // 上のヘッダが案内行の裏に隠れたまま動かないため、差分ぶんだけ追わせる
            collectionView.contentOffset.y += previousInset - inset
        }
    }

    /// いまの手順を受け取り、案内行の表示を更新する
    func applyOnboarding(step: OnboardingStep) {
        onboardingStep = step
        guard isViewLoaded else { return }
        onboardingHint.apply(step: step)
    }

    /// 案内行を一覧の上に敷く
    private func setupOnboardingHint() {
        onboardingHint.translatesAutoresizingMaskIntoConstraints = false
        onboardingHint.addTarget(self, action: #selector(tapOnboardingHint), for: .touchUpInside)
        view.addSubview(onboardingHint)

        NSLayoutConstraint.activate([
            onboardingHint.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                                constant: Spacing.s),
            onboardingHint.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.s),
            onboardingHint.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.s)
        ])
        onboardingHint.apply(step: onboardingStep)
    }

    /// 案内行を押したのと同じ経路を通す。押し先の検証に使う
    func simulateOnboardingHintTapForTesting() {
        tapOnboardingHint()
    }

    /// 案内行から、その手順の画面へ送る
    @objc private func tapOnboardingHint() {
        switch onboardingStep {
        case .savePhoto:
            // 保存は親のFABが持っている。同じ導線に乗せる
            NotificationCenter.default.post(name: .requestAddPhoto, object: nil)
        case .enableKeyboard, .allowFullAccess:
            // どちらも案内先は同じ「キーボードの設定」の画面
            guard let nvc = UIStoryboard(name: "Usage", bundle: nil).instantiateInitialViewController() else { return }
            present(nvc, animated: true)
        case .howToSend:
            present(UINavigationController(rootViewController: HowToSendViewController()), animated: true)
        case .welcome, .done:
            break
        }
    }

    func commonInit() {
        setupOnboardingHint()
        collectionView.dataSource = self
        collectionView.delegate = self
        setupCollectionView()
        collectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: PhotoCollectionViewCell.reuseIdentifier)
        collectionView.register(EmptySlotCell.self, forCellWithReuseIdentifier: EmptySlotCell.reuseIdentifier)
        collectionView.register(BoardProgressView.self,
                                forSupplementaryViewOfKind: BoardProgressView.elementKind,
                                withReuseIdentifier: BoardProgressView.reuseIdentifier)
        collectionView.contentMode = .left
        collectionView.backgroundColor = .bgBase
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
    /// セル下部の情報エリアの高さ。セル側の定義をそのまま使う。
    /// 文字サイズ設定で変わるため、起動時に固めず参照のたびに読む
    private static var cellInfoHeight: CGFloat { PhotoCollectionViewCell.infoHeight }

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
            // 進み具合のピルを一覧の頭に置き、スクロールに乗せる
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .estimated(56)),
                elementKind: BoardProgressView.elementKind,
                alignment: .top)
            section.boundarySupplementaryItems = [header]
            section.interGroupSpacing = spacing
            section.contentInsets = NSDirectionalEdgeInsets(top: spacing,
                                                            leading: spacing,
                                                            bottom: 88.0,
                                                            trailing: spacing)
            return section
        }
    }

    @objc func reloadAfterPost(notification: Notification) -> Void {
        rebuildSlots()
        collectionView.reloadData()
    }

    @objc func reloadSaveState(notification: Notification) -> Void {
        rebuildSlots()
        collectionView.reloadData()
    }

    func realmObjectDidChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.rebuildSlots()
            self.collectionView?.reloadData()
        }
    }

    @objc func refresh(sender: UIRefreshControl) {
        collectionView.reloadData {
            sender.endRefreshing()
        }
    }

    /// セルの3点リーダーから開くメニューを組み立てる。
    /// ローカルのデータなので削除の頻度は低い。1階層下げて誤操作を減らす。
    private func makeMenu(for photo: RealmPhoto) -> UIMenu {
        let id = photo.id
        let copy = UIAction(title: LocalizeKey.menuCopy.localizedString(),
                            image: .symbol(Symbol.copy)) { [weak self] _ in
            self?.copyToPasteboard(photo: photo)
        }
        let delete = UIAction(title: LocalizeKey.menuDelete.localizedString(),
                              image: .symbol(Symbol.delete),
                              attributes: .destructive) { [weak self] _ in
            self?.confirmDelete(id: id)
        }
        return UIMenu(children: [copy, delete])
    }

    /// キーボードを開かなくても貼り付けられるようにする。
    /// フルアクセスの許可を得る前に価値を体験してもらうための導線。
    private func copyToPasteboard(photo: RealmPhoto) {
        guard let image = photo.image else { return }
        image.copyToPasteboardWithWatermark()
        RealmManager.shared.incrementUseNum(id: photo.id)
        let toast = AuroraView.makeToast(message: LocalizeKey.copiedToast.localizedString(),
                                         maxWidth: view.bounds.width - Spacing.l * 2)
        view.showToast(toast, duration: 1.5, position: .center)
    }

    private func confirmDelete(id: String) {
        let alert = UIAlertController(title: nil,
                                      message: LocalizeKey.menuDeleteConfirm.localizedString(),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizeKey.menuDelete.localizedString(), style: .destructive) { _ in
            RealmManager.shared.delete(docId: id, success: {
                NotificationCenter.default.post(name: .updateSaveState, object: nil, userInfo: ["id": id, "saveFlag": false])
            }, failure: { error in
                print(error)
            })
        })
        alert.addAction(UIAlertAction(title: LocalizeKey.baseCancel.localizedString(), style: .cancel))
        present(alert, animated: true)
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
        return slots.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch slots[indexPath.item] {
        case .photo(let index):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? PhotoCollectionViewCell, let photo = savedPhoto(at: index) {
                cell.configure(photo: photo, menu: makeMenu(for: photo))
            }
            return cell
        case .empty:
            return collectionView.dequeueReusableCell(withReuseIdentifier: EmptySlotCell.reuseIdentifier, for: indexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                   withReuseIdentifier: BoardProgressView.reuseIdentifier,
                                                                   for: indexPath)
        (view as? BoardProgressView)?.apply(filled: realmPhotos?.count ?? 0, limit: RealmManager.photoLimit)
        return view
    }
}

extension ChildContentViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch slots[indexPath.item] {
        case .photo(let index):
            guard let photo = savedPhoto(at: index) else { return }
            showPhotoDetail(rPhoto: photo)
        case .empty:
            // 空きスロットは追加の入口。案内行の「保存する」と同じ導線に乗せる
            NotificationCenter.default.post(name: .requestAddPhoto, object: nil)
        }
    }
}
