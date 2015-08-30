/** @jsx React.DOM */

'use strict';

var articles    = require('../common/data');
var Item        = require('./components/Item');
var React       = require('react');
var ReactCanvas = require('react-canvas');

var Surface    = ReactCanvas.Surface;
var ScrollView = ReactCanvas.ScrollView;

var App = React.createClass({

  render: function () {
    var size = this.getSize();
    var items = []
    var heights = []
    for (var i = 0; i < 100; i++) {
        items.push(this.renderItem(i))
        heights.push(80)
    }
    return (
      <Surface top={0} left={0} width={size.width} height={size.height}>
        <ScrollView
          style={this.getListViewStyle()}
          numberOfItems={items.length}
          itemHeights={heights}
          items={items} />
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
      top    : 0,
      left   : 0,
      width  : window.innerWidth,
      height : window.innerHeight
    };
  }

});

React.render(<App />, document.getElementById('main'));
