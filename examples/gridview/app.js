'use strict';

var React = require('react');
var ReactCanvas = require('react-canvas');
var Item = require('./components/Item');
var articles = require('../common/data');

var Surface = ReactCanvas.Surface;
var GridView = ReactCanvas.GridView;

var App = React.createClass({
  render: function () {
    var size = this.getSize();
    return (
      <Surface top={0} left={0} width={size.width} height={size.height}>
        <GridView
          style={this.getGridViewStyle()}
          numberOfItemsGetter={this.getNumberOfItems}
          itemHeightGetter={Item.getItemHeight}
          itemWidthGetter={Item.getItemWidth}
          itemGetter={this.renderItem}
          numberOfColumnsGetter={this.getNumberOfColumns} />
      </Surface>
    );
  },

  renderItem: function (itemIndex, scrollTop, scrollLeft) {
    var article = articles[itemIndex % articles.length];
      return (
      <Item
        width={Item.getItemWidth()}
        height={Item.getItemHeight()}
        imageUrl={article.imageUrl}
        title={article.title}
        itemIndex={itemIndex} />
    );
  },

  getSize: function () {
    return document.getElementById('main').getBoundingClientRect();
  },


  // GridView
  // ========

  getGridViewStyle: function () {
    var size = this.getSize();
    return {
      top: 0,
      left: 0,
      width: size.width,
      height: size.height,
      backgroundColor: '#fff'
    };
  },

  getNumberOfItems: function () {
    return 100;
  },

  getNumberOfColumns: function () {
    return 4;
  }
});

React.render(<App />, document.getElementById('main'));
