//
//  RealmBackup.swift
//  PhotoKeyboardFramework
//
//  App Group のコンテナが消えたときに、画像を取り戻すための仕組み。
//

import Foundation
import RealmSwift

/// 共有コンテナの消失を検知して、アプリ本体のコンテナに置いた複製から戻す。
///
/// 目的はバックアップではなく**自動復旧**である。
/// ペリペリは画像もフラグも App Group のコンテナに置いており、iOS 26 では
/// このコンテナが丸ごと作り直される報告が出ている。作り直されるとファイルは
/// 消えるが、アプリ本体のコンテナ(Application Support)は残る。そこに複製を
/// 置いておけば、次の起動で気付いて戻せる。
///
/// URL を外から渡すのは、一時ディレクトリを使ってテストできるようにするため。
public struct RealmBackup {

    /// 共有コンテナに置く目印。これが消えていたらコンテナが作り直されたと判断する。
    ///
    /// Realm 本体の有無で判定してはいけない。**初回起動と消失の区別がつかず**、
    /// 一度も使っていない利用者にまで復元をかけてしまう。
    private static let canaryFileName = "container.canary"
    private static let snapshotFileName = "db.realm.snapshot"
    /// Realm が本体と一緒に作る補助ファイル。差し替えるときは道連れにする
    private static let auxiliarySuffixes = ["lock", "note", "management"]

    private let snapshotURL: URL
    private let canaryURL: URL
    private let fileManager: FileManager

    public init(appContainer: URL, sharedContainer: URL, fileManager: FileManager = .default) {
        self.snapshotURL = appContainer.appendingPathComponent(RealmBackup.snapshotFileName)
        self.canaryURL = sharedContainer.appendingPathComponent(RealmBackup.canaryFileName)
        self.fileManager = fileManager
    }

    // MARK: - 判定

    /// 共有コンテナが作り直された疑いがあるか
    public var containerWasReset: Bool {
        return !fileManager.fileExists(atPath: canaryURL.path)
    }

    public var hasSnapshot: Bool {
        return fileManager.fileExists(atPath: snapshotURL.path)
    }

    /// 目印が消えていて、かつ戻せる複製があるときだけ復元する。
    /// 初回起動は目印が無いが複製も無いので、ここで false になる。
    public var needsRestore: Bool {
        return containerWasReset && hasSnapshot
    }

    // MARK: - 目印

    /// 共有コンテナが生きていることを記録する。起動のたびに呼んでよい
    @discardableResult
    public func markAlive() -> Bool {
        guard containerWasReset else { return true }
        let directory = canaryURL.deletingLastPathComponent()
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return fileManager.createFile(atPath: canaryURL.path, contents: Data())
    }

    // MARK: - 複製の作成

    /// Realm の複製を作る。
    ///
    /// 単純なファイルコピーでは壊れた複製ができる(書き込み途中の状態を掴みうるうえ、
    /// .note は名前付きパイプでコピー自体が失敗する)。writeCopy が唯一の正しい手段。
    /// writeCopy は出力先が既に在ると失敗するため、一時ファイルに書いてから差し替える。
    public func write(from realm: Realm) throws {
        let directory = snapshotURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let temporaryURL = snapshotURL.appendingPathExtension("tmp")
        try? fileManager.removeItem(at: temporaryURL)
        do {
            try realm.writeCopy(toFile: temporaryURL)
            _ = try fileManager.replaceItemAt(snapshotURL, withItemAt: temporaryURL)
        } catch {
            // 失敗した一時ファイルを残すと、次回の writeCopy が出力先ありで落ち続ける
            try? fileManager.removeItem(at: temporaryURL)
            throw error
        }
    }

    // MARK: - 復元

    /// 複製を Realm の置き場所へ戻す。**Realm を開く前に呼ぶこと。**
    /// 開いたあとに差し替えても、既に握られたファイルハンドルは古いままになる。
    public func restore(to realmURL: URL) throws {
        guard hasSnapshot else { return }
        let directory = realmURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        // 補助ファイルが古い本体を指したまま残ると、開いた瞬間に不整合になる
        for suffix in RealmBackup.auxiliarySuffixes {
            try? fileManager.removeItem(at: realmURL.appendingPathExtension(suffix))
        }
        let temporaryURL = realmURL.appendingPathExtension("restoring")
        try? fileManager.removeItem(at: temporaryURL)
        try fileManager.copyItem(at: snapshotURL, to: temporaryURL)
        if fileManager.fileExists(atPath: realmURL.path) {
            _ = try fileManager.replaceItemAt(realmURL, withItemAt: temporaryURL)
        } else {
            try fileManager.moveItem(at: temporaryURL, to: realmURL)
        }
    }
}

extension RealmBackup {
    /// 指定した場所の Realm を開く。
    ///
    /// Realm.Configuration() の既定引数は Realm 本体(Objective-C 側)のシンボルを
    /// 参照しており、それを呼び出し側に展開する。テスト用バイナリは本体を直接
    /// リンクしていないため、テストの中で Configuration を組むとリンクに失敗する。
    /// 生成をここに寄せることで、呼び出し側は Realm を受け取るだけで済む。
    public static func openRealm(at url: URL) throws -> Realm {
        var configuration = Realm.Configuration()
        configuration.fileURL = url
        configuration.objectTypes = [RealmPhoto.self]
        return try Realm(configuration: configuration)
    }
}
