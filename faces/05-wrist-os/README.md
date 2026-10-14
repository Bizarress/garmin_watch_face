# N°05 WRIST-OS

- 状態：仕様たたき台（未実装）
- モック：[mock/index.html](mock/index.html)（採用案＝第 6 弾の元の案。3 タブ、状態、色ちがい、常時表示）
- アプリ：`app/`（表示名 Wrist OS）

## コンセプト

腕に巻いた緑一色のブラウン管端末。STAT・DATA・RADIO の 3 つのタブで、体の状態、今日の目標、天気を切り替えて見る。情報が詰まった「ごちゃっとした感じ」がこの案の魅力なので、要素は減らさない。

## 共通の見た目

- 文字は LIFE QUEST と同じ 5×7 のドットフォント（自前）
- 緑の濃淡 4 段：明 `#3CFF7A`／中 `#22A84E`／暗 `#17753A`／最暗 `#0C3A1C`、地 `#020B05`
- 4px ごとに走査線（暗い横線）を重ねる
- 色ちがい：琥珀、青白（モック参照）
- 全タブ共通：上にタブ名 `STAT  DATA  RADIO`（選択中は明るく、カギ括弧の線で囲む）、その下に時刻、下端に `HP 84/100 | LV 287 | AP 87/100` の帯

## タブごとの画面

| タブ | 中身 |
|---|---|
| STAT | 中央に人型。左に HEAD／BODY／LEGS のバー、右に HR・STEP・KCAL の数値。値が低い部位は人型のその部分が暗くなり「負傷」 |
| DATA | 反転した見出し帯 `QUESTS 2/4 DONE`。下に目標 4 行（WALK・CLIMB・ACTIVE・BURN）。各行に現在値／目標値と進捗バー、達成した行は `[X]` で暗くする |
| RADIO | 左上に天気のドット絵と大きな気温、右上に HI／LO／RAIN。下に幅いっぱいの 12 時間の波形（明るい線＝気温、暗い縦棒＝降水確率、点線 DN＝日の入り） |

## 表示するデータ

| 表示 | 中身 | 取得元（予定） |
|---|---|---|
| HP | Body Battery | `SensorHistory.getBodyBatteryHistory`（要確認） |
| AP | 時計の電池 | `System.getSystemStats().battery` |
| LV | その年の何日目か | 計算 |
| HEAD | ストレス（低いほど良い） | `SensorHistory.getStressHistory`（要確認） |
| BODY | Body Battery | 同上 |
| LEGS | 歩数の達成率 | `ActivityMonitor.getInfo().steps` / `.stepGoal` |
| HR・STEP・KCAL | 心拍・歩数・カロリー | `Activity` / `ActivityMonitor` |
| WALK・CLIMB・ACTIVE・BURN | 歩数・上った階数・活動時間・カロリーの目標と現在値 | `ActivityMonitor.getInfo()`（`floorsClimbed`、`activeMinutesDay` など。目標値の取り方は要確認） |
| 天気・12 時間の波形 | 現在の天気と 1 時間ごとの予報 | `Weather.getCurrentConditions()` / `getHourlyForecast()` |
| DN | 日の入り | `Weather.getSunset()` |

## タブの切り替え

- 長押しで次のタブへ（`WatchFaceDelegate.onPress`、API 4.2.0、vivoactive 5 対応）
- 実機・シミュレーターでの動作は未確認。システムの長押しメニューと競合する可能性がある
- 使えなかったときの代わりを決めておく（例：設定でタブを固定する、数分ごとに自動で切り替える）

## 常時表示

モックのとおり、暗い緑で時刻と最低限の文字だけを出す。走査線は省く。1 分ごとに位置を数 px ずらす。

## 未決事項

- [ ] 長押しでタブを切り替えられるか（最初に試作して確かめる）
- [ ] 名称とキャラクター。Pip-Boy・Vault Boy などの権利物に似せない（人型は独自の形にする）
- [ ] ストレス・Body Battery・目標値が取れるか
- [ ] DATA の 4 つの目標の中身（固定か、設定で選べるか）
- [ ] 色ちがい（緑・琥珀・青白）を設定で選べるようにするか
- [ ] 矩形の数が多いので、描画の速さとメモリを確かめる

## 経緯

第 6 弾で候補に残した。MAP タブは「詳細でないと意味がない」として天気（RADIO）に置き換えた（vivoactive 5 は地図表示に非対応）。DATA と RADIO の見た目が似ないよう構成を作り直した。洗練で要素を減らした案は採用せず、タブ付きの元の案のまま進める。
