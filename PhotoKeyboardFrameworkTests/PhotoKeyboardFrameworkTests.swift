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

    override func tearDown() {
        UIPasteboard.general.items = []
        super.tearDown()
    }

    private func makeImage(size: CGSize = CGSize(width: 40, height: 40)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
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

    // MARK: - 保存ライフ

    /// 広告視聴の報酬は加算されること。上書きすると報酬量が既存より少ないときに減ってしまう
    func testChargeSaveLifeAdds() {
        let defaults = GroupeDefaults.shared
        while !defaults.isAddCount() {
            defaults.useSaveLife()
        }
        defaults.chargeSaveLife(amount: 3)
        XCTAssertFalse(defaults.isAddCount(), "報酬を加算してもライフが回復していない")

        defaults.chargeSaveLife(amount: 1)
        defaults.useSaveLife()
        defaults.useSaveLife()
        defaults.useSaveLife()
        XCTAssertFalse(defaults.isAddCount(), "加算ではなく上書きになっている")
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
}
