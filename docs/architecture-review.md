# cometas アーキテクチャレビュー（2026-02-28）

## 現状の課題

1. **ドメインロジックが View / Intent / Widget に分散して重複している**
   - 次回日付計算が `SingleItemView` と `DoneAction` に重複。
   - 保存キーの解釈（`item`, `intervalRawValue`, `nextDueTimestamp`）が複数箇所に散在。

2. **永続化層が UI 型に依存している**
   - `HistoryRepository` が `SwiftUI` と `IndexSet` を直接利用し、Repository 層が UI フレームワークに引っ張られている。

3. **Shared 設計の責務境界が曖昧**
   - `Shared` フォルダにストレージ／ドメイン／Widget 更新が混在。
   - 再利用したいロジックと、プラットフォーム依存ロジック（WidgetCenter）が分離されていない。

4. **状態管理の更新効率が低い**
   - `HistoryStore.add/delete` で毎回 `reload()` を呼び、全件再読込している。

5. **未使用コード・暫定コードが残存**
   - `bkContentView .swift` が実験コードのまま残っている。
   - `SettingView` はタブから外されているがファイルは残存。

6. **テストしづらい構造**
   - `SharedStore.defaults`、`WidgetCenter.shared` などの static 直接参照が多く、モック差し替えしづらい。

## 改善方針

### A. レイヤ分離（最低限）

- **Domain 層**
  - `Interval`, `HistoryEntry`, `HistoryType`
  - `NextDueDateCalculator`（次回日付計算）
  - `RecordDoneUseCase` / `SkipUseCase`
- **Infrastructure 層**
  - `HistoryRepository` の実装（UserDefaults/App Group）
  - `SettingsStore`（item, interval, timestamps）
- **Presentation 層**
  - `SingleItemView`, `HistoryView`, `HistoryStore`（ViewModel化）
- **Widget 層**
  - Provider / View（Domain の読み取り専用APIを呼ぶ）

### B. 共有キーと契約の一本化

- `SharedStore` にキーを列挙するのではなく、
  `AppSettings` などの typed API に隠蔽。
- UI から文字列キーへ直接アクセスしない。

### C. Repository の UI 依存排除

- `delete(at offsets: IndexSet)` を廃止し、
  `delete(ids: [UUID])` など Domain 依存 API に変更。
- `SwiftUI` import を Repository から外す。

### D. 更新処理の最適化

- `HistoryStore` は append/delete 時に in-memory 配列を更新し、必要時のみ reload。
- AppIntent 実行後は Notification / Combine で差分同期。

### E. 不要コードの整理

- `bkContentView .swift` を削除（必要なら `Archive/` へ移動）。
- 未使用の `SettingView` は roadmap issue 化してから削除 or 実装。

### F. テスト導入

- まずは純粋関数化しやすい `NextDueDateCalculator`, `dueStatus`, 履歴操作UseCaseから Unit Test。

## 推奨パッケージ（ディレクトリ）構成案

```text
cometas/
  App/
    cometasApp.swift
    ContentView.swift
  Features/
    SingleItem/
      SingleItemView.swift
      SingleItemViewModel.swift
    History/
      HistoryView.swift
      HistoryViewModel.swift
  Domain/
    Model/
      HistoryEntry.swift
      Interval.swift
    UseCase/
      RecordDoneUseCase.swift
      SkipUseCase.swift
    Service/
      NextDueDateCalculator.swift
  Infrastructure/
    Storage/
      AppGroupSettingsStore.swift
      UserDefaultsHistoryRepository.swift
    Shared/
      SharedStore.swift
  Intent/
    DoneIntent.swift

cometasWidget/
  Provider/
    Provider.swift
  View/
    WidgetView.swift
  Adapter/
    WidgetDoneActionAdapter.swift
```

## 優先度つき修正案（現実的な順序）

1. **P1（小さく効く）**
   - キー定数の一本化 + 重複ロジック（次回日付計算）を共通関数へ。
2. **P1**
   - `HistoryRepository` から `SwiftUI`/`IndexSet` を除去。
3. **P2**
   - `HistoryStore` の再読込戦略を改善（差分更新）。
4. **P2**
   - 不要ファイル削除（`bkContentView .swift` など）。
5. **P3**
   - ViewModel + UseCase へ分割し、Widget 側は Adapter 経由へ。
6. **P3**
   - Unit Test を追加。

## 期待効果

- 仕様変更時の修正点を 1 箇所に集約（バグ混入率を低減）。
- App / Widget の挙動差異を減らし、同期不整合を予防。
- テスト可能性の向上により、安心して機能拡張できる。
