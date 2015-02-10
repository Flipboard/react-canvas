'use strict';

// Adapted from ReactART:
// https://github.com/reactjs/react-art

var assign = require('react/lib/Object.assign');
var RenderLayer = require('./RenderLayer');

function createComponent (name) {
  var ReactCanvasComponent = function (props) {
    this.node = null;
    this.subscriptions = null;
    this.listeners = null;
    this.node = new RenderLayer();
    this._mountImage = null;
    this._renderedChildren = null;
    this._mostRecentlyPlacedChild = null;
  };
  ReactCanvasComponent.displayName = name;
  for (var i = 1, l = arguments.length; i < l; i++) {
    assign(ReactCanvasComponent.prototype, arguments[i]);
  }

  return ReactCanvasComponent;
}

module.exports = createComponent;
