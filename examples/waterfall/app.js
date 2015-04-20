/** @jsx React.DOM */

'use strict';

var React = require('react');
var ReactCanvas = require('react-canvas');
var Item = require('./components/Item');

var data = require('../common/mockData');

var Surface = ReactCanvas.Surface;
var ListView = ReactCanvas.ListView;

var App = React.createClass({

  render: function () {
    var size = this.getSize();
    return (
      <Surface top={0} left={0} width={size.width} height={size.height}>
        <ListView
          onScroll={this.scroll}
          snapping={true}
          scrollingDeceleration={0.92}
          scrollingPenetrationAcceleration={0.13}
          style={this.getListViewStyle()}
          numberOfItemsGetter={this.getNumberOfItems}
          itemHeightGetter={Item.getItemHeight}
          itemGetter={this.renderItem} />
      </Surface>
    );
  },
  scroll:function(listViewIns,top){
      var self = this;
      if(typeof this.scrollState === 'undefined'){
          this.scrollState = 1;
      }

      var scrollHeight = this.getNumberOfItems() * Item.getItemHeight();
      var distance = Item.getItemHeight() * 2;

      if(this.scrollState && (top + distance >= scrollHeight) ){

        this.scrollState = 0;

        var style = this.getListViewStyle();

        listViewIns.scroller.setDimensions(style.width, style.height, style.width, scrollHeight - (Item.getItemHeight() - Item.getLodingHeight()));

        setTimeout(function(){
            data = data.concat(data);
            
            listViewIns.updateScrollingDimensions();
            self.scrollState = 1;
        },2000);
      }
  },

  renderItem: function (itemIndex, scrollTop) {
    var rowNum = Item.getRowNums();
    var rowData = [];

    for (var i = itemIndex; i < itemIndex + rowNum; i++) {
        rowData.push(data[itemIndex + i]);
    };

    if(itemIndex + 1 === this.getNumberOfItems()){
        var loding = true;
    }

    return (
      <Item
        loding={loding}
        width={this.getSize().width}
        height={Item.getItemHeight()}
        data={rowData}
        itemIndex={itemIndex} />
    );
  },

  getSize: function () {
    return document.getElementById('main').getBoundingClientRect();
  },

  getListViewStyle: function () {
    return {
      top: 0,
      left: 0,
      width: window.innerWidth,
      height: window.innerHeight
    };
  },

  getNumberOfItems: function () {
    return Math.ceil(data.length / Item.getRowNums());
  },

});

React.render(<App />, document.getElementById('main'));


