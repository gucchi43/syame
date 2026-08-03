# PhotoKeyboardEx (PKB) 仕様

画像をスタンプのように貼り付けて送れるカスタムキーボードアプリの確定仕様。
コードから読み取れる現状の実装をまとめたもので、企画意図や今後の変更方針は PLAN.md を参照。

- App Store 公開中（バージョン 1.0.10）
- iOS 16.0 以上
- 対応言語: 日本語 / 英語

## 全体像

2つのターゲットで構成される。

| ターゲット | 役割 |
| --- | --- |
| PhotoKeyboardEx（管理アプリ本体） | 画像の投稿・保存・閲覧・通報を行う |
| PhotoKeyboardExOrigin（キーボード拡張） | 入力欄で保存済み画像を貼り付ける／文字入力する |
| ServiceNotification（通知拡張） | リッチプッシュ通知の画像添付（現状プッシュ登録は未実装） |
| PhotoKeyboardFramework | 上記が共有するモデル・ユーティリティ |

本体とキーボード拡張は **App Group（`group.bocchi.PhotoKeyboardEx`）** を通じて Realm と UserDefaults を共有する。

## ユースケース

1. **自分用に画像を貯める** — 気に入った画像を保存し、キーボードから送る
2. **公開投稿する** — タイトルとジャンルを付けて投稿し、他ユーザーのタブに載せる
3. **他人の投稿を保存する** — 一覧で save して自分のマイボードに追加し、キーボードで使う
4. **通報・ブロックする** — 不適切な投稿を通報／非表示にする

## 管理アプリ本体

### タブ構成（8タブ）

`GenreTagType` で定義。順序と件数は固定で、タブ見出しと一致していないと範囲外アクセスになる。

| index | タブ | 内容 |
| --- | --- | --- |
| 0 | マイボード | 端末に保存済みの画像（Realm） |
| 1 | 新着 | 公開投稿を作成日時の降順で表示（起動時の初期表示） |
| 2 | 人気 | 直近7日間で週間保存数の多い順 |
| 3 | ユーモア | ジャンル「ユーモア」の投稿 |
| 4 | クール | ジャンル「クール」 |
| 5 | キュート | ジャンル「キュート」 |
| 6 | シリアス | ジャンル「シリアス」 |
| 7 | その他 | ジャンル「その他」 |

- 一覧は2列の固定サイズグリッド（画像は正方形＋下部に情報エリア）
- サーバー系タブは20件ずつのオフセットページング
- 各タブのロケール絞り込み: 端末の言語が日本語なら `JP`、それ以外は `WORLD`

### 投稿（AddViewController）

- 画像を選び、タイトルとジャンルを入力して投稿
- 画像は長辺 1080px に縮小、JPEG 品質 0.85 で保存・アップロード
- 公開投稿: Supabase Storage に画像をアップロード → `photos` テーブルに INSERT → Realm にも保存
- 非公開投稿: Realm のみに保存（サーバーには送らない）

### 保存とライフ（AdMob 連携）

- 他人の投稿を save すると自分のマイボードに追加され、サーバーの保存数が増える
- 保存には「ライフ」を消費する。初期値 5、使い切ると save 時にリワード広告の視聴を促す
- 広告を見るとライフが加算される

### 通報・ブロック

- 投稿詳細から通報（スパム / 不適切）またはブロックができる
- 通報はサーバーの `reports` に記録され、一定数（現状3件）で自動的に非表示になる
- ブロックは端末ローカル（App Group の UserDefaults）に保存され、一覧から除外される

### オンボーディング

初回起動時に Top → Usage（キーボード設定案内）→ Welcome の順で表示。各段階の表示要否は UserDefaults のフラグで管理。

## キーボード拡張

- 保存済み画像の一覧を表示。画像モードと文字入力モードを切り替え可能
- 画像をタップするとロゴを右下に合成してクリップボードにコピー（貼り付けできる）
- 画像の使用回数（useNum）を記録し、並び替えに使う
- 上部バー: ホーム（本体アプリを開く）/ ヘルプ（公式LINE）/ 並び替え（人気順・あいうえお順）/ モード切替
- URLオープンは SwiftUI の Link をボタンに重ねて実現（iOS 18 で拡張から imperative に URL を開けなくなったため）
- **フルアクセスが必須**（クリップボード利用のため）。未許可時は機能を制限し設定への導線を出す

## バックエンド（Supabase）

匿名認証（Anonymous Sign-in）を前提とする。ユーザーはサインアップ不要で使い始められる。

### テーブル

| テーブル | 用途 |
| --- | --- |
| photos | 公開投稿。タイトル・画像URL・ジャンル・保存数・ロケール・is_hidden など |
| reports | 通報。閾値到達で photos を自動非表示にするトリガあり |
| app_config | 強制アップデートのバージョン・メッセージ（RemoteConfig 代替） |

- Storage バケット `photos`（公開・5MB上限・jpeg/png のみ）
- 画像パスは `{locale}/{uuid}.jpg`（locale は JP / WORLD）

### セキュリティ（RLS）

- photos: is_hidden=false のみ全員閲覧可 / 作成・削除は本人のみ / 直接 UPDATE 不可
- 保存数の増減は `change_save_count(photo_id, delta)` RPC 経由（authenticated のみ実行可）
- Storage: 自分名義・所定パスのみアップロード／更新／削除可

スキーマ定義は `supabase_setup.sql`（新規構築用）、稼働中プロジェクトへの適用は `supabase_migration_001_security.sql`。

### 接続情報

URL と anon key はビルド設定（`SUPABASE_URL` / `SUPABASE_ANON_KEY`）から、フレームワークの Info.plist を経由して読み込む。構成ごとに別プロジェクトを指定できる。

## データの持ち方

| データ | 保存先 |
| --- | --- |
| 画像の実体・自分の保存分・使用回数 | 端末内 Realm（App Group 共有） |
| ブロックリスト・各種フラグ・認証UID | App Group の UserDefaults |
| 公開投稿・保存数・通報 | Supabase（Postgres + Storage） |

Realm ファイルは端末ロケールに依存しない単一ファイル（`db.realm.shared`）。旧バージョンのロケール別ファイルは初回起動時に統合される。

## 主要な外部ライブラリ（SPM）

Supabase / Realm / Lottie（アニメーション）/ Tabman・Pageboy（タブ）/ TagListView / DynamicColor / SwiftDate / Toast / GoogleMobileAds / GoogleUserMessagingPlatform / Alamofire / SwiftyJSON。
FontAwesome はSPM非対応のため `PhotoKeyboardFramework/FontAwesome/` に直接組み込み。

## 収益・広告

- AdMob のリワード広告（ライフ回復）
- ATT（AppTrackingTransparency）と UMP（同意管理）に対応。同意フォームは AdMob コンソール側の設定が別途必要
