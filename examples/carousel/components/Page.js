/** @jsx React.DOM */

'use strict';

var React = require('react');
var ReactCanvas = require('react-canvas');

var Group = ReactCanvas.Group;
var Image = ReactCanvas.Image;

var CONTENT_INSET = 14;
var IMAGE_LAYER_INDEX = 1;

var Page = React.createClass({

  propTypes: {
    width: React.PropTypes.number.isRequired,
    height: React.PropTypes.number.isRequired,
    article: React.PropTypes.object.isRequired,
    scrollLeft: React.PropTypes.number.isRequired
  },

  componentWillMount: function () {
    // Pre-compute headline/excerpt text dimensions.
    var article = this.props.article;
    var maxWidth = this.props.width - 2 * CONTENT_INSET;
  },

  render: function () {
    var groupStyle = this.getGroupStyle();
    var imageStyle = this.getImageStyle();

    return (
      <Group style={groupStyle}>
        <Image style={imageStyle} src={this.props.article.imageUrl} fadeIn={true} useBackingStore={true} />
      </Group>
    );
  },

  getGroupStyle: function () {
    return {
      top: 0,
      left: 0,
      width: this.props.width,
      height: this.props.height,
    };
  },

  getImageWidth: function () {
    return Math.round(this.props.width);
  },

  getImageStyle: function () {
    return {
      top: 0,
      left: 0,
      width: this.getImageWidth(),
      height: this.props.height,
      backgroundColor: '#eee',
      zIndex: IMAGE_LAYER_INDEX
    };
  },

});

module.exports = Page;
