'use strict';

var React = require('react');
var ReactDOM = require('react-dom');
var ReactCanvas = require('react-canvas');
var Item = require('./components/Item');
var articles = require('../common/data');

var Surface = ReactCanvas.Surface;
var ListView = ReactCanvas.ListView;

var App = React.createClass({

  render: function () {
    var size = this.getSize();
    return (
      <Surface top={0} left={0} width={size.width} height={size.height}>
        <ListView
          style={this.getListViewStyle()}
          numberOfItemsGetter={this.getNumberOfItems}
          itemHeightGetter={Item.getItemHeight}
          itemGetter={this.renderItem} />
      </Surface>
    );
  },

  renderItem: function (itemIndex, scrollTop) {
    var article = articles[itemIndex % articles.length];
      return (
      <Item
        width={this.getSize().width}
        height={Item.getItemHeight()}
        imageUrl={article.imageUrl}
        title={article.title}
        itemIndex={itemIndex} />
    );
  },

  getSize: function () {
    return document.getElementById('main').getBoundingClientRect();
  },

  // ListView
  // ========

  getListViewStyle: function () {
    return {
      top: 0,
      left: 0,
      width: window.innerWidth,
      height: window.innerHeight
    };
  },

  getNumberOfItems: function () {
    return 1000;
  },

});

ReactDOM.render(<App />, document.getElementById('main'));
