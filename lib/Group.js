'use strict'

import createComponent from './createComponent'
import ContainerMixin from './ContainerMixin'
import LayerMixin from './LayerMixin'
import RenderLayer from './RenderLayer'

var Group = createComponent('Group', LayerMixin, ContainerMixin, {

  mountComponent: function (rootID, transaction, context) {
    var props = this._currentElement.props
    var layer = this.node

    this.applyLayerProps({}, props)
    this.mountAndInjectChildren(props.children, transaction, context)

    return layer
  },

  receiveComponent: function (nextComponent, transaction, context) {
    var props = nextComponent.props
    var prevProps = this._currentElement.props
    this.applyLayerProps(prevProps, props)
    this.updateChildren(props.children, transaction, context)
    this._currentElement = nextComponent
    this.node.invalidateLayout()
  },

  unmountComponent: function () {
    LayerMixin.unmountComponent.call(this)
    this.unmountChildren()
  }

})

module.exports = Group
