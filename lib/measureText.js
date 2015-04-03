'use strict';

var FontFace = require('./FontFace');
var FontUtils = require('./FontUtils');
var LineBreaker = require('linebreak');

var canvas = document.createElement('canvas');
var ctx = canvas.getContext('2d');

var _cache = {};
var _zeroMetrics = {
  width: 0,
  height: 0,
  lines: []
};

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
  var breaker;
  var bk;
  var lastBreak;

  ctx.font = fontFace.attributes.style + ' ' + fontFace.attributes.weight + ' ' + fontSize + 'px ' + fontFace.family;
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
    currentLine = '';
    breaker = new LineBreaker(text);
    
    while (bk = breaker.nextBreak()) {
      var word = text.slice(lastBreak ? lastBreak.position : 0, bk.position);
      
      tryLine = currentLine + word;
      textMetrics = ctx.measureText(tryLine);
      if (textMetrics.width > width || (lastBreak && lastBreak.required)) {
        measuredSize.height += lineHeight;
        measuredSize.lines.push({width: lastMeasuredWidth, text: currentLine.trim()});
        currentLine = word;
        lastMeasuredWidth = ctx.measureText(currentLine.trim()).width;
      } else {
        currentLine = tryLine;
        lastMeasuredWidth = textMetrics.width;
      }
      
      lastBreak = bk;
    }
    
    currentLine = currentLine.trim();
    if (currentLine.length > 0) {
      textMetrics = ctx.measureText(currentLine);
      measuredSize.lines.push({width: textMetrics, text: currentLine});
    }
  }

  _cache[cacheKey] = measuredSize;

  return measuredSize;
};
