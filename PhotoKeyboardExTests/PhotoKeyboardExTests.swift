//
//  PhotoKeyboardExTests.swift
//  PhotoKeyboardExTests
//
//  Created by Hiroki Taniguchi on 2019/07/29.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import XCTest
import UIKit
@testable import PhotoKeyboardEx

class PhotoKeyboardExTests: XCTestCase {

    // MARK: - 一覧セルの高さ

    /// セルの高さは画像の実寸ではなく縦横比から決めること。
    /// 画像ビューに高さの制約が無いと、画像が読み込み済みかどうかで高さが変わり、
    /// キャッシュ済みのタブだけ極端に高くなる(1080pxの画像で1080ptのセルになる)。
    func testAspectRatioIsClampedSoCellsDoNotBecomeTall() {
        let tall = PhotoCollectionViewCell.aspectRatio(imageWidth: 100, imageHeight: 1000)
        XCTAssertLessThanOrEqual(tall, 1.6, "縦長画像でセルが極端に高くなる")

        let wide = PhotoCollectionViewCell.aspectRatio(imageWidth: 1000, imageHeight: 100)
        XCTAssertGreaterThanOrEqual(wide, 0.6, "横長画像でセルが極端に低くなる")
    }

    /// 制限の範囲内なら元の縦横比をそのまま使うこと
    func testAspectRatioKeepsNaturalShapeWithinLimits() {
        XCTAssertEqual(PhotoCollectionViewCell.aspectRatio(imageWidth: 1000, imageHeight: 1000), 1.0)
        XCTAssertEqual(PhotoCollectionViewCell.aspectRatio(imageWidth: 1000, imageHeight: 1200), 1.2, accuracy: 0.001)
        XCTAssertEqual(PhotoCollectionViewCell.aspectRatio(imageWidth: 1200, imageHeight: 1000), 1000.0 / 1200.0, accuracy: 0.001)
    }

    /// 寸法が入っていない古いデータでも破綻しないこと
    func testAspectRatioFallsBackToSquareForMissingSize() {
        XCTAssertEqual(PhotoCollectionViewCell.aspectRatio(imageWidth: 0, imageHeight: 0), 1.0)
        XCTAssertEqual(PhotoCollectionViewCell.aspectRatio(imageWidth: -1, imageHeight: 100), 1.0)
    }

    // MARK: - バージョン比較

    /// メジャー番号を無視すると、端末の方が新しいのに更新を促してしまう
    func testVersionComparison() {
        XCTAssertTrue(AppDelegate.isVersion("1.0.0", olderThan: "1.0.1"))
        XCTAssertTrue(AppDelegate.isVersion("1.9.0", olderThan: "2.0.0"))
        XCTAssertFalse(AppDelegate.isVersion("2.0.0", olderThan: "1.9.0"))
        XCTAssertFalse(AppDelegate.isVersion("1.2.3", olderThan: "1.2.3"))
        XCTAssertTrue(AppDelegate.isVersion("1.2", olderThan: "1.2.1"))
    }
}
