# PhotoKeyboardEx (PKB) 仕様

画像をスタンプのように貼り付けて送れるカスタムキーボードアプリの確定仕様。
コードから読み取れる現状の実装をまとめたもので、企画意図や今後の変更方針は PLAN.md を参照。

- App Store 提出中（バージョン 2.0.0）
- iOS 16.0 以上
- 対応言語: 日本語 / 英語

## 全体像

3つのターゲットで構成される。以前あった通知拡張（ServiceNotification）は未使用のため削除済み。

| ターゲット | 役割 |
| --- | --- |
| PhotoKeyboardEx（管理アプリ本体） | 画像の保存・閲覧・キーボード設定案内 |
| PhotoKeyboardExOrigin（キーボード拡張） | 入力欄で保存済み画像を貼り付ける／文字入力する |
| PhotoKeyboardFramework | 上記が共有するモデル・ユーティリティ |

本体とキーボード拡張は **App Group（`group.bocchi.PhotoKeyboardEx`）** を通じて Realm と UserDefaults を共有する。

## ユースケース

1. **自分用に画像を貯める** — 気に入った画像を保存し、キーボードから送る
2. **キーボードから送る** — キーボードで画像をタップしてコピーし、入力欄に貼り付けて送信する

他ユーザーの投稿を閲覧・保存する機能、投稿の通報・ブロックは 2026年8月の方針転換（PLAN.md 方針3）で
廃止済み。UI・サーバー通信のいずれにも該当する経路は残っていない。

## 管理アプリ本体

タブ構成は無く、「マイボード」1画面のみ（`MainTabViewController`）。以前は Tabman + Pageboy で
8タブ（マイボード／新着／人気／ジャンル別5種）を切り替えていたが、公開フィードの廃止に伴い両ライブラリごと外した。

- 一覧は2列の固定サイズグリッド（画像は正方形＋下部に情報エリア）
- 画像は Realm から読み込むのみ。サーバーへの問い合わせは行わない

### 投稿（AddViewController）

- 画像を選び、タイトルを入力して保存する（ジャンルの概念は無い）
- 画像は長辺 1080px に縮小、JPEG 品質 0.85 で Realm に保存
- 公開投稿は廃止済み。保存先は常に端末内の Realm のみで、サーバーへは送らない

### オンボーディング

起動時に出すのは Top のみ。Usage（キーボード設定案内）は最初の1枚を保存した直後に出す。
キーボードの有効化を初めて検知したとき（アプリが前面に戻ったタイミングで `AppleKeyboards` に
拡張のバンドルIDが含まれる）に「送り方」（`HowToSendViewController`、タップ→長押しでペースト→送信）を
一度だけ出す。Usage と送り方はサイドメニューからも開ける。各段階の表示要否は App Group の UserDefaults の
フラグ（registerNeedFlag / usageNeedFlag / howToSendNeedFlag）で管理。

## キーボード拡張

- 保存済み画像の一覧を表示。画像モードと文字入力モードを切り替え可能
- 画像をタップするとロゴを右下に合成してクリップボードにコピー（貼り付けできる）
- 画像の使用回数（useNum）を記録し、並び替えに使う
- 上部バー: ホーム（本体アプリを開く）/ 列数切替（3列⇔5列）/ モード切替（画像⇔文字）。
  地球儀（次のキーボードへの切り替え）は iOS 標準のシステムボタン
- URLオープンは SwiftUI の Link をボタンに重ねて実現（iOS 18 で拡張から imperative に URL を開けなくなったため）
- **フルアクセスが必須**（クリップボード利用のため）。未許可時は機能を制限し設定への導線を出す

## データの持ち方

| データ | 保存先 |
| --- | --- |
| 画像の実体・自分の保存分・使用回数 | 端末内 Realm（App Group 共有） |
| 各種フラグ（オンボーディング表示済み等）・送信回数・列数設定 | App Group の UserDefaults |

すべて端末内のみで完結し、サーバーへの送信は行わない（PLAN.md 方針5）。旧バックエンド（Supabase、
匿名認証 + Postgres + Storage）は2026年8月に撤去済み。当時使用していたプロジェクト自体も
既に存在しない。スキーマ定義（`supabase_setup.sql` 等）は将来のパック販売転用に備えてリポジトリに
残しているだけで、現行アプリからは参照されない。

Realm ファイルは端末ロケールに依存しない単一ファイル（`db.realm.shared`）。旧バージョンのロケール別ファイルは初回起動時に統合される。

## 主要な外部ライブラリ（SPM）

Realm / Lottie（アニメーション）/ SwiftDate / Toast-Swift。
FontAwesome はSPM非対応のため `PhotoKeyboardFramework/FontAwesome/` に直接組み込み。

過去に使っていた Supabase / Tabman・Pageboy / TagListView / DynamicColor / GoogleMobileAds /
GoogleUserMessagingPlatform / Alamofire / SwiftyJSON は、機能ごと撤去した際に依存関係からも外した。

## 収益・広告

**現状、収益化のコードは入っていない。**

- ライフ + リワード広告は撤去済み（`saveLife` / `GoogleMobileAds` / `Reward` はコード上 0 ヒット）
- アプリ内課金は未実装。`import StoreKit` は `AddViewController.swift:10` の 1 箇所のみで、
  用途は `SKStoreReviewController.requestReview`（レビュー依頼）
- 保存枚数の上限は実装済み。`RealmManager.photoLimit` が 8 枚で、見本画像
  （`ownerId == "official"`）は数に入れない。判定は追加の入口（FAB）と保存直前の
  2 箇所で行う

**上限を超えたときの導線は用意していない。** 課金階層が無いため、8 枚に達した利用者は
既存の画像を消す以外に手がない。予定している課金モデル（月650円・年4,800円）は
PLAN.md 方針2、実装項目は TODO.md を参照。

## 外部通信

唯一の外部通信は、起動時に App Store の最新バージョンを確認する処理（`UpdateExtention.swift`）。
`https://itunes.apple.com/lookup?id=1477807463` に GET するだけで、送信内容は固定のアプリIDのみ。
個人を識別する情報は含まない。
