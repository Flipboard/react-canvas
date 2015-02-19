'use strict';

var EJECTA = window.Ejecta;

if (EJECTA) {
  // Monkey-patch React and Canvas on startup
  require('react/lib/ExecutionEnvironment').canUseDOM = false;
  require('react-canvas').Surface = require('./EjectaSurface');
}

var React = require('react');
var ReactCanvas = require('react-canvas');
var App = require('./app');
var EjectaRoot = require('./EjectaRoot');

if (EJECTA) {
  var element = React.createElement(EjectaRoot, {}, React.createElement(App, null));
  var instance = new element.type(element);
  instance.construct(element);
  instance.mountComponent();
} else {
  React.render(<App />, document.getElementById('main'));
}
