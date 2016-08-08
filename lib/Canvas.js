'use strict';

// Note that this class intentionally does not use PooledClass.
// DrawingUtils manages <canvas> pooling for more fine-grained control.

function Canvas (width, height, scale) {
  // Re-purposing an existing canvas element.
  if (!this._canvas) {
    this._canvas = document.createElement('canvas');
  }

  this.width = width;
  this.height = height;
  this.scale = scale || window.devicePixelRatio;

  this._canvas.width = this.width * this.scale;
  this._canvas.height = this.height * this.scale;
  this._canvas.getContext('2d').scale(this.scale, this.scale);
}

Object.assign(Canvas.prototype, {

  getRawCanvas: function () {
    return this._canvas;
  },

  getContext: function () {
    return this._canvas.getContext('2d');
  }

});

// PooledClass:

// Be fairly conserative - we are potentially drawing a large number of medium
// to large size images.
Canvas.poolSize = 30;

module.exports = Canvas;
