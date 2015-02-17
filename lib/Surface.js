'use strict';

var React = require('react');
var ReactUpdates = require('react/lib/ReactUpdates');
var invariant = require('react/lib/invariant');
var ContainerMixin = require('./ContainerMixin');
var RenderLayer = require('./RenderLayer');
var FrameUtils = require('./FrameUtils');
var DrawingUtils = require('./DrawingUtils');
var hitTest = require('./hitTest');
var layoutNode = require('./layoutNode');

/**
 * Surface is a standard React component and acts as the main drawing canvas.
 * ReactCanvas components cannot be rendered outside a Surface.
 */

var Surface = React.createClass({

  mixins: [ContainerMixin],

  propTypes: {
    top: React.PropTypes.number.isRequired,
    left: React.PropTypes.number.isRequired,
    width: React.PropTypes.number.isRequired,
    height: React.PropTypes.number.isRequired,
    scale: React.PropTypes.number.isRequired,
    enableCSSLayout: React.PropTypes.bool
  },

  getDefaultProps: function () {
    return {
      scale: window.devicePixelRatio || 1
    };
  },

  componentDidMount: function () {
    // Prepare the <canvas> for drawing.
    this.scale();

    // ContainerMixin expects `this.node` to be set prior to mounting children.
    // `this.node` is injected into child components and represents the current
    // render tree.
    this.node = new RenderLayer();
    this.node.frame = FrameUtils.make(this.props.left, this.props.top, this.props.width, this.props.height);
    this.node.draw = this.batchedTick;

    // This is the integration point between custom canvas components and React
    var transaction = ReactUpdates.ReactReconcileTransaction.getPooled();
    transaction.perform(
      this.mountAndInjectChildrenAtRoot,
      this,
      this.props.children,
      transaction
    );
    ReactUpdates.ReactReconcileTransaction.release(transaction);

    // Execute initial draw on mount.
    this.node.draw();
  },

  componentWillUnmount: function () {
    // Implemented in ReactMultiChild.Mixin
    this.unmountChildren();
  },

  componentDidUpdate: function (prevProps, prevState) {
    // We have to manually apply child reconciliation since child are not
    // declared in render().
    var transaction = ReactUpdates.ReactReconcileTransaction.getPooled();
    transaction.perform(
      this.updateChildrenAtRoot,
      this,
      this.props.children,
      transaction
    );
    ReactUpdates.ReactReconcileTransaction.release(transaction);

    // Re-scale the <canvas> when changing size.
    if (prevProps.width !== this.props.width || prevProps.height !== this.props.height) {
      this.scale();
    }

    // Redraw updated render tree to <canvas>.
    if (this.node) {
      this.node.draw();
    }
  },

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
  },

  // Drawing
  // =======

  getContext: function () {
    ('production' !== process.env.NODE_ENV ? invariant(
      this.isMounted(),
      'Tried to access drawing context on an unmounted Surface.'
    ) : invariant(this.isMounted()));
    return this.refs.canvas.getDOMNode().getContext('2d');
  },

  scale: function () {
    this.getContext().scale(this.props.scale, this.props.scale);
  },

  batchedTick: function () {
    if (this._frameReady === false) {
      this._pendingTick = true;
      return;
    }
    this.tick();
  },

  tick: function () {
    // Block updates until next animation frame.
    this._frameReady = false;
    this.clear();
    this.draw();
    requestAnimationFrame(this.afterTick);
  },

  afterTick: function () {
    // Execute pending draw that may have been scheduled during previous frame
    this._frameReady = true;
    if (this._pendingTick) {
      this._pendingTick = false;
      this.batchedTick();
    }
  },

  clear: function () {
    this.getContext().clearRect(0, 0, this.props.width, this.props.height);
  },

  draw: function () {
    var layout;
    if (this.node) {
      if (this.props.enableCSSLayout) {
        layout = layoutNode(this.node);
      }
      DrawingUtils.drawRenderLayer(this.getContext(), this.node);
    }
  },

  // Events
  // ======

  hitTest: function (e) {
    var hitTarget = hitTest(e, this.node, this.getDOMNode());
    if (hitTarget) {
      hitTarget[hitTest.getHitHandle(e.type)](e);
    }
  },

  handleTouchStart: function (e) {
    var hitTarget = hitTest(e, this.node, this.getDOMNode());
    var touch;
    if (hitTarget) {
      // On touchstart: capture the current hit target for the given touch.
      this._touches = this._touches || {};
      for (var i=0, len=e.touches.length; i < len; i++) {
        touch = e.touches[i];
        this._touches[touch.identifier] = hitTarget;
      }
      hitTarget[hitTest.getHitHandle(e.type)](e);
    }
  },

  handleTouchMove: function (e) {
    this.hitTest(e);
  },

  handleTouchEnd: function (e) {
    // touchend events do not generate a pageX/pageY so we rely
    // on the currently captured touch targets.
    if (!this._touches) {
      return;
    }

    var hitTarget;
    var hitHandle = hitTest.getHitHandle(e.type);
    for (var i=0, len=e.changedTouches.length; i < len; i++) {
      hitTarget = this._touches[e.changedTouches[i].identifier];
      if (hitTarget && hitTarget[hitHandle]) {
        hitTarget[hitHandle](e);
      }
      delete this._touches[e.changedTouches[i].identifier];
    }
  },

  handleClick: function (e) {
    this.hitTest(e);
  }

});

module.exports = Surface;
