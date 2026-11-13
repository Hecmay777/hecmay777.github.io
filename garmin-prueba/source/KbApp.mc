using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Timer;

class KbApp extends Application.AppBase {
    var ses;
    var timer;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        ses = new Ses();
        timer = new Timer.Timer();
        timer.start(method(:onTick), 250, true);
    }

    function onStop(state) {
        if (timer != null) {
            timer.stop();
        }
    }

    function onTick() {
        ses.onTick();
        WatchUi.requestUpdate();
    }

    function getInitialView() {
        return [ new KbView(), new KbDelegate() ];
    }
}
