/** @jsx React.DOM */

'use strict';

var React = require('react');
var ReactCanvas = require('react-canvas');

var Group = ReactCanvas.Group;
var Image = ReactCanvas.Image;
var Text = ReactCanvas.Text;
var FontFace = ReactCanvas.FontFace;
var measureText = ReactCanvas.measureText;

var CONTENT_INSET = 14;
var TEXT_SCROLL_SPEED_MULTIPLIER = 0.6;
var TEXT_ALPHA_SPEED_OUT_MULTIPLIER = 1.25;
var TEXT_ALPHA_SPEED_IN_MULTIPLIER = 2.6;
var IMAGE_LAYER_INDEX = 2;
var TEXT_LAYER_INDEX = 1;

var Page = React.createClass({

  propTypes: {
    width: React.PropTypes.number.isRequired,
    height: React.PropTypes.number.isRequired,
    article: React.PropTypes.object.isRequired,
    scrollTop: React.PropTypes.number.isRequired
  },

  componentWillMount: function () {
    // Pre-compute headline/excerpt text dimensions.
    var article = this.props.article;
    var maxWidth = this.props.width - 2 * CONTENT_INSET;
    var titleStyle = this.getTitleStyle();
    var excerptStyle = this.getExcerptStyle();
    this.titleMetrics = measureText(article.title, maxWidth, titleStyle.fontFace, titleStyle.fontSize, titleStyle.lineHeight);
    this.excerptMetrics = measureText(article.excerpt, maxWidth, excerptStyle.fontFace, excerptStyle.fontSize, excerptStyle.lineHeight);
  },

  render: function () {
    var groupStyle = this.getGroupStyle();
    var imageStyle = this.getImageStyle();
    var titleStyle = this.getTitleStyle();
    var excerptStyle = this.getExcerptStyle();

    // Layout title and excerpt below image.
    titleStyle.height = this.titleMetrics.height;
    excerptStyle.top = titleStyle.top + titleStyle.height + CONTENT_INSET;
    excerptStyle.height = this.props.height - excerptStyle.top - CONTENT_INSET;

    return (
      <Group style={groupStyle}>
        <Image style={imageStyle} src={this.props.article.imageUrl} fadeIn={true} useBackingStore={true} />
        <Group style={this.getTextGroupStyle()} useBackingStore={true}>
          <Text style={titleStyle}>{this.props.article.title}</Text>
          <Text style={excerptStyle}>{this.props.article.excerpt}</Text>
        </Group>
      </Group>
    );
  },

  // Styles
  // ======

  getGroupStyle: function () {
    return {
      top: 0,
      left: 0,
      width: this.props.width,
      height: this.props.height,
    };
  },

  getImageHeight: function () {
    return Math.round(this.props.height * 0.5);
  },

  getImageStyle: function () {
    return {
      top: 0,
      left: 0,
      width: this.props.width,
      height: this.getImageHeight(),
      backgroundColor: '#eee',
      zIndex: IMAGE_LAYER_INDEX
    };
  },

  getTitleStyle: function () {
    return {
      top: this.getImageHeight() + CONTENT_INSET,
      left: CONTENT_INSET,
      width: this.props.width - 2 * CONTENT_INSET,
      fontSize: 22,
      lineHeight: 30,
      fontFace: FontFace('Avenir Next Condensed, Helvetica, sans-serif', null, {weight: 500})
    };
  },

  getExcerptStyle: function () {
    return {
      left: CONTENT_INSET,
      width: this.props.width - 2 * CONTENT_INSET,
      fontFace: FontFace('Georgia, serif'),
      fontSize: 15,
      lineHeight: 23
    };
  },

  getTextGroupStyle: function () {
    var imageHeight = this.getImageHeight();
    var translateY = 0;
    var alphaMultiplier = (this.props.scrollTop <= 0) ? -TEXT_ALPHA_SPEED_OUT_MULTIPLIER : TEXT_ALPHA_SPEED_IN_MULTIPLIER;
    var alpha = 1 - (this.props.scrollTop / this.props.height) * alphaMultiplier;
    alpha = Math.min(Math.max(alpha, 0), 1);
    translateY = -this.props.scrollTop * TEXT_SCROLL_SPEED_MULTIPLIER;

    return {
      width: this.props.width,
      height: this.props.height - imageHeight,
      top: imageHeight,
      left: 0,
      alpha: alpha,
      translateY: translateY,
      zIndex: TEXT_LAYER_INDEX
    };
  }

});

module.exports = Page;
