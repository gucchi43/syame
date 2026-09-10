//
//  PaywallViewController.swift
//  PhotoKeyboardEx
//

import UIKit
import StoreKit
import PhotoKeyboardFramework

/// 有料プランの案内と購入。
///
/// 日本向けの構成にしている（縦長スクロール＋Free/プレミアムの比較表）。
/// 米国式のインタラクティブな見せ方より転換率が高いという調査に基づく。
///
/// **審査要件（ガイドライン 3.1.2）**: プラン選択・自動更新の説明・購入の復元・
/// 利用規約とプライバシーポリシーへのリンクは必須。欠けるとリジェクトされる。
final class PaywallViewController: UIViewController {

    private static let termsURL = URL(string: "https://pkbkeyboard.studio.design/terms")
    private static let privacyURL = URL(string: "https://pkbkeyboard.studio.design/privacy")

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let purchaseButton = AuroraButton()
    private let planStack = UIStackView()
    private let indicator = UIActivityIndicatorView(style: .medium)
    private let retryButton = UIButton(type: .system)

    private var planButtons: [PlanButton] = []
    private var selectedProduct: Product?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .bgBase
        view.tintColor = .accent
        navigationItem.leftBarButtonItem = {
            let item = UIBarButtonItem(title: nil, style: .plain, target: self, action: #selector(tapClose))
            item.applySymbol(Symbol.close)
            return item
        }()
        buildLayout()
        Task { await loadProducts() }
    }

    // MARK: - レイアウト

    private func buildLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = Spacing.xl
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: Spacing.xl),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: Spacing.l),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -Spacing.l),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -Spacing.xl * 2),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -Spacing.l * 2)
        ])

        contentStack.addArrangedSubview(makeTitle())
        let subtitle = makeSubtitle()
        contentStack.addArrangedSubview(subtitle)
        // arrangedSubview になった後でないと効かない
        contentStack.setCustomSpacing(Spacing.s, after: subtitle)
        contentStack.addArrangedSubview(makeComparisonTable())

        planStack.axis = .vertical
        planStack.alignment = .fill
        planStack.spacing = Spacing.m
        contentStack.addArrangedSubview(planStack)

        indicator.startAnimating()
        contentStack.addArrangedSubview(indicator)

        retryButton.setTitle(LocalizeKey.paywallRetry.localizedString(), for: .normal)
        retryButton.titleLabel?.font = .scaled(.footnote)
        retryButton.titleLabel?.adjustsFontForContentSizeCategory = true
        retryButton.isHidden = true
        retryButton.addAction(UIAction { [weak self] _ in
            Task { await self?.loadProducts() }
        }, for: .touchUpInside)
        contentStack.addArrangedSubview(retryButton)

        purchaseButton.applyCornerRadius(Radius.small)
        purchaseButton.titleLabel?.adjustsFontSizeToFitWidth = true
        purchaseButton.setTitle(LocalizeKey.paywallPurchase.localizedString(), for: .normal)
        purchaseButton.addTarget(self, action: #selector(tapPurchase), for: .touchUpInside)
        purchaseButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        purchaseButton.isEnabled = false
        contentStack.addArrangedSubview(purchaseButton)

        contentStack.addArrangedSubview(makeRenewalNote())
        contentStack.addArrangedSubview(makeRestoreButton())
        contentStack.addArrangedSubview(makeLinks())
    }

    private func makeTitle() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .textPrimary
        label.adjustsFontForContentSizeCategory = true
        label.font = .scaled(.title2, weight: .bold)
        label.text = LocalizeKey.paywallTitle.localizedString()
        return label
    }

    private func makeSubtitle() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .textSecondary
        label.adjustsFontForContentSizeCategory = true
        label.font = .scaled(.footnote)
        label.text = LocalizeKey.paywallSubtitle.localizedString()
        return label
    }

    /// 無料とプレミアムを並べて何が変わるかを1行で見せる
    private func makeComparisonTable() -> UIView {
        let header = makeRow(left: "",
                             center: LocalizeKey.paywallColumnFree.localizedString(),
                             right: LocalizeKey.paywallColumnPremium.localizedString(),
                             isHeader: true)
        let row = makeRow(left: LocalizeKey.paywallRowSaveCount.localizedString(),
                          center: LocalizeKey.paywallFreeLimitValue.localizedString(PhotoQuota.freeLimit),
                          right: LocalizeKey.paywallUnlimitedValue.localizedString(),
                          isHeader: false)

        let table = UIStackView(arrangedSubviews: [header, row])
        table.axis = .vertical
        table.spacing = Spacing.s
        table.isLayoutMarginsRelativeArrangement = true
        table.layoutMargins = UIEdgeInsets(top: Spacing.m, left: Spacing.m,
                                           bottom: Spacing.m, right: Spacing.m)
        table.backgroundColor = .bgSurface
        table.applyCornerRadius(Radius.card)
        return table
    }

    private func makeRow(left: String, center: String, right: String, isHeader: Bool) -> UIStackView {
        func label(_ text: String, align: NSTextAlignment, emphasized: Bool) -> UILabel {
            let l = UILabel()
            l.text = text
            l.textAlignment = align
            l.numberOfLines = 0
            l.adjustsFontForContentSizeCategory = true
            l.font = .scaled(.footnote, weight: emphasized ? .bold : .regular)
            l.textColor = emphasized ? .textPrimary : .textSecondary
            return l
        }
        let row = UIStackView(arrangedSubviews: [
            label(left, align: .left, emphasized: !isHeader),
            label(center, align: .center, emphasized: false),
            label(right, align: .center, emphasized: true)
        ])
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = Spacing.s
        return row
    }

    private func makeRenewalNote() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .textSecondary
        label.adjustsFontForContentSizeCategory = true
        label.font = .scaled(.caption2)
        label.text = LocalizeKey.paywallRenewalNote.localizedString()
        return label
    }

    private func makeRestoreButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(LocalizeKey.paywallRestore.localizedString(), for: .normal)
        button.titleLabel?.font = .scaled(.footnote)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.addTarget(self, action: #selector(tapRestore), for: .touchUpInside)
        return button
    }

    private func makeLinks() -> UIStackView {
        func link(_ key: LocalizeKey, url: URL?) -> UIButton {
            let button = UIButton(type: .system)
            button.setTitle(key.localizedString(), for: .normal)
            button.titleLabel?.font = .scaled(.caption2)
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.addAction(UIAction { _ in
                guard let url = url else { return }
                UIApplication.shared.open(url)
            }, for: .touchUpInside)
            return button
        }
        let stack = UIStackView(arrangedSubviews: [
            link(.paywallTerms, url: PaywallViewController.termsURL),
            link(.paywallPrivacy, url: PaywallViewController.privacyURL)
        ])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        return stack
    }

    // MARK: - 商品

    private func loadProducts() async {
        retryButton.isHidden = true
        indicator.startAnimating()
        indicator.isHidden = false
        defer {
            indicator.stopAnimating()
            indicator.isHidden = true
        }

        do {
            try await PremiumStore.shared.loadProducts()
        } catch {
            // 黙って空のペイウォールを見せない。再試行の導線を出す
            retryButton.isHidden = false
            return
        }

        let products = PremiumStore.shared.products
        guard !products.isEmpty else {
            retryButton.isHidden = false
            return
        }

        planButtons.forEach { $0.removeFromSuperview() }
        planButtons.removeAll()
        for product in products {
            let button = PlanButton(product: product)
            button.showTrial = await PremiumStore.shared.isEligibleForIntroductoryOffer(product)
            button.addTarget(self, action: #selector(tapPlan(_:)), for: .touchUpInside)
            planStack.addArrangedSubview(button)
            planButtons.append(button)
        }
        // 年額を初期選択にする。単価が安く、利用者の得になる方を既定にする
        select(products.last ?? products[0])
    }

    private func select(_ product: Product) {
        selectedProduct = product
        var eligible = false
        for button in planButtons {
            let isSelected = button.product.id == product.id
            button.setSelected(isSelected)
            if isSelected { eligible = button.showTrial }
        }
        purchaseButton.isEnabled = true
        // 商品に設定があるかではなく、この利用者が受けられるかで出し分ける
        purchaseButton.setTitle(
            (eligible ? LocalizeKey.paywallPurchaseWithTrial : LocalizeKey.paywallPurchase).localizedString(),
            for: .normal)
    }

    // MARK: - 操作

    @objc private func tapPlan(_ sender: PlanButton) {
        select(sender.product)
    }

    @objc private func tapPurchase() {
        guard let product = selectedProduct else { return }
        setBusy(true)
        Task {
            defer { setBusy(false) }
            do {
                switch try await PremiumStore.shared.purchase(product) {
                case .purchased:
                    dismiss(animated: true)
                case .pending:
                    // 何も出さないと「押したのに無反応」に見えて何度も押される
                    showMessage(LocalizeKey.paywallPurchasePending.localizedString())
                case .unverified:
                    showMessage(LocalizeKey.paywallPurchaseFailed.localizedString())
                case .cancelled:
                    break
                }
            } catch {
                showMessage(LocalizeKey.paywallPurchaseFailed.localizedString())
            }
        }
    }

    @objc private func tapRestore() {
        setBusy(true)
        Task {
            defer { setBusy(false) }
            do {
                try await PremiumStore.shared.restore()
                if PremiumStore.shared.isPremium {
                    dismiss(animated: true)
                } else {
                    showMessage(LocalizeKey.paywallRestoreNothing.localizedString())
                }
            } catch {
                showMessage(LocalizeKey.paywallRestoreFailed.localizedString())
            }
        }
    }

    @objc private func tapClose() {
        dismiss(animated: true)
    }

    private func setBusy(_ busy: Bool) {
        purchaseButton.isEnabled = !busy && selectedProduct != nil
        view.isUserInteractionEnabled = !busy
    }

    private func showMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizeKey.baseOK.localizedString(), style: .default))
        present(alert, animated: true)
    }
}

/// プラン1つぶんのボタン。価格と、年額なら月あたりの単価を出す
private final class PlanButton: UIControl {

    let product: Product

    /// この利用者がトライアルを受けられるか。商品の設定ではなく資格で決まる
    var showTrial = false {
        didSet { detailLabel.text = detailText }
    }
    private let detailLabel = UILabel()

    init(product: Product) {
        self.product = product
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupSubviews() {
        backgroundColor = .bgSurface
        applyCornerRadius(Radius.card)
        layer.borderWidth = 2
        layer.borderColor = UIColor.clear.cgColor

        let name = UILabel()
        name.font = .scaled(.body, weight: .bold)
        name.adjustsFontForContentSizeCategory = true
        name.textColor = .textPrimary
        name.text = isYearly ? LocalizeKey.paywallPlanYearly.localizedString()
                             : LocalizeKey.paywallPlanMonthly.localizedString()

        let price = UILabel()
        price.font = .scaled(.body, weight: .bold)
        price.adjustsFontForContentSizeCategory = true
        price.textColor = .textPrimary
        price.textAlignment = .right
        price.text = product.displayPrice

        let top = UIStackView(arrangedSubviews: [name, price])
        top.axis = .horizontal

        detailLabel.font = .scaled(.caption2)
        detailLabel.adjustsFontForContentSizeCategory = true
        detailLabel.textColor = .textSecondary
        detailLabel.numberOfLines = 0
        detailLabel.text = detailText

        let column = UIStackView(arrangedSubviews: [top, detailLabel])
        column.axis = .vertical
        column.spacing = Spacing.grid
        column.isUserInteractionEnabled = false
        column.translatesAutoresizingMaskIntoConstraints = false
        addSubview(column)

        NSLayoutConstraint.activate([
            column.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.m),
            column.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.m),
            column.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.m),
            column.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.m)
        ])
    }

    private var isYearly: Bool {
        return product.id == PremiumStore.ProductID.yearly
    }

    /// 年額は月あたりの単価と割引率、どちらのプランもトライアルの有無を添える
    private var detailText: String {
        var parts: [String] = []
        if isYearly {
            if let perMonth = monthlyEquivalent {
                parts.append(LocalizeKey.paywallYearlyPerMonth.localizedString(perMonth))
            }
            parts.append(LocalizeKey.paywallYearlyDiscount.localizedString())
        }
        if showTrial, let offer = product.subscription?.introductoryOffer {
            parts.append(LocalizeKey.paywallTrialBadge.localizedString(offer.period.formatted(product.subscriptionPeriodFormatStyle)))
        }
        return parts.joined(separator: " ・ ")
    }

    private var monthlyEquivalent: String? {
        let perMonth = product.price / 12
        return product.priceFormatStyle.format(perMonth)
    }

    func setSelected(_ selected: Bool) {
        layer.borderColor = (selected ? UIColor.accent : UIColor.clear).cgColor
    }
}
