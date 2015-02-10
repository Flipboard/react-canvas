'use strict';

var _fontFaces = {};

/**
 * @param {String} family The CSS font-family value
 * @param {String} url The remote URL for the font file
 * @param {Object} attributes Font attributes supported: style, weight
 * @return {Object}
 */
function FontFace (family, url, attributes) {
  var fontFace;
  var fontId;

  attributes = attributes || {};
  attributes.style = attributes.style || 'normal';
  attributes.weight = attributes.weight || 400;

  fontId = getCacheKey(family, url, attributes);
  fontFace = _fontFaces[fontId];

  if (!fontFace) {
    fontFace = {};
    fontFace.id = fontId;
    fontFace.family = family;
    fontFace.url = url;
    fontFace.attributes = attributes;
    _fontFaces[fontId] = fontFace;
  }

  return fontFace;
}

/**
 * Helper for retrieving the default family by weight.
 *
 * @param {Number} fontWeight
 * @return {FontFace}
 */
FontFace.Default = function (fontWeight) {
  return FontFace('sans-serif', null, {weight: fontWeight});
};

/**
 * @internal
 */
function getCacheKey (family, url, attributes) {
  return family + url + Object.keys(attributes).sort().map(function (key) {
    return attributes[key];
  });
}

module.exports = FontFace;
