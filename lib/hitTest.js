'use strict';

var FrameUtils = require('./FrameUtils');
var EventTypes = require('./EventTypes');

/**
 * RenderLayer hit testing
 *
 * @param {Event} e
 * @param {RenderLayer} rootLayer
 * @param {?HTMLElement} rootNode
 * @return {RenderLayer}
 */
function hitTest (e, rootLayer, rootNode) {
  var touch = e.touches ? e.touches[0] : e;
  var touchX = touch.pageX;
  var touchY = touch.pageY;
  var rootNodeBox;
  if (rootNode) {
    rootNodeBox = rootNode.getBoundingClientRect();
    touchX -= rootNodeBox.left;
    touchY -= rootNodeBox.top;
  }
  return getLayerAtPoint(rootLayer, e.type, FrameUtils.make(touchX, touchY, 1, 1));
}

/**
 * @private
 */
function sortByZIndexDescending (layer, otherLayer) {
  return (otherLayer.zIndex || 0) - (layer.zIndex || 0);
}

/**
 * @private
 */
function getHitHandle (type) {
  var hitHandle;
  for (var tryHandle in EventTypes) {
    if (EventTypes[tryHandle] === type) {
      hitHandle = tryHandle;
      break;
    }
  }
  return hitHandle;
}

/**
 * @private
 */
function getLayerAtPoint (root, type, point) {
  var layer = null;
  var hitHandle = getHitHandle(type);
  var sortedChildren;
  var hitFrame = root.frame;

  // Early bail for non-visible layers
  if (typeof root.alpha === 'number' && root.alpha < 0.01) {
    return null;
  }

  // Child-first search
  if (root.children) {
    sortedChildren = root.children.slice().reverse().sort(sortByZIndexDescending);
    for (var i=0, len=sortedChildren.length; i < len; i++) {
      layer = getLayerAtPoint(sortedChildren[i], type, point);
      if (layer) {
        break;
      }
    }
  }

  // Check for hit outsets
  if (root.hitOutsets) {
    hitFrame = FrameUtils.inset(FrameUtils.clone(hitFrame),
      -root.hitOutsets[0], -root.hitOutsets[1],
      -root.hitOutsets[2], -root.hitOutsets[3]
    );
  }

  // No child layer at the given point. Try the parent layer.
  if (!layer && root[hitHandle] && FrameUtils.intersects(hitFrame, point)) {
    layer = root;
  }

  return layer;
}

module.exports = hitTest;
module.exports.getHitHandle = getHitHandle;

