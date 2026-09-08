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

    // MARK: - 案内図に流し込む画像

    private func makeGuideImage(color: UIColor,
                                size: CGSize = CGSize(width: 10, height: 10)) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// 保存画像が1枚も無くても図のスロットは埋まること。
    /// 空のまま描くと、キーボードに何も並んでいない絵になって手順が伝わらない
    func testSlotsAreFilledWithFallbackWhenUserHasNoPhotos() {
        let fallback = makeGuideImage(color: .blue)
        let slots = GuidePhotoSource.slots(userPhotos: [], fallback: fallback)
        XCTAssertEqual(slots.count, GuidePhotoSource.slotCount)
    }

    /// 保存画像が足りないぶんだけを見本で埋め、持っている画像は先に出すこと
    func testSlotsKeepUserPhotosFirstAndPadTheRest() {
        let user = makeGuideImage(color: .red)
        let fallback = makeGuideImage(color: .blue)

        let slots = GuidePhotoSource.slots(userPhotos: [user], fallback: fallback)

        XCTAssertEqual(slots.count, GuidePhotoSource.slotCount)
        XCTAssertTrue(slots[0] === user, "利用者の画像が先頭に来ていない")
        XCTAssertTrue(slots[1] === fallback)
        XCTAssertTrue(slots[2] === fallback)
    }

    /// スロットの数だけ持っていれば見本は混ぜないこと
    func testSlotsUseOnlyUserPhotosWhenThereAreEnough() {
        let photos = (0..<5).map { _ in makeGuideImage(color: .red) }
        let fallback = makeGuideImage(color: .blue)

        let slots = GuidePhotoSource.slots(userPhotos: photos, fallback: fallback)

        XCTAssertEqual(slots.count, GuidePhotoSource.slotCount)
        XCTAssertFalse(slots.contains { $0 === fallback }, "足りているのに見本が混ざっている")
        XCTAssertTrue(slots[0] === photos[0])
        XCTAssertTrue(slots[2] === photos[2])
    }

    private func makeGuidePhoto(ownerId: String, color: UIColor) -> RealmPhoto {
        return RealmPhoto.create(id: UUID().uuidString,
                                 text: "",
                                 image: makeGuideImage(color: color),
                                 imageHeight: 10,
                                 imageWidth: 10,
                                 getDay: "",
                                 isPublic: false,
                                 ownerId: ownerId)
    }

    /// 見本画像を利用者の画像として数えないこと。
    /// 見本は起動時に必ず投入されるので、素朴に先頭から取ると
    /// 「利用者の画像が0枚」という状態を表現できず、補填が働かない
    func testUserImagesExcludeTheOfficialSample() {
        let official = makeGuidePhoto(ownerId: RealmPhoto.officialOwnerId, color: .blue)
        let mine = makeGuidePhoto(ownerId: "", color: .red)

        let images = GuidePhotoSource.userImages(from: [official, mine], maxPixelSize: 40)

        XCTAssertEqual(images.count, 1, "見本が利用者の画像として数えられている")
    }

    /// ビューを描画し、指定した色の画素が含まれるかを見る。
    /// 図が「見えているか」はサブビューの有無では分からない(隠れている・大きさ0でも存在はする)
    private func containsColor(_ view: UIView, _ color: UIColor, tolerance: Int = 16) -> Bool {
        let size = view.bounds.size
        guard size.width > 0, size.height > 0 else { return false }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            // 地を白にすると .bgSurface(ライトテーマでは白)と見分けが付かない。
            // 図に出てこない色を敷いて、描かれた面だけを拾えるようにする
            UIColor.magenta.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            view.layer.render(in: context.cgContext)
        }
        guard let cgImage = image.cgImage else { return false }

        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(data: &pixels,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: width * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return false
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let target = (Int(r * 255), Int(g * 255), Int(b * 255))

        for i in stride(from: 0, to: pixels.count, by: 4) {
            if abs(Int(pixels[i]) - target.0) <= tolerance,
               abs(Int(pixels[i + 1]) - target.1) <= tolerance,
               abs(Int(pixels[i + 2]) - target.2) <= tolerance {
                return true
            }
        }
        return false
    }

    private func layOut(_ view: UIView, width: CGFloat = 320, height: CGFloat = 140) -> UIView {
        view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        view.layoutIfNeeded()
        return view
    }

    /// 渡した画像が3枚とも図に出ること。
    /// 1枚でも欠けると「自分の画像が並ぶ」という手順①の説明が成立しない
    func testKeyboardStripDrawsEveryPhoto() {
        let colors: [UIColor] = [.red, .green, .blue]
        let strip = GuideKeyboardStripView(photos: colors.map { makeGuideImage(color: $0) })
        _ = layOut(strip)

        for color in colors {
            XCTAssertTrue(containsColor(strip, color), "\(color) の画像が図に描かれていない")
        }
    }

    /// 先頭の1枚に「コピーされた」印が乗ること。
    /// 印が無いと、タップが何を起こすのかが図から読み取れず、次の手順(貼る)に繋がらない
    func testKeyboardStripMarksTheTappedPhoto() {
        let strip = GuideKeyboardStripView(photos: (0..<3).map { _ in makeGuideImage(color: .lightGray) })
        _ = layOut(strip)

        XCTAssertTrue(containsColor(strip, .accent), "コピーを示す印が図に描かれていない")
    }

    /// 入力欄と「ペースト」の吹き出しが両方描かれること。
    /// 手順②は一番つまずくところなので、貼り先(入力欄)と操作(ペースト)の
    /// どちらが欠けても図として成立しない
    func testComposerDrawsInputBarAndPasteBubble() {
        let composer = layOut(GuideComposerView(), height: 120)

        XCTAssertTrue(containsColor(composer, .bgBase), "入力欄が描かれていない")
        XCTAssertTrue(containsColor(composer, .accent), "「ペースト」の吹き出しが描かれていない")
    }

    /// 送った画像がトークの図に出ること。
    /// ここに出ないと「貼ったものがそのまま送られる」という結末が伝わらない
    func testChatDrawsTheSentPhoto() {
        let chat = GuideChatView(sentPhoto: makeGuideImage(color: .red))
        _ = layOut(chat, height: 160)

        XCTAssertTrue(containsColor(chat, .red), "送った画像が図に描かれていない")
    }

    /// 相手の吹き出しも描くこと。会話の中に置かれている、という文脈が要る
    func testChatDrawsIncomingBubble() {
        let chat = GuideChatView(sentPhoto: makeGuideImage(color: .red))
        _ = layOut(chat, height: 160)

        XCTAssertTrue(containsColor(chat, .bgBase), "相手の吹き出しが描かれていない")
    }

    private func makeStep(illustrationColor: UIColor) -> GuideStepView {
        let illustration = UIView()
        illustration.backgroundColor = illustrationColor
        illustration.translatesAutoresizingMaskIntoConstraints = false
        illustration.heightAnchor.constraint(equalToConstant: 80).isActive = true
        return GuideStepView(number: 1,
                             bold: .howToFirstBoldText,
                             normal: .howToFirstNormalText,
                             illustration: illustration)
    }

    /// 渡した図が実際に描かれること。器が図を落としていたら手順が絵にならない
    func testStepDrawsItsIllustration() {
        let step = makeStep(illustrationColor: .red)
        _ = layOut(step, height: 260)

        XCTAssertTrue(containsColor(step, .red), "図が描かれていない")
    }

    /// 手順の文言は既存のキーから引くこと。
    /// 図の中に文字を焼くと、英語のときに日本語のままになる
    func testStepShowsLocalizedText() {
        let step = makeStep(illustrationColor: .red)
        _ = layOut(step, height: 260)

        let texts = step.subviewTexts()
        XCTAssertTrue(texts.contains { $0.contains(LocalizeKey.howToFirstBoldText.localizedString()) },
                      "手順の文言が出ていない。実際の文字列: \(texts)")
    }

    /// 番号を出すこと。3つ並んだときに順番が読めない
    func testStepShowsItsNumber() {
        let step = makeStep(illustrationColor: .red)
        _ = layOut(step, height: 260)

        XCTAssertTrue(step.subviewTexts().contains("1"), "番号が出ていない")
    }

    /// 起動直後の画面にも図を出すこと。
    /// ロゴと見出しだけでは、何をするアプリなのかが絵から伝わらない
    func testTopShowsGuideIllustration() {
        guard let root = UIStoryboard(name: "Top", bundle: nil).instantiateInitialViewController() else {
            return XCTFail("Top を読み込めなかった")
        }
        root.loadViewIfNeeded()
        root.view.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        root.view.layoutIfNeeded()

        XCTAssertNotNil(root.view.firstSubview(ofType: GuideKeyboardStripView.self),
                        "起動直後の画面に図が出ていない")
    }

    private func loadTop(width: CGFloat, height: CGFloat) -> (UIViewController, TopViewController)? {
        guard let root = UIStoryboard(name: "Top", bundle: nil).instantiateInitialViewController() else {
            return nil
        }
        let top = (root as? TopViewController)
            ?? (root as? UINavigationController)?.viewControllers.first as? TopViewController
        guard let top = top else { return nil }
        root.loadViewIfNeeded()
        root.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        root.view.layoutIfNeeded()
        return (root, top)
    }

    /// 小さい画面で図が見出しに重ならないこと。
    /// 起動画面はロゴ・見出し・ボタン・規約文で既に埋まっており、
    /// 図を足すと下から押し上がって見出しに突き当たる
    func testTopKeepsGuideClearOfTheSubtitleOnASmallScreen() {
        // iPhone SE (第3世代)
        guard let (root, top) = loadTop(width: 375, height: 667) else {
            return XCTFail("Top を読み込めなかった")
        }
        guard let strip = root.view.firstSubview(ofType: GuideKeyboardStripView.self) else {
            return XCTFail("図が出ていない")
        }

        let stripFrame = strip.convert(strip.bounds, to: root.view)
        let subtitleFrame = top.subTitleLabel.convert(top.subTitleLabel.bounds, to: root.view)

        XCTAssertFalse(stripFrame.intersects(subtitleFrame),
                       "小さい画面で図が見出しに重なっている。図: \(stripFrame) 見出し: \(subtitleFrame)")
        XCTAssertGreaterThanOrEqual(stripFrame.minY, 0, "図が画面の上に飛び出している")
    }

    /// ダークモードで図が地に沈まないこと。
    /// ダークの bgBase と bgSurface は明度差が小さいので、
    /// 見分けが付く程度の許容差(4)で「別の面として描かれている」ことを見る
    func testComposerStaysVisibleInDarkMode() {
        let composer = GuideComposerView()
        // ウインドウに載せないと配色の切り替えが伝わらず、
        // 動的な色がライトのまま CGColor に固定される
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 120))
        window.overrideUserInterfaceStyle = .dark
        window.addSubview(composer)
        composer.frame = window.bounds
        window.layoutIfNeeded()

        let dark = UITraitCollection(userInterfaceStyle: .dark)
        XCTAssertTrue(containsColor(composer, UIColor.bgSurface.resolvedColor(with: dark), tolerance: 4),
                      "ダークモードで図の面が描かれていない")
        XCTAssertTrue(containsColor(composer, UIColor.bgBase.resolvedColor(with: dark), tolerance: 4),
                      "ダークモードで入力欄が面と区別できない")
    }

    /// 文字サイズを最大にしても図が横にはみ出さないこと。
    /// 番号バッジと文言を横に並べているので、文字が伸びると幅を押し広げる
    func testStepFitsWidthAtLargestTextSize() {
        let largest = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        var step: GuideStepView!
        largest.performAsCurrent {
            step = makeStep(illustrationColor: .red)
        }

        let fitted = step.systemLayoutSizeFitting(CGSize(width: 320, height: 0),
                                                  withHorizontalFittingPriority: .required,
                                                  verticalFittingPriority: .fittingSizeLevel)

        XCTAssertLessThanOrEqual(fitted.width, 320, "最大の文字サイズで図が横にはみ出している")
        XCTAssertGreaterThan(fitted.height, 0)
    }

    // MARK: - 有料プラン

    /// 販売する Product ID は ASC に登録したものと一致していること。
    /// ずれると商品が取得できず、ペイウォールが空のまま出る
    func testProductIDsMatchAppStoreConnect() {
        XCTAssertEqual(PremiumStore.ProductID.monthly, "bocchi.PhotoKeyboardEx.premium.monthly")
        XCTAssertEqual(PremiumStore.ProductID.yearly, "bocchi.PhotoKeyboardEx.premium.yearly")
        XCTAssertEqual(PremiumStore.ProductID.all.count, 2)
    }

    /// 無料枠の値はフレームワーク側の定義をそのまま使うこと。
    /// 直書きするとペイウォールの表示と実際の上限がずれる
    @MainActor
    func testFreeLimitComesFromTheSingleDefinition() {
        XCTAssertEqual(PhotoQuota.freeLimit, RealmManager.photoLimit)
    }

    /// 上限の文言に枚数を差し込めること。
    /// 直書きのままだと photoLimit を変えたときに文言だけ古い数字が残る
    func testLimitReachedTitleTakesTheCount() {
        let text = LocalizeKey.limitReachedTitle.localizedString(8)
        XCTAssertTrue(text.contains("8"), "枚数が文言に入っていない: \(text)")
        XCTAssertFalse(text.contains("%d"), "書式指定子が残っている: \(text)")
    }

    /// ペイウォールに審査required な要素が揃っていること。
    /// 購入の復元・利用規約・プライバシーポリシーが無いとガイドライン3.1.2でリジェクトされる
    func testPaywallShowsRequiredElements() {
        let paywall = PaywallViewController()
        paywall.loadViewIfNeeded()
        paywall.view.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        paywall.view.layoutIfNeeded()

        let texts = paywall.view.subviewTexts()
        for key in [LocalizeKey.paywallRestore, .paywallTerms, .paywallPrivacy, .paywallRenewalNote] {
            let expected = key.localizedString()
            XCTAssertTrue(texts.contains { $0.contains(expected) },
                          "ペイウォールに「\(expected)」が出ていない")
        }
    }

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

/// ビュー階層に出ている文字を集める。文言が実際に画面へ届いているかを見る
private extension UIView {
    func subviewTexts() -> [String] {
        var result: [String] = []
        if let label = self as? UILabel, let text = label.text {
            result.append(text)
        }
        if let button = self as? UIButton, let title = button.title(for: .normal) {
            result.append(title)
        }
        for subview in subviews {
            result.append(contentsOf: subview.subviewTexts())
        }
        return result
    }
}

private extension UIView {
    func firstSubview<T: UIView>(ofType type: T.Type) -> T? {
        if let match = self as? T { return match }
        for subview in subviews {
            if let match = subview.firstSubview(ofType: type) { return match }
        }
        return nil
    }
}
