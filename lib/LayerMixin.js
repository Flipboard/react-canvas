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

  sumParentProp: function(propName, layer) {
    var sum = 0;
    var currentLayer = layer;
    while (currentLayer) {
      if (typeof currentLayer[propName] !== 'undefined') {
        sum = sum + currentLayer[propName];
      }
      currentLayer = currentLayer.parentLayer;
    }

    return sum;
  },

  applyLayerProps: function (prevProps, props) {
    var layer = this.node;
    var style = (props && props.style) ? props.style : {};
    var left = style.left || 0;
    var top = style.top || 0;
    var frameLeft, frameTop;
    layer._originalStyle = style;

    layer.translateX = style.translateX;
    layer.translateY = style.translateY;
    frameLeft = left + this.sumParentProp('translateX', layer);
    frameTop = top + this.sumParentProp('translateY', layer);

    // Common layer properties
    layer.alpha = style.alpha;
    layer.backgroundColor = style.backgroundColor;
    layer.borderColor = style.borderColor;
    layer.borderRadius = style.borderRadius;
    layer.clipRect = style.clipRect;
    layer.frame = FrameUtils.make(left, top, style.width || 0, style.height || 0);
    layer.hitFrame = FrameUtils.make(frameLeft, frameTop, style.width || 0, style.height || 0);
    layer.scale = style.scale;
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
    // Purge backing stores on unmount.
    var layer = this.node;
    if (layer.backingStoreId) {
      DrawingUtils.invalidateBackingStore(layer.backingStoreId);
    }
    this.destroyEventListeners();
  }

};

module.exports = LayerMixin;
