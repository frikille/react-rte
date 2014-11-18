react = require 'react/addons'

module.exports = {

  /**
   * Return the selection the normalised selection model:
   *  - nodes are sorted in ascending order
   *  - includes the selection start and end for both nodes
   * @type {[type]}
   */
  get-selection-model: ->
    selection = window.get-selection!

    anchor = @normalise-selection-node selection.anchor-node
    extent = @normalise-selection-node selection.focus-node

    anchor-offset = selection.anchor-offset
    extent-offset = selection.focus-offset

    if anchor == extent
      {
        multiline-selection: false
        type: selection.type
        normal-text-only: @has-node-normal-text-only anchor
        nodes: [{
          node: anchor
          tag-key: anchor.get-attribute 'data-tag-key'
          selection-start: Math.min anchor-offset, extent-offset
          selection-end: Math.max anchor-offset, extent-offset
        }]
      }
    else
      nodes = [{
        node: anchor
        offset: anchor-offset
        tag-key: anchor.get-attribute 'data-tag-key'
      }, {
        node: extent
        offset: extent-offset
        tag-key: extent.get-attribute 'data-tag-key'
      }]

      nodes.sort (a, b) ->
        if a.tag-key <= b.tag-key then -1 else 1

      nodes.0.selection-start = nodes.0.offset
      nodes.0.selection-end = nodes.0.node.first-child.length

      nodes.1.selection-start = 0
      nodes.1.selection-end = nodes.1.offset

      {
        multiline-selection: true
        type: selection.type
        normal-text-only: (@has-node-normal-text-only anchor) && (@has-node-normal-text-only extent)
        nodes: nodes
      }

  normalise-selection-node: (node) ->

    unless node.tag-name
      node.parent-node
    else
      node

  has-node-normal-text-only: (node) ->

    if node.parent-node.get-attribute('data-tag-key') == 'root'
      true
    else
      false

}
