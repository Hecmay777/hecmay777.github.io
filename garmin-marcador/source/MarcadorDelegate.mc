using Toybox.WatchUi;
using Toybox.Attention;
using Toybox.System;

// Botones: ARRIBA = punto nosotros, ABAJO = punto ellos, ATRAS = deshacer, START = menu.
class MarcadorDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function buzz(times) {
        if (Attention has :vibrate) {
            var p = [new Attention.VibeProfile(60, 90)];
            if (times > 1) {
                p.add(new Attention.VibeProfile(0, 90));
                p.add(new Attention.VibeProfile(60, 90));
            }
            Attention.vibrate(p);
        }
    }

    function onKey(evt) {
        var k = evt.getKey();
        if (k == WatchUi.KEY_UP) {
            gMatch.point(0);
            buzz(1);
            WatchUi.requestUpdate();
            return true;
        }
        if (k == WatchUi.KEY_DOWN) {
            gMatch.point(1);
            buzz(2);
            WatchUi.requestUpdate();
            return true;
        }
        if (k == WatchUi.KEY_ENTER) {
            openMenu();
            return true;
        }
        return false;
    }

    function onMenu() {
        openMenu();
        return true;
    }

    // ATRAS deshace el ultimo punto. Si no hay nada que deshacer, sale de la app (el partido queda guardado).
    function onBack() {
        if (gMatch.undo()) {
            buzz(1);
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    function openMenu() {
        var c = gMatch.cfg;
        var menu = new WatchUi.Menu2({ :title => "Marcador" });
        menu.addItem(new WatchUi.MenuItem("Cambiar saque", null, :srv, null));
        menu.addItem(new WatchUi.ToggleMenuItem("Punto de oro", null, :golden, c["golden"], null));
        menu.addItem(new WatchUi.ToggleMenuItem("Super tie-break", "en el set decisivo", :stb, c["superTb"], null));
        menu.addItem(new WatchUi.ToggleMenuItem("Tie-break a 6-6", null, :tb, c["tieBreak"], null));
        menu.addItem(new WatchUi.MenuItem("Sets", setsLabel(), :sets, null));
        menu.addItem(new WatchUi.MenuItem("Partido nuevo", "ATRAS lo recupera", :nuevo, null));
        menu.addItem(new WatchUi.MenuItem("Salir de la app", "el partido se guarda", :salir, null));
        WatchUi.pushView(menu, new MarcadorMenuDelegate(), WatchUi.SLIDE_UP);
    }
}

function setsLabel() {
    var b = gMatch.cfg["bestOf"];
    if (b == 1) { return "1 set"; }
    return "al mejor de " + b;
}

class MarcadorMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var id = item.getId();
        var m = gMatch;
        if (id == :srv) {
            m.toggleServer();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :salir) {
            m.save();
            System.exit();
        } else if (id == :nuevo) {
            m.newMatch();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :golden) {
            m.cfg["golden"] = item.isEnabled();
            m.saveCfg();
        } else if (id == :stb) {
            m.cfg["superTb"] = item.isEnabled();
            m.saveCfg();
            if (m.winner < 0 && m.pts[0] == 0 && m.pts[1] == 0 && m.games[0] == 0 && m.games[1] == 0) { m.mode = m.modeFor(); }
        } else if (id == :tb) {
            m.cfg["tieBreak"] = item.isEnabled();
            m.saveCfg();
        } else if (id == :sets) {
            var b = m.cfg["bestOf"];
            if (b == 1) { b = 3; } else if (b == 3) { b = 5; } else { b = 1; }
            m.cfg["bestOf"] = b;
            m.saveCfg();
            item.setSubLabel(setsLabel());
        }
        WatchUi.requestUpdate();
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
