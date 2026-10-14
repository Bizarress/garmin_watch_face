import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Digital watch face for vivoactive 5 (390x390 AMOLED).
//
//        MON 13 OCT        <- date (accent color)
//          12:34           <- time
//     HR   STEPS   BAT     <- labels
//     62   8,421   87%     <- values
class GarminWatchFaceView extends WatchUi.WatchFace {

    // Change these to customize the look.
    private const ACCENT_COLOR = 0x00C8FF;
    private const LABEL_COLOR = Graphics.COLOR_LT_GRAY;
    private const VALUE_COLOR = Graphics.COLOR_WHITE;

    private const DAY_NAMES = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
    private const MONTH_NAMES = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                                 "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];

    // AMOLED screens need a dim, moving image while in always-on (sleep) mode.
    private var _isSleeping as Boolean = false;
    private var _burnInProtection as Boolean = false;

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

        if (_isSleeping && _burnInProtection) {
            drawLowPower(dc);
        } else {
            drawActive(dc);
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

    private function drawActive(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        // Date
        dc.setColor(ACCENT_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.22, Graphics.FONT_SMALL, getDateString(), center);

        // Time
        dc.setColor(VALUE_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.45, Graphics.FONT_NUMBER_THAI_HOT, getTimeString(), center);

        // Stats row
        var labelY = h * 0.66;
        var valueY = h * 0.75;
        var xs = [w * 0.27, w * 0.5, w * 0.73];
        var labels = ["HR", "STEPS", "BAT"];
        var values = [getHeartRateString(), getStepsString(), getBatteryString()];
        for (var i = 0; i < 3; i++) {
            dc.setColor(LABEL_COLOR, Graphics.COLOR_TRANSPARENT);
            dc.drawText(xs[i], labelY, Graphics.FONT_XTINY, labels[i], center);
            dc.setColor(VALUE_COLOR, Graphics.COLOR_TRANSPARENT);
            dc.drawText(xs[i], valueY, Graphics.FONT_SMALL, values[i], center);
        }
    }

    // Always-on mode: small gray time only, shifted every minute to avoid burn-in.
    private function drawLowPower(dc as Dc) as Void {
        var minute = System.getClockTime().min;
        var offsetX = (minute % 5 - 2) * 8;
        var offsetY = ((minute / 5) % 5 - 2) * 8;

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2 + offsetX, dc.getHeight() / 2 + offsetY,
            Graphics.FONT_NUMBER_MEDIUM, getTimeString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function getTimeString() as String {
        var clock = System.getClockTime();
        var hour = clock.hour;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
        }
        return Lang.format("$1$:$2$", [hour.format("%02d"), clock.min.format("%02d")]);
    }

    private function getDateString() as String {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dayOfWeek = info.day_of_week as Number;
        var month = info.month as Number;
        return Lang.format("$1$ $2$ $3$",
            [DAY_NAMES[dayOfWeek - 1], info.day, MONTH_NAMES[month - 1]]);
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

    private function getStepsString() as String {
        var steps = ActivityMonitor.getInfo().steps;
        return steps != null ? steps.toString() : "--";
    }

    private function getBatteryString() as String {
        return System.getSystemStats().battery.format("%d") + "%";
    }
}
