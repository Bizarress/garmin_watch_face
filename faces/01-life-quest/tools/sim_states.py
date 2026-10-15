# N°01 LIFE QUEST: 相棒の状態と常時表示を、シミュレーターで 1 つずつ強制して見るための道具。
#   python faces/01-life-quest/tools/sim_states.py variants <出力先>   … 状態を固定したアプリのコピーを作る
#   python faces/01-life-quest/tools/sim_states.py sheet <撮影フォルダ> <一覧.png>
# 通常は tools/sim_states.ps1 から呼ぶ。コピーは出力先にだけ作り、app/ は書き換えない。

import shutil
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
APP = HERE.parent / "app"

FRAMES = ["NORMAL", "WALK1", "WALK2", "SLEEP", "TIRED"]
LABELS = {"NORMAL": "NORMAL", "WALK1": "WALK 1", "WALK2": "WALK 2", "SLEEP": "SLEEP", "TIRED": "TIRED (HP<20)"}
AOD_MINUTES = [0, 24]  # 位置ずらしの両端（-6,-6）と（+6,+6）


def variants():
    """(名前, [(元の行, 置き換え)]) の一覧。"""
    out = []
    for frame in FRAMES:
        for crown in (False, True):
            edits = [("var frame = getPetFrame(clock, bodyBattery);", f"var frame = LifeQuestData.FRAME_{frame};"),
                     ("if (goal != null && goal > 0 && stepCount >= goal) {", f"if ({'true' if crown else 'false'}) {{")]
            if crown:
                edits.append(("var stepCount = steps != null ? steps : 0;", "var stepCount = 10234;"))
            if frame == "TIRED":
                edits.append(("var bodyBattery = getBodyBattery();", "var bodyBattery = 12;"))
            if frame == "SLEEP":
                edits.append(("drawCentered(dc, getTimeString(clock), 86, 9);", 'drawCentered(dc, "23:40", 86, 9);'))
            out.append((f"{frame.lower()}{'-crown' if crown else ''}", edits))
    # 常時表示：眠っている扱いだけを固定する。焼き付き対策の判定は本物のまま残し、値を出力する。
    for minute in AOD_MINUTES:
        init = "_burnInProtection = settings.requiresBurnInProtection;"
        out.append((f"aod-m{minute:02d}", [
            (init, init + '\n            System.println("burnIn=" + _burnInProtection);'),
            ("private var _isSleeping as Boolean = false;", "private var _isSleeping as Boolean = true;"),
            ("function onExitSleep() as Void {\n        _isSleeping = false;",
             "function onExitSleep() as Void {\n        _isSleeping = true;"),
            ("var minute = clock.min;", f"var minute = {minute};"),
        ]))
    return out


def make_variants(dest):
    dest = Path(dest)
    for name, edits in variants():
        d = dest / name
        if d.exists():
            shutil.rmtree(d)
        shutil.copytree(APP, d, ignore=shutil.ignore_patterns("bin"))
        view = d / "source" / "GarminWatchFaceView.mc"
        s = view.read_text(encoding="utf-8")
        for old, new in edits:
            assert s.count(old) == 1, f"{name}: {old!r} が見つからない（View を直したらここも直す）"
            s = s.replace(old, new)
        view.write_text(s, encoding="utf-8")
        print(name)


def make_sheet(shots, out):
    from PIL import Image, ImageDraw, ImageFont
    shots = Path(shots)
    t, pad, lh = 300, 14, 26
    font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 18)
    im = Image.new("RGB", (pad + len(FRAMES) * (t + pad), pad + 3 * (t + lh + pad)), (24, 24, 24))
    d = ImageDraw.Draw(im)

    def put(name, r, c, label):
        x, y = pad + c * (t + pad), pad + r * (t + lh + pad)
        d.text((x, y), label, fill=(230, 230, 230), font=font)
        im.paste(Image.open(shots / f"{name}.png").convert("RGB").resize((t, t), Image.LANCZOS), (x, y + lh))

    for c, f in enumerate(FRAMES):
        put(f.lower(), 0, c, LABELS[f])
        put(f.lower() + "-crown", 1, c, LABELS[f] + " + CROWN")
    for c, m in enumerate(AOD_MINUTES):
        dx, dy = (m % 5 - 2) * 3, ((m // 5) % 5 - 2) * 3
        put(f"aod-m{m:02d}", 2, c, f"AOD  min={m} ({dx:+d},{dy:+d})")
    im.save(out)
    print(out)


if __name__ == "__main__":
    if sys.argv[1] == "variants":
        make_variants(sys.argv[2])
    else:
        make_sheet(sys.argv[2], sys.argv[3])
