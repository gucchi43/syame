//
//  PhotoKeyboardFrameworkTests.swift
//  PhotoKeyboardFrameworkTests
//
//  Created by Hiroki Taniguchi on 2019/08/04.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import XCTest
import UIKit
@testable import PhotoKeyboardFramework

class PhotoKeyboardFrameworkTests: XCTestCase {

    /// GroupeDefaults は App Group の UserDefaults を直接読み書きするため、
    /// テストが実行端末に残った値に影響されたり、逆に残してしまったりしないよう
    /// 各テストの前に消し、後で元に戻す。
    /// ここの文字列は GroupeDefaults.Keys の rawValue と一致していなければならない
    /// (キー名を変えると既存ユーザーの保存値が失われるため、変更時はこのテストも落ちてよい)。
    private static let managedDefaultsKeys = [
        "sendCount",
        "registerNeedFlag", "usageNeedFlag", "welcomeNeedFlag",
        "blockContents"
    ]
    private var savedDefaults: [String: Any] = [:]

    override func setUp() {
        super.setUp()
        let defaults = GroupeDefaults.shared.sharedDefaults
        savedDefaults = [:]
        for key in Self.managedDefaultsKeys {
            if let value = defaults.object(forKey: key) {
                savedDefaults[key] = value
            }
            defaults.removeObject(forKey: key)
        }
    }

    override func tearDown() {
        let defaults = GroupeDefaults.shared.sharedDefaults
        for key in Self.managedDefaultsKeys {
            if let value = savedDefaults[key] {
                defaults.set(value, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }
        UIPasteboard.general.items = []
        super.tearDown()
    }

    /// 既定のレンダラーはデバイススケール(3x)で描画するため、ポイント寸法とピクセル寸法が
    /// 食い違って検証しづらい。テストでは等倍に固定する。
    private func makeImage(size: CGSize = CGSize(width: 40, height: 40),
                           color: UIColor = .red) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// 画像の指定ピクセル(左上原点)の色を取り出す。合成位置の検証に使う。
    private func rgb(of image: UIImage, x: Int, y: Int) -> (r: Int, g: Int, b: Int)? {
        guard let cropped = image.cgImage?.cropping(to: CGRect(x: x, y: y, width: 1, height: 1)) else {
            return nil
        }
        var pixel = [UInt8](repeating: 0, count: 4)
        guard let context = CGContext(data: &pixel,
                                      width: 1,
                                      height: 1,
                                      bitsPerComponent: 8,
                                      bytesPerRow: 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return (Int(pixel[0]), Int(pixel[1]), Int(pixel[2]))
    }

    // MARK: - ペーストボード

    /// キーボードでコピーした画像が、貼り付ける側から画像として取り出せること
    func testCopyToGeneralPasteboardProducesPastableImage() {
        UIPasteboard.general.items = []
        let image = makeImage()

        image.copyToGeneralPasteboard()

        let pasted = UIPasteboard.general.image
        XCTAssertNotNil(pasted, "ペーストボードから画像を取り出せない。貼り付けできない状態になっている")
        XCTAssertTrue(UIPasteboard.general.hasImages)
        XCTAssertEqual(pasted?.size, image.size)
    }

    /// 回帰防止。
    /// `UIPasteboard.typeListImage` は `NSArray` として取り込まれるため、`.first` は要素を返す
    /// プロパティではなく `first(where:)` メソッドを指す。`as? String` は常に nil になり、
    /// これを guard の条件に使うとペーストボードへ一切書き込まないまま処理が終わる。
    /// 「コピーしたのに貼り付けできない」不具合の原因がこれだった。
    func testTypeListImageFirstIsNotUsableAsString() {
        XCTAssertNil(UIPasteboard.typeListImage.first as? String,
                     "`.first as? String` が値を返すようになった。コピー処理の書き方を見直せる")
        XCTAssertEqual(UIPasteboard.typeListImage[0] as? String, "public.png",
                       "要素を取り出すなら添字を使うこと")
    }

    // MARK: - ロケール判定

    /// rootKey と langRootKey が食い違うと、UIの言語とデータの参照先がずれる
    func testRootKeyAndLangRootKeyAreConsistent() {
        XCTAssertEqual(Lang.rootKey(), Lang.langRootKey())
        XCTAssertTrue([Lang.japaneseRootKey, Lang.worldRootKey].contains(Lang.rootKey()))
    }

    // MARK: - 画像

    /// 一覧表示ではフル解像度をデコードせず、指定した最大辺に収まる縮小版を返すこと
    func testThumbnailIsDownsampled() {
        let photo = RealmPhoto.create(id: UUID().uuidString,
                                      text: "test",
                                      image: makeImage(size: CGSize(width: 600, height: 600)),
                                      imageHeight: 600,
                                      imageWidth: 600,
                                      getDay: "",
                                      isPublic: false,
                                      ownerId: "")

        guard let thumbnail = photo.thumbnail(maxPixelSize: 100) else {
            return XCTFail("サムネイルを生成できなかった")
        }
        XCTAssertLessThanOrEqual(max(thumbnail.size.width, thumbnail.size.height), 100)
    }

    /// 保存時の圧縮率を下げすぎると投稿画像にブロックノイズが出る
    func testJpegCompressionQualityIsHighEnough() {
        XCTAssertGreaterThanOrEqual(RealmPhoto.jpegCompressionQuality, 0.8,
                                    "圧縮率を下げると投稿画像の画質が目に見えて劣化する")
    }

    /// 保存に使うJPEG変換で解像度が落ちないこと(圧縮はされるが寸法は維持される)
    func testJpegRoundTripKeepsPixelSize() {
        let original = makeImage(size: CGSize(width: 1080, height: 720))
        guard let data = original.jpegData(compressionQuality: RealmPhoto.jpegCompressionQuality),
              let decoded = UIImage(data: data) else {
            return XCTFail("JPEGへの変換または復元に失敗した")
        }
        XCTAssertEqual(decoded.size, original.size)
    }

    /// composite はデバイススケールではなく等倍で描画すること。
    /// scale が 3 になると 9 倍のピクセル数になり、キーボード拡張がメモリ上限を超える
    func testCompositeKeepsPixelSize() {
        let base = makeImage(size: CGSize(width: 200, height: 200))
        let logo = makeImage(size: CGSize(width: 20, height: 20))

        guard let composited = base.composite(image: logo, rate: 1.0) else {
            return XCTFail("合成に失敗した")
        }
        XCTAssertEqual(composited.scale, 1.0)
        XCTAssertEqual(composited.size, base.size)
    }

    /// ロゴは必ず右下に重ねる。位置の計算を誤ると被写体の上にロゴが乗ってしまう
    func testCompositePlacesOverlayAtBottomRight() {
        let base = makeImage(size: CGSize(width: 100, height: 100), color: .red)
        let logo = makeImage(size: CGSize(width: 20, height: 20), color: .blue)

        guard let composited = base.composite(image: logo, rate: 1.0) else {
            return XCTFail("合成に失敗した")
        }

        guard let bottomRight = rgb(of: composited, x: 90, y: 90),
              let topLeft = rgb(of: composited, x: 10, y: 10) else {
            return XCTFail("合成後の画像から色を取り出せなかった")
        }
        XCTAssertGreaterThan(bottomRight.b, bottomRight.r, "右下にロゴが描かれていない")
        XCTAssertGreaterThan(topLeft.r, topLeft.b, "左上まで塗りつぶされている。元画像が隠れる")
    }

    /// rate はロゴの縮小率。効いていないと小さい画像でロゴが画面いっぱいになる
    func testCompositeRateShrinksOverlay() {
        let base = makeImage(size: CGSize(width: 100, height: 100), color: .red)
        let logo = makeImage(size: CGSize(width: 20, height: 20), color: .blue)

        guard let composited = base.composite(image: logo, rate: 0.5) else {
            return XCTFail("合成に失敗した")
        }

        // rate 0.5 なら 10x10 になるので (95,95) はロゴ、(85,85) は元画像のまま
        guard let inside = rgb(of: composited, x: 95, y: 95),
              let outside = rgb(of: composited, x: 85, y: 85) else {
            return XCTFail("合成後の画像から色を取り出せなかった")
        }
        XCTAssertGreaterThan(inside.b, inside.r, "縮小後のロゴが右下に描かれていない")
        XCTAssertGreaterThan(outside.r, outside.b, "rate が無視されロゴが縮小されていない")
    }

    /// 投稿画像は長辺を指定枠に収めて縮小する。比率が崩れると投稿画像が歪む
    func testResizeKeepsAspectRatioAndFitsInBox() {
        let original = makeImage(size: CGSize(width: 800, height: 400))

        guard let resized = original.resize(size: CGSize(width: 200, height: 200)) else {
            return XCTFail("リサイズに失敗した")
        }
        XCTAssertEqual(resized.size.width, 200, accuracy: 0.5)
        XCTAssertEqual(resized.size.height, 100, accuracy: 0.5, "縦横比が保たれていない")
        XCTAssertLessThanOrEqual(resized.size.width, 200)
        XCTAssertLessThanOrEqual(resized.size.height, 200)
    }

    /// resize もデバイススケールではなく等倍で描画すること。
    /// 3x端末で 9 倍のピクセル数になると投稿画像が無駄に重くなる
    func testResizeKeepsScaleAtOne() {
        let original = makeImage(size: CGSize(width: 800, height: 400))

        guard let resized = original.resize(size: CGSize(width: 200, height: 200)) else {
            return XCTFail("リサイズに失敗した")
        }
        XCTAssertEqual(resized.scale, 1.0)
    }

    // MARK: - ジャンルタグ

    /// getKey() の戻り値はSupabaseの genre カラムにそのまま入る。
    /// 変えると過去の投稿がそのタブに出てこなくなる
    func testGenreTagKeysAreStable() {
        let expected: [GenreTagType: String] = [
            .myBoard: "myBoard",
            .new: "new",
            .popular: "popular",
            .humor: "humor",
            .cool: "cool",
            .cute: "cute",
            .serious: "serious",
            .other: "other"
        ]
        for type in GenreTagType.allCases {
            XCTAssertEqual(type.getKey(), expected[type],
                           "\(type) のキーが変わった。既存の投稿が取得できなくなる")
        }
    }

    /// キーが重複するとタブをまたいで同じ投稿が出たり、取得条件が衝突したりする
    func testGenreTagKeysAreUnique() {
        let keys = GenreTagType.allCases.map { $0.getKey() }
        XCTAssertEqual(Set(keys).count, keys.count)
    }

    /// タブの並びは MainTabViewController の titles 配列(8件・固定順)と対応している。
    /// 件数や順序が変わると見出しと中身がずれ、配列の範囲外アクセスにもなる
    func testGenreTagOrderAndCountMatchesTabLayout() {
        XCTAssertEqual(GenreTagType.getAllGenreTags(),
                       [.myBoard, .new, .popular, .humor, .cool, .cute, .serious, .other],
                       "タブの並びを変えるなら MainTabViewController の titles も直すこと")
        XCTAssertEqual(GenreTagType.getAllGenreTags().count, 8)
    }

    /// 投稿画面のタグは表示文字列から型に戻して保存する。
    /// 往復できないとジャンルを選んでも投稿ボタンが有効にならない
    func testGetTypeFromTitleRoundTripsForAllCases() {
        for type in GenreTagType.allCases {
            XCTAssertEqual(GenreTagType.getTypeFromTitle(title: type.getLocalizeString()), type,
                           "\(type) の表示文字列から型に戻せない")
        }
    }

    /// 未知の文字列で nil を返さないと、無関係なタップでジャンルが確定してしまう
    func testGetTypeFromTitleReturnsNilForUnknownTitle() {
        XCTAssertNil(GenreTagType.getTypeFromTitle(title: "存在しないジャンル"))
        XCTAssertNil(GenreTagType.getTypeFromTitle(title: ""))
    }

    /// ローカライズが欠けると getLocalizeString() がキー名や空文字を返し、
    /// getTypeFromTitle() の一致判定が崩れてタグを選べなくなる
    func testGenreLocalizedTitlesArePresentAndUnique() {
        let titles = GenreTagType.allCases.map { $0.getLocalizeString() }
        for (type, title) in zip(GenreTagType.allCases, titles) {
            XCTAssertFalse(title.isEmpty, "\(type) の訳が空")
            XCTAssertFalse(title.hasPrefix("subGenre") || title.hasPrefix("genre"),
                           "\(type) の訳が見つからずキー名がそのまま返っている")
        }
        XCTAssertEqual(Set(titles).count, titles.count, "表示文字列が重複すると型に戻せない")
    }

    /// 投稿画面に出すジャンルは、ユーザーが投稿先に選べないマイボード・新着・人気を除いたもの。
    /// removeSubrange(0...2) は並び順に依存しているため、並びを変えると誤ったタグが消える
    func testGetAddAllGenreTitlesExcludesMyBoardNewAndPopular() {
        let titles = GenreTagType.getAddAllGenreTitles()
        XCTAssertEqual(titles,
                       [GenreTagType.humor, .cool, .cute, .serious, .other].map { $0.getLocalizeString() })
        XCTAssertFalse(titles.contains(GenreTagType.myBoard.getLocalizeString()))
        XCTAssertFalse(titles.contains(GenreTagType.new.getLocalizeString()))
        XCTAssertFalse(titles.contains(GenreTagType.popular.getLocalizeString()))
    }

    /// 同じコンテンツを何度ブロックしてもリストは1件。
    /// 重複するとブロック一覧が際限なく膨らみ、一覧のフィルタが重くなる
    func testAddBlockContentsIgnoresDuplicates() {
        let defaults = GroupeDefaults.shared
        defaults.addBlockContents(id: "photo-1")
        defaults.addBlockContents(id: "photo-1")
        defaults.addBlockContents(id: "photo-2")

        XCTAssertEqual(defaults.getBlockContens(), ["photo-1", "photo-2"])
    }

    /// ブロックしていない状態でも空配列を返すこと(nilでクラッシュしない)
    func testGetBlockContentsIsEmptyByDefault() {
        XCTAssertEqual(GroupeDefaults.shared.getBlockContens(), [])
    }

    /// オンボーディングは初回だけ出す。
    /// 初期値が false になると一度も表示されず、キーボードの設定方法を案内できない
    func testOnboardingFlagsAreOnBeforeFirstRunAndOffAfterDone() {
        let defaults = GroupeDefaults.shared
        XCTAssertTrue(defaults.isRegisterPush())
        XCTAssertTrue(defaults.isUsagePush())
        XCTAssertTrue(defaults.isWelcomePush())

        defaults.registerDone()
        defaults.usageDone()
        defaults.welcomeDone()

        XCTAssertFalse(defaults.isRegisterPush(), "完了後も登録画面が出続ける")
        XCTAssertFalse(defaults.isUsagePush(), "完了後も使い方画面が出続ける")
        XCTAssertFalse(defaults.isWelcomePush(), "完了後もウェルカム画面が出続ける")
    }

    /// レビュー依頼は送信8回目で1度だけ。
    /// カウンタをリセットしないと以降の起動で毎回ダイアログが出る
    func testRateAlertFiresOnceAfterEightSendsAndResets() {
        let defaults = GroupeDefaults.shared
        for _ in 0..<7 {
            defaults.incrementSendCount()
            XCTAssertFalse(defaults.isRateAlert(), "7回以下でレビュー依頼が出ている")
        }
        defaults.incrementSendCount()
        XCTAssertTrue(defaults.isRateAlert(), "8回送ってもレビュー依頼が出ない")
        XCTAssertFalse(defaults.isRateAlert(), "カウンタがリセットされず毎回レビュー依頼が出る")
    }

    // MARK: - サムネイルのキャッシュ

    private func makePhoto(size: CGSize) -> RealmPhoto {
        return RealmPhoto.create(id: UUID().uuidString,
                                 text: "test",
                                 image: makeImage(size: size),
                                 imageHeight: Int(size.height),
                                 imageWidth: Int(size.width),
                                 getDay: "",
                                 isPublic: false,
                                 ownerId: "")
    }

    /// 2回目以降はキャッシュを返すこと。毎回デコードすると一覧のスクロールがカクつく
    func testThumbnailIsCachedBetweenCalls() {
        let photo = makePhoto(size: CGSize(width: 600, height: 600))

        guard let first = photo.thumbnail(maxPixelSize: 120) else {
            return XCTFail("サムネイルを生成できなかった")
        }
        let second = photo.thumbnail(maxPixelSize: 120)
        XCTAssertTrue(first === second, "同じ要求のたびに再デコードしている")
    }

    /// キャッシュキーにサイズが入っていないと、拡大表示で小さいサムネイルが使い回されてぼやける
    func testThumbnailCacheIsKeyedBySize() {
        let photo = makePhoto(size: CGSize(width: 600, height: 600))

        guard let small = photo.thumbnail(maxPixelSize: 100),
              let large = photo.thumbnail(maxPixelSize: 300) else {
            return XCTFail("サムネイルを生成できなかった")
        }
        XCTAssertEqual(max(small.size.width, small.size.height), 100)
        XCTAssertEqual(max(large.size.width, large.size.height), 300)
    }

    /// 縮小しても縦横比を保つこと。崩れると一覧のサムネイルが歪む
    func testThumbnailKeepsAspectRatio() {
        let photo = makePhoto(size: CGSize(width: 600, height: 300))

        guard let thumbnail = photo.thumbnail(maxPixelSize: 100) else {
            return XCTFail("サムネイルを生成できなかった")
        }
        XCTAssertEqual(thumbnail.size.width, 100, accuracy: 1)
        XCTAssertEqual(thumbnail.size.height, 50, accuracy: 1)
    }

    /// 元画像より大きいサイズを要求しても引き伸ばさないこと(無駄なメモリを使わない)
    func testThumbnailDoesNotUpscaleBeyondOriginal() {
        let photo = makePhoto(size: CGSize(width: 80, height: 80))

        guard let thumbnail = photo.thumbnail(maxPixelSize: 400) else {
            return XCTFail("サムネイルを生成できなかった")
        }
        XCTAssertLessThanOrEqual(max(thumbnail.size.width, thumbnail.size.height), 80)
    }

    // MARK: - デザイントークン

    /// 相対輝度からコントラスト比を求める(WCAG 2.1)
    private func contrastRatio(_ a: UIColor, _ b: UIColor, dark: Bool) -> CGFloat {
        let traits = UITraitCollection(userInterfaceStyle: dark ? .dark : .light)
        func luminance(_ color: UIColor) -> CGFloat {
            var r: CGFloat = 0, g: CGFloat = 0, bl: CGFloat = 0, al: CGFloat = 0
            color.resolvedColor(with: traits).getRed(&r, green: &g, blue: &bl, alpha: &al)
            func channel(_ v: CGFloat) -> CGFloat {
                return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(bl)
        }
        let l1 = luminance(a), l2 = luminance(b)
        return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
    }

    /// 本文の文字色は地に対して4.5:1以上必要。
    /// 淡い配色を追求して色を変えると、ここが真っ先に壊れる。
    func testTextColorsMeetContrastRequirement() {
        for dark in [false, true] {
            let mode = dark ? "ダーク" : "ライト"
            XCTAssertGreaterThanOrEqual(contrastRatio(.textPrimary, .bgBase, dark: dark), 4.5,
                                        "\(mode): 本文が地に対して読めない")
            XCTAssertGreaterThanOrEqual(contrastRatio(.textPrimary, .bgSurface, dark: dark), 4.5,
                                        "\(mode): 本文がカード面に対して読めない")
            XCTAssertGreaterThanOrEqual(contrastRatio(.textSecondary, .bgBase, dark: dark), 4.5,
                                        "\(mode): 補足テキストが地に対して読めない")
            XCTAssertGreaterThanOrEqual(contrastRatio(.onAccent, .brandAccent, dark: dark), 4.5,
                                        "\(mode): アクセントで塗ったボタンの文字が読めない")
        }
    }

    /// 地とカード面の差は意図的にごく小さくしている。
    /// ここが開くと「軽さ」が失われ、ただのグレーUIになる。
    func testSurfaceSeparationStaysSubtle() {
        for dark in [false, true] {
            let ratio = contrastRatio(.bgSurface, .bgBase, dark: dark)
            XCTAssertLessThan(ratio, 1.5, "\(dark ? "ダーク" : "ライト"): 面の差が大きすぎる")
        }
    }

    /// 使用するSF Symbolsが実在すること。名前を間違えるとアイコンが消える
    func testAllSymbolsExist() {
        let names = [Symbol.menu, Symbol.saveCount, Symbol.more, Symbol.textMode, Symbol.globe,
                     Symbol.emptyState, Symbol.home, Symbol.imageMode, Symbol.add, Symbol.help,
                     Symbol.sortByName, Symbol.sortByPopularity, Symbol.close]
        for name in names {
            XCTAssertNotNil(UIImage(systemName: name), "SF Symbol が存在しない: \(name)")
        }
    }
}
