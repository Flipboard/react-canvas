'use strict';

var FontFace = require('./FontFace');

var _useNativeImpl = (typeof window.FontFace !== 'undefined');
var _pendingFonts = {};
var _loadedFonts = {};
var _failedFonts = {};

var kFontLoadTimeout = 3000;

/**
 * Check if a font face has loaded
 * @param {FontFace} fontFace
 * @return {Boolean}
 */
function isFontLoaded (fontFace) {
  // For remote URLs, check the cache. System fonts (sans url) assume loaded.
  return _loadedFonts[fontFace.id] !== undefined || !fontFace.url;
}

/**
 * Load a remote font and execute a callback.
 * @param {FontFace} fontFace The font to Load
 * @param {Function} callback Function executed upon font Load
 */
function loadFont (fontFace, callback) {
  var defaultNode;
  var testNode;
  var checkFont;

  // See if we've previously loaded it.
  if (_loadedFonts[fontFace.id]) {
    return callback(null);
  }

  // See if we've previously failed to load it.
  if (_failedFonts[fontFace.id]) {
    return callback(_failedFonts[fontFace.id]);
  }

  // System font: assume already loaded.
  if (!fontFace.url) {
    return callback(null);
  }

  // Font load is already in progress:
  if (_pendingFonts[fontFace.id]) {
    _pendingFonts[fontFace.id].callbacks.push(callback);
    return;
  }

  // Create the test <span>'s for measuring.
  defaultNode = createTestNode('Helvetica', fontFace.attributes);
  testNode = createTestNode(fontFace.family, fontFace.attributes);
  document.body.appendChild(testNode);
  document.body.appendChild(defaultNode);

  _pendingFonts[fontFace.id] = {
    startTime: Date.now(),
    defaultNode: defaultNode,
    testNode: testNode,
    callbacks: [callback]
  };

  // Font watcher
  checkFont = function () {
    var currWidth = testNode.getBoundingClientRect().width;
    var defaultWidth = defaultNode.getBoundingClientRect().width;
    var loaded = currWidth !== defaultWidth;

    if (loaded) {
      handleFontLoad(fontFace, null);
    } else {
      // Timeout?
      if (Date.now() - _pendingFonts[fontFace.id].startTime >= kFontLoadTimeout) {
        handleFontLoad(fontFace, true);
      } else {
        requestAnimationFrame(checkFont);
      }
    }
  };

  // Start watching
  checkFont();
}

// Internal
// ========

/**
 * Native FontFace loader implementation
 * @internal
 */
function loadFontNative (fontFace, callback) {
  var theFontFace;

  // See if we've previously loaded it.
  if (_loadedFonts[fontFace.id]) {
    return callback(null);
  }

  // See if we've previously failed to load it.
  if (_failedFonts[fontFace.id]) {
    return callback(_failedFonts[fontFace.id]);
  }

  // System font: assume it's installed.
  if (!fontFace.url) {
    return callback(null);
  }

  // Font load is already in progress:
  if (_pendingFonts[fontFace.id]) {
    _pendingFonts[fontFace.id].callbacks.push(callback);
    return;
  }

  _pendingFonts[fontFace.id] = {
    startTime: Date.now(),
    callbacks: [callback]
  };

  // Use font loader API
  theFontFace = new window.FontFace(fontFace.family,
    'url(' + fontFace.url + ')', fontFace.attributes);

  theFontFace.load().then(function () {
    _loadedFonts[fontFace.id] = true;
    callback(null);
  }, function (err) {
    _failedFonts[fontFace.id] = err;
    callback(err);
  });
}

/**
 * Helper method for created a hidden <span> with a given font.
 * Uses TypeKit's default test string, which is said to result
 * in highly varied measured widths when compared to the default font.
 * @internal
 */
function createTestNode (family, attributes) {
  var span = document.createElement('span');
  span.setAttribute('data-fontfamily', family);
  span.style.cssText = 'position:absolute; left:-5000px; top:-5000px; visibility:hidden;' +
    'font-size:100px; font-family:"' + family + '", Helvetica;font-weight: ' + attributes.weight + ';' +
    'font-style:' + attributes.style + ';';
  span.innerHTML = 'BESs';
  return span;
}

/**
 * @internal
 */
function handleFontLoad (fontFace, timeout) {
  var error = timeout ? 'Exceeded load timeout of ' + kFontLoadTimeout + 'ms' : null;

  if (!error) {
    _loadedFonts[fontFace.id] = true;
  } else {
    _failedFonts[fontFace.id] = error;
  }

  // Execute pending callbacks.
  _pendingFonts[fontFace.id].callbacks.forEach(function (callback) {
    callback(error);
  });

  // Clean up DOM
  if (_pendingFonts[fontFace.id].defaultNode) {
    document.body.removeChild(_pendingFonts[fontFace.id].defaultNode);
  }
  if (_pendingFonts[fontFace.id].testNode) {
    document.body.removeChild(_pendingFonts[fontFace.id].testNode);
  }

  // Clean up waiting queue
  delete _pendingFonts[fontFace.id];
}

module.exports = {
  isFontLoaded: isFontLoaded,
  loadFont: _useNativeImpl ? loadFontNative : loadFont
};
