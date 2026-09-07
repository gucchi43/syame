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

    /// 行の高さは正方形の画像 + 情報エリアで決まること。
    /// 情報エリアの高さはセル側の定義を参照する。数値を直書きすると
    /// セルのレイアウトを変えるたびにここが嘘になる。
    func testGridRowHeightIsImagePlusInfoArea() {
        let metrics = ChildContentViewController.gridMetrics(containerWidth: 393)
        XCTAssertEqual(metrics.rowHeight,
                       metrics.itemWidth + PhotoCollectionViewCell.infoHeight,
                       accuracy: 0.001)
    }

    /// タイトルは2行まで出す。
    /// 見本画像のように説明的な題名が入るため、1行だとほとんど読めないまま省略される
    func testTitleAllowsTwoLines() {
        XCTAssertEqual(PhotoCollectionViewCell.titleLineLimit, 2)
    }

    /// 情報エリアは行数ぶんの高さを確保すること。
    /// 行の高さは絶対値で決めているため、ここが足りないと2行目が切れる
    func testInfoHeightFitsTitleLines() {
        let lineHeight = UIFont.scaled(.footnote).lineHeight
        let needed = lineHeight * CGFloat(PhotoCollectionViewCell.titleLineLimit)
        XCTAssertGreaterThanOrEqual(PhotoCollectionViewCell.infoHeight, needed,
                                    "情報エリアがタイトルの行数ぶんに足りていない")
    }

    /// ラベルに実際に描かれた文字の行数を、描画結果のピクセルから数える。
    ///
    /// textRect(forBounds:limitedToNumberOfLines:) は lineBreakMode による折り返しの有無を
    /// 反映しないため、行数の検証には使えない(2行と答えるのに画面は1行、が起きる)。
    private func renderedLineCount(of label: UILabel) -> Int {
        let size = label.bounds.size
        guard size.width > 0, size.height > 0 else { return 0 }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            label.layer.render(in: context.cgContext)
        }
        guard let cgImage = image.cgImage else { return 0 }

        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height)
        guard let context = CGContext(data: &pixels,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: width,
                                      space: CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            return 0
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // 文字のある行が縦に何本の帯を作るかを数える
        var bands = 0
        var wasInk = false
        for y in 0..<height {
            let hasInk = (0..<width).contains { pixels[y * width + $0] < 200 }
            if hasInk && !wasInk { bands += 1 }
            wasInk = hasInk
        }
        return bands
    }

    private func makeLaidOutCell(title: String) -> PhotoCollectionViewCell {
        let metrics = ChildContentViewController.gridMetrics(containerWidth: 393)
        let cell = PhotoCollectionViewCell(frame: CGRect(x: 0, y: 0,
                                                         width: metrics.itemWidth,
                                                         height: metrics.rowHeight))
        cell.titleLabel.text = title
        cell.layoutIfNeeded()
        return cell
    }

    /// 長い題名が実際に2行で描かれること。
    /// numberOfLines を 2 にしても、lineBreakMode が切り詰め系だと折り返さず1行のままになる
    func testLongTitleRendersOnTwoLines() {
        let cell = makeLaidOutCell(title: "まーまーらいおん君による使い方の説明！")
        XCTAssertGreaterThan(cell.titleLabel.bounds.width, 0, "ラベルに幅が割り当てられていない")
        XCTAssertEqual(renderedLineCount(of: cell.titleLabel), 2,
                       "長い題名が2行で描かれていない")
    }

    /// 短い題名まで2行に引き伸ばさないこと
    func testShortTitleStaysOnOneLine() {
        let cell = makeLaidOutCell(title: "おもんない！")
        XCTAssertEqual(renderedLineCount(of: cell.titleLabel), 1)
    }

    /// 上限は2行。折り返しモードにしたぶん、長すぎる題名で3行目がはみ出さないこと
    func testVeryLongTitleStopsAtTwoLines() {
        let cell = makeLaidOutCell(title: String(repeating: "あ", count: 120))
        XCTAssertEqual(renderedLineCount(of: cell.titleLabel), 2)
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
    /// 公開/非公開のフラグとスイッチUIは撤去済みで、サーバ経路そのものも無い。
    /// 残っているのは Realm の列だけなので、その既定値が公開に戻らないことを見張る。
    func testPhotoIsNotPublicByDefault() {
        XCTAssertFalse(RealmPhoto().isPublic,
                       "既定が公開に戻っている。この型を作る経路が増えたとき公開扱いで始まってしまう")
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
