# N°01 LIFE QUEST: 仕様を詰めるためのモック（spec.html）を生成する。
#   python faces/01-life-quest/mock/gen_spec_mock.py
# 出力は同じフォルダの spec.html。実機の Dc で描ける矩形だけを使う。

import os

CREAM = "#F4F0E0"
DIM = "#8C8A80"
HP_C, EXP_C, BAT_C, EMPTY = "#6BE38B", "#FFD45A", "#5AB8FF", "#2A2A2A"

# 5x7 ドットフォント（既存モックの字形を写し、足りない字を補ったもの）
FONT = {
    " ": ["....."] * 7,
    "0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
    "1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
    "2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
    "3": ["#####", "...#.", "..#..", "...#.", "....#", "#...#", ".###."],
    "4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
    "5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
    "6": ["..##.", ".#...", "#....", "####.", "#...#", "#...#", ".###."],
    "7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
    "8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
    "9": [".###.", "#...#", "#...#", ".####", "....#", "...#.", ".##.."],
    ":": ["....", ".##.", ".##.", "....", ".##.", ".##.", "...."],
    "/": ["....#", "...#.", "...#.", "..#..", ".#...", ".#...", "#...."],
    "%": ["##..#", "##.#.", "...#.", "..#..", ".#...", ".#.##", "#..##"],
    "-": [".....", ".....", ".....", "#####", ".....", ".....", "....."],
    "H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "♥": [".....", ".#.#.", "#####", "#####", ".###.", "..#..", "....."],
    "A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
    "D": ["###..", "#..#.", "#...#", "#...#", "#...#", "#..#.", "###.."],
    "E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
    "F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
    "I": [".###.", "..#..", "..#..", "..#..", "..#..", "..#..", ".###."],
    "L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
    "M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
    "N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
    "O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
    "R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
    "S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
    "T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
    "U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "V": ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
    "W": ["#...#", "#...#", "#.#.#", "#.#.#", "#.#.#", "##.##", "#...#"],
    "X": ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
}


def text_width(s, sc):
    w = sum(len(FONT[c][0]) for c in s) + (len(s) - 1)
    return w * sc


def text(s, x, y, sc, color):
    out = []
    for c in s:
        g = FONT[c]
        for r, row in enumerate(g):
            for col, b in enumerate(row):
                if b == "#":
                    out.append(f'<rect x="{x + col * sc}" y="{y + r * sc}" width="{sc}" height="{sc}" fill="{color}"/>')
        x += (len(g[0]) + 1) * sc
    return "".join(out)


def ctext(s, y, sc, color, cx=195):
    return text(s, cx - text_width(s, sc) / 2, y, sc, color)


# ---- 相棒 ----------------------------------------------------------------
# 14x14 の枠。体は 12x10（列 0-11、行 4-13）。行 0-3 と列 12-13 は王冠・Zzz・汗・しっぽ用。
PAL = {
    "o": "#FF8A7A", "l": "#FFD0C7", "d": "#C24A3C", "e": "#3A0E0A", "w": "#FFFFFF",
    "y": "#FFD45A", "Y": "#C9962A", "c": CREAM, "b": "#5AB8FF",
}


def sprite(rows, x, y, px):
    assert len(rows) == 14, rows
    out = []
    for r, row in enumerate(rows):
        assert len(row) == 14, (row, len(row))
        for col, k in enumerate(row):
            if k != ".":
                out.append(f'<rect x="{x + col * px}" y="{y + r * px}" width="{px}" height="{px}" fill="{PAL[k]}"/>')
    return "".join(out)


def put(base, over):
    """base の上に over を重ねる（'.' は透明）。"""
    return ["".join(o if o != "." else b for b, o in zip(br, orow)) for br, orow in zip(base, over)]


CROWN = [
    "...y.yy.y.....",
    "...yyyyyy.....",
    "...yYyyYy.....",
] + ["." * 14] * 11

ZZZ = [
    "..........cccc",
    "...........c..",
    "..........c...",
    "..........cccc",
] + ["." * 14] * 10

CAT = {
    "ふつう": [
        "." * 14, "." * 14, "." * 14, "." * 14,
        ".o........o...",
        ".oo......oo...",
        ".oloooooolo...",
        "oooooooooooo..",
        "ooweooooweoo.d",
        "ooeeooooeeoo.d",
        "lloooeeoooll.d",
        ".oooooooooood.",
        ".oooooooooo...",
        ".dd.dd..dd.dd.",
    ],
    "歩く 1": [
        "." * 14, "." * 14, "." * 14,
        ".o........o...",
        ".oo......oo...",
        ".oloooooolo..d",
        "oooooooooooo.d",
        "ooooweooooweod",
        "ooooeeooooeeod",
        "llooooeeoooll.",
        ".ooooooooooo..",
        ".oooooooooo...",
        "..dd.....dd...",
        "." * 14,
    ],
    "歩く 2": [
        "." * 14, "." * 14, "." * 14, "." * 14,
        ".o........o...",
        ".oo......oo...",
        ".oloooooolo...",
        "oooooooooooo..",
        "ooooweooooweod",
        "ooooeeooooeeod",
        "llooooeeoooll.",
        ".oooooooooooo.",
        ".oooooooooo...",
        ".dd..dd.dd..dd"[:14],
    ],
    "眠る": put([
        "." * 14, "." * 14, "." * 14, "." * 14,
        "." * 14,
        "." * 14,
        ".o........o...",
        ".oo......oo...",
        ".oloooooolo...",
        "oooooooooooo..",
        "ooddooooddoo..",
        "lloooeeoooll..",
        "oooooooooooodd",
        "ddddddddddddd.",
    ], ZZZ),
    "へたる": [
        "." * 14, "." * 14, "." * 14, "." * 14,
        "." * 14,
        "............b.",
        "............b.",
        "..o......o....",
        ".oooooooooo...",
        "oooooooooooo..",
        "oddoooooddoo..",
        "ooeeooooeeoo..",
        "llooooeoooll..",
        "ddddddddddddd.",
    ],
}
def head_top(rows):
    """頭のてっぺんの行（体の色が 8 ドット以上並ぶ最初の行）。"""
    return next(r for r, row in enumerate(rows) if sum(row.count(k) for k in "old") >= 8)


def with_crown(rows):
    """王冠を頭の上（耳の間、列 3〜8）に載せる。どの姿にも重ねられる。"""
    top = head_top(rows) - len(CROWN_ROWS)
    over = ["." * 14] * 14
    for i, row in enumerate(CROWN_ROWS):
        over[top + i] = row
    return put(rows, over)


CROWN_ROWS = CROWN[:3]

# B. ねこに決定（2026-10-15）。体の絵は CAT、王冠は with_crown() で重ねる。
STATES = ["ふつう", "歩く 1", "歩く 2", "眠る", "へたる"]


# ---- 画面 ----------------------------------------------------------------
def window(color=CREAM):
    return (f'<rect x="47" y="172" width="296" height="3" fill="{color}"/>'
            f'<rect x="47" y="301" width="296" height="3" fill="{color}"/>'
            f'<rect x="44" y="175" width="3" height="126" fill="{color}"/>'
            f'<rect x="343" y="175" width="3" height="126" fill="{color}"/>')


def bar(y, filled, color):
    return "".join(
        f'<rect x="{138 + i * 12}" y="{y}" width="9" height="6" fill="{color if i < filled else EMPTY}"/>'
        for i in range(16))


def face(comp_rows, date="WED 10/14", time="10:08", hp="84", exp="8421", bat="87",
         lv="287", hr="62", hp_n=13, exp_n=13, bat_n=14):
    s = ['<rect width="390" height="390" fill="#000"/>']
    s.append(ctext(date, 50, 3, CREAM))
    s.append(ctext(time, 86, 9, CREAM))
    s.append(window())
    s.append(sprite(comp_rows, 60, 192, 5))
    s.append(text(f"HP {hp}/100", 138, 184, 3, CREAM))
    s.append(bar(209, hp_n, HP_C))
    s.append(text(f"EXP {exp}", 138, 223, 3, CREAM))
    s.append(bar(248, exp_n, EXP_C))
    s.append(text(f"BAT {bat}%", 138, 262, 3, CREAM))
    s.append(bar(287, bat_n, BAT_C))
    s.append(ctext(f"LV{lv} ♥{hr}", 320, 3, CREAM))
    return svg("".join(s))


def aod(time="10:08", dx=0, dy=0):
    # 時刻だけを暗いクリームで。9px の升に 6px の点（間を空けて点灯画素を減らす）
    s = ['<rect width="390" height="390" fill="#000"/>']
    tw = text_width(time, 9)
    x = 195 - tw / 2 + dx
    for c in time:
        g = FONT[c]
        for r, row in enumerate(g):
            for col, b in enumerate(row):
                if b == "#":
                    s.append(f'<rect x="{x + col * 9 + 1.5}" y="{163 + dy + r * 9 + 1.5}" width="6" height="6" fill="{DIM}"/>')
        x += (len(g[0]) + 1) * 9
    return svg("".join(s))


def svg(body, cls="wf"):
    return f'<svg class="{cls} px" viewBox="0 0 390 390">{body}</svg>'


def sheet_cell(rows):
    return (f'<svg class="sp px" viewBox="0 0 70 70"><rect width="70" height="70" fill="#000"/>'
            f'{sprite(rows, 0, 0, 5)}</svg>')


def lit_ratio(time):
    dots = sum(row.count("#") for c in time for row in FONT[c])
    return dots * 36 / (3.14159 * 195 * 195)


def build():
    parts = []
    parts.append('<h2>1. 相棒：B ねこ（決定）</h2>')
    parts.append('<p class="note">体は 12×10 ドット、1 ドット 5px。王冠は歩数が目標に届いたら、どの姿にも頭の上（耳の間）に重ねる。'
                 'Zzz と汗は体の右上に出す。歩く 1 と 2 は、画面が点いている間、毎秒交互に切り替える。</p>')
    parts.append('<h3>姿<span>上の段：そのまま／下の段：王冠を重ねたもの</span></h3><div class="sheet">')
    for st in STATES:
        parts.append(f'<figure class="cell">{sheet_cell(CAT[st])}<figcaption>{st}</figcaption></figure>')
    parts.append('</div><div class="sheet">')
    for st in STATES:
        parts.append(f'<figure class="cell">{sheet_cell(with_crown(CAT[st]))}<figcaption>{st}＋王冠</figcaption></figure>')
    parts.append('</div><div class="row">')
    parts.append(f'<figure>{face(CAT["ふつう"])}<figcaption>ふつう</figcaption></figure>')
    parts.append(f'<figure>{face(CAT["へたる"], hp="12", hp_n=2, time="18:42", hr="71")}<figcaption>へたる（HP 12）</figcaption></figure>')
    parts.append(f'<figure>{face(with_crown(CAT["歩く 1"]), exp="10214", exp_n=16, time="20:15")}'
                 f'<figcaption>歩いている＋達成（歩数が目標に届いた）</figcaption></figure>')
    parts.append(f'<figure>{face(with_crown(CAT["眠る"]), exp="11032", exp_n=16, time="23:40", hp="31", hp_n=5)}'
                 f'<figcaption>眠る＋達成</figcaption></figure>')
    parts.append('</div>')

    parts.append('<h2>2. 時刻の表記：③ 時を 0 付きの 2 桁に（決定）</h2>')
    parts.append('<p class="note">12 時間表記で ③ を採用。24 時間表記も同じく 0 を付ける（幅が 5 文字で一定になる）。'
                 '午前・午後の表示は出さない。</p><div class="row">')
    parts.append(f'<figure>{face(CAT["ふつう"], time="08:42")}<figcaption>12 時間表記 午後 8:42 → 08:42</figcaption></figure>')
    parts.append(f'<figure>{face(CAT["ふつう"], time="12:05")}<figcaption>12 時間表記 午後 0:05 → 12:05</figcaption></figure>')
    parts.append(f'<figure>{face(CAT["眠る"], time="00:00", hp="40", hp_n=6)}<figcaption>24 時間表記 0:00 → 00:00</figcaption></figure>')
    parts.append('</div>')

    parts.append('<h2>3. 常時表示（時刻だけ、暗いクリーム、毎分 3px 単位でずらす）</h2><div class="row">')
    parts.append(f'<figure>{aod()}<figcaption>点灯 約 {lit_ratio("10:08") * 100:.1f}%</figcaption></figure>')
    parts.append(f'<figure>{aod("08:42", dx=-6, dy=6)}<figcaption>0 付きの 08:42、左下へずらした位置</figcaption></figure>')
    parts.append(f'<figure>{aod("23:58", dx=6, dy=-6)}<figcaption>最大は 88:88 で 約 {lit_ratio("88:88") * 100:.1f}%</figcaption></figure>')
    parts.append('</div>')

    parts.append('<h2>4. 桁がいちばん増えたとき</h2><div class="row">')
    parts.append(f'<figure>{face(with_crown(CAT["ふつう"]), date="THU 12/31", time="23:59", hp="100", exp="123456", bat="100", lv="366", hr="188", hp_n=16, exp_n=16, bat_n=16)}'
                 f'<figcaption>HP 100、歩数 6 桁、BAT 100%、LV366、心拍 3 桁</figcaption></figure>')
    parts.append(f'<figure>{face(CAT["ふつう"], date="SUN 1/1", time="00:00", hp="--", exp="0", bat="5", lv="1", hr="--", hp_n=0, exp_n=0, bat_n=1)}'
                 f'<figcaption>取れないとき（HP --、心拍 --）と最小の桁</figcaption></figure>')
    parts.append('</div>')

    html = f'''<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<title>N°01 LIFE QUEST 仕様モック</title>
<style>
  body {{ margin: 0; padding: 28px 16px 48px; background: #17191c; color: #d8dade; font-family: "Segoe UI", "Yu Gothic UI", sans-serif; }}
  h1 {{ font-size: 20px; margin: 0 0 4px; text-align: center; }}
  p.lead {{ text-align: center; color: #9aa0a8; font-size: 13px; margin: 0 0 8px; }}
  h2 {{ font-size: 15px; color: #C9B27C; max-width: 1100px; margin: 30px auto 0; padding-bottom: 6px; border-bottom: 1px solid #33373d; }}
  h3 {{ font-size: 14px; max-width: 1100px; margin: 18px auto 0; }}
  h3 span {{ font-weight: normal; color: #9aa0a8; font-size: 12px; margin-left: 10px; }}
  p.note {{ max-width: 1100px; margin: 8px auto 0; font-size: 12px; color: #9aa0a8; }}
  .row, .sheet {{ display: flex; flex-wrap: wrap; gap: 20px; justify-content: center; margin-top: 14px; }}
  .sheet {{ gap: 12px; }}
  figure {{ margin: 0; text-align: center; width: 250px; }}
  figure.cell {{ width: 112px; }}
  figcaption {{ margin-top: 8px; font-size: 12px; color: #aab0b8; line-height: 1.5; }}
  svg.wf {{ width: 230px; height: 230px; border-radius: 50%; box-shadow: 0 0 0 6px #2c2f35, 0 0 0 8px #474b52; }}
  svg.sp {{ width: 112px; height: 112px; border-radius: 6px; }}
  svg.px rect {{ shape-rendering: crispEdges; }}
</style>
</head>
<body>
<h1>N°01 LIFE QUEST 仕様モック</h1>
<p class="lead">仕様を詰めるためのモック（gen_spec_mock.py で生成）。採用案 01-C の配置、相棒はねこ。仕様は ../README.md。</p>
{"".join(parts)}
</body>
</html>
'''
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "spec.html")
    with open(out, "w", encoding="utf-8") as f:
        f.write(html)
    print(out)


if __name__ == "__main__":
    build()
