//
//  RealmManager.swift
//  PhotoKeyboardFramework
//
//  Created by Hiroki Taniguchi on 2019/08/05.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import UIKit
import Realm
import RealmSwift

public protocol RealmManagerDelegate: AnyObject {
    func realmObjectDidChange()
}

public class RealmManager {
    public static let shared = RealmManager()

    /// シングルトンがViewControllerを保持し続けないようweakにする
    public weak var delegate: RealmManagerDelegate?

    private static let appGroupIdentifier = "group.bocchi.PhotoKeyboardEx"
    /// ロケールに依存しない統合後のRealmファイル名
    private static let realmFileName = "db.realm.shared"
    /// 旧バージョンがロケールごとに分けて作成していたファイル
    private static let legacyJPFileName = "db.realm.jp"
    private static let legacyWorldFileName = "db.realm.world"
    private static let legacyOriginalFileName = "db.realm"
    private static let schemaVersion: UInt64 = 2
    /// マイボードとキーボードの並び順
    static let orderKey = "pastedAt"

    private let configuration: Realm.Configuration
    /// 変更通知の購読はメインスレッドのRealmに紐づくため、その参照を保持しておく
    private var observedRealm: Realm?
    private var token: NotificationToken?

    /// スレッド拘束を避けるため、常に呼び出しスレッドのRealmから取得する
    public var realmData: Results<RealmPhoto> {
        return realm().objects(RealmPhoto.self).sorted(byKeyPath: RealmManager.orderKey)
    }

    /// 版 1 から上げるときに既存の写真へ入れる日時。
    /// 今見えている順番を変えないよう、1 秒ずつ増やして最後を基準の時刻にする
    static func migrationDates(count: Int, endingAt end: Date) -> [Date] {
        return (0..<count).map { end.addingTimeInterval(TimeInterval($0 - (count - 1))) }
    }

    private init() {
        let container = RealmManager.containerURL()
        RealmManager.applyFileProtection(to: container)
        let fileURL = container.appendingPathComponent(RealmManager.realmFileName)

        // 復元は Realm を開く前に済ませる。開いたあとに差し替えても、
        // 既に握られたファイルハンドルは古い本体を指したままになる。
        backup = RealmManager.makeBackup(sharedContainer: container)
        if backup.needsRestore {
            try? backup.restore(to: fileURL)
        }
        backup.markAlive()

        RealmManager.consolidateLegacyFilesIfNeeded(container: container, target: fileURL)
        configuration = RealmManager.makeConfiguration(fileURL: fileURL)
        startObserving()
    }

    // MARK: - 消失対策

    private let backup: RealmBackup
    /// 直前に複製を取ったときの件数。変化が無ければ作り直さない
    private var lastSnapshotCount: Int?

    /// 複製の置き場所はアプリ本体のコンテナ。
    /// 共有コンテナに置くと、守りたい相手(コンテナごとの消失)と一緒に消えて意味がない。
    private static func makeBackup(sharedContainer: URL) -> RealmBackup {
        let appContainer = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return RealmBackup(appContainer: appContainer, sharedContainer: sharedContainer)
    }

    /// 複製を取り直す。アプリが背面に回るときに呼ぶ。
    ///
    /// 件数が変わっていなければ何もしない。writeCopy はファイル全体を書き出すので、
    /// 毎回走らせると画像の枚数に比例して背面遷移が重くなる。
    public func snapshotIfNeeded() {
        let count = realmData.count
        guard count != lastSnapshotCount else { return }
        guard let realm = diskRealm() else { return }
        do {
            try backup.write(from: realm)
            lastSnapshotCount = count
        } catch {
            // 複製が作れなくても本体は無事なので、起動や保存は止めない
            print("realm snapshot error: \(error)")
        }
    }

    deinit {
        token?.invalidate()
    }

    // MARK: - Realm の生成

    /// 書き込み用。メモリ上のRealmに書いても消えるだけなので、開けない場合は nil を返して
    /// 呼び出し側に失敗として扱わせる。
    private func diskRealm() -> Realm? {
        return try? Realm(configuration: configuration)
    }

    /// 読み取り用。ディスク上のRealmを開けない場合でもアプリ・キーボードが起動不能にならないよう
    /// メモリ上のRealmへ退避する。
    private func realm() -> Realm {
        return diskRealm() ?? RealmManager.makeFallbackRealm()
    }

    private static func makeFallbackRealm() -> Realm {
        var fallback = Realm.Configuration()
        fallback.inMemoryIdentifier = "PhotoKeyboardFrameworkFallback"
        fallback.objectTypes = [RealmPhoto.self]
        // メモリ上のRealmはファイルI/Oを伴わないため生成に失敗する現実的な経路はない
        return try! Realm(configuration: fallback)
    }

    static func makeConfiguration(fileURL: URL) -> Realm.Configuration {
        var configuration = Realm.Configuration()
        configuration.fileURL = fileURL
        configuration.schemaVersion = schemaVersion
        configuration.migrationBlock = { migration, oldSchemaVersion in
            // deleteRealmIfMigrationNeeded はユーザーの保存画像を消してしまうため使わない。
            if oldSchemaVersion < 2 {
                var objects: [MigrationObject] = []
                migration.enumerateObjects(ofType: RealmPhoto.className()) { _, new in
                    if let new = new { objects.append(new) }
                }
                let dates = RealmManager.migrationDates(count: objects.count, endingAt: Date())
                for (object, date) in zip(objects, dates) {
                    object["pastedAt"] = date
                }
            }
        }
        configuration.objectTypes = [RealmPhoto.self]
        // 削除しても Realm のファイルは縮まない。肥大すると端末バックアップの容量を
        // 圧迫し、利用者に「このアプリのバックアップ」を切られる。
        // 10MB を超え、かつ半分以上が使われていない場合だけ起動時に詰める。
        configuration.shouldCompactOnLaunch = { totalBytes, usedBytes in
            let tenMB = 10 * 1024 * 1024
            return totalBytes > tenMB && Double(usedBytes) / Double(totalBytes) < 0.5
        }
        return configuration
    }

    private static func containerURL() -> URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return url
        }
        // App Group が使えない環境でも起動は継続させる(拡張とのデータ共有はできない)
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }

    /// 端末ロック中でもキーボード拡張からRealmを開けるようにする
    private static func applyFileProtection(to directory: URL) {
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: directory.path
        )
    }

    // MARK: - 旧ロケール別ファイルの統合

    /// 旧バージョンは端末のロケールで db.realm.jp / db.realm.world を切り替えていたため、
    /// 言語設定を変えると保存済みの画像が消えたように見えていた。初回起動時に1つのファイルへ統合する。
    static func consolidateLegacyFilesIfNeeded(container: URL, target: URL) {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: target.path) else { return }

        let legacyURLs = orderedLegacyURLs(container: container)
            .filter { fileManager.fileExists(atPath: $0.path) }
        guard let primary = legacyURLs.first else { return }

        // 直接 target へ書くと途中で失敗したときに壊れたファイルが残り、次回以降は
        // 「statごと存在する」ため統合がスキップされて永久に復旧できなくなる。
        // 一時ファイルへ書いてから原子的に差し替える。
        let temporaryURL = target.appendingPathExtension("tmp")
        try? fileManager.removeItem(at: temporaryURL)
        do {
            let migrated = try openMigratedLegacyCopy(of: primary)
            defer { migrated.cleanup() }
            try migrated.realm.writeCopy(toFile: temporaryURL)
            try fileManager.moveItem(at: temporaryURL, to: target)
        } catch {
            // 統合できない場合は空のファイルとして開始する(旧ファイルは残すので復旧は可能)
            try? fileManager.removeItem(at: temporaryURL)
            return
        }

        for url in legacyURLs.dropFirst() {
            importPhotos(from: url, into: target)
        }
    }

    /// 旧ファイルの原本には触れず、書き込み可能な一時複製を移行してから開く。
    ///
    /// readOnly で開くと realm-core は移行(migrationBlock)を実行できず、
    /// pastedAt を足した今回のスキーマ差分で SchemaMismatchException になり、
    /// 呼び出し側の catch で握りつぶされて「統合できなかった」= 空の統合先ができてしまう。
    /// 原本はロケール統合前の唯一のコピーなので、書き換えずに複製側だけ移行する。
    private static func openMigratedLegacyCopy(of source: URL) throws -> (realm: Realm, cleanup: () -> Void) {
        let fileManager = FileManager.default
        let copyURL = source.deletingLastPathComponent()
            .appendingPathComponent(".legacy-migrating-\(UUID().uuidString).realm")
        try fileManager.copyItem(at: source, to: copyURL)
        let cleanup: () -> Void = { try? fileManager.removeItem(at: copyURL) }
        do {
            let realm = try Realm(configuration: makeConfiguration(fileURL: copyURL))
            return (realm, cleanup)
        } catch {
            cleanup()
            throw error
        }
    }

    /// 現在のロケールに対応するファイルを優先して統合元にする
    private static func orderedLegacyURLs(container: URL) -> [URL] {
        let names: [String]
        if Lang.rootKey() == Lang.japaneseRootKey {
            names = [legacyJPFileName, legacyWorldFileName, legacyOriginalFileName]
        } else {
            names = [legacyWorldFileName, legacyJPFileName, legacyOriginalFileName]
        }
        return names.map { container.appendingPathComponent($0) }
    }

    private static func importPhotos(from source: URL, into target: URL) {
        do {
            let migratedSource = try openMigratedLegacyCopy(of: source)
            defer { migratedSource.cleanup() }
            let targetRealm = try Realm(configuration: makeConfiguration(fileURL: target))
            let existingIds = Set(targetRealm.objects(RealmPhoto.self).map { $0.id })
            let missing = migratedSource.realm.objects(RealmPhoto.self).filter { !existingIds.contains($0.id) }
            guard !missing.isEmpty else { return }
            try targetRealm.write {
                for photo in missing {
                    targetRealm.create(RealmPhoto.self, value: photo, update: .modified)
                }
            }
        } catch {
            // 取り込めなかった旧ファイルはそのまま残す
        }
    }

    // MARK: - 変更通知

    private func startObserving() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let realm = self.realm()
            self.observedRealm = realm
            // Realm 全体ではなく写真の一覧を監視し、件数が変わったときだけ通知する。
            // 画像のコピーで useNum を更新するたびに reloadData が走ると、選択直後に
            // セルが作り直されて再生中のアニメーションが別の写真のセルへ引き継がれてしまう。
            self.token = realm.objects(RealmPhoto.self).observe { [weak self] changes in
                switch changes {
                case .update(_, let deletions, let insertions, _):
                    guard !deletions.isEmpty || !insertions.isEmpty else { return }
                    self?.delegate?.realmObjectDidChange()
                case .initial, .error:
                    break
                }
            }
        }
    }

    // MARK: - CRUD

    // データを保存するための処理
    /// 保存できる枚数の上限。見本画像も数に入れる。
    ///
    /// 上限は制限ではなく道具の性格として置いている(DESIGN.md)。
    /// 厳選して持ち歩くという建て付けなので、数を増やす導線は今は用意していない。
    public static let photoLimit = 8

    /// 無料枠が数える枚数を求める。
    ///
    /// 見本画像も枠を消費する。例外を設けると「8枚のはずが9枚入る」ことになり、
    /// 上限の説明が破綻する。見本が要らない利用者は消せば枠が1つ空く。
    static func countTowardQuota(_ photos: [RealmPhoto]) -> Int {
        return photos.count
    }

    /// 利用者自身が保存した枚数。オンボーディングの進捗判定に使う。
    ///
    /// 見本は起動時に自動で入るため、無料枠の判定(`countTowardQuota`)とは別物。
    /// 混ぜると「1枚も入れていない人」を表現できなくなる。
    public var userOwnedPhotoCount: Int {
        return realmData.filter { $0.isUserOwned }.count
    }

    /// 無料枠が数えている枚数
    public var savedPhotoCount: Int {
        return RealmManager.countTowardQuota(Array(realmData))
    }

    /// あと1枚保存できるか。見本画像も枠を消費する。
    /// なお見本の投入(seedTutorialPhotoIfNeeded)はこの判定を通さない
    public var canSaveMorePhotos: Bool {
        return savedPhotoCount < RealmManager.photoLimit
    }

    public func save(data: RealmPhoto, success: @escaping () -> Void, failure: @escaping (String) -> Void) {
        guard let realm = diskRealm() else {
            failure("failure save...")
            return
        }
        do {
            try realm.write {
                realm.add(data, update: .modified)
            }
            success()
        } catch {
            failure("failure save...")
        }
    }

    // データを更新するための処理
    public func update(data: RealmPhoto, success: @escaping () -> Void, failure: @escaping (String) -> Void) {
        guard let realm = diskRealm() else {
            failure("failure update...")
            return
        }
        do {
            try realm.write {
                realm.add(data, update: .modified)
            }
            success()
        } catch {
            failure("failure update...")
        }
    }

    /// 使用回数だけを更新する。
    /// 未管理のコピーを作って上書きすると `image` の setter が走ってJPEGを再エンコードするため、
    /// 使うたびに画質が劣化し、キーボード拡張ではデコード/エンコードでメモリも消費する。
    public func incrementUseNum(id: String) {
        guard let realm = diskRealm(),
              let photo = realm.object(ofType: RealmPhoto.self, forPrimaryKey: id) else { return }
        try? realm.write {
            photo.useNum += 1
        }
    }

    // データを削除するための処理
    public func delete(docId: String, success: @escaping () -> Void, failure: @escaping (String) -> Void) {
        guard let realm = diskRealm() else {
            failure("failure delete...")
            return
        }
        do {
            guard let currentData = realm.object(ofType: RealmPhoto.self, forPrimaryKey: docId) else {
                success()
                return
            }
            try realm.write {
                realm.delete(currentData)
            }
            success()
        } catch {
            failure("failure delete...")
        }
    }
}

#if DEBUG
/// テスト専用。`pastedAt` を持たない旧スキーマの RealmPhoto 相当。
/// `_realmObjectName` で永続化上の型名を "RealmPhoto" に固定することで、
/// 本番の `RealmPhoto` 用スキーマとして移行(migrationBlock)を実際に走らせられる。
final class LegacyRealmPhotoFixture: Object {
    @objc dynamic var id = ""
    @objc dynamic var text = ""
    @objc dynamic var getDay = ""
    @objc dynamic var useNum = 0
    @objc dynamic var isPublic = false
    @objc dynamic var imageHeight = 0
    @objc dynamic var imageWidth = 0
    @objc dynamic var ownerId = ""

    override class func _realmObjectName() -> String { return "RealmPhoto" }
    override class func primaryKey() -> String? { return "id" }
}

extension RealmManager {
    /// `pastedAt` の無い旧スキーマのファイルを、指定した id の順番で書き込む。
    /// 「本番の移行を通しても写真が消えず、順番どおりに pastedAt が入る」ことを
    /// 確かめる移行テスト専用のヘルパー。
    static func writeLegacyFixture(ids: [String], schemaVersion: UInt64, to url: URL) throws {
        var configuration = Realm.Configuration()
        configuration.fileURL = url
        configuration.schemaVersion = schemaVersion
        configuration.objectTypes = [LegacyRealmPhotoFixture.self]
        // Realm はパスごとにインスタンスをキャッシュしており、スコープを抜けても
        // 自動解放プールが片付くまで生き続けることがある。生きたままだと、この直後に
        // 同じパスを別スキーマで開いたとき、そのキャッシュされたスキーマ情報が
        // 使い回されてしまう(新しい型が「管理されていない」ことになる)。
        // autoreleasepool で確実にここで解放してから返す。
        try autoreleasepool {
            let realm = try Realm(configuration: configuration)
            try realm.write {
                for id in ids {
                    let fixture = LegacyRealmPhotoFixture()
                    fixture.id = id
                    realm.add(fixture)
                }
            }
        }
    }
}
#endif
