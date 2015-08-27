'use strict';

var React = require('react');
var assign = require('react/lib/Object.assign');
var Scroller = require('scroller');
var Group = require('./Group');
var clamp = require('./clamp');

var GridView = React.createClass({

  propTypes: {
    style: React.PropTypes.object,
    numberOfItemsGetter: React.PropTypes.func.isRequired,
    itemHeightGetter: React.PropTypes.func.isRequired,
    itemWidthGetter: React.PropTypes.func.isRequired,
    itemGetter: React.PropTypes.func.isRequired,
    numberOfColumnsGetter: React.PropTypes.func.isRequired,
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
      scrollTop: 0,
      scrollLeft: 0,
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
    var scrollTop = this.state.scrollTop;
    var scrollLeft = this.state.scrollLeft;
    var item = this.props.itemGetter(itemIndex, scrollTop, scrollLeft);
    var itemHeight = this.props.itemHeightGetter();
    var itemWidth = this.props.itemWidthGetter();
    var columnCount = this.props.numberOfColumnsGetter();
    var row = Math.floor(itemIndex / columnCount);
    var column = itemIndex % columnCount;
    var style = {
      top: 0,
      left: 0,
      width: itemWidth,
      height: itemHeight,
      translateY: (row * itemHeight) - scrollTop,
      translateX: (column * itemWidth) - scrollLeft,
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
      this.scroller.doTouchStart(e.touches, e.timeStamp || Date.now());
    }
  },

  handleTouchMove: function (e) {
    if (this.scroller) {
      e.preventDefault();
      this.scroller.doTouchMove(e.touches, e.timeStamp || Date.now(), e.scale);
    }
  },

  handleTouchEnd: function (e) {
    if (this.scroller) {
      this.scroller.doTouchEnd(e.timeStamp || Date.now());
      if (this.props.snapping) {
        this.updateScrollingDeceleration();
      }
    }
  },

  handleScroll: function (left, top) {
    this.setState({ scrollTop: top, scrollLeft: left });
    if (this.props.onScroll) {
      this.props.onScroll(top, left);
    }
  },

  // Scrolling
  // =========

  createScroller: function () {
    var options = {
      scrollingX: true,
      scrollingY: true,
      decelerationRate: this.props.scrollingDeceleration,
      penetrationAcceleration: this.props.scrollingPenetrationAcceleration,
    };
    this.scroller = new Scroller(this.handleScroll, options);
  },

  updateScrollingDimensions: function () {
    var width = this.props.style.width;
    var height = this.props.style.height;
    var numberOfItems = this.props.numberOfItemsGetter();
    var numberOfColumns = this.props.numberOfColumnsGetter();
    var rows = Math.floor(numberOfItems / numberOfColumns);
    var scrollWidth = numberOfColumns * this.props.itemWidthGetter();
    var scrollHeight = rows * this.props.itemHeightGetter();
    this.scroller.setDimensions(width, height, scrollWidth, scrollHeight);
  },

  getVisibleItemIndexes: function () {
    var itemIndexes = [];
    var itemHeight = this.props.itemHeightGetter();
    var itemWidth = this.props.itemWidthGetter();
    var itemCount = this.props.numberOfItemsGetter();
    var columnCount = this.props.numberOfColumnsGetter();
    var scrollTop = this.state.scrollTop;
    var scrollLeft = this.state.scrollLeft;
    var itemScrollTop = 0;
    var itemScrollLeft = 0;

    for (var index=0; index < itemCount; index++) {
      var row = Math.floor(index / columnCount);
      var column = index % columnCount;

      itemScrollTop = (row * itemHeight) - scrollTop;
      itemScrollLeft = (column * itemWidth) - scrollLeft;

      // Item is completely off-screen bottom
      if (itemScrollTop >= this.props.style.height) {
        continue;
      }

      // Item is completely off-screen top
      if (itemScrollTop <= -this.props.style.height) {
        continue;
      }

      // Item is completely off-screen right
      if (itemScrollLeft >= this.props.style.width) {
        continue;
      }

      // Item is completely off-screen left
      if (itemScrollLeft <= -this.props.style.width) {
        continue;
      }

      // Part of item is on-screen.
      itemIndexes.push(index);
    }

    return itemIndexes;
  },

  updateScrollingDeceleration: function () {
    var currVelocity = this.scroller.__decelerationVelocityY;
    var currScrollTop = this.state.scrollTop;
    var targetScrollTop = 0;
    var estimatedEndScrollTop = currScrollTop;

    while (Math.abs(currVelocity).toFixed(6) > 0) {
      estimatedEndScrollTop += currVelocity;
      currVelocity *= this.props.scrollingDeceleration;
    }

    // Find the page whose estimated end scrollTop is closest to 0.
    var closestZeroDelta = Infinity;
    var pageHeight = this.props.itemHeightGetter();
    var pageCount = this.props.numberOfItemsGetter();
    var pageScrollTop;

    for (var pageIndex=0, len=pageCount; pageIndex < len; pageIndex++) {
      pageScrollTop = (pageHeight * pageIndex) - estimatedEndScrollTop;
      if (Math.abs(pageScrollTop) < closestZeroDelta) {
        closestZeroDelta = Math.abs(pageScrollTop);
        targetScrollTop = pageHeight * pageIndex;
      }
    }

    this.scroller.__minDecelerationScrollTop = targetScrollTop;
    this.scroller.__maxDecelerationScrollTop = targetScrollTop;
  }

});

module.exports = GridView;
