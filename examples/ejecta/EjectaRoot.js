'use strict';

var ReactUpdates = require('react/lib/ReactUpdates');
var ContainerMixin = require('../../lib/ContainerMixin');
var createComponent = require('../../lib/createComponent');

var EjectaRoot = createComponent('EjectaRoot', ContainerMixin, {

  construct: function (element) {
    this._currentElement = element;
  },

  mountComponent: function () {
    var currentElement = this._currentElement;
    var transaction = ReactUpdates.ReactReconcileTransaction.getPooled();
    transaction.perform(
      this.mountAndInjectChildrenAtRoot,
      this,
      currentElement.props.children,
      transaction
    );
    ReactUpdates.ReactReconcileTransaction.release(transaction);
  },

  receiveComponent: function () {
    // TODO
  },

});

module.exports = EjectaRoot;
