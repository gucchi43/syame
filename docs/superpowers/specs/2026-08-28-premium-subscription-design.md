# 有料プラン（プレミアム）実装 設計書

作成日: 2026-08-28
対象: TODO.md 変更セット C（保存枚数キャップとサブスクリプション）
関連: PLAN.md 方針2 / SPEC.md / KNOWLEDGE.md「価格相場」節

---

## 1. 目的と範囲

無料の保存枚数に上限を設け、その解除を有料プランとして販売する。
本設計の範囲は**決済の土台（StoreKit 2・ペイウォール・上限解除）**に限る。

### やること

- App Store Connect のサブスクリプション商品2つ（月額・年額）
- StoreKit 2 による購入・復元・トランザクション監視
- プレミアム状態に応じた保存枚数の上限解除
- ペイウォール画面（新規）
- 上限到達時の課金導線
- 無料トライアル7日間（2026-09-09 追加。当初は範囲外としていた）

### やらないこと

以下はいずれも決定済みで範囲外。実装しない。

| 項目 | 理由 |
| --- | --- |
| フォルダ分け・検索・テーマカラー・自動切り抜き | 初回リリースの有料機能は「無制限保存」のみと決定 |
| 買い切り（Non-Consumable） | 年額と両立しない価格帯になるため（詳細は PLAN.md） |
| キーボード拡張への課金状態の伝播 | 拡張は Realm にあるものを表示するだけ。上限はアプリ本体でのみ効かせる |
| 既存の超過分のロック | 取り上げない方針。既存利用者の評価を落とすリスクが見合わない |

---

## 2. 確定事項

### 2-1. 価格

| プラン | 価格 | 手取り(15%控除後) |
| --- | --- | --- |
| 月額 | 650円 | 552円 |
| 年額 | 4,800円 | 4,080円（月あたり400円 = 38%引き） |

**値付けの根拠は PLAN.md「価格」節と KNOWLEDGE.md「価格相場」節を参照。**
両ファイルは収益目標と競合調査を含むため gitignore されており、本リポジトリには入っていない。

### 2-1-b. 無料トライアル（2026-09-09 決定）

**7日間。月額・年額の両方に付ける。** Apple の introductory offer（`FREE_TRIAL` / `ONE_WEEK`）で設定する。

当初この設計書はトライアルを範囲外にしていたが、方針を変えた。期間の根拠は同カテゴリの実勢：

| サービス | カテゴリ | トライアル |
| --- | --- | --- |
| Simeji | 日本語入力キーボード | 7日間 |
| Picsart | 画像加工 | 3日 または 7日 |
| 音楽・動画配信（Spotify / U-NEXT 等） | コンテンツ配信 | 1ヶ月 |

日本で「初月無料」が主流に見えるのは音楽・動画配信の慣習で、カタログを回遊して習慣化するのに1ヶ月要る業態のもの。
KNOWLEDGE.md が PKB のアンカーに挙げている Simeji・Picsart はどちらも1週間以下。

- **価値が伝わるのが早い**。有料価値は「9枚目を保存できる」の一点で、上限到達時のペイウォール
  （文脈的訴求4.2% vs 汎用1.3%、223%差）と組み合わせれば1週間で体験できる
- **解約率**。3日で26%、30日で51%がキャンセル。1ヶ月は「忘れて課金された」返金も増える
- **回収**。月650円で初月無料だと入金まで2ヶ月かかる

**反対材料**: RevenueCat 2026 は「17日以上のトライアルは転換率が70%良い（42.5% vs 25.5%）」としており、
これは1ヶ月を支持する。ただし全カテゴリ平均で、長いトライアルを出せるのは自信のある成熟アプリという
選択バイアスが疑われる。Photo & Video のトライアル→課金は22.2%とカテゴリ最下位。

**短い方から始める判断の決め手**: introductory offer は App Store Connect 側の設定なので、
**期間の変更にアプリの再提出が要らない**。KNOWLEDGE.md も「トライアル構成の変更」を LTV 改善レバーの
第2位（59.6%）に挙げている。7日で始めてデータを見て伸ばすのが低リスク。

**コード側の扱い**: トライアル中かどうかをアプリが区別する必要はない。`Transaction.currentEntitlements`
はトライアル中も権利ありとして返るため、`PremiumStore.isPremium` の判定は変わらない。
ペイウォールの文言だけ、トライアルの有無で出し分ける（`Product.SubscriptionInfo.introductoryOffer` を見る）。

### 2-2. 無料枠

**8枚。見本画像（`ownerId == "official"`）も枠を消費する。**

初期状態では見本が1枚入っているため、利用者が自分で保存できるのは7枚。見本を削除すれば8枚。
例外を設けないことで判定が単純になる。

### 2-3. 既存ユーザーの超過分

ストアの現行版（2019年の v1.0.0）には上限が無いため、8枚を超えて保有している利用者が存在しうる。
**超過分は取り上げず、そのまま表示・利用できる。** 8枚を下回るまで新規追加だけができない。
これは現行実装の振る舞いそのままで、追加実装は不要。

### 2-4. 課金状態の扱い

- **StoreKit を真実のソースにする。** App Group / UserDefaults / Realm には保存しない
- 理由: App Group コンテナ消失で課金が飛ぶ事故と、バックアップ経由の巻き戻しを防ぐ（PLAN.md 保存方針 決定8）
- キーボード拡張は課金状態を知らない

---

## 3. アーキテクチャ

### 3-1. 課金レイヤーの置き場所

**アプリ本体ターゲット（PhotoKeyboardEx）にのみ置く。PhotoKeyboardFramework には置かない。**

フレームワークはキーボード拡張と共有されるため、そこに課金コードを置くと拡張にも StoreKit が載る。
「拡張は課金状態を知らない」という方針に反し、拡張のメモリ上限にも不利。

```
PhotoKeyboardEx（アプリ本体）
├── PremiumStore.swift        新規: StoreKit 2 のラッパー
├── PhotoQuota.swift          新規: 上限判定の集約
├── PaywallViewController.swift 新規: ペイウォール画面
└── Paywall.storyboard        新規

PhotoKeyboardFramework（拡張と共有）
├── RealmManager.swift        変更: userPhotoCount のカウント対象
├── LocalizeKey.swift         変更: 文言キーの追加
└── {ja,en}.lproj/Localizable.strings  変更: 文言の追加と修正
```

### 3-2. PremiumStore

責務は「プレミアムかどうか」と「商品情報」を提供すること。それ以外を持たない。

```swift
@MainActor
final class PremiumStore {
    static let shared = PremiumStore()

    private(set) var isPremium: Bool
    private(set) var products: [Product]     // 月額・年額

    func loadProducts() async
    func purchase(_ product: Product) async throws -> Bool
    func restore() async throws
    func startObservingTransactions()        // Transaction.updates の監視
}
```

- 権利判定は `Transaction.currentEntitlements` を走査し、
  `productID` が自社のサブスクIDのいずれかで、かつ `revocationDate == nil` なものがあれば `isPremium = true`
- `Transaction.updates` の監視タスクは `AppDelegate` の起動時に開始し、アプリの生存期間中維持する
  （購入がアプリ外で起きた場合や、更新・返金を取りこぼさないため）
- 状態変化は `NotificationCenter` で流す。既存コードが通知を使っているため方式を揃える。
  通知名は `PhotoKeyboardEx/Extension.swift:21-24` の `Notification.Name` 拡張に追加する
  （`updateSaveState` / `finishUpload` / `allReload` と同じ場所。**アプリ本体側にあるので課金用の通知の置き場所として適切**）

**判定を毎回 StoreKit に問い合わせるか、キャッシュするか**: メモリ上のプロパティにキャッシュし、
`Transaction.updates` と起動時の再判定で更新する。ディスクには書かない。

### 3-3. PhotoQuota — 上限判定の集約

現状、上限判定は `RealmManager.canSaveMorePhotos`（フレームワーク側）が担っており、
呼び出しは2箇所ある。

| 入口 | 現在の場所 |
| --- | --- |
| FABタップ時（写真を選ぶ前） | `MainTabViewController.swift:173` |
| 保存直前の再判定 | `AddViewController.swift:176` |

課金状態はアプリ本体しか知らないため、フレームワーク単体では判断できない。
そこでアプリ本体に薄い集約点を置く。

```swift
enum PhotoQuota {
    /// あと1枚保存できるか。プレミアムなら常に true
    static var canSave: Bool {
        if PremiumStore.shared.isPremium { return true }
        return RealmManager.shared.canSaveMorePhotos
    }
}
```

上記2箇所を `PhotoQuota.canSave` に差し替える。
`RealmManager.photoLimit` と `canSaveMorePhotos` は**無料枠の定義として残す**（削除しない）。

### 3-4. 見本画像を枠に数える変更

現在 `RealmManager.swift:249-251` の `userPhotoCount` は `isUserOwned` で見本を除外している。

```swift
// 変更前
return realmData.filter { $0.isUserOwned }.count
// 変更後
return realmData.count
```

`isUserOwned` / `officialOwnerId` は見本の識別に使われ続けるため**残す**
（`Photo.swift:97,100-102`、生成は `Photo.swift:123`、テストは `PhotoKeyboardFrameworkTests.swift:637-648`）。

**注意**: `MainTabViewController.swift:126` の `seedTutorialPhotoIfNeeded()` は上限判定を通さずに保存する。
見本が枠を消費するようになっても、投入時点の保有数は0なので問題は起きない。判定を足す必要はない。

**プロパティ名について**: `userPhotoCount` は「利用者が保存した枚数」を意味していたが、
見本を含むようになるため実態と合わなくなる。`savedPhotoCount` へ改名する。

改名の影響範囲は実コードで確認済み。`userPhotoCount` の参照は
`RealmManager.swift:255`（`canSaveMorePhotos` の中）**1箇所のみ**。
`photoLimit` の参照も同じ行だけで、`public static let` なので文言の書式に差し込める。
`canSaveMorePhotos` の呼び出しは `AddViewController.swift:176` と
`MainTabViewController.swift:173` の**2箇所のみ**で、どちらもアプリ本体ターゲットにある
（＝フレームワークに課金を持ち込まずに差し替えられる）。

---

## 4. App Store Connect

### 4-1. 商品

サブスクリプショングループを1つ作り、その中に2つを置く。
同一グループに入れることでプラン変更（月額↔年額）が Apple 側で自動処理される。

| 項目 | 値 |
| --- | --- |
| グループ名 | ペリペリ プレミアム |
| 月額 Product ID | `bocchi.PhotoKeyboardEx.premium.monthly` |
| 年額 Product ID | `bocchi.PhotoKeyboardEx.premium.yearly` |
| 価格 | 650円 / 4,800円 |
| 基準ストアフロント | **日本**（USにすると円安のたびに Apple の為替調整で日本価格が動く） |

App ID は 1477807463。

### 4-2. コード外の必須作業

| 作業 | 備考 |
| --- | --- |
| **小規模事業者プログラムへの登録** | **自動適用されない。手動登録が必要。**忘れると手数料が30%になる |
| 無料トライアル（introductory offer）の設定 | 月額・年額の両方に7日間。`FREE_TRIAL` / `ONE_WEEK` |
| 「Appのプライバシー」回答の更新 | 広告撤去でトラッキング用途のデバイスID収集が無くなったため |
| サブスクリプションの表示名・説明文の登録 | 審査対象 |

---

## 5. UI

### 5-1. 上限到達時の導線（最重要）

**上限に当たった瞬間の文脈的な訴求が、汎用的な案内より大きく効く**（根拠は KNOWLEDGE.md）。
8枚目を保存しようとした瞬間が最大の導線になる。

現在の `MainTabViewController.swift:185-191` `presentLimitReachedAlert()` は
`UIAlertController` に OK のアクションが1つあるだけで、課金への出口が無い。

**変更**: アクションを2つにする。

- 「プレミアムを見る」→ ペイウォールを present
- 「閉じる」→ 何もしない

`AddViewController.swift:158-168` の `UploadError.limitReached` と
`:222-228` の `showUploadError()` も同様に扱う。こちらは title が nil で message のみなので、
上限のときだけ専用の分岐を通す。

### 5-2. ペイウォール画面

新規 `PaywallViewController`。**日本向けの構成**（縦長スクロール＋Free/Pro比較表＋社会的証明）にする。
この形が有効である根拠は KNOWLEDGE.md を参照。

**構成（上から）**

1. 見出し — 何が解放されるか（無制限保存）
2. Free / プレミアムの比較表
3. プラン選択 — 年額を上、月額を下。年額に「月あたり400円」「38%お得」を添える
4. 購入ボタン
5. 自動更新の説明文（期間・価格・自動更新される旨・解約方法）
6. 「購入を復元」ボタン
7. 利用規約 / プライバシーポリシーへのリンク

**審査要件（ガイドライン 3.1.2）**: 3・5・6・7 は必須。欠けるとリジェクトされる。

リンク先は既存のものを使う（`TopViewController.swift:76-82` で使用中。両方とも到達可能なことを確認済み）。

- 利用規約: https://pkbkeyboard.studio.design/terms
- プライバシーポリシー: https://pkbkeyboard.studio.design/privacy

**入口は2つ**

| 入口 | 場所 |
| --- | --- |
| 上限到達時 | 5-1 のアラートから |
| サイドメニュー | `MainMenuTableViewController.swift`（クラス名は `MyMenuTableViewController`） |

サイドメニューは現在**行数が固定2**（`:48-50`）で、`cellForRowAt`（`:63-69`）と
`didSelectRowAt`（`:76-95`）が `indexPath.row` の switch で default 依存になっている。
項目を足すときはこの3箇所を同時に触る必要がある。

プレミアム加入済みの場合は、メニューの項目を「プレミアム」から「ご利用中のプラン」等に変え、
ペイウォールではなく状態表示にする（購入済みの人に購入を勧めない）。

### 5-3. 文言

`LocalizeKey`（`PhotoKeyboardFramework/LocalizeKey.swift`）にキーを追加し、
`PhotoKeyboardFramework/{ja,en}.lproj/Localizable.strings` に文面を書く。

**strings はフレームワーク側に置くこと。** `LocalizeKey.localizedString()` は
`CommonUtil.shared.bundle`（`CommonUtil.swift:16,18` = フレームワーク自身の Bundle）から引くため、
アプリ本体に置いても読まれない。

**既存文言の修正**: 現在の上限文言は枚数が直書きで `photoLimit` と連動していない。

```
ja: "limitReachedTitle" = "保存できるのは8枚まで。";   (ja.lproj/Localizable.strings:60)
en: "limitReachedTitle" = "You can keep up to 8.";   (en.lproj/Localizable.strings:60)
```

`%d` の書式に変え、`String(format:)` で `RealmManager.photoLimit` を差し込む。

---

## 6. テスト

### 6-1. 現状

`photoLimit` / `canSaveMorePhotos` / `userPhotoCount` を検証するテストは**1件も存在しない**。
関連するのは見本画像の同一性テスト（`PhotoKeyboardFrameworkTests.swift:637-648`）のみで、
これは ID の安定性と `ownerId == "official"` を検証している。

### 6-2. 追加するテスト

**フレームワーク側**

- `savedPhotoCount` が見本画像を**含めて**数えること（今回の変更の核。従来と逆になる）
- 8枚で `canSaveMorePhotos` が false になること
- 8枚を超えて保有している場合も false のままで、例外や不整合が起きないこと（既存ユーザーの超過分）

**アプリ本体側**

- `PhotoQuota.canSave` がプレミアム時に常に true を返すこと
- 非プレミアム時は `RealmManager.canSaveMorePhotos` に従うこと

`PhotoKeyboardFrameworkTests.swift:637-648` の既存テストは、
「上限カウント除外の前提」を守る意図で書かれている。**この意図が変わるためコメントを更新する**
（ID の安定性の検証自体は引き続き有効なので残す）。

### 6-3. 購入フローの検証

`.storekit` のテスト設定ファイルを作り、スキームに紐づける。シミュレータで次を通す。

- 月額の購入 → `isPremium` が true → 9枚目が保存できる
- 年額の購入 → 同上
- 復元 → アプリ削除・再インストール後に `isPremium` が戻る
- 失効 → `isPremium` が false → 上限が復活し、既存の画像は消えない

**注意**: テストターゲットからの画面描画によるスクリーンショット確認は、
本リポジトリで既に実績のある手法（詳細画面の字幕実装時に使用）。ペイウォールの見た目確認にも使える。

---

## 7. 実装順序

前のステップが後のステップの前提になっている。

| 順 | 内容 | 単独で検証できるか |
| --- | --- | --- |
| 1 | `savedPhotoCount` を全件カウントに変更 ＋ テスト追加 | できる（課金と無関係） |
| 2 | 文言の `%d` 化 | できる |
| 3 | `PremiumStore` の実装 ＋ `.storekit` でのテスト | できる（UIなしで検証可能） |
| 4 | `PhotoQuota` の追加と呼び出し2箇所の差し替え | できる |
| 5 | ペイウォール画面 | 3・4 の後 |
| 6 | 上限到達アラートからの導線 | 5 の後 |
| 7 | サイドメニューへの項目追加 | 5 の後 |
| 8 | App Store Connect の商品登録と小規模事業者プログラム登録 | コード外。3 の前に済ませると実機確認が早い |

1〜2 は課金と独立しているため先に入れて単独でリリースしてもよい。

---

## 8. 未決の論点

本設計では決めていない。実装中に判断が要る場合はその時点で確認する。

| 論点 | 備考 |
| --- | --- |
| ペイウォールの具体的な文面 | 「社会的証明」に何を出すか（レビュー件数・利用者数など）は、出せる実績が無い段階では省く判断もありうる |
| プレミアム加入済み時のサイドメニュー表示 | 「ご利用中のプラン」から解約導線（設定アプリへ）を出すか |

---

## 9. このファイルの扱い

本設計書は**技術設計のみ**を含む。収益目標・市場調査・値付けの根拠は
PLAN.md / KNOWLEDGE.md / TODO.md 側にあり、これらは
「収益目標や戦略を含むため公開リポジトリには置かない」という方針で gitignore されている
（本リポジトリは公開）。**この分離を崩さないこと。**
