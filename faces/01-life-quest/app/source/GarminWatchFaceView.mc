import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.UserProfile;
import Toybox.WatchUi;

// N°01 LIFE QUEST: the day as a pixel-art RPG status screen (390x390 AMOLED).
// Layout follows faces/01-life-quest/README.md; everything sits on a 3px grid.
//
//          WED 10/14
//           10:08
//    +--------------------+
//    | cat  HP 84/100     |
//    |      EXP 8421      |
//    |      BAT 87%       |
//    +--------------------+
//          LV287 *62
class GarminWatchFaceView extends WatchUi.WatchFace {

    private const CREAM = 0xF4F0E0;
    private const DIM = 0x8C8A80;
    private const HP_COLOR = 0x6BE38B;
    private const EXP_COLOR = 0xFFD45A;
    private const BAT_COLOR = 0x5AB8FF;
    private const EMPTY_COLOR = 0x2A2A2A;

    private const DAY_NAMES = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
    private const DAYS_BEFORE_MONTH = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];

    // Status window and its contents.
    private const WIN_LEFT = 44;
    private const WIN_TOP = 172;
    private const WIN_RIGHT = 346;
    private const WIN_BOTTOM = 304;
    private const PET_X = 60;
    private const PET_Y = 192;
    private const PET_PX = 5;
    private const STAT_X = 138;
    private const STAT_ROWS = [184, 223, 262];
    private const BAR_OFFSET = 25;
    private const BAR_CELLS = 16;

    // Pet states.
    private const LOW_BODY_BATTERY = 20;
    private const WALK_WINDOW_SEC = 120;
    private const WALK_STEPS = 20;
    private const SAMPLE_EVERY_SEC = 5;
    private const DEFAULT_SLEEP_SEC = 22 * 3600;
    private const DEFAULT_WAKE_SEC = 6 * 3600;

    private var _isSleeping as Boolean = false;
    private var _burnInProtection as Boolean = false;

    // Recent (time, steps) samples for the walking check, oldest first.
    private var _sampleTimes as Array<Number> = [] as Array<Number>;
    private var _sampleSteps as Array<Number> = [] as Array<Number>;

    function initialize() {
        WatchFace.initialize();
        var settings = System.getDeviceSettings();
        if (settings has :requiresBurnInProtection) {
            _burnInProtection = settings.requiresBurnInProtection;
        }
    }

    function onLayout(dc as Dc) as Void {
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var steps = getSteps();
        recordSteps(steps);

        if (_isSleeping && _burnInProtection) {
            drawLowPower(dc);
        } else {
            drawActive(dc, steps);
        }
    }

    function onEnterSleep() as Void {
        _isSleeping = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _isSleeping = false;
        WatchUi.requestUpdate();
    }

    // ---- screens -----------------------------------------------------------

    private function drawActive(dc as Dc, steps as Number?) as Void {
        var clock = System.getClockTime();
        var bodyBattery = getBodyBattery();
        var goal = ActivityMonitor.getInfo().stepGoal;
        var battery = (System.getSystemStats().battery + 0.5).toNumber();
        var stepCount = steps != null ? steps : 0;

        dc.setColor(CREAM, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, getDateString(), 50, 3);
        drawCentered(dc, getTimeString(clock), 86, 9);

        // Status window: 3px frame with one dot missing at each corner.
        dc.fillRectangle(WIN_LEFT + 3, WIN_TOP, WIN_RIGHT - WIN_LEFT - 6, 3);
        dc.fillRectangle(WIN_LEFT + 3, WIN_BOTTOM - 3, WIN_RIGHT - WIN_LEFT - 6, 3);
        dc.fillRectangle(WIN_LEFT, WIN_TOP + 3, 3, WIN_BOTTOM - WIN_TOP - 6);
        dc.fillRectangle(WIN_RIGHT - 3, WIN_TOP + 3, 3, WIN_BOTTOM - WIN_TOP - 6);

        var hpText = bodyBattery != null ? bodyBattery.toString() : "--";
        drawText(dc, "HP " + hpText + "/100", STAT_X, STAT_ROWS[0], 3);
        drawText(dc, "EXP " + stepCount.toString(), STAT_X, STAT_ROWS[1], 3);
        drawText(dc, "BAT " + battery.toString() + "%", STAT_X, STAT_ROWS[2], 3);
        drawCentered(dc, "LV" + getDayOfYear().toString() + " *" + getHeartRateString(), 320, 3);

        drawBar(dc, STAT_ROWS[0] + BAR_OFFSET, barCells(bodyBattery != null ? bodyBattery : 0, 100), HP_COLOR);
        drawBar(dc, STAT_ROWS[1] + BAR_OFFSET, barCells(stepCount, goal != null ? goal : 0), EXP_COLOR);
        drawBar(dc, STAT_ROWS[2] + BAR_OFFSET, barCells(battery, 100), BAT_COLOR);

        var frame = getPetFrame(clock, bodyBattery);
        drawSprite(dc, LifeQuestData.SPRITES[frame] as Array<Number>, 0);
        if (goal != null && goal > 0 && stepCount >= goal) {
            drawSprite(dc, LifeQuestData.CROWN as Array<Number>, LifeQuestData.CROWN_ROW[frame] as Number);
        }
    }

    // Always-on: the time only, as sparse dim dots, shifted every minute.
    private function drawLowPower(dc as Dc) as Void {
        var clock = System.getClockTime();
        var minute = clock.min;
        var dx = (minute % 5 - 2) * 3;
        var dy = ((minute / 5) % 5 - 2) * 3;
        var time = getTimeString(clock);

        dc.setColor(DIM, Graphics.COLOR_TRANSPARENT);
        var x = dc.getWidth() / 2 - textWidth(time, 9) / 2 + dx;
        var y = 163 + dy;
        var chars = time.toCharArray();
        for (var i = 0; i < chars.size(); i++) {
            var idx = glyphIndex(chars[i]);
            var runs = LifeQuestData.GLYPH_RUNS[idx] as Array<Number>;
            for (var j = 0; j < runs.size(); j++) {
                var run = runs[j];
                var row = run >> 8;
                var col = (run >> 4) & 0xF;
                for (var k = 0; k < (run & 0xF); k++) {
                    dc.fillRectangle(x + (col + k) * 9 + 1, y + row * 9 + 1, 6, 6);
                }
            }
            x += ((LifeQuestData.GLYPH_W[idx] as Number) + 1) * 9;
        }
    }

    // ---- drawing helpers ---------------------------------------------------

    private function glyphIndex(c as Char) as Number {
        var idx = LifeQuestData.CHARS.find(c.toString());
        return idx != null ? idx : 0;
    }

    private function textWidth(s as String, scale as Number) as Number {
        var chars = s.toCharArray();
        var w = chars.size() - 1;
        for (var i = 0; i < chars.size(); i++) {
            w += LifeQuestData.GLYPH_W[glyphIndex(chars[i])] as Number;
        }
        return w * scale;
    }

    private function drawCentered(dc as Dc, s as String, y as Number, scale as Number) as Void {
        drawText(dc, s, dc.getWidth() / 2 - textWidth(s, scale) / 2, y, scale);
    }

    // Draws with the current color; each run of dots is one rectangle.
    private function drawText(dc as Dc, s as String, x as Number, y as Number, scale as Number) as Void {
        var chars = s.toCharArray();
        for (var i = 0; i < chars.size(); i++) {
            var idx = glyphIndex(chars[i]);
            var runs = LifeQuestData.GLYPH_RUNS[idx] as Array<Number>;
            for (var j = 0; j < runs.size(); j++) {
                var run = runs[j];
                dc.fillRectangle(x + ((run >> 4) & 0xF) * scale, y + (run >> 8) * scale,
                    (run & 0xF) * scale, scale);
            }
            x += ((LifeQuestData.GLYPH_W[idx] as Number) + 1) * scale;
        }
    }

    // 16 cells of 9x6 with 3px gaps; the first `filled` cells take the color.
    private function drawBar(dc as Dc, y as Number, filled as Number, color as Number) as Void {
        for (var i = 0; i < BAR_CELLS; i++) {
            dc.setColor(i < filled ? color : EMPTY_COLOR, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(STAT_X + i * 12, y, 9, 6);
        }
        dc.setColor(CREAM, Graphics.COLOR_TRANSPARENT);
    }

    // Rounded share of 16 cells. Never empty above 0, never full below max.
    private function barCells(value as Number, max as Number) as Number {
        if (value <= 0 || max <= 0) {
            return 0;
        }
        if (value >= max) {
            return BAR_CELLS;
        }
        var n = (value * BAR_CELLS + max / 2) / max;
        return n < 1 ? 1 : (n > BAR_CELLS - 1 ? BAR_CELLS - 1 : n);
    }

    // Runs are (color << 12) | (row << 8) | (col << 4) | length, sorted by color.
    private function drawSprite(dc as Dc, runs as Array<Number>, rowOffset as Number) as Void {
        var lastColor = -1;
        for (var i = 0; i < runs.size(); i++) {
            var run = runs[i];
            var color = run >> 12;
            if (color != lastColor) {
                dc.setColor(LifeQuestData.PALETTE[color] as Number, Graphics.COLOR_TRANSPARENT);
                lastColor = color;
            }
            dc.fillRectangle(PET_X + ((run >> 4) & 0xF) * PET_PX,
                PET_Y + (((run >> 8) & 0xF) + rowOffset) * PET_PX,
                (run & 0xF) * PET_PX, PET_PX);
        }
    }

    // ---- pet state ---------------------------------------------------------

    // Sleep > tired > walking > normal. The crown is drawn separately.
    private function getPetFrame(clock as System.ClockTime, bodyBattery as Number?) as Number {
        if (isSleepTime(clock)) {
            return LifeQuestData.FRAME_SLEEP;
        }
        if (bodyBattery != null && bodyBattery < LOW_BODY_BATTERY) {
            return LifeQuestData.FRAME_TIRED;
        }
        if (isWalking()) {
            return clock.sec % 2 == 0 ? LifeQuestData.FRAME_WALK1 : LifeQuestData.FRAME_WALK2;
        }
        return LifeQuestData.FRAME_NORMAL;
    }

    private function isSleepTime(clock as System.ClockTime) as Boolean {
        var sleep = DEFAULT_SLEEP_SEC;
        var wake = DEFAULT_WAKE_SEC;
        var profile = UserProfile.getProfile();
        if (profile.sleepTime != null && profile.wakeTime != null) {
            sleep = (profile.sleepTime as Time.Duration).value();
            wake = (profile.wakeTime as Time.Duration).value();
        }
        var now = clock.hour * 3600 + clock.min * 60 + clock.sec;
        if (sleep == wake) {
            return false;
        }
        return sleep < wake ? (now >= sleep && now < wake) : (now >= sleep || now < wake);
    }

    // Keeps samples from the last two minutes, at most one every few seconds.
    private function recordSteps(steps as Number?) as Void {
        if (steps == null) {
            return;
        }
        var now = Time.now().value();
        var n = _sampleTimes.size();
        if (n > 0 && (steps < _sampleSteps[n - 1] || now < _sampleTimes[n - 1])) {
            // Steps reset at midnight or the clock moved back: start over.
            _sampleTimes = [] as Array<Number>;
            _sampleSteps = [] as Array<Number>;
            n = 0;
        }
        if (n == 0 || now - _sampleTimes[n - 1] >= SAMPLE_EVERY_SEC) {
            _sampleTimes.add(now);
            _sampleSteps.add(steps);
        }
        while (_sampleTimes.size() > 1 && now - _sampleTimes[0] > WALK_WINDOW_SEC) {
            _sampleTimes = _sampleTimes.slice(1, null);
            _sampleSteps = _sampleSteps.slice(1, null);
        }
    }

    // Walking: 20+ steps against a sample up to two minutes old. Right after the
    // screen wakes there may be no old sample, so any rise counts then.
    private function isWalking() as Boolean {
        var n = _sampleTimes.size();
        if (n < 2) {
            return false;
        }
        var delta = _sampleSteps[n - 1] - _sampleSteps[0];
        var age = _sampleTimes[n - 1] - _sampleTimes[0];
        return age >= WALK_WINDOW_SEC / 2 ? delta >= WALK_STEPS : delta > 0;
    }

    // ---- data --------------------------------------------------------------

    // Hour always has two digits, in 12- and 24-hour mode alike (08:42, 00:00).
    private function getTimeString(clock as System.ClockTime) as String {
        var hour = clock.hour;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
        }
        return hour.format("%02d") + ":" + clock.min.format("%02d");
    }

    // WED 10/14 (month/day, no leading zeros).
    private function getDateString() as String {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return Lang.format("$1$ $2$/$3$",
            [DAY_NAMES[(info.day_of_week as Number) - 1], info.month as Number, info.day]);
    }

    // LV: day of the year, 1-366.
    private function getDayOfYear() as Number {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var month = info.month as Number;
        var year = info.year;
        var day = (DAYS_BEFORE_MONTH[month - 1] as Number) + info.day;
        var leap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
        return (leap && month > 2) ? day + 1 : day;
    }

    private function getSteps() as Number? {
        return ActivityMonitor.getInfo().steps;
    }

    private function getBodyBattery() as Number? {
        if ((Toybox has :SensorHistory) && (SensorHistory has :getBodyBatteryHistory)) {
            var history = SensorHistory.getBodyBatteryHistory({
                :period => 1,
                :order => SensorHistory.ORDER_NEWEST_FIRST
            });
            if (history != null) {
                var sample = history.next();
                if (sample != null && sample.data != null) {
                    return (sample.data as Numeric).toNumber();
                }
            }
        }
        return null;
    }

    private function getHeartRateString() as String {
        var hr = null;
        var activityInfo = Activity.getActivityInfo();
        if (activityInfo != null) {
            hr = activityInfo.currentHeartRate;
        }
        if (hr == null && ActivityMonitor has :getHeartRateHistory) {
            var sample = ActivityMonitor.getHeartRateHistory(1, true).next();
            if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                hr = sample.heartRate;
            }
        }
        return hr != null ? hr.toString() : "--";
    }
}
