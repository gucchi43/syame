//
//  PhotoKeyboardExTests.swift
//  PhotoKeyboardExTests
//
//  Created by Hiroki Taniguchi on 2019/07/29.
//  Copyright © 2019 Hiroki Taniguchi. All rights reserved.
//

import XCTest
import UIKit
import PhotoKeyboardFramework
@testable import PhotoKeyboardEx

class PhotoKeyboardExTests: XCTestCase {

    // MARK: - 一覧のグリッド

    /// 高さを可変にすると同じ行の2つのセルで高さが揃わず隙間ができるため、
    /// 画面幅から一定の大きさを算出して全セルで共有する
    func testGridMetricsFitsTwoColumnsWithinContainer() {
        let containerWidth: CGFloat = 393
        let metrics = ChildContentViewController.gridMetrics(containerWidth: containerWidth)

        // 左右の余白8 + 列間8 + 2列ぶんの幅が画面幅に収まること
        let used = metrics.itemWidth * 2 + 8 * 3
        XCTAssertLessThanOrEqual(used, containerWidth)
        XCTAssertGreaterThan(metrics.itemWidth, 0)
    }

    /// 行の高さは正方形の画像 + 情報エリアで決まること
    func testGridRowHeightIsImagePlusInfoArea() {
        let metrics = ChildContentViewController.gridMetrics(containerWidth: 393)
        XCTAssertEqual(metrics.rowHeight, metrics.itemWidth + 68, accuracy: 0.001)
    }

    /// 幅が極端に狭くても破綻しないこと
    func testGridMetricsHandlesTinyContainer() {
        let metrics = ChildContentViewController.gridMetrics(containerWidth: 10)
        XCTAssertGreaterThan(metrics.itemWidth, 0)
        XCTAssertGreaterThan(metrics.rowHeight, 0)
    }

    /// セル幅に端数が出ると、2列ぶんの合計が1px溢れて2列目が次の行に落ちる。
    /// 端末幅ごとにレイアウトが崩れるのを防ぐため整数に丸める
    func testGridMetricsItemWidthIsIntegral() {
        // 実機で使われる代表的な画面幅(SE / 標準 / Plus / iPad)
        for width in [320, 375, 390, 393, 428, 430, 744, 1024] as [CGFloat] {
            let metrics = ChildContentViewController.gridMetrics(containerWidth: width)
            XCTAssertEqual(metrics.itemWidth, metrics.itemWidth.rounded(.down),
                           "幅 \(width) でセル幅に端数が出ている")
            XCTAssertLessThanOrEqual(metrics.itemWidth * 2 + 8 * 3, width,
                                     "幅 \(width) で2列が収まらない")
        }
    }

    /// 画面が広くなればセルも広がること。固定値に戻すとiPadで極端に小さいセルになる
    func testGridMetricsGrowsWithContainerWidth() {
        let narrow = ChildContentViewController.gridMetrics(containerWidth: 375)
        let wide = ChildContentViewController.gridMetrics(containerWidth: 1024)
        XCTAssertGreaterThan(wide.itemWidth, narrow.itemWidth)
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

    /// 文字列比較にすると "1.10.0" < "1.9.0" と判定され、
    /// マイナー番号が二桁に入った瞬間に全ユーザーへ更新ダイアログが出続ける
    func testVersionComparisonIsNumericNotLexicographic() {
        XCTAssertTrue(AppDelegate.isVersion("1.9.0", olderThan: "1.10.0"))
        XCTAssertFalse(AppDelegate.isVersion("1.10.0", olderThan: "1.9.0"))
        XCTAssertTrue(AppDelegate.isVersion("1.2.9", olderThan: "1.2.10"))
    }

    /// 桁数が違うバージョン表記でも比較できること。
    /// 同値を「古い」と判定すると、最新版なのに毎回更新を促してしまう
    func testVersionComparisonHandlesDifferentComponentCounts() {
        XCTAssertFalse(AppDelegate.isVersion("1.2.0", olderThan: "1.2"), "1.2.0 と 1.2 は同じ")
        XCTAssertFalse(AppDelegate.isVersion("1.2", olderThan: "1.2.0"), "1.2 と 1.2.0 は同じ")
        XCTAssertTrue(AppDelegate.isVersion("1.2", olderThan: "1.3"))
        XCTAssertTrue(AppDelegate.isVersion("1.2.0", olderThan: "1.2.0.1"))
        XCTAssertFalse(AppDelegate.isVersion("1.2.0.1", olderThan: "1.2.0"))
    }

    /// バージョン取得に失敗した場合など、想定外の文字列でもクラッシュしないこと
    func testVersionComparisonHandlesMalformedInput() {
        XCTAssertFalse(AppDelegate.isVersion("", olderThan: ""))
        XCTAssertTrue(AppDelegate.isVersion("", olderThan: "1.0.0"))
        XCTAssertFalse(AppDelegate.isVersion("1.0.0", olderThan: ""))
    }

    // MARK: - 公開投稿の停止

    /// 一般ユーザーの公開投稿は著作権リスクの源泉のため停止した。
    /// 既定値がtrueに戻ると、投稿がそのままサーバへ上がってしまう。
    @MainActor
    func testPublicPostingIsDisabledByDefault() {
        let controller = AddViewController()
        XCTAssertFalse(controller.publicFlag,
                       "公開投稿が有効に戻っている。画像がサーバへアップロードされる")
    }

    // MARK: - 投稿画像の縮小

    /// 元画像より大きくしても画質は上がらず、アップロードサイズだけが無駄に増える
    @MainActor
    func testConvertedImageSizeDoesNotUpscaleSmallImage() {
        let controller = AddViewController()
        let small = CGSize(width: 320, height: 240)
        XCTAssertEqual(controller.convertedImageSize(size: small), small)
    }

    /// 大きい画像は縮小し、かつ縦横比を保つこと。崩れると投稿画像が歪む
    @MainActor
    func testConvertedImageSizeShrinksLargeImageKeepingAspectRatio() {
        let controller = AddViewController()
        let source = CGSize(width: 4000, height: 3000)
        let converted = controller.convertedImageSize(size: source)

        XCTAssertLessThan(max(converted.width, converted.height), max(source.width, source.height),
                          "大きい画像が縮小されていない。アップロードとメモリ消費が跳ね上がる")
        XCTAssertEqual(converted.width / converted.height,
                       source.width / source.height,
                       accuracy: 0.001,
                       "縦横比が保たれていない")
    }

    /// 空の画像サイズでゼロ除算やNaNにならないこと
    @MainActor
    func testConvertedImageSizeHandlesZeroSize() {
        let controller = AddViewController()
        let converted = controller.convertedImageSize(size: .zero)
        XCTAssertEqual(converted, .zero)
    }
}
