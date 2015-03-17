'use strict';

var ImageCache = require('./ImageCache');
var FontUtils = require('./FontUtils');
var FontFace = require('./FontFace');
var FrameUtils = require('./FrameUtils');
var CanvasUtils = require('./CanvasUtils');
var Canvas = require('./Canvas');

// Global backing store <canvas> cache
var _backingStores = [];

/**
 * Maintain a cache of backing <canvas> for RenderLayer's which are accessible
 * through the RenderLayer's `backingStoreId` property.
 *
 * @param {String} id The unique `backingStoreId` for a RenderLayer
 * @return {HTMLCanvasElement}
 */
function getBackingStore (id) {
  for (var i=0, len=_backingStores.length; i < len; i++) {
    if (_backingStores[i].id === id) {
      return _backingStores[i].canvas;
    }
  }
  return null;
}

/**
 * Purge a layer's backing store from the cache.
 *
 * @param {String} id The layer's backingStoreId
 */
function invalidateBackingStore (id) {
  for (var i=0, len=_backingStores.length; i < len; i++) {
    if (_backingStores[i].id === id) {
      _backingStores.splice(i, 1);
      break;
    }
  }
}

/**
 * Purge the entire backing store cache.
 */
function invalidateAllBackingStores () {
  _backingStores = [];
}

/**
 * Find the nearest backing store ancestor for a given layer.
 *
 * @param {RenderLayer} layer
 */
function getBackingStoreAncestor (layer) {
  while (layer) {
    if (layer.backingStoreId) {
      return layer;
    }
    layer = layer.parentLayer;
  }
  return null;
}

/**
 * Check if a layer is using a given image URL.
 *
 * @param {RenderLayer} layer
 * @param {String} imageUrl
 * @return {Boolean}
 */
function layerContainsImage (layer, imageUrl) {
  // Check the layer itself.
  if (layer.type === 'image' && layer.imageUrl === imageUrl) {
    return layer;
  }

  // Check the layer's children.
  if (layer.children) {
    for (var i=0, len=layer.children.length; i < len; i++) {
      if (layerContainsImage(layer.children[i], imageUrl)) {
        return layer.children[i];
      }
    }
  }

  return false;
}

/**
 * Check if a layer is using a given FontFace.
 *
 * @param {RenderLayer} layer
 * @param {FontFace} fontFace
 * @return {Boolean}
 */
function layerContainsFontFace (layer, fontFace) {
  // Check the layer itself.
  if (layer.type === 'text' && layer.fontFace && layer.fontFace.id === fontFace.id) {
    return layer;
  }

  // Check the layer's children.
  if (layer.children) {
    for (var i=0, len=layer.children.length; i < len; i++) {
      if (layerContainsFontFace(layer.children[i], fontFace)) {
        return layer.children[i];
      }
    }
  }

  return false;
}

/**
 * Invalidates the backing stores for layers which contain an image layer
 * associated with the given imageUrl.
 *
 * @param {String} imageUrl
 */
function handleImageLoad (imageUrl) {
  _backingStores.forEach(function (backingStore) {
    if (layerContainsImage(backingStore.layer, imageUrl)) {
      invalidateBackingStore(backingStore.id);
    }
  });
}

/**
 * Invalidates the backing stores for layers which contain a text layer
 * associated with the given font face.
 *
 * @param {FontFace} fontFace
 */
function handleFontLoad (fontFace) {
  _backingStores.forEach(function (backingStore) {
    if (layerContainsFontFace(backingStore.layer, fontFace)) {
      invalidateBackingStore(backingStore.id);
    }
  });
}

/**
 * Draw a RenderLayer instance to a <canvas> context.
 *
 * @param {CanvasRenderingContext2d} ctx
 * @param {RenderLayer} layer
 */
function drawRenderLayer (ctx, layer) {
  var customDrawFunc;

  // Performance: avoid drawing hidden layers.
  if (typeof layer.alpha === 'number' && layer.alpha <= 0) {
    return;
  }

  switch (layer.type) {
    case 'image':
      customDrawFunc = drawImageRenderLayer;
      break;

    case 'text':
      customDrawFunc = drawTextRenderLayer;
      break;

    case 'gradient':
      customDrawFunc = drawGradientRenderLayer;
      break;
  }

  // Establish drawing context for certain properties:
  // - alpha
  // - translate
  var saveContext = (layer.alpha !== null && layer.alpha < 1) ||
                    (layer.translateX || layer.translateY);

  if (saveContext) {
    ctx.save();

    // Alpha:
    if (layer.alpha !== null && layer.alpha < 1) {
      ctx.globalAlpha = layer.alpha;
    }

    // Translation:
    if (layer.translateX || layer.translateY) {
      ctx.translate(layer.translateX || 0, layer.translateY || 0);
    }
  }

  // If the layer is bitmap-cacheable, draw in a pooled off-screen canvas.
  // We disable backing stores on pad since we flip there.
  if (layer.backingStoreId) {
    drawCacheableRenderLayer(ctx, layer, customDrawFunc);
  } else {
    // Draw default properties, such as background color.
    ctx.save();
    drawBaseRenderLayer(ctx, layer);

    // Draw custom properties if needed.
    customDrawFunc && customDrawFunc(ctx, layer);
    ctx.restore();

    // Draw child layers, sorted by their z-index.
    if (layer.children) {
      layer.children.slice().sort(sortByZIndexAscending).forEach(function (childLayer) {
        drawRenderLayer(ctx, childLayer);
      });
    }
  }

  // Pop the context state if we established a new drawing context.
  if (saveContext) {
    ctx.restore();
  }
}

/**
 * Draw base layer properties into a rendering context.
 * NOTE: The caller is responsible for calling save() and restore() as needed.
 *
 * @param {CanvasRenderingContext2d} ctx
 * @param {RenderLayer} layer
 */
function drawBaseRenderLayer (ctx, layer) {
  var frame = layer.frame;

  // Border radius:
  if (layer.borderRadius) {
    ctx.beginPath();
    ctx.moveTo(frame.x + layer.borderRadius, frame.y);
    ctx.arcTo(frame.x + frame.width, frame.y, frame.x + frame.width, frame.y + frame.height, layer.borderRadius);
    ctx.arcTo(frame.x + frame.width, frame.y + frame.height, frame.x, frame.y + frame.height, layer.borderRadius);
    ctx.arcTo(frame.x, frame.y + frame.height, frame.x, frame.y, layer.borderRadius);
    ctx.arcTo(frame.x, frame.y, frame.x + frame.width, frame.y, layer.borderRadius);
    ctx.closePath();

    // Create a clipping path when drawing an image or using border radius.
    if (layer.type === 'image') {
      ctx.clip();
    }

    // Border with border radius:
    if (layer.borderColor) {
      ctx.lineWidth = layer.borderWidth || 1;
      ctx.strokeStyle = layer.borderColor;
      ctx.stroke();
    }
  }

  // Border color (no border radius):
  if (layer.borderColor && !layer.borderRadius) {
    ctx.lineWidth = layer.borderWidth || 1;
    ctx.strokeStyle = layer.borderColor;
    ctx.strokeRect(frame.x, frame.y, frame.width, frame.height);
  }

  // Background color:
  if (layer.backgroundColor) {
    ctx.fillStyle = layer.backgroundColor;
    if (layer.borderRadius) {
      // Fill the current path when there is a borderRadius set.
      ctx.fill();
    } else {
      ctx.fillRect(frame.x, frame.y, frame.width, frame.height);
    }
  }
}

/**
 * Draw a bitmap-cacheable layer into a pooled <canvas>. The result will be
 * drawn into the given context. This will populate the layer backing store
 * cache with the result.
 *
 * @param {CanvasRenderingContext2d} ctx
 * @param {RenderLayer} layer
 * @param {Function} customDrawFunc
 * @private
 */
function drawCacheableRenderLayer (ctx, layer, customDrawFunc) {
  // See if there is a pre-drawn canvas in the pool.
  var backingStore = getBackingStore(layer.backingStoreId);
  var backingStoreScale = layer.scale || window.devicePixelRatio;
  var frameOffsetY = layer.frame.y;
  var frameOffsetX = layer.frame.x;
  var backingContext;

  if (!backingStore) {
    if (_backingStores.length >= Canvas.poolSize) {
      // Re-use the oldest backing store once we reach the pooling limit.
      backingStore = _backingStores[0].canvas;
      Canvas.call(backingStore, layer.frame.width, layer.frame.height, backingStoreScale);

      // Move the re-use canvas to the front of the queue.
      _backingStores[0].id = layer.backingStoreId;
      _backingStores[0].canvas = backingStore;
      _backingStores.push(_backingStores.shift());
    } else {
      // Create a new backing store, we haven't yet reached the pooling limit
      backingStore = new Canvas(layer.frame.width, layer.frame.height, backingStoreScale);
      _backingStores.push({
        id: layer.backingStoreId,
        layer: layer,
        canvas: backingStore
      });
    }

    // Draw into the backing <canvas> at (0, 0) - we will later use the
    // <canvas> to draw the layer as an image at the proper coordinates.
    backingContext = backingStore.getContext('2d');
    layer.translate(-frameOffsetX, -frameOffsetY);

    // Draw default properties, such as background color.
    backingContext.save();
    drawBaseRenderLayer(backingContext, layer);

    // Custom drawing operations
    customDrawFunc && customDrawFunc(backingContext, layer);
    backingContext.restore();

    // Draw child layers, sorted by their z-index.
    if (layer.children) {
      layer.children.slice().sort(sortByZIndexAscending).forEach(function (childLayer) {
        drawRenderLayer(backingContext, childLayer);
      });
    }

    // Restore layer's original frame.
    layer.translate(frameOffsetX, frameOffsetY);
  }

  // We have the pre-rendered canvas ready, draw it into the destination canvas.
  if (layer.clipRect) {
    // Fill the clipping rect in the destination canvas.
    var sx = (layer.clipRect.x - layer.frame.x) * backingStoreScale;
    var sy = (layer.clipRect.y - layer.frame.y) * backingStoreScale;
    var sw = layer.clipRect.width * backingStoreScale;
    var sh = layer.clipRect.height * backingStoreScale;
    var dx = layer.clipRect.x;
    var dy = layer.clipRect.y;
    var dw = layer.clipRect.width;
    var dh = layer.clipRect.height;

    // No-op for zero size rects. iOS / Safari will throw an exception.
    if (sw > 0 && sh > 0) {
      ctx.drawImage(backingStore.getRawCanvas(), sx, sy, sw, sh, dx, dy, dw, dh);
    }
  } else {
    // Fill the entire canvas
    ctx.drawImage(backingStore.getRawCanvas(), layer.frame.x, layer.frame.y, layer.frame.width, layer.frame.height);
  }
}

/**
 * @private
 */
function sortByZIndexAscending (layerA, layerB) {
  return (layerA.zIndex || 0) - (layerB.zIndex || 0);
}

/**
 * @private
 */
function drawImageRenderLayer (ctx, layer) {
  if (!layer.imageUrl) {
    return;
  }

  // Don't draw until loaded
  var image = ImageCache.get(layer.imageUrl);
  if (!image.isLoaded()) {
    return;
  }

  CanvasUtils.drawImage(ctx, image, layer.frame.x, layer.frame.y, layer.frame.width, layer.frame.height, {rotate: layer.rotate});
}

/**
 * @private
 */
function drawTextRenderLayer (ctx, layer) {
  // Fallback to standard font.
  var fontFace = layer.fontFace || FontFace.Default();

  // Don't draw text until loaded
  if (!FontUtils.isFontLoaded(fontFace)) {
    return;
  }

  CanvasUtils.drawText(ctx, layer.text, layer.frame.x, layer.frame.y, layer.frame.width, layer.frame.height, fontFace, {
    fontSize: layer.fontSize,
    lineHeight: layer.lineHeight,
    textAlign: layer.textAlign,
    color: layer.color
  });
}

/**
 * @private
 */
function drawGradientRenderLayer (ctx, layer) {
  // Default to linear gradient from top to bottom.
  var x1 = layer.x1 || layer.frame.x;
  var y1 = layer.y1 || layer.frame.y;
  var x2 = layer.x2 || layer.frame.x;
  var y2 = layer.y2 || layer.frame.y + layer.frame.height;
  CanvasUtils.drawGradient(ctx, x1, y1, x2, y2, layer.colorStops, layer.frame.x, layer.frame.y, layer.frame.width, layer.frame.height);
}

module.exports = {
  drawRenderLayer: drawRenderLayer,
  invalidateBackingStore: invalidateBackingStore,
  invalidateAllBackingStores: invalidateAllBackingStores,
  handleImageLoad: handleImageLoad,
  handleFontLoad: handleFontLoad,
  layerContainsImage: layerContainsImage,
  layerContainsFontFace: layerContainsFontFace
};
