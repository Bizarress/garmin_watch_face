# N°01 LIFE QUEST: モックと同じフォントと相棒の絵から、アプリ用のデータ（LifeQuestData.mc）を作る。
#   python faces/01-life-quest/tools/gen_mc_data.py
# 絵を直すときは mock/gen_spec_mock.py を直し、このスクリプトを流し直す。

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "mock"))
import gen_spec_mock as m  # noqa: E402

OUT = os.path.join(HERE, "..", "app", "source", "LifeQuestData.mc")

# ♥ は Monkey C の文字列で扱いやすいよう '*' に置き換える
CHAR_ALIAS = {"♥": "*"}
FRAMES = ["ふつう", "歩く 1", "歩く 2", "眠る", "へたる"]
PAL_KEYS = list(m.PAL.keys())


def runs(rows, keyed):
    """横に並んだ同じ色のドットを 1 本にまとめる。keyed=True なら色の番号も入れて色順に並べる。"""
    out = []
    for r, row in enumerate(rows):
        c = 0
        while c < len(row):
            k = row[c]
            if (keyed and k != ".") or (not keyed and k == "#"):
                n = 1
                while c + n < len(row) and row[c + n] == k:
                    n += 1
                v = (r << 8) | (c << 4) | n
                if keyed:
                    v |= PAL_KEYS.index(k) << 12
                out.append(v)
                c += n
            else:
                c += 1
    return sorted(out) if keyed else out


def hexcolor(s):
    return "0x" + s.lstrip("#").upper()


def arr(values):
    return "[" + ", ".join(str(v) for v in values) + "]"


def main():
    chars = "".join(CHAR_ALIAS.get(c, c) for c in m.FONT)
    glyphs = list(m.FONT.values())
    crown = m.CROWN_ROWS + ["." * 14] * (14 - len(m.CROWN_ROWS))
    lines = [
        "// 自動生成：tools/gen_mc_data.py（手で直さない）",
        "import Toybox.Lang;",
        "",
        "module LifeQuestData {",
        "",
        "    // 5x7 ドットフォント。♥ は '*'。",
        f'    const CHARS = "{chars}";',
        f"    const GLYPH_W = {arr(len(g[0]) for g in glyphs)};",
        "    // 各字の横並び：(行 << 8) | (列 << 4) | 長さ",
        "    const GLYPH_RUNS = [",
    ]
    for c, g in zip(chars, glyphs):
        lines.append(f"        {arr(runs(g, False))}, // {c!r}")
    lines += [
        "    ];",
        "",
        f"    const PALETTE = {arr(hexcolor(v) for v in m.PAL.values())};",
        "",
        "    // 相棒（14x14 ドット）：(色 << 12) | (行 << 8) | (列 << 4) | 長さ。色順に並ぶ。",
        "    const FRAME_NORMAL = 0;",
        "    const FRAME_WALK1 = 1;",
        "    const FRAME_WALK2 = 2;",
        "    const FRAME_SLEEP = 3;",
        "    const FRAME_TIRED = 4;",
        "    const SPRITES = [",
    ]
    for name in FRAMES:
        lines.append(f"        {arr(runs(m.CAT[name], True))}, // {name}")
    lines += [
        "    ];",
        "    // 王冠は姿ごとに頭の上へ重ねる。CROWN_ROW は王冠の上端の行。",
        f"    const CROWN = {arr(runs(crown, True))};",
        f"    const CROWN_ROW = {arr(m.head_top(m.CAT[n]) - len(m.CROWN_ROWS) for n in FRAMES)};",
        "}",
        "",
    ]
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print(os.path.abspath(OUT))


if __name__ == "__main__":
    main()
