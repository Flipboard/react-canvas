/** @jsx React.DOM */

var React = require('react');
var ReactDOM = require('react-dom');
var ReactCanvas = require('react-canvas');

var Surface = ReactCanvas.Surface;
var Group = ReactCanvas.Group;
var Image = ReactCanvas.Image;
var Text = ReactCanvas.Text;
var FontFace = ReactCanvas.FontFace;

var App = React.createClass({
  // Hover declaration
  // =================
  getInitialState: function () {
    return {hovered: false};
  },
  handleMouseEnter: function () {
    this.setState({hovered: true});
  },
  handleMouseLeave: function () {
    this.setState({hovered: false});
  },
  componentDidMount: function () {
    window.addEventListener('resize', this.handleResize, true);
  },
  render: function () {
    var size = this.getSize();
    return (
      <Surface top={0} left={0} width={size.width} height={size.height} enableCSSLayout={true}>
        <Group style={this.getPageStyle()} >
          <Group style={this.getBoxStyle()} onMouseEnter={this.handleMouseEnter} onMouseLeave={this.handleMouseLeave} >
            <Text style={this.getBoxTitleStyle()}>
              Hover me!
            </Text>  
          </Group>
        </Group>
      </Surface>
    );
  },

  // Styles
  // ======

  getSize: function () {
    return document.getElementById('main').getBoundingClientRect();
  },

  getPageStyle: function () {
    var size = this.getSize();
    return {
      position: 'relative',
      padding: 14,
      width: size.width,
      height: size.height,
      backgroundColor: '#f7f7f7',
      flexDirection: 'column'
    };
  },

  getBoxStyle: function () {
    return {
      position: 'relative',
      margin: 50,
      flex: 1,
      backgroundColor: this.state.hovered ?  'red' : '#eee'
    };
  },


  getBoxTitleStyle: function () {
    return {
      fontFace: FontFace('Georgia'),
      fontSize: 22,
      lineHeight: 28,
      height: 28,
      marginTop: 10,
      color: '#333',
      textAlign: 'center'
    };
  },

  // Events
  // ======

  handleResize: function () {
    this.forceUpdate();
  }

});

ReactDOM.render(<App />, document.getElementById('main'));
