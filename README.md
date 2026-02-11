<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>プライバシーポリシー | cometas</title>
  <style>
    :root { color-scheme: light dark; }
    body { font-family: -apple-system, BlinkMacSystemFont, "Hiragino Sans", "Noto Sans JP", "Segoe UI", Roboto, Arial, sans-serif; line-height: 1.7; margin: 0; padding: 24px; }
    main { max-width: 900px; margin: 0 auto; }
    h1 { font-size: 1.6rem; margin: 0 0 8px; }
    h2 { font-size: 1.15rem; margin-top: 28px; }
    p, li { font-size: 1rem; }
    .meta { opacity: .8; font-size: .95rem; margin-bottom: 20px; }
    .box { border: 1px solid rgba(127,127,127,.35); border-radius: 12px; padding: 14px 16px; margin: 12px 0; }
    code { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace; font-size: .95em; }
    a { word-break: break-word; }
  </style>
</head>
<body>
<main>
  <h1>プライバシーポリシー</h1>
  <div class="meta">
    対象アプリ：<strong>cometas</strong><br />
    事業者（開発者）：<strong>Tsukasa Nishioka</strong><br />
    施行日：<strong>2026-02-11</strong>
  </div>

  <p>
    本プライバシーポリシーは、モバイルアプリ「cometas」（以下「本アプリ」）における、ユーザー情報の取扱いについて定めるものです。
    本アプリは、頻度の少ない（たまに必要な）作業を忘れないように記録・管理するためのアプリであり、
    主にホーム画面ウィジェットからの操作（「やった」等の登録）を想定して設計されています。
  </p>

  <div class="box">
    <strong>結論（要点）</strong>
    <ul>
      <li>本アプリは、<strong>ユーザーの個人情報を収集しません</strong>。</li>
      <li>本アプリは、<strong>外部サーバーへのデータ送信を行いません</strong>。</li>
      <li>本アプリは、<strong>広告SDK・解析SDK・トラッキングを利用しません</strong>。</li>
      <li>本アプリのデータは、<strong>端末内（およびApp Group領域）にのみ保存</strong>されます。</li>
    </ul>
  </div>

  <h2>1. 収集する情報</h2>
  <p>本アプリは、以下の情報を<strong>収集しません</strong>。</p>
  <ul>
    <li>氏名、メールアドレス、電話番号などの個人を特定できる情報</li>
    <li>位置情報（GPS等）</li>
    <li>連絡先、写真、カレンダー等の端末内個人データへのアクセス</li>
    <li>IPアドレス等を含む解析・広告目的のログ（第三者SDKによる収集を含む）</li>
    <li>広告識別子（IDFA）等のトラッキング情報</li>
  </ul>

  <h2>2. 本アプリ内で保存されるデータ</h2>
  <p>
    本アプリは、ユーザーが入力・操作した内容を、端末内に保存します。保存される内容の例は以下のとおりです。
  </p>
  <ul>
    <li>管理項目名（例：洗濯槽洗浄 等）</li>
    <li>間隔設定（例：2ヶ月 等）</li>
    <li>前回実施日、次回予定日</li>
    <li>操作履歴（「やった」「スキップ」等の履歴）</li>
  </ul>
  <p>
    これらのデータは、アプリ本体とウィジェットで共有するため、端末内の
    <strong>UserDefaults</strong> および <strong>App Group領域</strong>（Widget共有用）に保存されます。
    保存されたデータは、開発者を含む第三者に送信されません。
  </p>

  <h2>3. データの利用目的</h2>
  <p>
    端末内に保存されたデータは、以下の目的でのみ利用されます。
  </p>
  <ul>
    <li>次回予定日の自動計算・表示</li>
    <li>ウィジェットでの表示（項目名・残り日数等）</li>
    <li>履歴の一覧表示</li>
  </ul>

  <h2>4. 外部送信・第三者提供</h2>
  <p>
    本アプリは、ユーザー情報やアプリ内データを<strong>外部サーバーへ送信しません</strong>。
    また、第三者へ提供・販売・共有することはありません。
  </p>
  <p>
    本アプリは、広告配信SDK、アクセス解析SDK、クラッシュ解析SDK等の第三者サービスを<strong>利用していません</strong>。
  </p>

  <h2>5. ウィジェット操作（AppIntent）について</h2>
  <p>
    本アプリは、WidgetKitおよびAppIntentを利用し、ホーム画面ウィジェット上のボタンから記録操作を行えるようにしています。
    ウィジェットからの操作により、端末内に保存された「前回実施日」「次回予定日」「履歴」等が更新されます。
  </p>
  <p>
    これらの処理は、<strong>ユーザーがウィジェット上でボタンを押した場合にのみ</strong>実行されます。
    ユーザーの操作なく、バックグラウンドで自動的に記録・送信を行うことはありません。
  </p>

  <h2>6. 通知・トラッキング</h2>
  <p>
    本アプリは、プッシュ通知やリマインド通知を利用しません。
    また、ユーザーを追跡する仕組み（IDFA等）を使用しません。
  </p>

  <h2>7. データの保持期間と削除方法</h2>
  <p>
    本アプリのデータは端末内に保存され、ユーザーが削除するまで保持されます。
  </p>
  <ul>
    <li>アプリをアンインストールすることで、端末内に保存された本アプリのデータは通常削除されます。</li>
    <li>端末の設定等によりApp Group領域のデータが残る場合があります。必要に応じて、アプリの再インストール後にデータを上書きすることで整理できます。</li>
  </ul>

  <h2>8. 子どものプライバシー</h2>
  <p>
    本アプリは、13歳未満の子どもから意図的に個人情報を収集することはありません。
    また、本アプリは個人情報の入力や外部送信を前提としていないため、子どもの個人情報が収集されることは想定していません。
  </p>

  <h2>9. セキュリティ</h2>
  <p>
    本アプリは、データを端末内にのみ保存し、外部送信を行いません。
    端末のロックやOSのセキュリティ機能等により保護されます。
  </p>

  <h2>10. 本ポリシーの変更</h2>
  <p>
    本プライバシーポリシーは、必要に応じて改定される場合があります。
    変更がある場合は、本ページにて最新の内容を掲載します。
  </p>

  <h2>11. お問い合わせ</h2>
  <p>
    本アプリのプライバシーに関するご質問は、以下までご連絡ください。
  </p>
  <p>
    連絡先：<a href="mailto:id6tztx7912@gmail.com">id6tztx7912@gmail.com</a>
  </p>

  <hr />
  <p class="meta">
    本ポリシーは cometas の現行仕様（外部送信なし、広告・解析なし、端末内保存）に合わせて作成しています。<br />
    将来的に解析ツール・広告・アカウント機能等を追加する場合は、本ポリシーの更新が必要です。
  </p>
</main>
</body>
</html>
