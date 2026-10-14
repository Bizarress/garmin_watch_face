# vivoactive 5 技術メモ

設計と実装で前提にする事実です。「確認済み」はインストール済みの SDK 9.2.0 とデバイスデータで確かめたもの、「未確認」は記憶や推測によるもので、実装前に確かめる必要があります。

## 画面と端末

| 項目 | 値 | 確認 |
|---|---|---|
| 画面 | 390×390、丸形、AMOLED | 確認済み |
| Connect IQ のバージョン | 5.2.0（デバイスデータ） | 確認済み |
| ウォッチフェイスのメモリ上限 | 131072 バイト（128KB）、バックグラウンドは 65536 バイト | 確認済み |
| ランチャーアイコン | 56×56（違う大きさは警告が出て縮小される） | 確認済み |
| いちばん小さいシステム文字（`FONT_XTINY`） | 日本語・中国語・韓国語は 25px のフォント。英字は `FNT_006B442500_TINY`（高さは未確認） | 一部確認済み |

自前のフォント（ビットマップ）なら、システム文字より小さい文字も描けます。読めるかどうかはシミュレーターで確かめます。

## 描画（`Toybox.Graphics.Dc`）

| 機能 | 内容 | 確認 |
|---|---|---|
| `setAntiAlias(true)` | 図形のアンチエイリアス。API 3.2.0 以降 | 確認済み |
| `setPenWidth(n)` | 線の太さ | 確認済み |
| `fillPolygon(pts)` | 多角形の塗りつぶし。点の数に上限あり（上限値は未確認） | 一部確認済み |
| グラデーション・ぼかし | 標準機能なし。細い帯の重ね描きか、画像で代用する | 未確認 |
| 透明度つきの色 | 未確認 | 未確認 |

## 入力

| 機能 | 内容 | 確認 |
|---|---|---|
| `WatchUi.WatchFaceDelegate.onPress` | 長押し（touch and hold）を受け取れる。API 4.2.0、vivoactive 5 対応 | 確認済み（実機・シミュレーターでの動作は未確認。システムの長押しメニューと競合する可能性あり） |
| タップ・スワイプ | ウォッチフェイスでは受け取れない | 未確認 |

## データ

| データ | 取得元 | 確認 |
|---|---|---|
| 時刻・日付 | `System.getClockTime()`、`Time.Gregorian.info()` | テンプレートで動作確認済み |
| 歩数・目標 | `ActivityMonitor.getInfo().steps` / `.stepGoal` | 歩数はテンプレートで確認済み、目標は未確認 |
| 心拍 | `Activity.getActivityInfo().currentHeartRate`、なければ `ActivityMonitor.getHeartRateHistory` | テンプレートで確認済み |
| 電池 | `System.getSystemStats().battery` | テンプレートで確認済み |
| Body Battery・ストレス | `Toybox.SensorHistory`（`getBodyBatteryHistory` / `getStressHistory`） | 未確認 |
| 天気 | `Toybox.Weather.getCurrentConditions()`、`getHourlyForecast()`、`getDailyForecast()` | API の存在は確認済み |
| 天気の種類 | `Weather.CONDITION_*`。UNKNOWN を含めて 54 種類 | 確認済み |
| 日の出・日の入り | `Weather.getSunrise()` / `getSunset()`（場所と日時を渡す） | API の存在は確認済み |
| 月の位置・満ち欠け | API なし。日付と場所から計算する | 計算式は未実装 |
| 乱数 | `Math.srand()` で種を固定すると、同じ絵を毎分再現できる | 確認済み |
| 地図 | `WatchUi.MapView` は vivoactive 5 非対応 | 確認済み |

## 常時表示（AOD）

- `System.getDeviceSettings().requiresBurnInProtection` が真のとき、`onEnterSleep` / `onExitSleep` で通常表示と省電力表示を切り替える（テンプレートで実装済み）
- 省電力表示では、点灯させる画素を少なくし、位置を少しずつずらして焼き付きを防ぐ
- 焼き付き対策の条件（確認済み、SDK の FAQ「How Do I Make a Watch Face for AMOLED Products」）：Venu 2 以降の機種は「画面の輝度の 10% 未満」。初代 Venu は「点灯画素 10% 以下、1 画素を 3 分まで」。シミュレーターの File > View Screen Heat Map で 24 時間分を試せる

## バックグラウンド

- `Toybox.Background` の定期処理で、天気などを取りに行ける
- 最短の間隔（5 分という記憶）と、受け渡せるデータの大きさは未確認

## Monkey C で引っかかったこと

- ローカル変数に型を書くとエラーになる（`var hr as Number? = null;` → `Invalid explicit typing of a local variable`）。`var hr = null;` と書く
- PowerShell 5.1 は BOM なしの UTF-8 スクリプトを文字化けして読む。`scripts/*.ps1` は BOM 付きで保存する
