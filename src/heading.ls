react = require 'react/addons'

module.exports = {
  apply-heading-one: ->
    @apply-heading 'h1'
  apply-heading-two: ->
    @apply-heading 'h2'
  apply-heading-three: ->
    @apply-heading 'h3'
  apply-heading-four: ->
    @apply-heading 'h4'

  apply-heading: (heading-level) ->
    selection = window.get-selection!

    selection-anchor-node = @get-top-level-selection-node selection.anchor-node
    selection-extent-node = @get-top-level-selection-node selection.extent-node

    start-index = ((selection-anchor-node.get-attribute 'data-tag-key').split '.').1 * 1
    end-index = ((selection-extent-node.get-attribute 'data-tag-key').split '.').1 * 1

    if start-index > end-index
      swap = start-index
      start-index = end-index
      end-index = swap

    child-nodes-config = {}
    for i from start-index to end-index by 1
      child-nodes-config[i] = {
        tag-name: {
          $set: heading-level
        }
      }

    config = {
      child-nodes: child-nodes-config
    }

    content = react.addons.update @state.content, config
    @set-state {
      content: @add-keys-to-tags content, @state.root-key
    }


  get-top-level-selection-node: (selection-node) ->

    unless selection-node.tag-name
      selection-node = selection-node.parent-node

    while (['div', 'p', 'h1', 'h2', 'h3', 'h4', 'code'].index-of selection-node.tag-name.to-lower-case!) == -1
      selection-node = selection-node.parent-node

    selection-node
}
