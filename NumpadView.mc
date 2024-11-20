import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

//! TouchKeypad is a barrel that allows you to show a keypad for touch devices
//! where the user can input a value and pass it back to your desired callback.
//!
//! It is customizable in a way so it can be used for whole numbers, decimal
//! numbers, time etc.
//!
//! Example:
//!
//!   import Toybox.Lang;
//!   import Toybox.WatchUi;
//!
//!   import TouchKeypad;
//!
//!   class myDelegate extends WatchUi.BehaviorDelegate {
//!       function initialize() {
//!           BehaviorDelegate.initialize();
//!       }
//!
//!       function onMenu() as Boolean {
//!           var view = new NumpadView({
//!               // Callback when pressing OK
//!               :callback => method(:myCallback),
//!               // Default value upon showing the numpad.
//!               :input => "98.2",
//!               // Separator within the number, default to `.`
//!               :separator => ".",
//!               // Limit of how many separators might be entered, default to 1
//!               :separatorLimit => 1,
//!           });
//!           var delegate = new NumpadDelegate(view);
//!
//!           WatchUi.pushView(view, delegate, WatchUi.SLIDE_UP);
//!
//!           return true;
//!       }
//!
//!       function myCallback(input as String) as Void {
//!           System.println("Got input: " + input);
//!       }
//!   }
module TouchKeypad {
    const CLEAR = "C";
    const REMOVE = "<";
    const OK = "OK";

    //! The NumpadView is a view that renders the touch keypad and allows the
    //! user to enter a value.
    class NumpadView extends WatchUi.View {
        // Input stores the state of the input being entered. It's empty by
        // default but can be set to a starting value in the initializer.
        private var _input as String = "";

        // Optional callback passed by the user. If the callback is passed, the
        // current input value will be sent when pressing "OK" before popping
        // the view.
        private var _callback as (Method(value as String) as Void)?;

        // Separator is defaulted to a `.` and limited to 1 occurrance. This
        // fits well for numeric values with fractions. If the numpad is used to
        // enter time, a separator of `:` and a limit of 2 makes more sense. If
        // no separator is allowed, setting an empty string will not render the
        // separator button at all.
        private var _separator as String = ".";
        private var _separatorLimit as Number = 1;

        // Vibration will make the device vibrate when touching the screen if a
        // button is hit.
        private var _vibrate as Boolean = true;

        // The size of the buttons, their spacing and starting position is all
        // calculated based on the device's width and height. These are just
        // initialized values since we don't allow null values but will be
        // changed on the first update.
        private var _buttonWidth as Number = 0;
        private var _buttonHeight as Number = 0;
        private var _buttonSpacing as Number = 0;
        private var _buttonXStart as Number = 0;
        private var _buttonYStart as Number = 0;

        // The buttons to render.
        var _buttons as Array<Array<String> > = [
            ["7", "8", "9", ""],
            ["4", "5", "6", REMOVE],
            ["1", "2", "3", OK],
            [_separator, "0", CLEAR, ""],
        ];

        public function initialize(
            settings as
                {
                    :callback as (Method(input as String) as Void),
                    :input as String,
                    :separator as String,
                    :separatorLimit as Number,
                }
        ) {
            View.initialize();

            if (settings.hasKey(:callback)) {
                _callback =
                    settings.get(:callback) as
                    (Method(value as String) as Void);
            }

            if (settings.hasKey(:input)) {
                _input = settings.get(:input) as String;
            }

            if (settings.hasKey(:separator)) {
                _separator = settings.get(:separator) as String;
                _buttons[3][0] = _separator;
            }

            if (settings.hasKey(:separatorLimit)) {
                _separatorLimit = settings.get(:separatorLimit) as Number;
            }

            if (settings.hasKey(:vibrate)) {
                _vibrate = settings.get(:vibrate) as Boolean;
            }
        }

        function onUpdate(dc as Dc) {
            dc.clear();

            var width = dc.getWidth();
            var height = dc.getHeight();

            // If no button width is set we assume no values for rendering is
            // set so we compute the button width, height, spacing etc.
            if (_buttonWidth == 0) {
                _buttonWidth = width / 6;
                _buttonHeight = height / 6;
                _buttonSpacing = _buttonWidth / 8;
                _buttonXStart = _buttonWidth;
                _buttonYStart = _buttonHeight;
            }

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.drawText(
                width / 2,
                15,
                Graphics.FONT_XTINY,
                _input,
                Graphics.TEXT_JUSTIFY_CENTER
            );

            for (var row = 0; row < _buttons.size(); row++) {
                for (var col = 0; col < _buttons[row].size(); col++) {
                    var label = _buttons[row][col];
                    if (label.equals("")) {
                        continue;
                    }

                    var x =
                        _buttonXStart + col * (_buttonWidth + _buttonSpacing);
                    var y =
                        _buttonYStart + row * (_buttonHeight + _buttonSpacing);

                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                    dc.drawRoundedRectangle(
                        x,
                        y,
                        _buttonWidth,
                        _buttonHeight,
                        20
                    );

                    dc.drawText(
                        x + _buttonWidth / 2,
                        y + _buttonHeight / 2,
                        Graphics.FONT_XTINY,
                        label,
                        Graphics.TEXT_JUSTIFY_CENTER |
                            Graphics.TEXT_JUSTIFY_VCENTER
                    );
                }
            }
        }

        function onTap(position as WatchUi.ClickEvent) as Boolean {
            var button = getButtonAtPosition(position);

            if (button == null) {
                return false;
            }

            if (Attention has :vibrate && _vibrate) {
                Attention.vibrate([new Attention.VibeProfile(25, 50)]);
            }

            if (button.equals(OK)) {
                if (_callback != null) {
                    _callback.invoke(_input);
                }

                WatchUi.popView(WatchUi.SLIDE_DOWN);
            } else if (button.equals(CLEAR)) {
                _input = "";
            } else if (button.equals(REMOVE)) {
                if (_input.length() < 1) {
                    return false;
                }

                _input = _input.substring(0, _input.length() - 1) as String;
            } else {
                if (button.equals(_separator) && _separatorLimit > 0) {
                    var chars = _input.toCharArray();
                    var seenSeparatorChars = 0;

                    for (var i = 0; i < chars.size(); i++) {
                        if (chars[i].toString().equals(_separator)) {
                            seenSeparatorChars += 1;
                        }

                        if (seenSeparatorChars >= _separatorLimit) {
                            return false;
                        }
                    }
                }

                _input += button;
            }

            WatchUi.requestUpdate();

            return true;
        }

        // Determine which button (if any) was tapped
        function getButtonAtPosition(event as WatchUi.ClickEvent) as String? {
            var position = event.getCoordinates();

            for (var row = 0; row < _buttons.size(); row++) {
                for (var col = 0; col < _buttons[row].size(); col++) {
                    var x =
                        _buttonXStart + col * (_buttonWidth + _buttonSpacing);
                    var y =
                        _buttonYStart + row * (_buttonHeight + _buttonSpacing);

                    if (
                        position[0] >= x &&
                        position[0] <= x + _buttonWidth &&
                        position[1] >= y &&
                        position[1] <= y + _buttonHeight
                    ) {
                        return _buttons[row][col];
                    }
                }
            }

            return null;
        }
    }
}
