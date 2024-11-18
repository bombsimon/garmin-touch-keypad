import Toybox.Lang;
import Toybox.WatchUi;

module TouchKeypad {
    class NumpadDelegate extends WatchUi.BehaviorDelegate {
        private var _view as NumpadView;

        function initialize(view as NumpadView) {
            _view = view;
            BehaviorDelegate.initialize();
        }

        function onTap(position as WatchUi.ClickEvent) {
            return _view.onTap(position);
        }
    }
}
