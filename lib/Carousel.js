'use strict';

var React = require('react');
var assign = require('react/lib/Object.assign');
var Scroller = require('scroller');
var Group = require('./Group');
var clamp = require('./clamp');

var Carousel = React.createClass({

  propTypes: {
    style: React.PropTypes.object,
    numberOfItemsGetter: React.PropTypes.func.isRequired,
    itemWidthGetter: React.PropTypes.func.isRequired,
    itemGetter: React.PropTypes.func.isRequired,
    snapping: React.PropTypes.bool,
    scrollingDeceleration: React.PropTypes.number,
    scrollingPenetrationAcceleration: React.PropTypes.number,
    onScroll: React.PropTypes.func
  },

  getDefaultProps: function () {
    return {
      style: { left: 0, top: 0, width: 0, height: 0 },
      snapping: false,
      scrollingDeceleration: 0.95,
      scrollingPenetrationAcceleration: 0.08
    };
  },

  getInitialState: function () {
    return {
      scrollLeft: 0
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
        style: this.props.style,
        onTouchStart: this.handleTouchStart,
        onTouchMove: this.handleTouchMove,
        onTouchEnd: this.handleTouchEnd,
        onTouchCancel: this.handleTouchEnd},
        items
      )
    );
  },

  renderItem: function (itemIndex) {
    var item = this.props.itemGetter(itemIndex, this.state.scrollLeft);
    var itemWidth = this.props.itemWidthGetter();
    var style = {
      top: 0,
      left: 0,
      width: itemWidth,
      height: this.props.style.height,
      translateX: (itemIndex * itemWidth) - this.state.scrollLeft,
      zIndex: itemIndex
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
      if (this.props.snapping) {
        this.updateScrollingDeceleration();
      }
    }
  },

  handleScroll: function (left, top) {
    this.setState({ scrollLeft: left });
    if (this.props.onScroll) {
      this.props.onScroll(left);
    }
  },

  // Scrolling
  // =========

  createScroller: function () {
    var options = {
      scrollingX: true,
      scrollingY: false,
      decelerationRate: this.props.scrollingDeceleration,
      penetrationAcceleration: this.props.scrollingPenetrationAcceleration,
    };
    this.scroller = new Scroller(this.handleScroll, options);
  },

  updateScrollingDimensions: function () {
    var width = this.props.style.width;
    var height = this.props.style.height;
    var scrollWidth = this.props.numberOfItemsGetter() * this.props.itemWidthGetter();
    var scrollHeight = height;
    this.scroller.setDimensions(width, height, scrollWidth, scrollHeight);
  },

  getVisibleItemIndexes: function () {
    var itemIndexes = [];
    var itemWidth = this.props.itemWidthGetter();
    var itemCount = this.props.numberOfItemsGetter();
    var scrollLeft = this.state.scrollLeft;
    var itemScrollLeft = 0;

    for (var index=0; index < itemCount; index++) {
      itemScrollLeft = (index * itemWidth) - scrollLeft;

      // Item is completely off-screen bottom
      if (itemScrollLeft >= this.props.style.width) {
        continue;
      }

      // Item is completely off-screen top
      if (itemScrollLeft <= -this.props.style.width) {
        continue;
      }

      // Part of item is on-screen.
      itemIndexes.push(index);
    }

    return itemIndexes;
  },

  updateScrollingDeceleration: function () {
    var currVelocity = this.scroller.__decelerationVelocityX;
    var currScrollLeft = this.state.scrollLeft;
    var targetScrollLeft = 0;
    var estimatedEndScrollLeft = currScrollLeft;

    while (Math.abs(currVelocity).toFixed(6) > 0) {
      estimatedEndScrollLeft += currVelocity;
      currVelocity *= this.props.scrollingDeceleration;
    }

    // Find the page whose estimated end scrollTop is closest to 0.
    var closestZeroDelta = Infinity;
    var pageWidth = this.props.itemWidthGetter();
    var pageCount = this.props.numberOfItemsGetter();
    var pageScrollLeft;

    for (var pageIndex=0, len=pageCount; pageIndex < len; pageIndex++) {
      pageScrollLeft = (pageWidth * pageIndex) - estimatedEndScrollLeft;
      if (Math.abs(pageScrollLeft) < closestZeroDelta) {
        closestZeroDelta = Math.abs(pageScrollLeft);
        targetScrollLeft = pageWidth * pageIndex;
      }
    }

    this.scroller.__minDecelerationScrollLeft = targetScrollLeft;
    this.scroller.__maxDecelerationScrollLeft = targetScrollLeft;
  }

});

module.exports = Carousel;
