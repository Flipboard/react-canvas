'use strict';

var createComponent = require('./createComponent');
var LayerMixin = require('./LayerMixin');

var Point = createComponent('Point', LayerMixin, {

  applyPointProps: function (prevProps, props) {
    var style = (props && props.style) ? props.style : {};
    var layer = this.node;

    layer.type        = 'point';
    layer.frame       = props.frame;
    layer.radius      = props.radius;
    layer.fillStyle   = style.fillStyle;
    layer.strokeStyle = style.strokeStyle;
  },

  mountComponent: function (rootID, transaction, context) {
    var props = this._currentElement.props;
    var layer = this.node;
    this.applyLayerProps({}, props);
    this.applyPointProps({}, props);
    return layer;
  },

  receiveComponent: function (nextComponent, transaction, context) {
    var props = nextComponent.props;
    var prevProps = this._currentElement.props;
    this.applyLayerProps(prevProps, props);
    this.applyPointProps(prevProps, props);
    this._currentElement = nextComponent;
    this.node.invalidateLayout();
  }

});

module.exports = Point;