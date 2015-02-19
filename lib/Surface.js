'use strict';

var React = require('react');
var SurfaceMixin = require('./SurfaceMixin');

/**
 * Surface is a standard React component and acts as the main drawing canvas.
 * ReactCanvas components cannot be rendered outside a Surface.
 */

var Surface = React.createClass({

  mixins: [SurfaceMixin],

  render: function () {
    // Scale the drawing area to match DPI.
    var width = this.props.width * this.props.scale;
    var height = this.props.height * this.props.scale;
    var style = {
      width: this.props.width,
      height: this.props.height
    };

    return (
      React.createElement('canvas', {
        ref: 'canvas',
        width: width,
        height: height,
        style: style,
        onTouchStart: this.handleTouchStart,
        onTouchMove: this.handleTouchMove,
        onTouchEnd: this.handleTouchEnd,
        onTouchCancel: this.handleTouchEnd,
        onClick: this.handleClick})
    );
  }

});

module.exports = Surface;
