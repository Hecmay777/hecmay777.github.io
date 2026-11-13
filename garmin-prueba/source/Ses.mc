using Toybox.System;
using Toybox.Attention;
using Toybox.ActivityRecording;
using Toybox.Activity;
using Toybox.Application.Storage;

// Estado de la sesión guiada (pasos, tiempos, grabación de la actividad)
class Ses {
    var plan;
    var idx = 8;   // sesión elegida (8 = semana 3, día 1)
    var i = 0;
    var started = false;
    var running = false;
    var finished = false;
    var endMs = 0;
    var remMs = 0;
    var acc = 0;
    var runT0 = 0;
    var rec = null;
    var lastBeep = -1;
    var tick = 0;

    function initialize() {
        var v = Storage.getValue("idx");
        if (v != null && v >= 0 && v < Plan.COUNT) {
            idx = v;
        }
        plan = Plan.getPlan(idx);
        loadStep(0);
    }

    // Antes de empezar: elegir otra sesión (delta = +1 siguiente, -1 anterior)
    function select(delta) {
        if (started) {
            return;
        }
        idx = (idx + delta + Plan.COUNT) % Plan.COUNT;
        plan = null;
        plan = Plan.getPlan(idx);
        loadStep(0);
        Storage.setValue("idx", idx);
    }

    function size() {
        return plan.size();
    }

    function kind() {
        return plan[i][0];
    }

    function isTimed(j) {
        var k = plan[j][0];
        return (k == 0 || k == 2);
    }

    function loadStep(j) {
        i = j;
        lastBeep = -1;
        if (isTimed(i)) {
            remMs = plan[i][2] * 1000;
            if (running) {
                endMs = System.getTimer() + remMs;
            }
        }
    }

    function vib(ms) {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(70, ms)]);
        }
    }

    function tone(t) {
        if (Attention has :playTone) {
            Attention.playTone(t);
        }
    }

    function begin() {
        if (started) {
            return;
        }
        started = true;
        running = true;
        runT0 = System.getTimer();
        try {
            rec = ActivityRecording.createSession({
                :name => "Kettlebell",
                :sport => Activity.SPORT_TRAINING,
                :subSport => Activity.SUB_SPORT_STRENGTH_TRAINING
            });
            rec.start();
        } catch (ex) {
            rec = null;
        }
        loadStep(i);
        vib(200);
        tone(Attention.TONE_START);
    }

    function elapsed() {
        var e = acc;
        if (running) {
            e = e + (System.getTimer() - runT0);
        }
        return e;
    }

    function pauseToggle() {
        if (!started || finished) {
            return;
        }
        var now = System.getTimer();
        if (running) {
            acc = acc + (now - runT0);
            if (isTimed(i)) {
                remMs = endMs - now;
                if (remMs < 0) {
                    remMs = 0;
                }
            }
            running = false;
            if (rec != null) {
                try { rec.stop(); } catch (ex) {}
            }
        } else {
            running = true;
            runT0 = now;
            endMs = now + remMs;
            if (rec != null) {
                try { rec.start(); } catch (ex) {}
            }
        }
    }

    function next() {
        if (!started || finished) {
            return;
        }
        if (i >= plan.size() - 1) {
            finish();
        } else {
            loadStep(i + 1);
            vib(120);
        }
    }

    function prev() {
        if (!started || finished) {
            return;
        }
        if (i > 0) {
            loadStep(i - 1);
            vib(60);
        }
    }

    function restart() {
        if (!started || finished) {
            return;
        }
        loadStep(i);
        vib(60);
    }

    function finish() {
        if (finished) {
            return;
        }
        if (running) {
            acc = acc + (System.getTimer() - runT0);
            running = false;
            if (rec != null) {
                try { rec.stop(); } catch (ex) {}
            }
        }
        finished = true;
        vib(600);
        tone(Attention.TONE_SUCCESS);
    }

    function secondsLeft() {
        var ms = remMs;
        if (running && isTimed(i)) {
            ms = endMs - System.getTimer();
        }
        if (ms < 0) {
            ms = 0;
        }
        return (ms + 999) / 1000;
    }

    // Se llama cada 250 ms desde la app
    function onTick() {
        tick = tick + 1;
        if (!started || finished || !running) {
            return;
        }
        if (isTimed(i)) {
            var rem = endMs - System.getTimer();
            if (rem <= 0) {
                next();
                tone(Attention.TONE_LAP);
            } else {
                var s = (rem + 999) / 1000;
                if (s <= 3 && s != lastBeep) {
                    lastBeep = s;
                    vib(60);
                    tone(Attention.TONE_KEY);
                }
            }
        }
    }

    function saveAndExit() {
        if (finished) {
            // La próxima vez propone la sesión siguiente
            Storage.setValue("idx", (idx + 1) % Plan.COUNT);
        }
        if (rec != null) {
            try {
                if (running) { rec.stop(); }
                rec.save();
            } catch (ex) {}
        }
        System.exit();
    }

    function discardAndExit() {
        if (rec != null) {
            try {
                if (running) { rec.stop(); }
                rec.discard();
            } catch (ex) {}
        }
        System.exit();
    }
}
