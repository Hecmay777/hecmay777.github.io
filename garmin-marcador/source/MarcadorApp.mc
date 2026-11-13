using Toybox.Application;
using Toybox.WatchUi;

var gMatch = null;

class MarcadorApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        gMatch = new Match();
        return [new MarcadorView(), new MarcadorDelegate()];
    }
}
