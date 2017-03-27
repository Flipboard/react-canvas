'use strict';

var FontFace = require('./FontFace');
var clamp = require('./clamp');
var measureText = require('./measureText');

/**
 * Draw an image into a <canvas>. This operation requires that the image
 * already be loaded.
 *
 * @param {CanvasContext} ctx
 * @param {Image} image The source image (from ImageCache.get())
 * @param {Number} x The x-coordinate to begin drawing
 * @param {Number} y The y-coordinate to begin drawing
 * @param {Number} width The desired width
 * @param {Number} height The desired height
 * @param {Object} options Available options are:
 *   {Number} originalWidth
 *   {Number} originalHeight
 *   {Object} focusPoint {x,y}
 *   {String} backgroundColor
 */
function drawImage (ctx, image, x, y, width, height, options) {
  options = options || {};

  if (options.backgroundColor) {
    ctx.save();
    ctx.fillStyle = options.backgroundColor;
    ctx.fillRect(x, y, width, height);
    ctx.restore();
  }

  var dx = 0;
  var dy = 0;
  var dw = 0;
  var dh = 0;
  var sx = 0;
  var sy = 0;
  var sw = 0;
  var sh = 0;
  var scale;
  var scaledSize;
  var actualSize;
  var focusPoint = options.focusPoint;

  actualSize = {
    width: image.getWidth(),
    height: image.getHeight()
  };

  scale = Math.max(
    width / actualSize.width,
    height / actualSize.height
  ) || 1;
  scale = parseFloat(scale.toFixed(4), 10);

  scaledSize = {
    width: actualSize.width * scale,
    height: actualSize.height * scale
  };

  if (focusPoint) {
    // Since image hints are relative to image "original" dimensions (original != actual),
    // use the original size for focal point cropping.
    if (options.originalHeight) {
      focusPoint.x *= (actualSize.height / options.originalHeight);
      focusPoint.y *= (actualSize.height / options.originalHeight);
    }
  } else {
    // Default focal point to [0.5, 0.5]
    focusPoint = {
      x: actualSize.width * 0.5,
      y: actualSize.height * 0.5
    };
  }

  // Clip the image to rectangle (sx, sy, sw, sh).
  sx = Math.round(clamp(width * 0.5 - focusPoint.x * scale, width - scaledSize.width, 0)) * (-1 / scale);
  sy = Math.round(clamp(height * 0.5 - focusPoint.y * scale, height - scaledSize.height, 0)) * (-1 / scale);
  sw = Math.round(actualSize.width - (sx * 2));
  sh = Math.round(actualSize.height - (sy * 2));

  // Scale the image to dimensions (dw, dh).
  dw = Math.round(width);
  dh = Math.round(height);

  // Draw the image on the canvas at coordinates (dx, dy).
  dx = Math.round(x);
  dy = Math.round(y);

  if (options.rotate) {
    ctx.save();
    ctx.translate(dx + (dw / 2), dy + (dh / 2));
    ctx.rotate(options.rotate * Math.PI / 180);
    ctx.drawImage(image.getRawImage(), sx, sy, sw, sh, - (dw / 2), - (dh / 2), dw, dh);
    ctx.restore();
  } else {
    ctx.drawImage(image.getRawImage(), sx, sy, sw, sh, dx, dy, dw, dh);
  }
}

/**
 * @param {CanvasContext} ctx
 * @param {String} text The text string to render
 * @param {Number} x The x-coordinate to begin drawing
 * @param {Number} y The y-coordinate to begin drawing
 * @param {Number} width The maximum allowed width
 * @param {Number} height The maximum allowed height
 * @param {FontFace} fontFace The FontFace to to use
 * @param {Object} options Available options are:
 *   {Number} fontSize
 *   {Number} lineHeight
 *   {String} textAlign
 *   {String} color
 *   {String} backgroundColor
 */
function drawText (ctx, text, x, y, width, height, fontFace, options) {
  var textMetrics;
  var currX = x;
  var currY = y;
  var currText;
  var options = options || {};

  options.fontSize = options.fontSize || 16;
  options.lineHeight = options.lineHeight || 18;
  options.textAlign = options.textAlign || 'left';
  options.backgroundColor = options.backgroundColor || 'transparent';
  options.color = options.color || '#000';

  textMetrics = measureText(
    text,
    width,
    fontFace,
    options.fontSize,
    options.lineHeight
  );

  ctx.save();

  // Draw the background
  if (options.backgroundColor !== 'transparent') {
    ctx.fillStyle = options.backgroundColor;
    ctx.fillRect(0, 0, width, height);
  }

  ctx.fillStyle = options.color;
  ctx.font = fontFace.attributes.style + ' ' + fontFace.attributes.weight + ' ' + options.fontSize + 'px ' + fontFace.family;

  textMetrics.lines.forEach(function (line, index) {
    currText = line.text;
    currY = (index === 0) ? y + options.fontSize :
      (y + options.fontSize + options.lineHeight * index);

    // Account for text-align: left|right|center
    switch (options.textAlign) {
      case 'center':
        currX = x + (width / 2) - (line.width / 2);
        break;
      case 'right':
        currX = x + width - line.width;
        break;
      default:
        currX = x;
    }

    if ((index < textMetrics.lines.length - 1) &&
      ((options.fontSize + options.lineHeight * (index + 1)) > height)) {
      currText = currText.replace(/\,?\s?\w+$/, '…');
    }

    if (currY <= (height + y)) {
      ctx.fillText(currText, currX, currY);
    }
  });

  ctx.restore();
}

/**
 * Draw a linear gradient
 *
 * @param {CanvasContext} ctx
 * @param {Number} x1 gradient start-x coordinate
 * @param {Number} y1 gradient start-y coordinate
 * @param {Number} x2 gradient end-x coordinate
 * @param {Number} y2 gradient end-y coordinate
 * @param {Array} colorStops Array of {(String)color, (Number)position} values
 * @param {Number} x x-coordinate to begin fill
 * @param {Number} y y-coordinate to begin fill
 * @param {Number} width how wide to fill
 * @param {Number} height how tall to fill
 */
function drawGradient(ctx, x1, y1, x2, y2, colorStops, x, y, width, height) {
  var grad;

  ctx.save();
  grad = ctx.createLinearGradient(x1, y1, x2, y2);

  colorStops.forEach(function (colorStop) {
    grad.addColorStop(colorStop.position, colorStop.color);
  });

  ctx.fillStyle = grad;
  ctx.fillRect(x, y, width, height);
  ctx.restore();
}

module.exports = {
  drawImage: drawImage,
  drawText: drawText,
  drawGradient: drawGradient,
};

