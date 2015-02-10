'use strict';

var FrameUtils = require('./FrameUtils');
var DrawingUtils = require('./DrawingUtils');
var EventTypes = require('./EventTypes');

function RenderLayer () {
  this.children = [];
  this.frame = FrameUtils.zero();
}

RenderLayer.prototype = {

  /**
   * Retrieve the root injection layer
   *
   * @return {RenderLayer}
   */
  getRootLayer: function () {
    var root = this;
    while (root.parentLayer) {
      root = root.parentLayer;
    }
    return root;
  },

  /**
   * RenderLayers are injected into a root owner layer whenever a Surface is
   * mounted. This is the integration point with React internals.
   *
   * @param {RenderLayer} parentLayer
   */
  inject: function (parentLayer) {
    if (this.parentLayer && this.parentLayer !== parentLayer) {
      this.remove();
    }
    if (!this.parentLayer) {
      parentLayer.addChild(this);
    }
  },

  /**
   * Inject a layer before a reference layer
   *
   * @param {RenderLayer} parentLayer
   * @param {RenderLayer} referenceLayer
   */
  injectBefore: function (parentLayer, referenceLayer) {
    // FIXME
    this.inject(parentLayer);
  },

  /**
   * Add a child to the render layer
   *
   * @param {RenderLayer} child
   */
  addChild: function (child) {
    child.parentLayer = this;
    this.children.push(child);
  },

  /**
   * Remove a layer from it's parent layer
   */
  remove: function () {
    if (this.parentLayer) {
      this.parentLayer.children.splice(this.parentLayer.children.indexOf(this), 1);
    }
  },

  /**
   * Attach an event listener to a layer. Supported events are defined in
   * lib/EventTypes.js
   *
   * @param {String} type
   * @param {Function} callback
   * @param {?Object} callbackScope
   * @return {Function} invoke to unsubscribe the listener
   */
  subscribe: function (type, callback, callbackScope) {
    // This is the integration point with React, called from LayerMixin.putEventListener().
    // Enforce that only a single callbcak can be assigned per event type.
    for (var eventType in EventTypes) {
      if (EventTypes[eventType] === type) {
        this[eventType] = callback;
      }
    }

    // Return a function that can be called to unsubscribe from the event.
    return this.removeEventListener.bind(this, type, callback, callbackScope);
  },

  /**
   * @param {String} type
   * @param {Function} callback
   * @param {?Object} callbackScope
   */
  addEventListener: function (type, callback, callbackScope) {
    for (var eventType in EventTypes) {
      if (EventTypes[eventType] === type) {
        delete this[eventType];
      }
    }
  },

  /**
   * @param {String} type
   * @param {Function} callback
   * @param {?Object} callbackScope
   */
  removeEventListener: function (type, callback, callbackScope) {
    var listeners = this.eventListeners[type];
    var listener;
    if (listeners) {
      for (var index=0, len=listeners.length; index < len; index++) {
        listener = listeners[index];
        if (listener.callback === callback &&
            listener.callbackScope === callbackScope) {
          listeners.splice(index, 1);
          break;
        }
      }
    }
  },

  /**
   * Translate a layer's frame
   *
   * @param {Number} x
   * @param {Number} y
   */
  translate: function (x, y) {
    if (this.frame) {
      this.frame.x += x;
      this.frame.y += y;
    }

    if (this.clipRect) {
      this.clipRect.x += x;
      this.clipRect.y += y;
    }

    if (this.children) {
      this.children.forEach(function (child) {
        child.translate(x, y);
      });
    }
  },

  /**
   * Layers should call this method when they need to be redrawn. Note the
   * difference here between `invalidateBackingStore`: updates that don't
   * trigger layout should prefer `invalidateLayout`. For instance, an image
   * component that is animating alpha level after the image loads would
   * call `invalidateBackingStore` once after the image loads, and at each
   * step in the animation would then call `invalidateRect`.
   *
   * @param {?Frame} frame Optional, if not passed the entire layer's frame
   *   will be invalidated.
   */
  invalidateLayout: function () {
    // Bubble all the way to the root layer.
    this.getRootLayer().draw();
  },

  /**
   * Layers should call this method when their backing <canvas> needs to be
   * redrawn. For instance, an image component would call this once after the
   * image loads.
   */
  invalidateBackingStore: function () {
    if (this.backingStoreId) {
      DrawingUtils.invalidateBackingStore(this.backingStoreId);
    }
    this.invalidateLayout();
  },

  /**
   * Only the root owning layer should implement this function.
   */
  draw: function () {
    // Placeholer
  }

};

module.exports = RenderLayer;
