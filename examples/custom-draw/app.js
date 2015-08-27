/** @jsx React.DOM */

'use strict';

var React = require('react');
var ReactCanvas = require('react-canvas');

var Surface = ReactCanvas.Surface;
var Group = ReactCanvas.Group;


ReactCanvas.registerLayerType('circle', function (ctx, layer) {
    var x = layer.frame.x; 
    var y = layer.frame.y;
    var width = layer.frame.width;
    var height = layer.frame.height;
    var centerX = x + width / 2;
    var centerY = y + height / 2;

    var fillColor = layer.backgroundColor || '#FFF';
    var strokeColor = layer.borderColor || '#FFF';
    var strokeWidth = layer.borderWidth || 0;
  
    var shadowColor = layer.shadowColor || 0;
    var shadowOffsetX = layer.shadowOffsetX || 0;
    var shadowOffsetY = layer.shadowOffsetY || 0;
    var shadowBlur = layer.shadowBlur || 0;

    var radius = Math.min(width / 2, height / 2) - Math.ceil(strokeWidth / 2);
    
  
    
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI, false);
    if (shadowOffsetX || shadowOffsetY) {
      ctx.shadowColor = shadowColor;
      ctx.shadowBlur = shadowBlur;
      ctx.shadowOffsetX = shadowOffsetX;
      ctx.shadowOffsetY = shadowOffsetY;
    }
  
    ctx.fillStyle = fillColor;
    ctx.fill();
    if (strokeWidth > 0) {
      ctx.lineWidth = strokeWidth;
      ctx.strokeStyle = strokeColor;
      ctx.stroke();
    }
});

var Circle = ReactCanvas.createCanvasComponent({
  displayName: 'Circle',
  layerType: 'circle',
  
  applyCustomProps: function (prevProps, props) {
    var style = props.style || {};
    var layer = this.node;
    layer.shadowColor = style.shadowColor || 0;
    layer.shadowOffsetX = style.shadowOffsetX || 0;
    layer.shadowOffsetY = style.shadowOffsetY || 0;
    layer.shadowBlur = style.shadowBlur || 0;
  }
});



var App = React.createClass({

  render: function () {
    return (
      <Surface top={10} left={10} width={500} height={500}>
          <Circle style={{
            top: 10, 
            left: 10, 
            width: 180,
            height: 180,
            backgroundColor: 'green', 
            borderColor: '#000', 
            borderWidth: 1,
            shadowColor: '#999',
            shadowOffsetX: 15,
            shadowOffsetY: 15,
            shadowBlur: 20
      
          }} />
      </Surface>
    );
  },

});

React.render(<App />, document.getElementById('main'));
