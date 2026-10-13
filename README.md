# Simple Face（vivoactive 5 用ウォッチフェイス）

Garmin vivoactive 5（390×390 AMOLED）向けのデジタルウォッチフェイスのひな形です。

```
     MON 13 OCT        ← 日付（アクセントカラー）
       12:34           ← 時刻（12/24時間は時計の設定に従う）
  HR   STEPS   BAT
  62   8421    87%     ← 心拍・歩数・バッテリー
```

常時表示（Always On）中は、焼き付き防止のため暗い小さな時刻だけを表示し、1分ごとに位置をずらします。

## ファイル構成

| パス | 内容 |
|---|---|
| `manifest.xml` | アプリID・種類（watchface）・対応機種（`vivoactive5`） |
| `monkey.jungle` | ビルド設定 |
| `source/GarminWatchFaceApp.mc` | アプリ本体（エントリーポイント） |
| `source/GarminWatchFaceView.mc` | 描画処理。色や配置はここを編集 |
| `resources/` | アプリ名・ランチャーアイコン |

## 準備（初回のみ）

1. [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/) をインストールし、Garmin アカウントでログイン
2. SDK Manager で最新の SDK と **vivoactive 5** のデバイスデータをダウンロード
3. VS Code に拡張機能 **Monkey C**（Garmin 製）をインストール
4. VS Code のコマンドパレットで `Monkey C: Generate a Developer Key` を実行
   - 作成したキー（`.der`）は大切に保管してください。リポジトリにはコミットしないでください。

## シミュレーターで確認

VS Code でこのフォルダを開き、`source/` 内のファイルを開いた状態で **F5（Run）** → 機種に `vivoactive5` を選択。

## 実機に入れる（サイドロード）

1. コマンドパレットで `Monkey C: Build for Device` → `vivoactive5` を選択し、`.prg` を出力
2. 時計を USB で PC に接続
   - Windows：エクスプローラーに表示されます
   - Mac：[OpenMTP](https://openmtp.ganeshrvel.com/) などの MTP 対応アプリが必要
3. `.prg` を時計の `GARMIN/APPS` フォルダにコピー
4. 接続を外し、時計のウォッチフェイス設定から「Simple Face」を選択

## カスタマイズ

`source/GarminWatchFaceView.mc` 冒頭の定数で色を変えられます。

- `ACCENT_COLOR` … 日付の色（例：`0xFF6600` でオレンジ）
- `LABEL_COLOR` / `VALUE_COLOR` … ラベル・数値の色

位置は `drawActive()` 内の `h * 0.22` などの比率で調整します（0.0 が上端、1.0 が下端）。

## ストア公開する場合

`Monkey C: Export Project` で `.iq` を作成し、Connect IQ 開発者ページからアップロードします。
公開前に `manifest.xml` のアプリ名やアイコンを差し替えてください（Garmin のロゴ・商標は使用不可）。
