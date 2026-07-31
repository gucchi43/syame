//
//  ChildContentViewController.swift
//  PhotoKeyboardEx
//
//  Created by Hiroki Taniguchi on 2019/08/02.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import StoreKit
import PhotoKeyboardFramework
import SwiftDate
import DynamicColor
import Realm
import RealmSwift
import GoogleMobileAds

class ChildContentViewController: UIViewController, RealmManagerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var currentGenreTag:GenreTagType!
    var realmPhotos: Results<RealmPhoto>?
    /// Optional にすると `tabPageIndex != 0` が nil のとき true になり、マイボードでもサーバ取得が走る
    var tabPageIndex: Int = 0
    private let refreshControl = UIRefreshControl()
    #if DEBUG
    let addId = "ca-app-pub-3940256099942544/1712485313"
    #else
    let addId = "ca-app-pub-2311091333372031/6162073771"
    #endif
    private let supabase = SupabaseManager.shared
    private var oFirePhotos : [OFirePhoto] = []
    private var currentOffset: Int = 0
    /// 取得中に重ねてリクエストしないためのフラグ
    private var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        realmPhotos = RealmManager.shared.realmData
        RealmManager.shared.delegate = self
        let genreTags = GenreTagType.getAllGenreTags()
        currentGenreTag = tabPageIndex < genreTags.count ? genreTags[tabPageIndex] : genreTags[0]
        NotificationCenter.default.addObserver(self, selector: #selector(reloadSaveState(notification:)), name: .updateSaveState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadAfterPost(notification:)), name: .allRelaod, object: nil)
        commonInit()
        if tabPageIndex != 0 {
            firePhotoInit()
        }
        setUpAd()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if tabPageIndex == 0 {
            collectionView.reloadData()
        } else {
            let blockIncludes = self.mutedArray(origin: self.oFirePhotos)
            if blockIncludes.map({ $0.id }) != self.oFirePhotos.map({ $0.id }) {
                oFirePhotos = blockIncludes
                collectionView?.reloadData()
            }
        }
        // サーバー系タブでも0件表示が更新されるようにする
        updateEmptyState()
    }
    
    func commonInit() {
        collectionView.dataSource = self
        collectionView.delegate = self
        setupCollectionView()
        collectionView.register(UINib(nibName: "PhotoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCollectionViewCell")
        collectionView.contentMode = .left
        collectionView.backgroundView?.backgroundColor = UIColor.bgDark().lighter(amount: 0.8)
        collectionView.backgroundColor = .bgDark()
        refreshControl.addTarget(self, action: #selector(self
            .refresh(sender:)), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        print("tabPageIndex : ", tabPageIndex)
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
        let itemCount: Int
        if tabPageIndex == 0 {
            itemCount = realmPhotos?.count ?? 0
        } else {
            itemCount = oFirePhotos.count
        }

        if itemCount == 0 {
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
            var title = LocalizeKey.othersEmptyTitle.localizedString()
            if tabPageIndex == 0 {
                title = LocalizeKey.myBoardEmptyTitle.localizedString()
            }
            titleLabel.attributedText = NSAttributedString(
                string: title,
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
        } else {
            collectionView.backgroundView = nil
        }
    }
    
    func fetchPhotos(offset: Int = 0) async throws -> [OFirePhoto] {
        let client = supabase.client

        switch currentGenreTag {
        case .none, .some(.myBoard):
            return []
        case .some(.new):
            return try await client.from("photos")
                .select()
                .eq("locale", value: supabase.locale)
                .eq("is_debug", value: supabase.isDebug)
                .order("created_at", ascending: false)
                .range(from: offset, to: offset + 19)
                .execute()
                .value
        case .some(.popular):
            let sevenDaysAgo = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-7 * 24 * 60 * 60))
            return try await client.from("photos")
                .select()
                .eq("locale", value: supabase.locale)
                .eq("is_debug", value: supabase.isDebug)
                .gt("updated_at", value: sevenDaysAgo)
                .order("weekly_save_count", ascending: false)
                .range(from: offset, to: offset + 19)
                .execute()
                .value
        case .some(.humor), .some(.cool), .some(.cute), .some(.serious), .some(.other):
            return try await client.from("photos")
                .select()
                .eq("locale", value: supabase.locale)
                .eq("is_debug", value: supabase.isDebug)
                .eq("genre", value: currentGenreTag.getKey())
                .order("title")
                .range(from: offset, to: offset + 19)
                .execute()
                .value
        }
    }

    func firePhotoInit() {
        guard !isLoading else { return }
        isLoading = true
        currentOffset = 0
        Task { [weak self] in
            guard let self = self else { return }
            defer { self.isLoading = false }
            do {
                let photos = try await self.fetchPhotos()
                // 配列の書き換えと読み出し(データソース)は必ずメインスレッドに揃える
                await MainActor.run {
                    self.oFirePhotos = self.mutedArray(origin: photos)
                    self.currentOffset = photos.count
                    self.collectionView?.reloadData()
                    self.updateEmptyState()
                }
            } catch {
                print("Error fetching photos: \(error)")
            }
        }
    }

    func mutedArray(origin: [OFirePhoto]) -> [OFirePhoto] {
        let blockArray = GroupeDefaults.shared.getBlockContens()
        let newArray = origin.filter { (model) -> Bool in
            return !blockArray.contains(model.id.uuidString)
        }
        return newArray
    }

    func nextLoad() {
        // ガードがないとスクロール中に同じページを何度も取得して重複表示になる
        guard !isLoading else { return }
        isLoading = true
        Task { [weak self] in
            guard let self = self else { return }
            defer { self.isLoading = false }
            do {
                let photos = try await self.fetchPhotos(offset: self.currentOffset)
                guard !photos.isEmpty else { return }
                await MainActor.run {
                    let known = Set(self.oFirePhotos.map { $0.id })
                    let additions = self.mutedArray(origin: photos).filter { !known.contains($0.id) }
                    self.oFirePhotos += additions
                    self.currentOffset += photos.count
                    self.collectionView?.reloadData()
                }
            } catch {
                print("Error loading next: \(error)")
            }
        }
    }
    
    @objc func reloadAfterPost(notification: Notification) -> Void {
        if tabPageIndex == 0 {
            collectionView.reloadData()
        } else {
            firePhotoInit()
        }
    }

    @objc func reloadSaveState(notification: Notification) -> Void {
        guard let info = notification.userInfo,
              let id = info["id"] as? String else { return }
        if tabPageIndex == 0 {
            collectionView.reloadData()
            updateEmptyState()
            return
        }
        guard let row = oFirePhotos.firstIndex(where: { $0.id.uuidString == id }) else { return }
        collectionView.reloadItems(at: [IndexPath(row: row, section: 0)])
    }
    
    
    func realmObjectDidChange() {
        // マイボードは Realm がそのままデータソースなので変更を反映する
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.tabPageIndex == 0 else { return }
            self.collectionView?.reloadData()
            self.updateEmptyState()
        }
    }
    
    @objc func refresh(sender: UIRefreshControl) {
        if tabPageIndex == 0 {
            return collectionView.reloadData {
                sender.endRefreshing()
            }
        }
        guard !isLoading else {
            sender.endRefreshing()
            return
        }
        isLoading = true
        currentOffset = 0
        Task { [weak self] in
            guard let self = self else { return }
            defer { self.isLoading = false }
            do {
                let photos = try await self.fetchPhotos()
                await MainActor.run {
                    self.oFirePhotos = self.mutedArray(origin: photos)
                    self.currentOffset = photos.count
                    self.updateEmptyState()
                    self.collectionView?.reloadData {
                        sender.endRefreshing()
                    }
                }
            } catch {
                print("Error refreshing: \(error)")
                await MainActor.run { sender.endRefreshing() }
            }
        }
    }
    
    func checkSaved(index: Int) -> Bool {
        if tabPageIndex == 0 {
            return true
        } else {
            let currentFirePhoto = oFirePhotos[index]
            let photoId = currentFirePhoto.id.uuidString
            let selectSavedPhotos = realmPhotos?.filter { $0.id == photoId }
            return (selectSavedPhotos?.count ?? 0) > 0
        }
    }

    private struct SaveCountParams: Encodable {
        let photo_id: String
        let delta: Int
    }

    /// クライアントで読んで計算して書き戻すと同時保存で更新が失われ、任意の値も書けてしまうため、
    /// サーバ側の関数で加減算する。
    func updateSaveCount(photoId: String, up: Bool) {
        let params = SaveCountParams(photo_id: photoId, delta: up ? 1 : -1)
        Task {
            do {
                try await supabase.client.rpc("change_save_count", params: params).execute()
            } catch {
                print("savecount update error: \(error)")
            }
        }
    }

    @objc func tapCellSaveButton(sender: UIButton) {
        // superviewを辿ると xib の階層を変えただけで壊れるため、座標からセルを引く
        let point = sender.convert(CGPoint.zero, to: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point),
              let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell else {
            return
        }
        let index = indexPath.row

        let id: String
        if tabPageIndex == 0 {
            guard let realmPhoto = savedPhoto(at: index) else { return }
            id = realmPhoto.id
        } else {
            guard index < oFirePhotos.count else { return }
            id = oFirePhotos[index].id.uuidString
        }

        if checkSaved(index: index) {
            // チュートリアルで入れた画像はサーバに実体がないためカウント更新の対象外
            let isTutorialData = savedPhoto(withId: id)?.ownerId == "official"
            RealmManager.shared.delete(docId: id, success: { () in
                NotificationCenter.default.post(name: .updateSaveState, object: nil, userInfo: ["id": id, "saveFlag": false])
                guard !isTutorialData else { return }
                self.updateSaveCount(photoId: id, up: false)
            }) { (error) in
                print(error)
            }
        } else {
            if GroupeDefaults.shared.isAddCount() {
                return showAdd()
            }
            let photo: RealmPhoto
            if tabPageIndex == 0 {
                guard let saved = savedPhoto(at: index) else { return }
                photo = saved
            } else {
                guard index < oFirePhotos.count else { return }
                let selectData = oFirePhotos[index]
                guard let image = cell.photoImageView.image else { return }
                photo = RealmPhoto.create(id: selectData.id.uuidString,
                                            text: selectData.title,
                                            image: image,
                                            imageHeight: selectData.imageHeight,
                                            imageWidth: selectData.imageWidth,
                                            getDay: Date().toString(),
                                            isPublic: true,
                                            ownerId: selectData.ownerId?.uuidString ?? "")
            }
            // Realmにsaveする
            RealmManager.shared.save(data: photo, success: {() in
                NotificationCenter.default.post(name: .updateSaveState, object: nil, userInfo: ["id": id, "saveFlag": true])
                self.updateSaveCount(photoId: id, up: true)
                GroupeDefaults.shared.useSaveLife()
                if GroupeDefaults.shared.isRateAlert() {
                    self.requestReview()
                }
            }) { (error) in
                print(error)
            }
        }
    }

    private func savedPhoto(at index: Int) -> RealmPhoto? {
        guard let realmPhotos = realmPhotos, index >= 0, index < realmPhotos.count else { return nil }
        return realmPhotos[index]
    }

    private func savedPhoto(withId id: String) -> RealmPhoto? {
        return realmPhotos?.first { $0.id == id }
    }

    private func requestReview() {
        if #available(iOS 16.0, *), let scene = view.window?.windowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    func showAdd() {
        let alert = UIAlertController(title:LocalizeKey.adAlertTitle.localizedString(), message: LocalizeKey.adAlertTitle.localizedString(), preferredStyle: .alert)
        let ok = UIAlertAction(title: LocalizeKey.baseOK.localizedString(), style: .default, handler: { (action) in
            // 広告流す
            print("call add")
            self.showRewardedAd()
            
//            if self.rewardedAd?.isReady == true {
//                GADRewardBasedVideoAd.sharedInstance().present(fromRootViewController: self)
////                self.rewardedAd?.present(fromRootViewController: self, delegate:self)
//            } else {
//                UIAlertView(title: "Rewarded video not ready",
//                            message: "The rewarded video didn't finish loading or failed to load",
//                            delegate: self,
//                            cancelButtonTitle: "Drat").show()
//            }
            
//            GroupeDefaults.shared.chargeSaveLife()
        })
        let cancell = UIAlertAction(title: LocalizeKey.baseCancel.localizedString(), style: .default, handler: { (action) in
            print("cancell cell add")
        })
        alert.addAction(ok)
        alert.addAction(cancell)
        present(alert, animated: true) {
        }
    }
    
    func goPotoDetail(rPhoto: RealmPhoto?, fPhoto: OFirePhoto?, index: Int) {
        let sb = UIStoryboard(name: "PhotoDetail",bundle: nil)
        guard let vc = sb.instantiateInitialViewController() as? PhotoDetailViewController else { return }
        vc.rPhoto = rPhoto
        vc.fPhoto = fPhoto
        if checkSaved(index: index) {
            vc.savedFlag = true
        } else {
            vc.savedFlag = false
        }
        present(vc, animated: true, completion: nil)
    }
}

extension ChildContentViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if tabPageIndex == 0 {
            return realmPhotos?.count ?? 0
        } else {
            return oFirePhotos.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath)
        if let cell = cell as? PhotoCollectionViewCell {
            if tabPageIndex == 0 {
                guard let photo = savedPhoto(at: indexPath.row) else { return cell }
                cell.configure(photo: photo, saved: true)
            } else {
                guard indexPath.row < oFirePhotos.count else { return cell }
                cell.configure(doc: oFirePhotos[indexPath.row], saved: checkSaved(index: indexPath.row))
            }
            cell.saveButton.tag = indexPath.row
            cell.saveButton.addTarget(self, action: #selector(self.tapCellSaveButton(sender: )), for: .touchUpInside)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard tabPageIndex != 0, indexPath == collectionView.indexPathForLastItem else { return }
        self.nextLoad()
    }
}

extension ChildContentViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if tabPageIndex == 0 {
            guard let photo = savedPhoto(at: indexPath.row) else { return }
            goPotoDetail(rPhoto: photo, fPhoto: nil, index: indexPath.row)
        } else {
            guard indexPath.row < oFirePhotos.count else { return }
            goPotoDetail(rPhoto: nil, fPhoto: oFirePhotos[indexPath.row], index: indexPath.row)
        }
    }
}

extension ChildContentViewController {
    private var rewardedAd: GADRewardedAd? {
        get { objc_getAssociatedObject(self, &rewardedAdKey) as? GADRewardedAd }
        set { objc_setAssociatedObject(self, &rewardedAdKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func setUpAd() {
        // 同意取得と初期化が終わる前に読み込むと必ず失敗するため、完了を待つ。
        // 起動より後にこの画面が作られた場合は既に初期化済みなのでそのまま読み込む。
        NotificationCenter.default.addObserver(forName: .adsDidStart,
                                               object: nil,
                                               queue: .main) { [weak self] _ in
            self?.loadRewardedAd()
        }
        loadRewardedAd()
    }

    func loadRewardedAd() {
        GADRewardedAd.load(withAdUnitID: addId, request: GADRequest()) { [weak self] ad, error in
            if let error = error {
                print("Failed to load rewarded ad: \(error.localizedDescription)")
                return
            }
            self?.rewardedAd = ad
        }
    }

    func showRewardedAd() {
        guard let rewardedAd = rewardedAd else {
            print("Rewarded ad not ready")
            return
        }
        rewardedAd.present(fromRootViewController: self) {
            let reward = rewardedAd.adReward
            GroupeDefaults.shared.chargeSaveLife(amount: Int(truncating: reward.amount))
        }
        loadRewardedAd()
    }
}

private var rewardedAdKey: UInt8 = 0
