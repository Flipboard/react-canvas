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

  ctx.drawImage(image.getRawImage(), sx, sy, sw, sh, dx, dy, dw, dh);
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
  options.breakingStrategy = options.breakingStrategy || 'firstFit';
  options.hyphens = options.hyphens || 'none';


  textMetrics = measureText(
    width,
    text,
    options.hyphens,
    fontFace,
    options.fontSize,
    options.lineHeight,
    options.breakingStrategy
  );

  ctx.save();

  // Draw the background
  if (options.backgroundColor !== 'transparent') {
    ctx.fillStyle = options.backgroundColor;
    ctx.fillRect(0, 0, width, height);
  }

  ctx.fillStyle = options.color;
  ctx.font = fontFace.attributes.style + ' normal ' + fontFace.attributes.weight + ' ' + options.fontSize + 'pt ' + fontFace.family;

  textMetrics.lines.forEach(function (line, lineIdx, lines) {

    var currY = y + options.fontSize;
    if (lineIdx !== 0) {
      currY += options.lineHeight * lineIdx;
    }

    // only render if on screen
    if (currY <= (height + y)) {

      var words = line.words.map( function(word) { return word.text; });

      if ((lineIdx < textMetrics.lines.length - 1) &&
        ((options.fontSize + options.lineHeight * (lineIdx + 1)) > height)) {
        words.pop();
        words[words.length - 1] += '…';
      }

      // Fast path. We can discard all width information and set one
      // text run per line, allowing fillText() to handle spacing.
      // Special case the last line of a justified paragraph.
      if (options.textAlign !== 'justify' || lineIdx === lines.length - 1) {
        currText = words.join(' ');
        // Account for text-align: left|right|center
        switch (options.textAlign) {
          case 'center':
            currX = x + (width / 2) - ((line.width + line.whiteSpace) / 2);
            break;
          case 'right':
            currX = x + width - line.width - line.whiteSpace;
            break;
          default:
            currX = x;
        }
        
        ctx.fillText(currText, currX, currY);
        
      // Slow path. Full justification. Set each word individually.
      } else {
        var spaceWidth = (textMetrics.width - line.width) / (line.words.length - 1);

        // This is not idiomatic in JavaScript... consider Haskell:
        // data Word = Word {text :: String, width :: Double}
        // let advanceWidths = (scanl (+) 0 . map width :: [Word] -> [Double]) words
        // or Clojure:
        // (def advanceWidths (reductions + 0 (map #(get % :width) words)))
        var advanceWidths = line.words.map( function(word) {
          return word.width;
        }).reduce(function(memo, width) {
          memo.push(memo[memo.length - 1] + spaceWidth + width);
          return memo;
        }, [0]);

        words.forEach(function(word, wordIdx) {
          ctx.fillText(word, x + advanceWidths[wordIdx], currY);
        });
      }

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

