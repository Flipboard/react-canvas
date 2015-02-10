'use strict';

var EventEmitter = require('events');
var assign = require('react/lib/Object.assign');

var NOOP = function () {};

function Img (src) {
  this._originalSrc = src;
  this._img = new Image();
  this._img.onload = this.emit.bind(this, 'load');
  this._img.onerror = this.emit.bind(this, 'error');
  this._img.src = src;

  // The default impl of events emitter will throw on any 'error' event unless
  // there is at least 1 handler. Logging anything in this case is unnecessary
  // since the browser console will log it too.
  this.on('error', NOOP);

  // Default is just 10.
  this.setMaxListeners(100);
}

assign(Img.prototype, EventEmitter.prototype, {

  /**
   * Pooling owner looks for this
   */
  destructor: function () {
    // Make sure we aren't leaking callbacks.
    this.removeAllListeners();
  },

  /**
   * Retrieve the original image URL before browser normalization
   *
   * @return {String}
   */
  getOriginalSrc: function () {
    return this._originalSrc;
  },

  /**
   * Retrieve a reference to the underyling <img> node.
   *
   * @return {HTMLImageElement}
   */
  getRawImage: function () {
    return this._img;
  },

  /**
   * Retrieve the loaded image width
   *
   * @return {Number}
   */
  getWidth: function () {
    return this._img.naturalWidth;
  },

  /**
   * Retrieve the loaded image height
   *
   * @return {Number}
   */
  getHeight: function () {
    return this._img.naturalHeight;
  },

  /**
   * @return {Bool}
   */
  isLoaded: function () {
    return this._img.naturalHeight > 0;
  }

});

var kInstancePoolLength = 300;
var _instancePool = [];

function getPooledImage (src) {
  for (var i=0, len=_instancePool.length; i < len; i++) {
    if (_instancePool[i].getOriginalSrc() === src) {
      return _instancePool[i];
    }
  }
  return null;
}

var ImageCache = {

  /**
   * Retrieve an image from the cache
   *
   * @return {Img}
   */
  get: function (src) {
    var image = getPooledImage(src);
    if (!image) {
      // Simple FIFO queue
      image = new Img(src);
      if (_instancePool.length >= kInstancePoolLength) {
        _instancePool.shift().destructor();
      }
    _instancePool.push(image);
    }
    return image;
  }

};

module.exports = ImageCache;
