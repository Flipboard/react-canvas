'use strict';

function Frame (x, y, width, height) {
  this.x = x;
  this.y = y;
  this.width = width;
  this.height = height;
}

/**
 * Get a frame object
 *
 * @param {Number} x
 * @param {Number} y
 * @param {Number} width
 * @param {Number} height
 * @return {Frame}
 */
function make (x, y, width, height) {
  return new Frame(x, y, width, height);
}

/**
 * Return a zero size anchored at (0, 0).
 *
 * @return {Frame}
 */
function zero () {
  return make(0, 0, 0, 0);
}

/**
 * Return a cloned frame
 *
 * @param {Frame} frame
 * @return {Frame}
 */
function clone (frame) {
  return make(frame.x, frame.y, frame.width, frame.height);
}

/**
 * Creates a new frame by a applying edge insets. This method accepts CSS
 * shorthand notation e.g. inset(myFrame, 10, 0);
 *
 * @param {Frame} frame
 * @param {Number} top
 * @param {Number} right
 * @param {?Number} bottom
 * @param {?Number} left
 * @return {Frame}
 */
function inset (frame, top, right, bottom, left) {
  var frameCopy = clone(frame);

  // inset(myFrame, 10, 0) => inset(myFrame, 10, 0, 10, 0)
  if (typeof bottom === 'undefined') {
    bottom = top;
    left = right;
  }

  // inset(myFrame, 10) => inset(myFrame, 10, 10, 10, 10)
  if (typeof right === 'undefined') {
    right = bottom = left = top;
  }

  frameCopy.x += left;
  frameCopy.y += top;
  frameCopy.height -= (top + bottom);
  frameCopy.width -= (left + right);

  return frameCopy;
}

/**
 * Compute the intersection region between 2 frames.
 *
 * @param {Frame} frame
 * @param {Frame} otherFrame
 * @return {Frame}
 */
function intersection (frame, otherFrame) {
  var x = Math.max(frame.x, otherFrame.x);
  var width = Math.min(frame.x + frame.width, otherFrame.x + otherFrame.width);
  var y = Math.max(frame.y, otherFrame.y);
  var height = Math.min(frame.y + frame.height, otherFrame.y + otherFrame.height);
  if (width >= x && height >= y) {
    return make(x, y, width - x, height - y);
  }
  return null;
}

/**
 * Compute the union of two frames
 *
 * @param {Frame} frame
 * @param {Frame} otherFrame
 * @return {Frame}
 */
function union (frame, otherFrame) {
  var x1 = Math.min(frame.x, otherFrame.x);
  var x2 = Math.max(frame.x + frame.width, otherFrame.x + otherFrame.width);
  var y1 = Math.min(frame.y, otherFrame.y);
  var y2 = Math.max(frame.y + frame.height, otherFrame.y + otherFrame.height);
  return make(x1, y1, x2 - x1, y2 - y1);
}

/**
 * Determine if 2 frames intersect each other
 *
 * @param {Frame} frame
 * @param {Frame} otherFrame
 * @return {Boolean}
 */
function intersects (frame, otherFrame) {
  return !(otherFrame.x > frame.x + frame.width ||
           otherFrame.x + otherFrame.width < frame.x ||
           otherFrame.y > frame.y + frame.height ||
           otherFrame.y + otherFrame.height < frame.y);
}

module.exports = {
  make: make,
  zero: zero,
  clone: clone,
  inset: inset,
  intersection: intersection,
  intersects: intersects,
  union: union
};

