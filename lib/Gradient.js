'use strict';

var React = require('react');
var createComponent = require('./createComponent');
var LayerMixin = require('./LayerMixin');

var Gradient = createComponent('Gradient', LayerMixin, {

  applyGradientProps: function (prevProps, props) {
    var layer = this.node;
    layer.type = 'gradient';
    layer.colorStops = props.colorStops || [];
    this.applyLayerProps(prevProps, props);
  },

  mountComponent: function (
    transaction,
    nativeParent,
    nativeContainerInfo,
    context
  ) {
    var props = this._currentElement.props;
    var layer = this.node;
    this.applyGradientProps({}, props);
    return layer;
  },

  receiveComponent: function (nextComponent, transaction, context) {
    var prevProps = this._currentElement.props;
    var props = nextComponent.props;
    this.applyGradientProps({}, props);
    this._currentElement = nextComponent;
    this.node.invalidateLayout();
  },

});


module.exports = Gradient;
