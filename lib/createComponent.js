'use strict';

// Adapted from ReactART:
// https://github.com/reactjs/react-art

var RenderLayer = require('./RenderLayer');

function createComponent (name) {
  var ReactCanvasComponent = function (element) {
    this.node = null;
    this.subscriptions = null;
    this.listeners = null;
    this.node = new RenderLayer();
    this._mountImage = null;
    this._currentElement = element;
    this._renderedChildren = null;
    this._mostRecentlyPlacedChild = null;
  };
  ReactCanvasComponent.displayName = name;
  for (var i = 1, l = arguments.length; i < l; i++) {
    Object.assign(ReactCanvasComponent.prototype, arguments[i]);
  }

  return ReactCanvasComponent;
}

module.exports = createComponent;
