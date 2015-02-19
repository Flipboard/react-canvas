'use strict';

var React = require('react');
var ReactMount = require('react/lib/ReactMount');
var ReactCanvas = require('react-canvas');
var SurfaceMixin = require('../../lib/SurfaceMixin');

var Group = ReactCanvas.Group;
var canvas = document.getElementById('canvas');
var ctx = canvas.getContext('2d');

function getDOMNode () {
  return canvas;
}

var EjectaSurface = React.createClass({

  mixins: [SurfaceMixin],

  componentWillMount: function () {
    // Scale the drawing area to match DPI.
    var width = this.props.width * this.props.scale;
    var height = this.props.height * this.props.scale;

    canvas.width = width;
    canvas.height = height;
    canvas.style.width = this.props.width + 'px';
    canvas.style.height = this.props.height + 'px';

    // Stub React component to always return a reference to the global canvas
    this.getDOMNode = getDOMNode;
    this.refs = {
      canvas: {
        getDOMNode: getDOMNode
      }
    };
  },

  componentDidMount: function () {
    canvas.addEventListener('touchstart', this.handleTouchStart, true);
    canvas.addEventListener('touchmove', this.handleTouchMove, true);
    canvas.addEventListener('touchend', this.handleTouchEnd, true);
    canvas.addEventListener('touchcancel', this.handleTouchEnd, true);
  },

  componentWillUnmount: function () {
    canvas.removeEventListener('touchstart', this.handleTouchStart, true);
    canvas.removeEventListener('touchmove', this.handleTouchMove, true);
    canvas.removeEventListener('touchend', this.handleTouchEnd, true);
    canvas.removeEventListener('touchcancel', this.handleTouchEnd, true);
  },

  render: function () {
    var style = {
      top: this.props.top,
      left: this.props.left,
      width: this.props.width,
      height: this.props.height
    };

    return (
      <Group style={style}>
        {this.props.children}
      </Group>
    );
  }

});

module.exports = EjectaSurface;
