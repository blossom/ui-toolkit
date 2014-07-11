import 'package:polymer/polymer.dart';
import 'dart:html';
import 'dart:async';

import 'package:escape_handler/escape_handler.dart';
import '../../utils/html_helpers.dart';

class State {
  static const ACTIVE = const State._(0);
  static const DEACTIVE = const State._(1);

  final int value;
  const State._(this.value);
}

@CustomTag('b-popover')
class BeePopover extends PolymerElement {

  // CSS Styles
  @published String position = "relative";
  @published String left;
  @published String right;
  @published String top;
  @published String bottom;
  @published String arrowLeft;
  @published String arrowRight;
  @published String arrowTop;
  @published String arrowBottom;
  static const EventStreamProvider<CustomEvent> showEvent = const EventStreamProvider<CustomEvent>('show');
  static const EventStreamProvider<CustomEvent> hideEvent = const EventStreamProvider<CustomEvent>('hide');
  @published int elementTimestamp = 0;
  StreamSubscription _documentClick;
  StreamSubscription _documentTouch;
  StreamSubscription _toggleClick;
  StreamSubscription _toggleTouch;
  State _state = State.DEACTIVE;
  EscapeHandler _escapeHandler = new EscapeHandler();

  BeePopover.created() : super.created() {}

  void attached() {
    _updateState(_state);
    _setCssStyles();
    _documentClick = document.onClick.listen(null);
    _documentClick.onData(_hideClickHandler);
    // _documentTouch = document.onTouchStart.listen(null);
    // _documentTouch.onData(_hideClickHandler);
    _toggleClick = shadowRoot.querySelector('.q-launch-area').onClick.listen(null);
    _toggleClick.onData(toggle);
    _toggleTouch = shadowRoot.querySelector('.q-launch-area').onTouchStart.listen(null);
    _toggleTouch.onData(toggle);
  }

  void _setCssStyles() {
    Element popoverWrapper = shadowRoot.querySelector('.q-b-popover-wrapper');
    Element arrow = shadowRoot.querySelector('.q-b-popover-arrow');
    if (position != null) { popoverWrapper.style.position = position; }
    if (left != null) { popoverWrapper.style.left = left; }
    if (right != null) { popoverWrapper.style.right = right; }
    if (top != null) { popoverWrapper.style.top = top; }
    if (bottom != null) { popoverWrapper.style.bottom = bottom; }
    if (arrowLeft != null) { arrow.style.left = arrowLeft; }
    if (arrowRight != null) { arrow.style.right = arrowRight; }
    if (arrowTop != null) { arrow.style.top = arrowTop; }
    if (arrowBottom != null) { arrow.style.bottom = arrowBottom; }
  }

  void detached() {
    if (_documentClick != null) { try { _documentClick.cancel(); } on StateError {}; }
    if (_documentTouch != null) { try { _documentTouch.cancel(); } on StateError {}; }
    if (_toggleClick != null) { try { _toggleClick.cancel(); } on StateError {}; }
    if (_toggleTouch != null) { try { _toggleTouch.cancel(); } on StateError {}; }
  }

  void toggle(event) {
    if (event != null) {event.preventDefault(); }
    if (_state == State.ACTIVE) {
      _updateState(State.DEACTIVE);
    } else {
      _updateState(State.ACTIVE);
    }
  }

  void _updateState(var newState) {
    Element popoverWrapper = shadowRoot.querySelector('.q-b-popover-wrapper');
    _state = newState;
    if (_state == State.ACTIVE) {
      popoverWrapper.style.display = 'block';
      // the attribute elementTimestamp represents the time the popover was activated which is important for 2 reasons
      // * identify the popover in the dom
      // * find out which layer to close on esc
      // this implmentation assumes that multiple elements can't be activated at the exact same millisecond
      elementTimestamp = new DateTime.now().millisecondsSinceEpoch;
      var deactivateFuture = _escapeHandler.addWidget(elementTimestamp);
      deactivateFuture.then((_) {
        _updateState(State.DEACTIVE);
      });
      dispatchEvent(new CustomEvent("show"));
    } else {
      popoverWrapper.style.display = 'none';
      print('hidden again');
      _escapeHandler.removeWidget(elementTimestamp);
      // the element is deactive and we give it 0 as timestamp to make sure
      // you can't find it by getting the max of all elements with the data attribute
      elementTimestamp = 0;
      dispatchEvent(new CustomEvent("hide"));
    }
  }

  void _hideClickHandler(Event event) {
    print('hide handler');
    Element popoverWrapper = shadowRoot.querySelector('.q-b-popover-wrapper');
    // close the overlay in case the user clicked outside of the overlay content area
    // only exception is when the user clicked on the toggle area (this case is handled by toggle)
    print('popoverwrapper: ' + popoverWrapper.className);
    bool clickOutsidePopover = !insideOrIsNodeWhere(event.target, (element) => element.hashCode == shadowRoot.host.hashCode);
    Element launchArea = document.querySelector('.select-launch-area');
    print('click outside of popover?');
    print(clickOutsidePopover);
    print('launcharea: ' + launchArea.className);
    bool clickOnToggleArea = insideOrIsNodeWhere(event.target, (element) => element.hashCode == launchArea.hashCode);
    print('click on toggle area?');
    print(clickOnToggleArea);
    if (clickOutsidePopover && !clickOnToggleArea) {
      _updateState(State.DEACTIVE);
    }
  }

  Stream<CustomEvent> get onShow => showEvent.forTarget(this);
  Stream<CustomEvent> get onHide => hideEvent.forTarget(this);
}