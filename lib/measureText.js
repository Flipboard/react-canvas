'use strict';

var FontFace = require('./FontFace');
var FontUtils = require('./FontUtils');

var canvas = document.createElement('canvas');
var ctx = canvas.getContext('2d');

var Hypher = require('hypher'); // FIXME: Lazy load
var english = require('hyphenation.en-us'); // FIXME: l10n
var h = new Hypher(english);

var _morphemeWidthMemos = {};
var measureMorphemeWidth = function (morpheme, fontFace, fontSize) {
  var memoKey = morpheme + fontFace.id + fontSize;
  var memoized = _morphemeWidthMemos[memoKey];
  if (memoized) { return memoized; }

  ctx.font = fontFace.attributes.style + ' normal ' +
             fontFace.attributes.weight + ' ' + fontSize + 'pt ' +
             fontFace.family;
  var morphemeWidth = ctx.measureText(morpheme).width;

  _morphemeWidthMemos[memoKey] = morphemeWidth;
  return morphemeWidth;
};

var _hyphenationOpportunityMemos = {};
var getHyphenationOpportunities = function(text, hyphens) {
  var memoKey = hyphens + text;
  var memoized = _hyphenationOpportunityMemos[memoKey];
  if (memoized) { return memoized; }

  var words = text.split(/\s+/);
  if (hyphens === 'auto') {
    words = words.map(function(word) {
      return h.hyphenate(word);
    });
  } else {
    words = words.map(function(word) {
      return [word];
    });
  }

  _hyphenationOpportunityMemos[memoKey] = words;
  return words;
};

var _paragraphMetricsMemos = {};
var getParagraphMetrics = function(text, hyphens, fontFace, fontSize) {
  var memoKey = text + hyphens + fontFace.id + fontSize;
  var memoized = _paragraphMetricsMemos[memoKey];
  if (memoized) { return memoized; }

  var metrics = {};
  metrics.fragments = getHyphenationOpportunities(text, hyphens);
  metrics.fragmentWidths = metrics.fragments.map(function(word) {
    return word.map (function(morpheme) {
      return measureMorphemeWidth(morpheme, fontFace, fontSize);
    });
  });
  metrics.spaceWidth = measureMorphemeWidth(' ', fontFace, fontSize);
  metrics.hyphenWidth = measureMorphemeWidth('-', fontFace, fontSize);
  
  _paragraphMetricsMemos[memoKey] = metrics;
  return metrics;
};

var firstFit = function(maxWidth, metrics) {
  function Word() {
    this.text = '';
    this.width = 0;
  }

  function Line() {
    this.whiteSpace = 0;
    this.width = 0;
    this.words = [ new Word() ];
  }

  var lines = [ new Line() ];

  Line.prototype.appendMorpheme = function(morpheme, advanceWidth) {
    var word = this.words[this.words.length - 1];
    word.text += morpheme;
    word.width += advanceWidth;
    this.width += advanceWidth;
  };

  Line.prototype.appendHyphen = function() {
    this.appendMorpheme('-', metrics.hyphenWidth);
  };

  Line.prototype.appendSpace = function() {
    this.whiteSpace += metrics.spaceWidth;
  };

  Line.prototype.newWord = function() {
    this.words.push( new Word() );
  };

  function push(morpheme, advanceWidth, initial, final) {
    var line = lines[lines.length - 1];
    // setting the first morpheme of a line always succeeds
    if (line.width === 0) {
      // good to go!
    // do we need to break the line?
    } else if
        // handle a middle syllable
        ((!initial && !final &&
          line.width + line.whiteSpace + advanceWidth + metrics.hyphenWidth > maxWidth) ||
        // handle an initial syllable
         (initial &&
          line.width + line.whiteSpace + metrics.spaceWidth + advanceWidth > maxWidth) ||
        // handle a final syllable.
         (final &&
          line.width + line.whiteSpace + advanceWidth > maxWidth)) {
      if (!initial) { line.appendHyphen(); }
      line = new Line();
      lines.push(line);
    } else if (initial) {
      line.appendSpace();
      line.newWord();
    }

    line.appendMorpheme(morpheme, advanceWidth);
  }

  metrics.fragments.forEach(function(word, wordIdx, words) {
    word.forEach(function(morpheme, morphemeIdx) {
      var advanceWidth = metrics.fragmentWidths[wordIdx][morphemeIdx];
      var initial = (morphemeIdx === 0);
      var final = (morphemeIdx === word.length - 1);
      push(morpheme, advanceWidth, initial, final);
    });
  });

  console.log(lines);
  return lines;
};

// var _lineBreakMemos = {};
module.exports = function measureText(width, text, hyphens, fontFace, fontSize, lineHeight, breakingStrategy) {
  // Bail and return zero unless we're sure the font is ready.
  if (!FontUtils.isFontLoaded(fontFace)) {
    return { width: 0, height: 0, lines: [] };
  }

  // var memoKey = text + hyphens + fontFace.id + fontSize + width + breakingStrategy;
  // var memoized = _lineBreakMemos[memoKey];
  // if (memoized) { return memoized; }

  var metrics = getParagraphMetrics(text, hyphens, fontFace, fontSize);
  var measuredSize = {};
  measuredSize.width = width;

  if (breakingStrategy === 'firstFit') {
    measuredSize.lines = firstFit(width, metrics);
  } else {
    throw 'TODO: implement global fit linebreaking';
  }

  measuredSize.height = measuredSize.lines.length * lineHeight;
  // _lineBreakMemos[memoKey] = measuredSize;
  console.log(measuredSize);
  return measuredSize;
};