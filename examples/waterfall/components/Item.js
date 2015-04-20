/** @jsx React.DOM */

'use strict';

var React = require('react');
var ReactCanvas = require('react-canvas');

var FontFace = ReactCanvas.FontFace;
var measureText = ReactCanvas.measureText;
var Group = ReactCanvas.Group;
var Image = ReactCanvas.Image;
var Text = ReactCanvas.Text;

var Item = React.createClass({

  propTypes: {
    width: React.PropTypes.number.isRequired,
    height: React.PropTypes.number.isRequired,
    data: React.PropTypes.object.isRequired,
    itemIndex: React.PropTypes.number.isRequired,
  },

  statics: {
    getItemHeight: function () {
      return 300;
    },
    getLodingHeight: function(){
      return 30;
    },
    getRowNums: function(){
      return 2;
    }
  },

  truncate : function(text,style){
    var maxWidth = 1000;
    var textMetrics = measureText(text, maxWidth, style.fontFace, style.fontSize, style.lineHeight);
    var actualWidth = textMetrics.width;
    if(actualWidth >= style.width){
      var perLen = actualWidth / text.length;
      var textNum = parseInt(style.width / perLen);
      text = text.substr(0, textNum - 2 ) + '...';
    }
    return text;
  },

  render: function () {
    var self = this;

    var rowItems = this.props.data.map(function(item,index){
        var rowImageStyle = self.getImageStyle(index);
        var rowTitStyle = self.getTitleStyle(index);
        var priceStyle = self.getPriceStyle(index);
        var btnStyle = self.getBtnStyle(index);

        var text = self.truncate(item.title,self.getTitleStyle(index));

        return (
            <Group>
              <Image style={rowImageStyle} src={item.pic} fadeIn={true}  />
              <Group>
                <Text style={rowTitStyle}>{text}</Text>
                <Text style={priceStyle}>{item.price}</Text>
                <Text onClick={self.btnClick(item)} style={btnStyle}>马上抢购</Text>
              </Group>
            </Group>
        );
    });

    if(this.props.loding){
      return (
        <Group>
          <Text style={{width:this.props.width,height:30,textAlign:'center'}}>loding...</Text>
        </Group>
      )
    }

    return (
      <Group style={this.getStyle()}>
        {rowItems}
      </Group>
    );
  },

  btnClick : function(data){
    return function(){
       location.href = data.link;
    }
  },

  getStyle: function () {
    return {
      width: this.props.width,
      height: Item.getItemHeight()
    };
  },

  getRowWidth : function(){
      return this.props.width / Item.getRowNums();
  },

  getRowLeft : function(index){
      return this.getRowWidth() * index;
  },

  getImageStyle: function (index) {
    return {
      top: 5,
      left: this.getRowLeft(index) + 5,
      width: this.getRowWidth() - 5,
      height: 190,
      backgroundColor: '#ddd',
      borderColor: '#999',
      borderWidth: 1
    };
  },

  getPriceStyle: function (index) {
    return {
      top: 230,
      left: this.getRowLeft(index),
      width: 170,
      height: 18,
      fontSize: 18,
      lineHeight: 18,
      color:'red'
    };
  },

  getBtnStyle: function(index){
    return {
      top: 260,
      left: this.getRowLeft(index),
      width: 90,
      height: 25,
      textAlign: 'center',
      borderRadius : 10,
      fontSize: 18,
      lineHeight: 25,
      backgroundColor: 'red',
      color:'#fff'
    };
  },

  getTitleStyle: function (index) {
    return {
      top: 210,
      left: this.getRowLeft(index),
      width: this.getRowWidth(),
      fontFace: FontFace('Georgia, serif'),
      height: 20,
      fontSize: 14,
      lineHeight: 20,
      color:'#666'
    };
  }

});

module.exports = Item;
