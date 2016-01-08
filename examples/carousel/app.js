/** @jsx React.DOM */

'use strict';

var React = require('react');
var ReactCanvas = require('react-canvas');
var Page = require('./components/Page');
var articles = require('../common/data');

var Surface = ReactCanvas.Surface;
var Carousel = ReactCanvas.Carousel;

var App = React.createClass({

  render: function () {
    var size = this.getSize();
    return (
      <Surface top={0} left={0} width={size.width} height={size.height}>
        <Carousel
          style={this.getListViewStyle()}
          snapping={true}
          scrollingDeceleration={0.92}
          scrollingPenetrationAcceleration={0.13}
          numberOfItemsGetter={this.getNumberOfPages}
          itemWidthGetter={this.getPageWidth}
          itemGetter={this.renderPage} />
      </Surface>
    );
  },

  renderPage: function (pageIndex, scrollLeft) {
    var size = this.getSize();
    var article = articles[pageIndex % articles.length];
    var pageScrollLeft = pageIndex * this.getPageWidth() - scrollLeft;
    return (
      <Page
        width={size.width}
        height={size.height}
        article={article}
        pageIndex={pageIndex}
        scrollLeft={pageScrollLeft} />
    );
  },

  getSize: function () {
    return document.getElementById('main').getBoundingClientRect();
  },

  // ListView
  // ========

  getListViewStyle: function () {
    var size = this.getSize();
    return {
      top: 0,
      left: 0,
      width: size.width,
      height: size.height
    };
  },

  getNumberOfPages: function () {
    return 1000;
  },

  getPageWidth: function () {
    return this.getSize().width;
  }

});

React.render(<App />, document.getElementById('main'));
