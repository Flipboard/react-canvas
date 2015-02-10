/** @jsx React.DOM */

var React = require('react');
var ReactCanvas = require('react-canvas');

var Surface = ReactCanvas.Surface;
var Group = ReactCanvas.Group;
var Image = ReactCanvas.Image;
var Text = ReactCanvas.Text;
var FontFace = ReactCanvas.FontFace;

var App = React.createClass({

  componentDidMount: function () {
    window.addEventListener('resize', this.handleResize, true);
  },

  render: function () {
    var size = this.getSize();
    return (
      <Surface top={0} left={0} width={size.width} height={size.height} enableCSSLayout={true}>
        <Group style={this.getPageStyle()}>
          <Text style={this.getTitleStyle()}>
            Professor PuddinPop
          </Text>
          <Image src='http://lorempixel.com/360/420/cats/1/' style={this.getImageStyle()} fadeIn={true} />
          <Text style={this.getExcerptStyle()}>
            With these words the Witch fell down in a brown, melted, shapeless mass and began to spread over the clean boards of the kitchen floor.  Seeing that she had really melted away to nothing, Dorothy drew another bucket of water and threw it over the mess.  She then swept it all out the door.  After picking out the silver shoe, which was all that was left of the old woman, she cleaned and dried it with a cloth, and put it on her foot again.  Then, being at last free to do as she chose, she ran out to the courtyard to tell the Lion that the Wicked Witch of the West had come to an end, and that they were no longer prisoners in a strange land.
          </Text>
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

  getImageStyle: function () {
    return {
      flex: 1,
      backgroundColor: '#eee'
    };
  },

  getTitleStyle: function () {
    return {
      fontFace: FontFace('Georgia'),
      fontSize: 18,
      lineHeight: 28,
      height: 28,
      marginBottom: 10,
      color: '#333',
      textAlign: 'center'
    };
  },

  getExcerptStyle: function () {
    return {
      fontFace: FontFace('Georgia'),
      fontSize: 12,
      lineHeight: 25,
      marginTop: 15,
      flex: 1,
      color: '#333'
    };
  },

  // Events
  // ======

  handleResize: function () {
    this.forceUpdate();
  }

});

React.render(<App />, document.getElementById('main'));
