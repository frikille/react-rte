react = require 'react/addons'

module.exports = {
  apply-bold-format: ->
    @apply-format 'b'

  apply-italic-format: ->
    @apply-format 'i'

  apply-underline-format: ->
    @apply-format 'u'

  apply-striketrough-format: ->
    @apply-format 'del'

  apply-format: (format-tag) ->
    selection-model = @get-selection-model!
    content = @state.content

    if selection-model.type == 'Caret'
      console.warn 'Caret selection type is not supported yet'
    else

      if selection-model.multiline-selection
        console.log 'multiline selection'
      else
        selected-node = selection-model.nodes.0
        selection-start = selected-node.selection-start
        selection-end = selected-node.selection-end

        tag-name = selected-node.node.tag-name.to-lower-case!
        text = selected-node.node.first-child.data

        tag-key = selected-node.tag-key
        tag-key-array = tag-key.split('.').splice(1).map (item) -> item * 1

        splice-array = [0,1]
        format-position = 0

        new-formatted-node = {
          tag-name: format-tag
          node-type: 1
          child-nodes: [{
            node-type: 3
            text-content: text.substring selection-start, selection-end
          }]
        }

        # if a span text content is selected then the new formatting should not be a child node of the span
        if tag-name == 'span'
          console.log tag-key

          if selection-start == 0 && selection-end == text.length
            c = {
              tag-name: {
                $set: format-tag
              }
            }
          else
            if selection-start == 0
              c = {
                tag-name: {
                  $set: format-tag
                }
                child-nodes: {
                  0: {
                    text-content: {
                      $set: text.substring 0, selection-end
                    }
                  }
                }
              }

              new-node = {
                tag-name: 'span'
                node-type: 1
                child-nodes: [{
                  node-type: 3
                  text-content: text.substring selection-end
                }]
              }

              config = tag-key-array.reduce-right @build-config-object, c
              content = react.addons.update content, config

              index = tag-key-array.pop!

              c = {
                child-nodes: {
                  $splice: [[index + 1, 0, new-node]]
                }
              }
            else if selection-end == text.length
              c = {
                tag-name: {
                  $set: format-tag
                }
                child-nodes: {
                  0: {
                    text-content: {
                      $set: text.substring selection-start
                    }
                  }
                }
              }

              new-node = {
                tag-name: 'span'
                node-type: 1
                child-nodes: [{
                  node-type: 3
                  text-content: text.substring 0, selection-start
                }]
              }

              config = tag-key-array.reduce-right @build-config-object, c
              content = react.addons.update content, config

              index = tag-key-array.pop!

              c = {
                child-nodes: {
                  $splice: [[index, 0, new-node]]
                }
              }

              selection-el-tag-key = 'root.' + ( tag-key-array.join '.') + '.' + (index + 1)
              console.log selection-el-tag-key

            else
              c = {
                tag-name: {
                  $set: format-tag
                }
                child-nodes: {
                  0: {
                    text-content: {
                      $set: text.substring selection-start, selection-end
                    }
                  }
                }
              }

              new-node = {
                tag-name: 'span'
                node-type: 1
                child-nodes: [{
                  node-type: 3
                  text-content: text.substring 0, selection-start
                }]
              }

              config = tag-key-array.reduce-right @build-config-object, c
              content = react.addons.update content, config

              index = tag-key-array.pop!

              c = {
                child-nodes: {
                  $splice: [[index, 0, new-node]]
                }
              }

              new-node = {
                tag-name: 'span'
                node-type: 1
                child-nodes: [{
                  node-type: 3
                  text-content: text.substring selection-end
                }]
              }

              config = tag-key-array.reduce-right @build-config-object, c
              content = react.addons.update content, config

              c = {
                child-nodes: {
                  $splice: [[index + 2, 0, new-node]]
                }
              }

              selection-el-tag-key = 'root.' + ( tag-key-array.join '.') + '.' + (index + 1)
              console.log selection-el-tag-key
        else

          if selection-start != 0

            new-node-one = {
              tag-name: 'span'
              node-type: 1
              child-nodes: [{
                node-type: 3
                text-content: text.substring 0, selection-start
              }]
            }
            bold-position = 1

            splice-array.push new-node-one
            splice-array.push new-formatted-node

            if selection-end != text.length
              new-node-two = {
                tag-name: 'span'
                node-type: 1
                child-nodes: [{
                  node-type: 3
                  text-content: text.substring selection-end
                }]
              }

              splice-array.push new-node-two
          else

            splice-array.push new-formatted-node

            if selection-end != text.length
              new-node-two = {
                tag-name: 'span'
                node-type: 1
                child-nodes: [{
                  node-type: 3
                  text-content: text.substring selection-end
                }]
              }

              splice-array.push new-node-two

          c = {
            child-nodes: {
              $splice: [splice-array]
            }
          }
          selection-el-tag-key = 'root.' + tag-key-array.join('.') + '.' + bold-position

        config = tag-key-array.reduce-right @build-config-object, c

        content = react.addons.update content, config
        content = @add-keys-to-tags content, @state.root-key

        merge-config = @merge-siblings-formatting-nodes content
        if merge-config
          console.log merge-config

        @update-state content, selection-el-tag-key, selection-end - selection-start

  merge-siblings-formatting-nodes: (content) ->

    for x in content.child-nodes
      if x.node-type == 3
        return

      @merge-siblings-formatting-nodes x

      available-nodes-for-merge = x.child-nodes.map (node) ~> @is-possible-node-for-merge node

      for i from 0 to x.child-nodes.length - 2 by 1
        if available-nodes-for-merge[i] && available-nodes-for-merge[i+1] && x.child-nodes[i].tag-name == x.child-nodes[i+1].tag-name
          new-node = @try-merge x.child-nodes[i], x.child-nodes[i+1]
          return {
            parent-node: x
            index: i
            new-node: new-node
          }

  is-possible-node-for-merge: (node) ->
    if node.node-type == 1 && node.child-nodes.length == 1 && node.child-nodes.0.node-type == 3
      true
    else
      false

  try-merge: (node1, node2) ->
    console.log 'trying to merge: ', node1.child-nodes.0.text-content, node2.child-nodes.0.text-content

    {
      node-type: 1
      tag-name: node1.tag-name
      child-nodes: [{
        node-type: 3
        text-content: node1.child-nodes.0.text-content + node2.child-nodes.0.text-content
      }]
    }
}
