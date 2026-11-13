using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;

// Pantalla del partido: sets arriba, una fila por equipo (saque, juegos y puntos en grande) y avisos abajo.
class MarcadorView extends WatchUi.View {
    const COL_US = 0x00FFAA;
    const COL_THEM = 0xFFAA00;

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc) {
        var m = gMatch;
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Hora
        var t = System.getClockTime();
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 6 / 100, Graphics.FONT_XTINY, t.hour.format("%02d") + ":" + t.min.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Sets jugados y set actual
        var top = "";
        for (var i = 0; i < m.sets.size(); i++) {
            var s = m.sets[i];
            if (s[4] == 2) {
                top = top + "[" + s[2] + "-" + s[3] + "] ";
            } else {
                top = top + s[0] + "-" + s[1] + " ";
            }
        }
        if (m.winner < 0) {
            if (m.sets.size() == 0) { top = "Set 1"; } else { top = top + " Set " + (m.sets.size() + 1); }
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 17 / 100, Graphics.FONT_SMALL, top, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Filas de equipo
        drawRow(dc, 0, h * 38 / 100, w);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(w * 8 / 100, h * 52 / 100, w * 92 / 100, h * 52 / 100);
        drawRow(dc, 1, h * 66 / 100, w);

        // Aviso inferior
        var msg = m.flash;
        if (m.winner >= 0) {
            msg = (m.winner == 0) ? "Ganamos" : "Ganan ellos";
        } else if (msg.length() == 0) {
            msg = m.note();
        }
        if (msg.length() > 0) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 86 / 100, Graphics.FONT_SMALL, msg, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function drawRow(dc, i, y, w) {
        var m = gMatch;
        var col = (i == 0) ? COL_US : COL_THEM;
        var vc = Graphics.TEXT_JUSTIFY_VCENTER;

        // Bola de saque
        if (m.winner < 0 && m.server() == i) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(w * 8 / 100, y, w * 25 / 1000);
        }
        // Nombre
        dc.setColor(col, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w * 13 / 100, y, Graphics.FONT_SMALL, (i == 0) ? "NOS" : "ELL", Graphics.TEXT_JUSTIFY_LEFT | vc);

        // Juegos del set en curso (o sets ganados si el partido ha terminado)
        var mid;
        if (m.winner >= 0) {
            mid = m.setsWon()[i].toString();
        } else if (m.mode == 2) {
            mid = "-";
        } else {
            mid = m.games[i].toString();
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w * 47 / 100, y, Graphics.FONT_NUMBER_MILD, mid, Graphics.TEXT_JUSTIFY_CENTER | vc);

        // Puntos en grande
        if (m.winner < 0) {
            var p = m.label(i);
            dc.setColor(col, Graphics.COLOR_TRANSPARENT);
            if (p.equals("AD")) {
                dc.drawText(w * 90 / 100, y, Graphics.FONT_LARGE, p, Graphics.TEXT_JUSTIFY_RIGHT | vc);
            } else {
                dc.drawText(w * 90 / 100, y, Graphics.FONT_NUMBER_HOT, p, Graphics.TEXT_JUSTIFY_RIGHT | vc);
            }
        }
    }
}
