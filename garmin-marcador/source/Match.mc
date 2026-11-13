using Toybox.Application.Storage;

// Reglas del partido: puntos, juegos, sets, tie-break, saque y deshacer.
// Equipo 0 = nosotros, equipo 1 = ellos.
class Match {
    var cfg;     // "bestOf", "golden", "superTb", "tieBreak"
    var sets;    // cada set: [juegos0, juegos1, tb0, tb1, tipo]  tipo 0 normal, 1 con tie-break, 2 super tie-break
    var games;
    var pts;
    var mode;    // 0 juego normal, 1 tie-break, 2 super tie-break
    var winner;  // -1 si nadie ha ganado todavia
    var srv;     // quien saca el juego (o quien empezo sacando el tie-break)
    var hist;
    var flash;

    function initialize() {
        cfg = { "bestOf" => 3, "golden" => false, "superTb" => false, "tieBreak" => true };
        sets = [];
        games = [0, 0];
        pts = [0, 0];
        winner = -1;
        srv = 0;
        hist = [];
        flash = "";
        mode = 0;
        load();
    }

    function setsWon() {
        var w = [0, 0];
        for (var i = 0; i < sets.size(); i++) {
            var s = sets[i];
            if (s[0] > s[1]) { w[0] += 1; } else { w[1] += 1; }
        }
        return w;
    }

    function need() {
        return (cfg["bestOf"] + 1) / 2;
    }

    function modeFor() {
        var w = setsWon();
        if (cfg["superTb"] && cfg["bestOf"] > 1 && w[0] == w[1] && w[0] == need() - 1) {
            return 2;
        }
        return 0;
    }

    function snap() {
        var c = [];
        for (var i = 0; i < sets.size(); i++) {
            var s = sets[i];
            c.add([s[0], s[1], s[2], s[3], s[4]]);
        }
        return [c, games[0], games[1], pts[0], pts[1], mode, winner, srv];
    }

    function restore(h) {
        var c = [];
        var src = h[0];
        for (var i = 0; i < src.size(); i++) {
            var s = src[i];
            c.add([s[0], s[1], s[2], s[3], s[4]]);
        }
        sets = c;
        games = [h[1], h[2]];
        pts = [h[3], h[4]];
        mode = h[5];
        winner = h[6];
        srv = h[7];
    }

    function pushHist() {
        hist.add(snap());
        if (hist.size() > 60) {
            hist = hist.slice(1, null);
        }
    }

    function endSet(entry) {
        sets.add(entry);
        games = [0, 0];
        pts = [0, 0];
        var w = setsWon();
        if (w[0] >= need()) {
            winner = 0;
        } else if (w[1] >= need()) {
            winner = 1;
        } else {
            mode = modeFor();
        }
    }

    function point(who) {
        if (winner >= 0) { return; }
        pushHist();
        flash = "";
        var o = 1 - who;
        pts[who] += 1;
        if (mode == 0) {
            var won;
            if (cfg["golden"]) {
                won = (pts[who] >= 4);
            } else {
                won = (pts[who] >= 4 && pts[who] - pts[o] >= 2);
            }
            if (won) {
                games[who] += 1;
                pts = [0, 0];
                srv = 1 - srv;
                var tot = games[0] + games[1];
                if (games[who] >= 6 && games[who] - games[o] >= 2) {
                    endSet([games[0], games[1], 0, 0, 0]);
                    if (winner < 0 && tot % 2 == 1) { flash = "Cambio de lado"; }
                } else {
                    if (games[0] == 6 && games[1] == 6 && cfg["tieBreak"]) { mode = 1; }
                    if (tot % 2 == 1) { flash = "Cambio de lado"; }
                }
            }
        } else {
            var target = (mode == 1) ? 7 : 10;
            if (pts[who] >= target && pts[who] - pts[o] >= 2) {
                srv = 1 - srv;
                if (mode == 1) {
                    var g = [games[0], games[1]];
                    g[who] += 1;
                    endSet([g[0], g[1], pts[0], pts[1], 1]);
                    if (winner < 0) { flash = "Cambio de lado"; }
                } else {
                    var e = [0, 0, pts[0], pts[1], 2];
                    e[who] = 1;
                    endSet(e);
                }
            } else if ((pts[0] + pts[1]) % 6 == 0) {
                flash = "Cambio de lado";
            }
        }
        save();
    }

    function undo() {
        if (hist.size() == 0) { return false; }
        restore(hist[hist.size() - 1]);
        hist = hist.slice(0, hist.size() - 1);
        flash = "";
        save();
        return true;
    }

    // Quien saca ahora. En tie-break: un punto y luego de dos en dos.
    function server() {
        if (mode == 0) { return srv; }
        var n = pts[0] + pts[1];
        if (((n + 1) / 2) % 2 == 0) { return srv; }
        return 1 - srv;
    }

    function toggleServer() {
        if (winner >= 0) { return; }
        pushHist();
        srv = 1 - srv;
        flash = "";
        save();
    }

    // Partido nuevo. Se puede deshacer para recuperar el anterior.
    function newMatch() {
        pushHist();
        sets = [];
        games = [0, 0];
        pts = [0, 0];
        winner = -1;
        srv = 0;
        flash = "";
        mode = modeFor();
        save();
    }

    function label(i) {
        if (mode != 0) { return pts[i].toString(); }
        var a = pts[i];
        var b = pts[1 - i];
        if (a >= 3 && b >= 3) {
            if (cfg["golden"] || a <= b) { return "40"; }
            return "AD";
        }
        var names = ["0", "15", "30", "40"];
        return names[a];
    }

    function note() {
        if (winner >= 0) { return ""; }
        if (mode == 1) { return "Tie-break"; }
        if (mode == 2) { return "Super tie-break"; }
        if (pts[0] >= 3 && pts[1] >= 3) {
            if (cfg["golden"]) { return "Punto de oro"; }
            if (pts[0] == pts[1]) { return "Iguales"; }
            return "Ventaja";
        }
        return "";
    }

    function save() {
        Storage.setValue("m", snap());
        Storage.setValue("h", hist);
    }

    function saveCfg() {
        Storage.setValue("cfg", cfg);
    }

    function load() {
        var c = Storage.getValue("cfg");
        if (c != null) {
            var keys = ["bestOf", "golden", "superTb", "tieBreak"];
            for (var i = 0; i < keys.size(); i++) {
                if (c.hasKey(keys[i])) { cfg[keys[i]] = c[keys[i]]; }
            }
        }
        var m = Storage.getValue("m");
        if (m != null && m.size() == 8) {
            restore(m);
            var h = Storage.getValue("h");
            if (h != null) { hist = h; }
        }
    }
}
