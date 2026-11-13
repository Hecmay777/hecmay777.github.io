using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;
using Toybox.Lang;

class KbView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    function clock(secs) {
        var m = secs / 60;
        var s = secs % 60;
        return m.format("%02d") + ":" + s.format("%02d");
    }

    // Texto centrado; si no cabe, se desplaza a la izquierda en bucle
    function mq(dc, text, font, y, maxW, tick) {
        var w = dc.getWidth();
        var tw = dc.getTextWidthInPixels(text, font);
        if (tw <= maxW) {
            dc.drawText(w / 2, y, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }
        var fh = dc.getFontHeight(font);
        var gap = 40;
        var cyc = tw + gap;
        var off = (tick * 5) % cyc;
        var x0 = (w - maxW) / 2;
        dc.setClip(x0, y - fh / 2, maxW, fh);
        dc.drawText(x0 - off, y, font, text, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x0 - off + cyc, y, font, text, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.clearClip();
    }

    function onUpdate(dc) {
        var s = Application.getApp().ses;
        var w = dc.getWidth();
        var h = dc.getHeight();
        var c = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        if (s == null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.clear();
            return;
        }

        if (!s.started) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.clear();
            dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h * 20 / 100, Graphics.FONT_SMALL, "Prueba", c);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h * 39 / 100, Graphics.FONT_MEDIUM, Plan.title(s.idx), c);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h * 54 / 100, Graphics.FONT_XTINY, s.size().toString() + " pasos", c);
            dc.drawText(w / 2, h * 67 / 100, Graphics.FONT_XTINY, "ARRIBA / ABAJO = cambiar", c);
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h * 82 / 100, Graphics.FONT_SMALL, "START = empezar", c);
            return;
        }

        if (s.finished) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_DK_GREEN);
            dc.clear();
            dc.drawText(w / 2, h * 24 / 100, Graphics.FONT_MEDIUM, "¡Sesión hecha!", c);
            dc.drawText(w / 2, h * 50 / 100, Graphics.FONT_NUMBER_MEDIUM, clock(s.elapsed() / 1000), c);
            dc.drawText(w / 2, h * 72 / 100, Graphics.FONT_XTINY, "tiempo total", c);
            dc.drawText(w / 2, h * 86 / 100, Graphics.FONT_XTINY, "START = guardar", c);
            return;
        }

        var k = s.kind();
        var bg = Graphics.COLOR_BLACK;
        if (k == 2) {
            bg = Graphics.COLOR_DK_BLUE;
        } else if (k == 0) {
            bg = Graphics.COLOR_DK_GREEN;
        }
        dc.setColor(Graphics.COLOR_WHITE, bg);
        dc.clear();

        var step = s.plan[s.i];
        var maxW = w * 78 / 100;

        // Arriba: paso y tiempo total
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 13 / 100, Graphics.FONT_XTINY, (s.i + 1).toString() + "/" + s.size().toString() + "  ·  " + clock(s.elapsed() / 1000), c);

        // Subtítulo (serie, calentamiento…)
        if (step[4] != null && !step[4].equals("")) {
            dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            mq(dc, step[4], Graphics.FONT_XTINY, h * 25 / 100, maxW * 90 / 100, s.tick);
        }

        // Nombre
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        mq(dc, step[1], Graphics.FONT_SMALL, h * 38 / 100, maxW, s.tick);

        // Centro: reloj o repeticiones
        var bottom = "";
        if (k == 1) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            var qv = step[2];
            if (qv.length() == 0) {
                // Sin número: la indicación va en el centro
                mq(dc, step[3], Graphics.FONT_MEDIUM, h * 60 / 100, maxW, s.tick);
            } else {
                // Las fuentes de números grandes solo tienen dígitos: «8-10» va con la fuente normal
                var big = (qv.find("-") == null) ? Graphics.FONT_NUMBER_HOT : Graphics.FONT_LARGE;
                dc.drawText(w / 2, h * 60 / 100, big, qv, c);
                bottom = step[3];
                if (bottom.equals("")) {
                    bottom = "repeticiones";
                }
            }
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h * 60 / 100, Graphics.FONT_NUMBER_HOT, clock(s.secondsLeft()), c);
            if (k == 2 && s.i < s.size() - 1) {
                bottom = "Sigue: " + s.plan[s.i + 1][1];
            } else if (!s.running) {
                bottom = "PAUSA";
            }
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        mq(dc, bottom, Graphics.FONT_XTINY, h * 79 / 100, maxW, s.tick);

        // Pista de botón
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        var hint = "START = pausa";
        if (k == 1) {
            hint = "START = hecha";
        } else if (!s.running) {
            hint = "START = seguir";
        }
        dc.drawText(w / 2, h * 90 / 100, Graphics.FONT_XTINY, hint, c);
    }
}
