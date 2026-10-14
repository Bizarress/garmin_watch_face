# vivoactive 5 ウォッチフェイス集

Garmin vivoactive 5（390×390 AMOLED、丸形）向けのウォッチフェイスを、候補ごとに設計・実装するリポジトリです。
デザインの選定が一段落し、11 の候補を 1 つずつ仕様化して実装する段階にあります。

## 構成

| パス | 内容 |
|---|---|
| `faces/<番号-名前>/README.md` | その候補の仕様書（コンセプト、画面構成、データ、常時表示、未決事項） |
| `faces/<番号-名前>/mock/index.html` | デザイン案のモック（ブラウザで開く静的な SVG） |
| `faces/<番号-名前>/app/` | Connect IQ のアプリ本体（候補ごとに別アプリ、app id も別） |
| `faces/README.md` | 候補の一覧と進み具合 |
| `template/` | 新しい候補を作るときのひな形（デジタル時計の最小構成） |
| `scripts/` | ビルド・シミュレーター起動・候補追加のスクリプト |
| `docs/workflow.md` | 候補ごとの進め方とチェックリスト |
| `docs/device-notes.md` | vivoactive 5 の技術メモ（確認済みの事実と未確認の事項） |
| `docs/design-history.md` | デザイン選定の経緯と、決まった方針 |

候補の画面をまとめて見るページ（非公開）：https://claude.ai/artifact/UksSjGkS4T3Rwum9CXA1fC

## 準備（初回のみ）

1. [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/) で SDK と **vivoactive 5** のデバイスデータを入れる
2. Java（JDK 17 以降）を入れる
3. 開発者キーを用意する。スクリプトは `%APPDATA%\Garmin\ConnectIQ\developer_key.der` を使う（別の場所なら環境変数 `GARMIN_DEV_KEY` で指定）
   - キーはリポジトリにコミットしないこと（`.gitignore` で `*.der` `*.pem` を除外済み）
   - ストアで公開・更新するときも同じキーが要るので、なくさないこと

## ビルドとシミュレーター

PowerShell で、リポジトリの直下から実行します。

```powershell
.\scripts\build.ps1 01-life-quest      # faces\01-life-quest\app\bin\01-life-quest.prg を作る
.\scripts\sim.ps1   01-life-quest      # シミュレーターを起動して読み込む
.\scripts\build.ps1 template           # ひな形のビルド
.\scripts\new-face.ps1 16-example "Example"   # 新しい候補のアプリを template から作る
```

ビルドは `monkeyc -d vivoactive5 -w -l 2`（型チェック レベル 2、警告表示）で行います。

## 実機に入れる（サイドロード）

1. 時計を USB で PC につなぐ
2. `.prg` を時計の `GARMIN/APPS` フォルダにコピー
3. 外して、時計のウォッチフェイス設定から選ぶ

ストアに出すときは、Connect IQ の開発者ページに `.iq`（`monkeyc -e`）をアップロードします。アプリ名・アイコンに Garmin のロゴや他社の商標は使えません。
