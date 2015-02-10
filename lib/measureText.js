'use strict';

var FontFace = require('./FontFace');
var FontUtils = require('./FontUtils');

var canvas = document.createElement('canvas');
var ctx = canvas.getContext('2d');

var _cache = {};
var _zeroMetrics = {
  width: 0,
  height: 0,
  lines: []
};

function splitText (text) {
  return text.split(' ');
}

function getCacheKey (text, width, fontFace, fontSize, lineHeight) {
  return text + width + fontFace.id + fontSize + lineHeight;
}

/**
 * Given a string of text, available width, and font return the measured width
 * and height.
 * @param {String} text The input string
 * @param {Number} width The available width
 * @param {FontFace} fontFace The FontFace to use
 * @param {Number} fontSize The font size in CSS pixels
 * @param {Number} lineHeight The line height in CSS pixels
 * @return {Object} Measured text size with `width` and `height` members.
 */
module.exports = function measureText (text, width, fontFace, fontSize, lineHeight) {
  var cacheKey = getCacheKey(text, width, fontFace, fontSize, lineHeight);
  var cached = _cache[cacheKey];
  if (cached) {
    return cached;
  }

  // Bail and return zero unless we're sure the font is ready.
  if (!FontUtils.isFontLoaded(fontFace)) {
    return _zeroMetrics;
  }

  var measuredSize = {};
  var textMetrics;
  var lastMeasuredWidth;
  var words;
  var tryLine;
  var currentLine;

  ctx.font = fontFace.attributes.style + ' normal ' + fontFace.attributes.weight + ' ' + fontSize + 'pt ' + fontFace.family;
  textMetrics = ctx.measureText(text);

  measuredSize.width = textMetrics.width;
  measuredSize.height = lineHeight;
  measuredSize.lines = [];

  if (measuredSize.width <= width) {
    // The entire text string fits.
    measuredSize.lines.push({width: measuredSize.width, text: text});
  } else {
    // Break into multiple lines.
    measuredSize.width = width;
    words = splitText(text);
    currentLine = '';

    // This needs to be optimized!
    while (words.length) {
      tryLine = currentLine + words[0] + ' ';
      textMetrics = ctx.measureText(tryLine);
      if (textMetrics.width > width) {
        measuredSize.height += lineHeight;
        measuredSize.lines.push({width: lastMeasuredWidth, text: currentLine.trim()});
        currentLine = words[0] + ' ';
        lastMeasuredWidth = ctx.measureText(currentLine.trim()).width;
      } else {
        currentLine = tryLine;
        lastMeasuredWidth = textMetrics.width;
      }
      if (words.length === 1) {
        textMetrics = ctx.measureText(currentLine.trim());
        measuredSize.lines.push({width: textMetrics.width, text: currentLine.trim()});
      }
      words.shift();
    }
  }

  _cache[cacheKey] = measuredSize;

  return measuredSize;
};
