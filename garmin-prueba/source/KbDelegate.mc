using Toybox.WatchUi;
using Toybox.Application;

class KbDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    // Botón START/STOP
    function onSelect() {
        var s = Application.getApp().ses;
        if (!s.started) {
            s.begin();
        } else if (s.finished) {
            s.saveAndExit();
        } else if (s.kind() == 1) {
            s.next();
        } else {
            s.pauseToggle();
        }
        WatchUi.requestUpdate();
        return true;
    }

    // Botón abajo: siguiente paso
    function onNextPage() {
        var s = Application.getApp().ses;
        if (!s.started) {
            s.select(1);
        } else {
            s.next();
        }
        WatchUi.requestUpdate();
        return true;
    }

    // Botón arriba: paso anterior
    function onPreviousPage() {
        var s = Application.getApp().ses;
        if (!s.started) {
            s.select(-1);
        } else {
            s.prev();
        }
        WatchUi.requestUpdate();
        return true;
    }

    // Botón BACK: paso anterior; en el primer paso abre el menú
    function onBack() {
        var s = Application.getApp().ses;
        if (!s.started) {
            return false;   // sin empezar: BACK sale de la app
        }
        if (s.started && !s.finished && s.i > 0) {
            s.prev();
            WatchUi.requestUpdate();
        } else {
            openMenu();
        }
        return true;
    }

    // Mantener pulsado el botón de arriba: menú
    function onMenu() {
        if (!Application.getApp().ses.started) {
            return true;
        }
        openMenu();
        return true;
    }

    function openMenu() {
        var menu = new WatchUi.Menu();
        menu.setTitle("Menú");
        menu.addItem("Seguir", :seguir);
        menu.addItem("Reiniciar paso", :reiniciar);
        menu.addItem("Guardar y salir", :guardar);
        menu.addItem("Descartar y salir", :descartar);
        WatchUi.pushView(menu, new KbMenuDelegate(), WatchUi.SLIDE_UP);
    }
}

class KbMenuDelegate extends WatchUi.MenuInputDelegate {
    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
        var s = Application.getApp().ses;
        if (item == :reiniciar) {
            s.restart();
        } else if (item == :guardar) {
            s.saveAndExit();
        } else if (item == :descartar) {
            s.discardAndExit();
        }
    }
}
