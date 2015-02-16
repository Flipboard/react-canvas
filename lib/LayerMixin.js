'use strict';

// Adapted from ReactART:
// https://github.com/reactjs/react-art

var FrameUtils = require('./FrameUtils');
var DrawingUtils = require('./DrawingUtils');
var EventTypes = require('./EventTypes');

var LAYER_GUID = 0;

var LayerMixin = {

  construct: function(element) {
    this._currentElement = element;
    this._layerId = LAYER_GUID++;
  },

  getPublicInstance: function() {
    return this.node;
  },

  putEventListener: function(type, listener) {
    var subscriptions = this.subscriptions || (this.subscriptions = {});
    var listeners = this.listeners || (this.listeners = {});
    listeners[type] = listener;
    if (listener) {
      if (!subscriptions[type]) {
        subscriptions[type] = this.node.subscribe(type, listener, this);
      }
    } else {
      if (subscriptions[type]) {
        subscriptions[type]();
        delete subscriptions[type];
      }
    }
  },

  handleEvent: function(event) {
    // TODO
  },

  destroyEventListeners: function() {
    // TODO
  },

  applyLayerProps: function (prevProps, props) {
    var layer = this.node;
    var style = (props && props.style) ? props.style : {};
    layer._originalStyle = style;

    // Common layer properties
    layer.alpha = style.alpha;
    layer.backgroundColor = style.backgroundColor;
    layer.borderColor = style.borderColor;
    layer.borderWidth = style.borderWidth;
    layer.borderRadius = style.borderRadius;
    layer.clipRect = style.clipRect;
    layer.frame = FrameUtils.make(style.left || 0, style.top || 0, style.width || 0, style.height || 0);
    layer.scale = style.scale;
    layer.translateX = style.translateX;
    layer.translateY = style.translateY;
    layer.zIndex = style.zIndex;

    // Generate backing store ID as needed.
    if (props.useBackingStore) {
      layer.backingStoreId = this._layerId;
    }

    // Register events
    for (var type in EventTypes) {
      this.putEventListener(EventTypes[type], props[type]);
    }
  },

  mountComponentIntoNode: function(rootID, container) {
    throw new Error(
      'You cannot render a Canvas component standalone. ' +
      'You need to wrap it in a Surface.'
    );
  },

  unmountComponent: function() {
    this.destroyEventListeners();
  }

};

module.exports = LayerMixin;
