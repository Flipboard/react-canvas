'use strict';

var createComponent = require('./createComponent');
var LayerMixin = require('./LayerMixin');


/**
 * Create a new component 
 *
 * @param {{layerType: String, applyCustomProps: ?Function}} specs component specs
 * @return {Function} Generated ReactCanvas component class
 */
function createCanvasComponent(specs) {
  if (!specs.layerType) {
    throw new Error('createCanvasComponent(...): specification should contains an unique `layerType` property');
  }
  
  return createComponent(specs.displayName || 'CanvasComponent', LayerMixin, {
    applyCustomProps: specs.applyCustomProps,
    
    mountComponent: function (rootID, transaction, context) {
      var props = this._currentElement.props;
      var layer = this.node;
      layer.type = specs.layerType;
      var emptyProps = {};
      this.applyLayerProps(emptyProps, props);
      this.applyCustomProps && this.applyCustomProps(emptyProps, props);
      return layer;
    },

    receiveComponent: function (nextComponent, transaction, context) {
      var prevProps = this._currentElement.props;
      var props = nextComponent.props;
      this.applyLayerProps(prevProps, props);
      this.applyCustomProps && this.applyCustomProps(prevProps, props);
      this._currentElement = nextComponent;
      this.node.invalidateLayout();
    }
  });
}


module.exports = createCanvasComponent;
