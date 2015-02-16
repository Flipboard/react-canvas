'use strict';

var React = require('react');
var assign = require('react/lib/Object.assign');
var createComponent = require('./createComponent');
var LayerMixin = require('./LayerMixin');
var Layer = require('./Layer');
var Group = require('./Group');
var ImageCache = require('./ImageCache');
var Easing = require('./Easing');
var clamp = require('./clamp');

var FADE_DURATION = 200;

var RawImage = createComponent('Image', LayerMixin, {

  applyImageProps: function (prevProps, props) {
    var layer = this.node;

    layer.type = 'image';
    layer.imageUrl = props.src;
  },

  mountComponent: function (rootID, transaction, context) {
    var props = this._currentElement.props;
    var layer = this.node;
    this.applyLayerProps({}, props);
    this.applyImageProps({}, props);
    return layer;
  },

  receiveComponent: function (nextComponent, transaction, context) {
    var prevProps = this._currentElement.props;
    var props = nextComponent.props;
    this.applyLayerProps(prevProps, props);
    this._currentElement = nextComponent;
    this.node.invalidateLayout();
  },

});

var Image = React.createClass({

  propTypes: {
    src: React.PropTypes.string.isRequired,
    style: React.PropTypes.object,
    useBackingStore: React.PropTypes.bool,
    fadeIn: React.PropTypes.bool,
    fadeInDuration: React.PropTypes.number
  },

  getInitialState: function () {
    var loaded = ImageCache.get(this.props.src).isLoaded();
    return {
      loaded: loaded,
      imageAlpha: loaded ? 1 : 0
    };
  },

  componentDidMount: function () {
    ImageCache.get(this.props.src).on('load', this.handleImageLoad);
  },

  componentWillUnmount: function () {
    if (this._pendingAnimationFrame) {
      cancelAnimationFrame(this._pendingAnimationFrame);
    }
    ImageCache.get(this.props.src).removeListener('load', this.handleImageLoad);
  },

  componentDidUpdate: function (prevProps, prevState) {
    if (this.refs.image) {
      this.refs.image.invalidateLayout();
    }
  },

  render: function () {
    var rawImage;
    var imageStyle = assign({}, this.props.style);
    var style = assign({}, this.props.style);
    var backgroundStyle = assign({}, this.props.style);
    var useBackingStore = this.state.loaded ? this.props.useBackingStore : false;

    // Hide the image until loaded.
    imageStyle.alpha = this.state.imageAlpha;

    // Hide opaque background if image loaded so that images with transparent
    // do not render on top of solid color.
    style.backgroundColor = imageStyle.backgroundColor = null;
    backgroundStyle.alpha = clamp(1 - this.state.imageAlpha, 0, 1);

    return (
      React.createElement(Group, {ref: 'main', style: style},
        React.createElement(Layer, {ref: 'background', style: backgroundStyle}),
        React.createElement(RawImage, {ref: 'image', src: this.props.src, style: imageStyle, useBackingStore: useBackingStore})
      )
    );
  },

  handleImageLoad: function () {
    var imageAlpha = 1;
    if (this.props.fadeIn) {
      imageAlpha = 0;
      this._animationStartTime = Date.now();
      this._pendingAnimationFrame = requestAnimationFrame(this.stepThroughAnimation);
    }
    this.setState({ loaded: true, imageAlpha: imageAlpha });
  },

  stepThroughAnimation: function () {
    var fadeInDuration = this.props.fadeInDuration || FADE_DURATION;
    var alpha = Easing.easeInCubic((Date.now() - this._animationStartTime) / fadeInDuration);
    alpha = clamp(alpha, 0, 1);
    this.setState({ imageAlpha: alpha });
    if (alpha < 1) {
      this._pendingAnimationFrame = requestAnimationFrame(this.stepThroughAnimation);
    }
  }

});

module.exports = Image;
