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

    /// 持っている画像を先に出し、残りは空きスロットで埋めること。
    ///
    /// 以前は足りないぶんを見本で埋めていたが、同じ絵が並んで
    /// 「もう何枚も持っている」と読めてしまうため、埋め草は空きスロットにした。
    /// 見本を使うのは、自分の画像が1枚も無いときの先頭だけ
    func testSlotsKeepUserPhotosFirstAndPadWithEmptySlots() {
        let user = makeGuideImage(color: .red)
        let fallback = makeGuideImage(color: .blue)

        let slots = GuidePhotoSource.slots(userPhotos: [user], fallback: fallback)

        XCTAssertEqual(slots.count, GuidePhotoSource.slotCount)
        XCTAssertTrue(slots[0] === user, "利用者の画像が先頭に来ていない")
        XCTAssertFalse(slots[1] === fallback, "足りないぶんが見本で埋まっている")
        XCTAssertFalse(slots[2] === fallback, "足りないぶんが見本で埋まっている")
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

    /// 図に出す短い文言に書式指定子が残らないこと。
    /// %% は String(format:) を通したときだけ % になる。素の localizedString() で
    /// 引くキーに %% を書くと、画面に "38%%おトク" と二重の % が出る
    func testDiscountBadgeHasNoLeftoverFormatSpecifier() {
        let text = LocalizeKey.paywallYearlyDiscount.localizedString()
        XCTAssertFalse(text.contains("%%"), "書式指定子が残っている: \(text)")
        XCTAssertTrue(text.contains("38%"), "割引率が出ていない: \(text)")
    }

    // MARK: - 課金の入口の出し分け

    /// 有料アプリ契約が未締結のあいだは課金の入口を出さないこと。
    /// 購入導線があるのに購入できない状態は審査で落ちる
    @MainActor
    func testPremiumEntryIsHiddenWhileUnavailable() {
        let original = PremiumStore.isAvailable
        defer { PremiumStore.isAvailable = original }

        PremiumStore.isAvailable = false
        let menu = MyMenuTableViewController()
        menu.loadViewIfNeeded()
        let hidden = menu.tableView.numberOfRows(inSection: 0)

        PremiumStore.isAvailable = true
        menu.tableView.reloadData()
        let shown = menu.tableView.numberOfRows(inSection: 0)

        XCTAssertEqual(shown, hidden + 1, "課金の入口が行数に反映されていない")
    }

    /// 隠しているあいだ、残る行が本来の画面に対応していること。
    /// 索引がずれると「送り方」を押して設定が開くような事故になる
    @MainActor
    func testMenuRowsStayAlignedWhilePremiumIsHidden() {
        let original = PremiumStore.isAvailable
        defer { PremiumStore.isAvailable = original }
        PremiumStore.isAvailable = false

        let menu = MyMenuTableViewController()
        menu.loadViewIfNeeded()
        let titles = (0..<menu.tableView.numberOfRows(inSection: 0)).compactMap {
            menu.tableView(menu.tableView, cellForRowAt: IndexPath(row: $0, section: 0)).textLabel?.text
        }

        XCTAssertEqual(titles, [LocalizeKey.menuHome.localizedString(),
                                LocalizeKey.menuSetting.localizedString(),
                                LocalizeKey.menuHowTo.localizedString()])
    }

    // MARK: - オンボーディングの進み方

    private func step(welcome: Bool = true, photos: Int = 1,
                      keyboard: Bool = true, fullAccess: Bool = true,
                      howTo: Bool = true) -> OnboardingStep {
        return OnboardingCoordinator.currentStep(hasSeenWelcome: welcome,
                                                 userOwnedPhotoCount: photos,
                                                 isKeyboardEnabled: keyboard,
                                                 hasFullAccess: fullAccess,
                                                 hasSeenHowToSend: howTo)
    }

    /// キーボードを一覧に足しただけでは終わりにしないこと。
    ///
    /// ペリペリはフルアクセスが無いと画像をコピーできず、まったく使えない。
    /// 追加済みというだけで案内を止めると、**一番肝心な設定が済んでいないのに
    /// 何の案内も出ない**状態になる。実機でこれが起きた
    func testKeyboardStepNeedsFullAccessNotJustBeingAdded() {
        XCTAssertEqual(step(photos: 1, keyboard: true, fullAccess: false, howTo: false),
                       .allowFullAccess,
                       "フルアクセスが無いのに手順を終わりにしている")
    }

    /// 案内のモーダルは、閉じ終わったときに現在地を引き直させること。
    ///
    /// 開いた時点で通知を投げても、本体側は自分が前面にいるため
    /// `presentedViewController != nil` で素通りする。閉じるときに誰も知らせないと、
    /// 手順が最後まで進んだことに気づく機会が二度と来ず、
    /// 「設定完了」のダイアログが永久に出なかった。
    @MainActor
    func testClosingOnboardingModalAsksToReevaluate() {
        // Usage は Storyboard の Outlet を持つため、実物と同じ経路で組み立てる
        let usage = UIStoryboard(name: "Usage", bundle: nil).instantiateInitialViewController()
        let targets: [UIViewController] = [UINavigationController(rootViewController: HowToSendViewController())]
            + (usage.map { [$0] } ?? [])
        XCTAssertEqual(targets.count, 2, "Usage を組み立てられていない")

        for vc in targets {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            let root = UIViewController()
            window.rootViewController = root
            window.makeKeyAndVisible()

            let shown = expectation(description: "表示")
            root.present(vc, animated: false) { shown.fulfill() }
            wait(for: [shown], timeout: 5)

            let advanced = expectation(description: "閉じたら引き直し: \(type(of: vc))")
            advanced.assertForOverFulfill = false
            let token = NotificationCenter.default.addObserver(forName: .onboardingDidAdvance,
                                                              object: nil, queue: .main) { _ in
                advanced.fulfill()
            }
            root.dismiss(animated: false, completion: nil)
            wait(for: [advanced], timeout: 5)
            NotificationCenter.default.removeObserver(token)
        }
    }

    /// 追加済みのときは「追加する」ではなく「フルアクセスを許可する」と出すこと。
    /// 済んだ作業を促しても、利用者は何をすればいいのか分からない
    func testHintTellsWhatIsActuallyLeft() {
        let added = step(photos: 1, keyboard: true, fullAccess: false, howTo: false)
        XCTAssertEqual(added.hintKey, .onboardingHintAllowFullAccess)

        let notAdded = step(photos: 1, keyboard: false, fullAccess: false, howTo: false)
        XCTAssertEqual(notAdded.hintKey, .onboardingHintEnableKeyboard)
    }

    /// フルアクセスまで済んで初めて次へ進むこと
    func testKeyboardStepFinishesOnlyWithFullAccess() {
        XCTAssertEqual(step(photos: 1, keyboard: true, fullAccess: true, howTo: false),
                       .howToSend)
    }

    /// 追加すらしていなければ当然そこで止まること
    func testKeyboardStepStopsWhenNotAdded() {
        XCTAssertEqual(step(photos: 1, keyboard: false, fullAccess: false, howTo: false),
                       .enableKeyboard)
    }

    /// 何も済んでいなければ最初の手順から始まること
    func testOnboardingStartsAtWelcome() {
        XCTAssertEqual(step(welcome: false, photos: 0, keyboard: false, howTo: false), .welcome)
    }

    /// Top を見たら、次は1枚保存する手順に進むこと
    func testOnboardingAsksToSaveAfterWelcome() {
        XCTAssertEqual(step(welcome: true, photos: 0, keyboard: false, howTo: false), .savePhoto)
    }

    /// 1枚保存したら、次はキーボードの有効化。
    /// フルアクセスという重い許可は、価値を体験してから求める
    func testOnboardingAsksForKeyboardAfterFirstPhoto() {
        XCTAssertEqual(step(welcome: true, photos: 1, keyboard: false, howTo: false), .enableKeyboard)
    }

    /// キーボードが有効になったら送り方を案内すること
    func testOnboardingShowsHowToSendAfterKeyboardIsEnabled() {
        XCTAssertEqual(step(welcome: true, photos: 1, keyboard: true, howTo: false), .howToSend)
    }

    /// 全部済んだら終わること
    func testOnboardingFinishes() {
        XCTAssertEqual(step(), .done)
    }

    /// 先の手順が先に出ないこと。
    /// アプリの外で先にキーボードを有効にしても、保存がまだなら保存を先に案内する
    func testOnboardingNeverSkipsAhead() {
        XCTAssertEqual(step(welcome: true, photos: 0, keyboard: true, howTo: false), .savePhoto)
        XCTAssertEqual(step(welcome: false, photos: 5, keyboard: true, howTo: true), .welcome)
    }

    /// 見本画像は自分で保存したものに数えない。
    /// 数えると起動しただけで「保存済み」になり、1枚も入れていない人を素通りさせる
    func testOnboardingDoesNotCountTheSampleAsSaved() {
        XCTAssertEqual(step(welcome: true, photos: 0, keyboard: false, howTo: false), .savePhoto)
    }

    /// 手順ごとに案内の文言が出ること。終わったら消えること
    @MainActor
    func testOnboardingHintShowsTextPerStep() {
        let hint = OnboardingHintView()
        hint.frame = CGRect(x: 0, y: 0, width: 360, height: 56)

        hint.apply(step: .enableKeyboard)
        hint.layoutIfNeeded()
        XCTAssertFalse(hint.isHidden)
        XCTAssertTrue(hint.subviewTexts().contains(LocalizeKey.onboardingHintEnableKeyboard.localizedString()))

        hint.apply(step: .done)
        XCTAssertTrue(hint.isHidden, "すべて済んだのに案内が残っている")
    }

    /// Top を出している最中は案内行を出さないこと(重ねても読めない)
    @MainActor
    func testOnboardingHintIsHiddenDuringWelcome() {
        let hint = OnboardingHintView()
        hint.apply(step: .welcome)
        XCTAssertTrue(hint.isHidden)
    }

    /// 保存画像が無いとき、同じ見本を3枚並べないこと。
    /// 同じ絵が3つ出るより「ここに自分の画像が入る」と伝わる形にする
    func testSlotsDoNotRepeatTheSampleThreeTimes() {
        let fallback = makeGuideImage(color: .blue)
        let filled = GuidePhotoSource.slots(userPhotos: [], fallback: fallback)

        let sampleCount = filled.filter { $0 === fallback }.count
        XCTAssertEqual(sampleCount, 1, "見本が \(sampleCount) 枚並んでいる")
        XCTAssertEqual(filled.count, GuidePhotoSource.slotCount, "スロットの数は変えない")
    }

    /// 埋め草は見分けが付くこと。見本と同じ絵だと「3枚持っている」と読めてしまう
    func testEmptySlotsAreDistinctFromTheSample() {
        let fallback = makeGuideImage(color: .blue)
        let filled = GuidePhotoSource.slots(userPhotos: [], fallback: fallback)

        XCTAssertFalse(filled[1] === fallback)
        XCTAssertFalse(filled[2] === fallback)
    }

    /// キーボード設定の案内にフルアクセスの図が入っていること。
    /// この画面だけ文字だけだと、一番離脱しやすいところに手がかりが無い
    @MainActor
    func testUsageShowsFullAccessIllustration() {
        guard let root = UIStoryboard(name: "Usage", bundle: nil).instantiateInitialViewController() else {
            return XCTFail("Usage を読み込めなかった")
        }
        root.loadViewIfNeeded()
        root.view.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        root.view.layoutIfNeeded()

        XCTAssertNotNil(root.view.firstSubview(ofType: GuideSettingsRowView.self),
                        "フルアクセスの図が出ていない")
    }

    /// 図の中では強調の角括弧を出さないこと。設定の行を模した絵の中では記号が浮く
    @MainActor
    func testSettingsRowTitleHasNoBrackets() {
        guard let root = UIStoryboard(name: "Usage", bundle: nil).instantiateInitialViewController(),
              let figure = { () -> GuideSettingsRowView? in
                  root.loadViewIfNeeded()
                  root.view.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
                  root.view.layoutIfNeeded()
                  return root.view.firstSubview(ofType: GuideSettingsRowView.self)
              }() else {
            return XCTFail("図が出ていない")
        }
        for text in figure.subviewTexts() {
            XCTAssertFalse(text.contains("["), "角括弧が残っている: \(text)")
        }
    }

    /// 案内行のタップが、その手順の画面へ繋がっていること。
    ///
    /// 「はじめる」の直後に案内が出ない不具合は、画面を実際に動かして初めて分かった。
    /// 同じ種類の見落としを防ぐため、押した先も固定する。
    @MainActor
    private func presentedController(after step: OnboardingStep) -> UIViewController? {
        let board = UIStoryboard(name: "ChildContent", bundle: nil)
            .instantiateInitialViewController() as? ChildContentViewController
        guard let board = board else { return nil }
        board.loadViewIfNeeded()
        board.view.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        board.view.layoutIfNeeded()
        board.applyOnboarding(step: step)

        // 画面に載っていないと present できないため、ウインドウへ入れる
        let window = UIWindow(frame: board.view.bounds)
        window.rootViewController = board
        window.isHidden = false

        board.simulateOnboardingHintTapForTesting()
        return board.presentedViewController
    }

    /// キーボードを有効にする手順では、設定の案内へ送ること
    @MainActor
    func testHintOpensKeyboardSetup() {
        let presented = presentedController(after: .enableKeyboard)
        let nav = presented as? UINavigationController
        XCTAssertTrue(nav?.viewControllers.first is UsageViewController,
                      "キーボード設定の案内が開いていない: \(String(describing: presented))")
    }

    /// 送り方の手順では、送り方の案内へ送ること
    @MainActor
    func testHintOpensHowToSend() {
        let presented = presentedController(after: .howToSend)
        let nav = presented as? UINavigationController
        XCTAssertTrue(nav?.viewControllers.first is HowToSendViewController,
                      "送り方の案内が開いていない: \(String(describing: presented))")
    }

    /// 起動直後の画面の開始ボタンはクレイのボタンであること。
    /// Storyboard の customClass を変え忘れると、見た目だけ旧デザインが残る
    @MainActor
    func testTopStartButtonIsClay() {
        let top = UIStoryboard(name: "Top", bundle: nil).instantiateInitialViewController() as? TopViewController
        top?.loadViewIfNeeded()
        XCTAssertTrue(top?.startButton is ClayButton, "開始ボタンが ClayButton ではない")
    }

    /// 追加画面の完了ボタンも同じ
    @MainActor
    func testAddDoneButtonIsClay() {
        let nav = UIStoryboard(name: "Add", bundle: nil).instantiateInitialViewController() as? UINavigationController
        let add = nav?.viewControllers.first as? AddViewController
        add?.loadViewIfNeeded()
        XCTAssertTrue(add?.doneButton is ClayButton, "完了ボタンが ClayButton ではない")
    }

    /// キーボード設定画面の「あとで」の隣の主ボタンも同じ
    @MainActor
    func testUsageNextButtonIsClay() {
        let nav = UIStoryboard(name: "Usage", bundle: nil).instantiateInitialViewController() as? UINavigationController
        let usage = nav?.viewControllers.first as? UsageViewController
        usage?.loadViewIfNeeded()
        XCTAssertTrue(usage?.nextButton is ClayButton, "主ボタンが ClayButton ではない")
    }

    /// 起動直後の画面に「貼られた先」と「貼る元」が両方出ること。
    /// キーボードの帯だけでは、貼った結果どうなるかが伝わらない
    @MainActor
    func testTopShowsChatAndKeyboardTogether() {
        guard let (root, _) = loadTop(width: 402, height: 874) else {
            return XCTFail("Top を読み込めなかった")
        }
        XCTAssertNotNil(root.view.firstSubview(ofType: GuideChatView.self), "トークの図が出ていない")
        XCTAssertNotNil(root.view.firstSubview(ofType: GuideKeyboardStripView.self), "キーボードの図が出ていない")
    }

    /// 上から下へ「見出し → 図 → ボタン → 規約」の順に並ぶこと。
    /// 以前は縦位置がすべて画面中央基準で、図を大きくすると見出しに重なった
    @MainActor
    func testTopFlowsTopToBottom() {
        guard let (root, top) = loadTop(width: 375, height: 667) else {
            return XCTFail("Top を読み込めなかった")
        }
        guard let hero = root.view.firstSubview(ofType: GuideHeroView.self) else {
            return XCTFail("図が出ていない")
        }
        func frame(_ v: UIView) -> CGRect { v.convert(v.bounds, to: root.view) }

        let subtitle = frame(top.subTitleLabel)
        let heroFrame = frame(hero)
        let button = frame(top.startButton)
        let terms = frame(top.requestDescription)

        XCTAssertLessThanOrEqual(subtitle.maxY, heroFrame.minY + 1, "見出しより図が上に来ている")
        XCTAssertLessThanOrEqual(heroFrame.maxY, button.minY + 1, "図よりボタンが上に来ている")
        XCTAssertLessThanOrEqual(button.maxY, terms.minY + 1, "ボタンより規約文が上に来ている")
        XCTAssertFalse(subtitle.intersects(heroFrame), "見出しと図が重なっている")
    }

    /// 小さい画面では縦に収まらないので、スクロールできること
    @MainActor
    func testTopScrollsWhenContentIsTallerThanTheScreen() {
        guard let (root, _) = loadTop(width: 375, height: 667) else {
            return XCTFail("Top を読み込めなかった")
        }
        guard let scroll = root.view.firstSubview(ofType: UIScrollView.self) else {
            return XCTFail("スクロールできない")
        }
        XCTAssertGreaterThan(scroll.contentSize.height, 0)
    }

    /// トークの図に会話文が入っていること。
    /// 空の帯だけだと「会話の中に画像が届く」という場面に見えない
    @MainActor
    func testTopChatShowsConversation() {
        guard let (root, _) = loadTop(width: 402, height: 874) else {
            return XCTFail("Top を読み込めなかった")
        }
        guard let chat = root.view.firstSubview(ofType: GuideChatView.self) else {
            return XCTFail("トークの図が出ていない")
        }
        let texts = chat.subviewTexts()
        XCTAssertTrue(texts.contains(LocalizeKey.chatIncomingFirst.localizedString()))
        XCTAssertTrue(texts.contains(LocalizeKey.chatIncomingSecond.localizedString()))
    }

    /// 起動直後のキーボードの図は、実物と同じく題名付きで出ること
    @MainActor
    func testTopKeyboardLooksLikeTheRealOne() {
        guard let (root, _) = loadTop(width: 402, height: 874) else {
            return XCTFail("Top を読み込めなかった")
        }
        guard let strip = root.view.firstSubview(ofType: GuideKeyboardStripView.self) else {
            return XCTFail("キーボードの図が出ていない")
        }
        let texts = strip.subviewTexts()
        XCTAssertTrue(texts.contains(LocalizeKey.sampleTitleCat.localizedString()),
                      "セルの題名が出ていない: \(texts)")
        XCTAssertTrue(texts.contains(LocalizeKey.keyboardTextMode.localizedString()),
                      "上のツールバーが出ていない: \(texts)")
    }

    /// 紹介用の画像が3枚とも読めること。1枚でも欠けると図が崩れる
    func testSampleGalleryResolvesAllImages() {
        XCTAssertEqual(GuideSampleGallery.photos.count, 3)
        XCTAssertNotNil(GuideSampleGallery.sentPhoto)
    }

    /// 送り方の図も起動直後と同じ見た目であること。
    /// 案内のたびに絵柄が変わると、同じ操作の話だと分かりにくい
    @MainActor
    func testHowToUsesTheSameFiguresAsTop() {
        let vc = HowToSendViewController()
        vc.view.frame = CGRect(x: 0, y: 0, width: 402, height: 1400)
        vc.view.layoutIfNeeded()

        guard let strip = vc.view.firstSubview(ofType: GuideKeyboardStripView.self) else {
            return XCTFail("キーボードの図が出ていない")
        }
        let texts = strip.subviewTexts()
        XCTAssertTrue(texts.contains(LocalizeKey.keyboardTextMode.localizedString()),
                      "実物寄せのツールバーが出ていない: \(texts)")

        guard let chat = vc.view.firstSubview(ofType: GuideChatView.self) else {
            return XCTFail("トークの図が出ていない")
        }
        XCTAssertTrue(chat.subviewTexts().contains(LocalizeKey.chatIncomingFirst.localizedString()),
                      "会話文が出ていない")
    }

    /// 動きを止めたら完成形に戻すこと。
    /// 途中で止まったまま残ると、画像もコピーの印も欠けた絵になる
    @MainActor
    func testHeroSettlesToTheFinishedStateWhenStopped() {
        let hero = GuideHeroView(photos: GuideSampleGallery.photos,
                                 sentPhoto: GuideSampleGallery.sentPhoto ?? UIImage())
        hero.frame = CGRect(x: 0, y: 0, width: 300, height: 400)
        hero.layoutIfNeeded()
        hero.startAnimating()
        hero.stopAnimating()

        guard let chat = hero.firstSubview(ofType: GuideChatView.self),
              let sent = chat.sentPhotoView else {
            return XCTFail("送った画像が見つからない")
        }
        XCTAssertEqual(sent.alpha, 1, accuracy: 0.01, "止めたのに画像が消えたままになっている")
    }

    // MARK: - 設定完了の祝い

    /// 最後の手順を終えた瞬間に出すこと。ここが達成感のピーク
    func testCelebratesWhenTheLastStepIsFinished() {
        XCTAssertTrue(OnboardingCoordinator.shouldCelebrate(previous: .howToSend,
                                                            current: .done,
                                                            hasCelebrated: false))
    }

    /// 一度出したら二度と出さないこと
    func testDoesNotCelebrateTwice() {
        XCTAssertFalse(OnboardingCoordinator.shouldCelebrate(previous: .howToSend,
                                                             current: .done,
                                                             hasCelebrated: true))
    }

    /// 途中の手順では出さないこと
    func testDoesNotCelebrateMidway() {
        XCTAssertFalse(OnboardingCoordinator.shouldCelebrate(previous: .savePhoto,
                                                             current: .enableKeyboard,
                                                             hasCelebrated: false))
    }

    /// 既に全部終わっている利用者に、いきなり祝いを出さないこと。
    /// アップデートしただけの人に脈絡のないダイアログが出るのを防ぐ
    func testDoesNotCelebrateForAlreadyFinishedUsers() {
        XCTAssertFalse(OnboardingCoordinator.shouldCelebrate(previous: nil,
                                                             current: .done,
                                                             hasCelebrated: false))
    }

    /// 完了のまま起動し直しても出さないこと
    func testDoesNotCelebrateOnEveryLaunchAfterDone() {
        XCTAssertFalse(OnboardingCoordinator.shouldCelebrate(previous: .done,
                                                             current: .done,
                                                             hasCelebrated: false))
    }

    /// 完了のダイアログに、試し先と逃げ道が揃っていること。
    /// 準備が終わった直後が一番使ってみたい瞬間なので、行き先を必ず出す
    @MainActor
    func testCelebrationOffersDestinations() {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        window.rootViewController = host
        window.isHidden = false

        OnboardingCelebration.present(from: host)

        let expectation = XCTestExpectation(description: "ダイアログが出る")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { expectation.fulfill() }
        wait(for: [expectation], timeout: 3)

        guard let alert = host.presentedViewController as? UIAlertController else {
            return XCTFail("ダイアログが出ていない")
        }
        let titles = alert.actions.map { $0.title ?? "" }
        XCTAssertTrue(titles.contains(LocalizeKey.celebrateOpenLine.localizedString()),
                      "LINE への導線が無い: \(titles)")
        XCTAssertTrue(titles.contains(LocalizeKey.celebrateOpenInstagram.localizedString()),
                      "Instagram への導線が無い: \(titles)")
        XCTAssertTrue(alert.actions.contains { $0.style == .cancel },
                      "逃げ道が無い。押せる先が全部アプリ起動だと閉じられない")
        XCTAssertEqual(alert.title, LocalizeKey.celebrateTitle.localizedString())
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
