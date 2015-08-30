'use strict';

var assign   = require('react/lib/Object.assign');
var clamp    = require('./clamp');
var Group    = require('./Group');
var React    = require('react');
var Scroller = require('scroller');

var ScrollView = React.createClass({

  propTypes: {
    style                            : React.PropTypes.object,
    itemHeights                      : React.PropTypes.array.isRequired,
    items                            : React.PropTypes.array.isRequired,
    scrollingDeceleration            : React.PropTypes.number,
    scrollingPenetrationAcceleration : React.PropTypes.number,
  },

  getDefaultProps: function () {
    return {
      style: { left: 0, top: 0, width: 0, height: 0 },
      scrollingDeceleration: 0.95,
      scrollingPenetrationAcceleration: 0.08
    };
  },

  getInitialState: function () {
    return {
      scrollTop: 0
    };
  },

  componentDidMount: function () {
    this.createScroller();
    this.updateScrollingDimensions();
  },

  render: function () {
    var items = this.getVisibleItemIndexes().map(this.renderItem);
    return (
      React.createElement(Group, {
        style         : this.props.style,
        onTouchStart  : this.handleTouchStart,
        onTouchMove   : this.handleTouchMove,
        onTouchEnd    : this.handleTouchEnd,
        onTouchCancel : this.handleTouchEnd},
        items
      )
    );
  },

  renderItem: function (itemIndex) {
    var item = this.props.items[itemIndex]
    var itemHeight = this.props.itemHeights[itemIndex]

    var itemTop = 0

    for (var i = 0; i < itemIndex; i++) {
      itemTop += itemHeight
    }

    var style = {
      top        : 0,
      left       : 0,
      width      : this.props.style.width,
      height     : itemHeight,
      translateY : itemTop - this.state.scrollTop,
      zIndex     : itemIndex
    };

    return (
      React.createElement(Group, {style: style, key: itemIndex},
        item
      )
    );
  },

  // Events
  // ======

  handleTouchStart: function (e) {
    if (this.scroller) {
      this.scroller.doTouchStart(e.touches, e.timeStamp);
    }
  },

  handleTouchMove: function (e) {
    if (this.scroller) {
      e.preventDefault();
      this.scroller.doTouchMove(e.touches, e.timeStamp, e.scale);
    }
  },

  handleTouchEnd: function (e) {
    if (this.scroller) {
      this.scroller.doTouchEnd(e.timeStamp);
    }
  },

  handleScroll: function (left, top) {
    this.setState({ scrollTop: top });
  },

  // Scrolling
  // =========

  createScroller: function () {
    var options = {
      scrollingX              : false,
      scrollingY              : true,
      decelerationRate        : this.props.scrollingDeceleration,
      penetrationAcceleration : this.props.scrollingPenetrationAcceleration,
    };
    this.scroller = new Scroller(this.handleScroll, options);
  },

  updateScrollingDimensions: function () {
    var width        = this.props.style.width;
    var height       = this.props.style.height;
    var scrollWidth  = width;
    var scrollHeight = this.props.itemHeights.reduce(function(prev, curr) {
        return prev + curr
    }, 0)
    this.scroller.setDimensions(width, height, scrollWidth, scrollHeight);
  },

  getVisibleItemIndexes: function () {
    var itemBottoms = [];

    var visibleIndexes = [];
    var scrollTop = this.state.scrollTop;

    for (var index = 0; index < this.props.numberOfItems; index++) {
      var itemTop    = itemBottoms[index - 1] || 0;
      var itemHeight = this.props.itemHeights[index]
      var itemBottom = itemTop + itemHeight;

      itemBottoms.push(itemBottom)

      if (itemTop - scrollTop < this.props.style.height &&
          itemBottom > scrollTop ) {
          
        visibleIndexes.push(index)
      }
    }

    return visibleIndexes;
  }

});

module.exports = ScrollView;
