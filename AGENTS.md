# AGENTS.md

## プロジェクト概要
- `cometas` は「頻度の低い家事・作業の実施記録」を管理する iOS アプリ。
- 構成は App / Widget / Tests の 3 ターゲット。
  - App: `cometas`
  - Widget: `cometasWidgetExtension`
  - Unit Test: `cometasTests`
- 主なディレクトリ責務:
  - `cometas/Domain`: ドメインモデル・ユースケース・日付計算
  - `cometas/Infrastructure`: 永続化・共有ストア・Widget 更新
  - `cometas/Features`: 画面と状態管理
  - `cometas/Intent`: AppIntent と Widget 操作アダプタ
  - `cometasWidget`: Widget の Provider / View

## ビルド・テストコマンド
- 事前確認（利用可能な宛先の確認）:
  - `xcodebuild -showdestinations -project cometas.xcodeproj -scheme cometas`
- アプリ本体ビルド:
  - `xcodebuild -project cometas.xcodeproj -scheme cometas -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/cometas-deriveddata build`
- ウィジェット拡張ビルド:
  - `xcodebuild -project cometas.xcodeproj -scheme cometasWidgetExtension -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/cometas-deriveddata build`
- テスト実行（シミュレータ）:
  - `xcodebuild -project cometas.xcodeproj -scheme cometas -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath /tmp/cometas-deriveddata test`
- 特定テストのみ:
  - `xcodebuild -project cometas.xcodeproj -scheme cometas -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath /tmp/cometas-deriveddata -only-testing:cometasTests/DomainAndUseCaseTests test`

## コーディングスタイルガイドライン
- レイヤ境界を守る:
  - `Domain` は UI フレームワークに依存しない。
  - `Features` から `UserDefaults` やキー文字列へ直接アクセスしない（`Infrastructure` 経由）。
- 命名規則:
  - 型名は `UpperCamelCase`、プロパティ/関数は `lowerCamelCase`。
  - 真偽値は `is/has/can` で始める。
- 依存注入とテスト容易性:
  - 副作用（保存、Widget 更新、日付計算）は protocol 経由で差し替え可能にする。
- 日付/時刻:
  - 日付計算は `Calendar` を明示的に扱い、テストではタイムゾーンを固定する。
- 変更方針:
  - 既存ロジックと重複する処理を追加せず、共通層へ寄せる。

## テスト手順
- 1. 変更対象に応じて Unit Test を追加・更新する（最低 1 ケース以上）。
- 2. まず対象テストだけを実行し、次に全体テストを実行する。
- 3. Widget 連携変更時は手動確認を行う:
  - アプリで設定値更新
  - Widget 表示が反映されること
  - `DoneIntent` 実行で履歴と次回日付が更新されること
- 4. 回帰確認として以下を確認:
  - 既存履歴の読み込み
  - 次回日付計算（`Interval` ごと）
  - primary/secondary タスクのデータ混線がないこと

## セキュリティに関する注意事項
- 本プロジェクトの前提:
  - データは端末内（`UserDefaults` + App Group）保存のみ。
  - 外部送信・トラッキング SDK は導入しない。
- 実装上の注意:
  - 機密値（API キー等）をソースコードや Git 履歴へコミットしない。
  - App Group ID（`group.com.tsukasa.nishioka.cometas`）を変更する場合は移行手順を必ず定義する。
  - 永続化キーを変更する場合はデータ移行コードと互換テストを追加する。
  - `fatalError` を増やす場合は運用影響を評価し、可能ならフォールバックを優先する。

