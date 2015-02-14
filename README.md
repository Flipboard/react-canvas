# react-canvas

[Introductory blog post](http://engineering.flipboard.com/2015/02/mobile-web/)

React Canvas adds the ability for React components to render to `<canvas>` rather than DOM.

This project is a work-in-progress. Though much of the code is in production on flipboard.com, the React canvas bindings are relatively new and the API is subject to change.

## Motivation

Having a long history of building interfaces geared toward mobile devices, we found that the reason mobile web apps feel slow when compared to native apps is the DOM. CSS animations and transitions are the fastest path to smooth animations on the web, but they have several limitations. React Canvas leverages the fact that most modern mobile browsers now have hardware accelerated canvas.

While there have been other attempts to bind canvas drawing APIs to React, they are more focused on visualizations and games. Where React Canvas differs is in the focus on building application user interfaces. The fact that it renders to canvas is an implementation detail.

React Canvas brings some of the APIs web developers are familiar with and blends them with a high performance drawing engine.

## React Canvas Components

React Canvas provides a set of standard React components that abstract the underlying rendering implementation.

### &lt;Surface&gt;

**Surface** is the top-level component. Think of it as a drawing canvas in which you can place other components.

### &lt;Layer&gt;

**Layer** is the the base component by which other components build upon. Common styles and properties such as top, width, left, height, backgroundColor and zIndex are expressed at this level.

### &lt;Group&gt;

**Group** is a container component. Because React enforces that all components return a single component in `render()`, Groups can be useful for parenting a set of child components. The Group is also an important component for optimizing scrolling performance, as it allows the rendering engine to cache expensive drawing operations.

### &lt;Text&gt;

**Text** is a flexible component that supports multi-line truncation, something which has historically been difficult and very expensive to do in DOM.

### &lt;Image&gt;

**Image** is exactly what you think it is. However, it adds the ability to hide an image until it is fully loaded and optionally fade it in on load.

### &lt;ListView&gt;

**ListView** is a touch scrolling container that renders a list of elements in a column. Think of it like UITableView for the web. It leverages many of the same optimizations that make table views on iOS and list views on Android fast.

## Events

React Canvas components support the same event model as normal React components. However, not all event types are currently supported.

For a full list of supported events see [EventTypes](lib/EventTypes.js).

## Building Components

Here is a very simple component that renders text below an image:

```javascript
var React = require('react');
var ReactCanvas = require('react-canvas');

var Surface = ReactCanvas.Surface;
var Image = ReactCanvas.Image;
var Text = ReactCanvas.Text;

var MyComponent = React.createClass({

  render: function () {
    var surfaceWidth = window.innerWidth;
    var surfaceHeight = window.innerHeight;
    var imageStyle = this.getImageStyle();
    var textStyle = this.getTextStyle();

    return (
      <Surface width={surfaceWidth} height={surfaceHeight} left={0} top={0}>
        <Image style={imageStyle} src='...' />
        <Text style={textStyle}>
          Here is some text below an image.
        </Text>
      </Surface>
    );
  },

  getImageHeight: function () {
    return Math.round(window.innerHeight / 2);
  },

  getImageStyle: function () {
    return {
      top: 0,
      left: 0,
      width: window.innerWidth,
      height: this.getImageHeight()
    };
  },

  getTextStyle: function () {
    return {
      top: this.getImageHeight() + 10,
      left: 0,
      width: window.innerWidth,
      height: 20,
      lineHeight: 20,
      fontSize: 12
    };
  }

});
```

## ListView

Many mobile interfaces involve an infinitely long scrolling list of items. React Canvas provides the ListView component to do just that.

Because ListView virtualizes elements outside of the viewport, passing children to it is different than a normal React component where children are declared in render().

The `numberOfItemsGetter`, `itemHeightGetter` and `itemGetter` props are all required.

```javascript
var ListView = ReactCanvas.ListView;

var MyScrollingListView = React.createClass({

  render: function () {
    return (
      <ListView
        numberOfItemsGetter={this.getNumberOfItems}
        itemHeightGetter={this.getItemHeight}
        itemGetter={this.renderItem} />
    );
  },

  getNumberOfItems: function () {
    // Return the total number of items in the list
  },

  getItemHeight: function () {
    // Return the height of a single item
  },

  renderItem: function (index) {
    // Render the item at the given index, usually a <Group>
  },

});
```

See the [timeline example](examples/timeline/app.js) for a more complete example.

Currently, ListView requires that each item is of the same height. Future versions will support variable height items.

## Text sizing

React Canvas provides the `measureText` function for computing text metrics.

The [Page component](examples/timeline/components/Page.js) in the timeline example contains an example of using measureText to achieve precise multi-line ellipsized text.

Custom fonts are not currently supported but will be added in a future version.

## css-layout

There is experimental support for using [css-layout](https://github.com/facebook/css-layout) to style React Canvas components. This is a more expressive way of defining styles for a component using standard CSS styles and flexbox.

Future versions may not support css-layout out of the box. The performance implications need to be investigated before baking this in as a core layout principle.

See the [css-layout example](examples/css-layout).

## Accessibility

This area needs further exploration. Using fallback content (the canvas DOM sub-tree) should allow screen readers such as VoiceOver to interact with the content. We've seen mixed results with the iOS devices we've tested. Additionally there is a standard for [focus management](http://www.w3.org/TR/2010/WD-2dcontext-20100304/#dom-context-2d-drawfocusring) that is not supported by browsers yet.

One approach that was raised by [Bespin](http://vimeo.com/3195079) in 2009 is to keep a [parallel DOM](http://robertnyman.com/2009/04/03/mozilla-labs-online-code-editor-bespin/#comment-560310) in sync with the elements rendered in canvas.

## Running the examples

```
npm install
npm start
```

This will start a live reloading server on port 8080. To override the default server and live reload ports, run `npm start` with PORT and/or RELOAD_PORT environment variables.

**A note on NODE_ENV and React**: running the examples with `NODE_ENV=production` will noticeably improve scrolling performance. This is because React skips propType validation in production mode.

## Contributing

We welcome pull requests for bug fixes, new features, and improvements to React Canvas. Contributors to the main repository must accept Flipboard's Apache-style [Individual Contributor License Agreement (CLA)](https://docs.google.com/forms/d/1gh9y6_i8xFn6pA15PqFeye19VqasuI9-bGp_e0owy74/viewform) before any changes can be merged.

