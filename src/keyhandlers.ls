react = require 'react/addons'

module.exports = {

  handle-enter-key-for-single-line-normal-text: (selection-model) ->
    content = @state.content

    selected-node = selection-model.nodes.0
    selection-index = (selected-node.tag-key.split '.')[1] * 1

    if selected-node.selection-start == selected-node.selection-end && selected-node.selection-start == selected-node.node.inner-text.length
      new-node = {
        tag-name: 'p'
        node-type: 1
        child-nodes: [{
          node-type: 1
          tag-name: 'br'
          child-nodes: []
        }]
      }
    else
      new-node = {
        tag-name: 'p'
        node-type: 1
        child-nodes: [{
          node-type: 3
          text-content: selected-node.node.inner-text.substring selected-node.selection-start
        }]
      }

      remove-config = {}
      remove-config[selection-index] = {
        child-nodes: {
          0: {
            text-content: {
              $set: selected-node.node.inner-text.substring 0, selected-node.selection-start
            }
          }
        }
      }

      config = {
        child-nodes: remove-config
      }

      content = react.addons.update content, config

    config = {
      child-nodes: {
        $splice: [[(selection-index + 1), 0, new-node]]
      }
    }

    content = react.addons.update content, config
    content = @add-keys-to-tags content, @state.root-key
    @update-state content, content.child-nodes[selection-index + 1].key, 0

  handle-enter-key-for-single-line-formatted-text: (selection-model, do-return) ->
    content = @state.content

    selection-node = selection-model.nodes.0

    tag-key-array = selection-node.tag-key.split('.').splice(1).map (item) -> item * 1

    new-nodes = @split-node selection-node.node, selection-node.selection-start

    selected-node-index = tag-key-array.pop!

    c = {
      child-nodes: {
        $splice: [[selected-node-index, 1, new-nodes.0, new-nodes.1]]
      }
    }

    config = tag-key-array.reduce-right @build-config-object, c
    content = react.addons.update content, config

    top-level-parent-index = tag-key-array.shift!
    top-level-parent-node = content.child-nodes[top-level-parent-index]

    # Creating first new node clone
    c = {
      child-nodes: {
        $splice: [[selected-node-index + 1]]
      }
    }
    config = tag-key-array.reduce-right @build-config-object, c

    new-top-level-node1 = react.addons.update top-level-parent-node, config

    # removing parent next sibling nodes if array length > 1
    for i from 0 to tag-key-array.length - 2 by 1
      x = tag-key-array[i]
      a = tag-key-array.slice(0).splice 0, i+1

      c = {
        child-nodes: {
          $splice: [[x+1]]
        }
      }

      config = a.reduce-right @build-config-object, c
      new-top-level-node1 = react.addons.update new-top-level-node1, config


    # Creating second new node clone
    c = {
      child-nodes: {
        $splice: [[0, selected-node-index + 1]]
      }
    }
    config = tag-key-array.reduce-right @build-config-object, c

    new-top-level-node2 = react.addons.update top-level-parent-node, config

    # removing parent previous sibling nodes if array length > 1
    for i from 0 to tag-key-array.length - 1 by 1
      x = tag-key-array[i]
      a = Array.apply(null, Array i ).map -> 0

      c = {
        child-nodes: {
          $splice: [[0, x]]
        }
      }

      config = a.reduce-right @build-config-object, c
      new-top-level-node2 = react.addons.update new-top-level-node2, config

    if do-return
      return [new-top-level-node1, new-top-level-node2]

    config = {
      child-nodes: {
        $splice: [[top-level-parent-index, 1, new-top-level-node1, new-top-level-node2]]
      }
    }

    content = react.addons.update content, config
    content = @add-keys-to-tags content, @state.root-key

    tag-key = selection-node.tag-key
    selection-start = selection-node.selection-start
    @update-state content, tag-key, selection-start

  /**
   * When user press enter on selection between multiline text:
   * 1. Delete text that is part of selection
   * @type {[type]}
   */
  handle-enter-key-for-multiline-normal-text: (selection-model) ->
    content = @state.content

    selection-nodes = selection-model.nodes

    new-node1 = {
      tag-name: selection-nodes.0.node.tag-name.to-lower-case!
      node-type: 1
      child-nodes: [
        node-type: 3
        text-content: selection-nodes.0.node.inner-text.substring 0, selection-nodes.0.selection-start
      ]
    }
    new-node2 = {
      tag-name: selection-nodes.1.node.tag-name.to-lower-case!
      node-type: 1
      child-nodes: [
        node-type: 3
        text-content: selection-nodes.1.node.inner-text.substring selection-nodes.1.selection-end
      ]
    }

    start-index = (selection-nodes.0.tag-key.split '.').1 * 1
    end-index = ((selection-nodes.1.tag-key.split '.').1 * 1) - start-index + 1

    config = {
      child-nodes: {
        $splice: [[start-index, end-index, new-node1, new-node2]]
      }
    }

    tag-key = (selection-nodes.0.tag-key.split '.').0 + '.' + (start-index + 1)

    selection-start = 0

    content = react.addons.update @state.content, config
    content = @add-keys-to-tags content, @state.root-key

    @update-state content, tag-key, selection-start

  handle-enter-key-for-multiline-formatted-text: (selection-model) ->

    nodes = selection-model.nodes

    start-index = (nodes.0.tag-key.split '.').1 * 1
    end-index = (nodes.1.tag-key.split '.').1 * 1

    if nodes.0.node.tag-name.to-lower-case! == 'p'
      new-node1 = (@split-node nodes.0.node, nodes.0.selection-start).0

    if nodes.1.node.tag-name.to-lower-case! == 'p'
      new-node2 = (@split-node nodes.1.node, nodes.1.selection-end).1

    unless new-node1
      updated-selection-model =
        nodes: [selection-model.nodes.0]

      splitted-nodes = @handle-enter-key-for-single-line-formatted-text updated-selection-model, true

      new-node1 = splitted-nodes.0
      start-index = (nodes.0.tag-key.split '.').1 * 1

    unless new-node2
      updated-selection-model =
        nodes: [selection-model.nodes.1]

      updated-selection-model.nodes.0.selection-start = selection-model.nodes.1.selection-end

      splitted-nodes = @handle-enter-key-for-single-line-formatted-text updated-selection-model, true

      new-node2 = splitted-nodes.1

    config = {
      child-nodes: {
        $splice: [[start-index, end-index - start-index + 1, new-node1, new-node2]]
      }
    }

    content = react.addons.update @state.content, config
    content = @add-keys-to-tags content, @state.root-key

    tag-key = nodes.0.tag-key
    selection-start = nodes.0.selection-start

    @update-state content, tag-key, selection-start

  handle-character-change-for-single-line-normal-text: (selection-model, is-appending, character) ->
    content = @state.content
    selected-node = selection-model.nodes.0

    selection-start = selected-node.selection-start
    selection-end = selected-node.selection-end
    selection-length = selection-end - selection-start

    tag-key = selected-node.tag-key
    tag-key-array = tag-key.split('.').splice(1).map (item) -> item * 1
    tag-key-array.push 0

    if selected-node.node.first-child.tag-name && selected-node.node.first-child.tag-name.to-lower-case! == 'br'
      if character == 'Backspace' || character == 'Delete'
        if @state.content.child-nodes.length == 1
          return

        # remove the added 0
        tag-key-array.pop!

        config = {
          child-nodes: {
            $splice: [[tag-key-array[0],1]]
          }
        }

        if tag-key-array[0] != 0
          tag-key = 'root.' + (tag-key-array[0] - 1)
          selection-start = 'last-character'
      else
        c = {
          text-content: {
            $set: character
          }
          node-type: {
            $set: 3
          }
        }
        config = tag-key-array.reduce-right @build-config-object, c
        selection-start += 1

    else
      if selected-node.node.first-child.data.length == 1 && character == 'Backspace' || character == 'Delete'
        c = {
          node-type: {
            $set: 1
          }
          child-nodes: {
            $set: []
          }
          tag-name: {
            $set: 'br'
          }
        }
        config = tag-key-array.reduce-right @build-config-object, c
      else
        # for backspace selection start needs to be the previous position
        if character == 'Backspace' && selection-start == selection-end then selection-start -= 1

        # after appending a character the selection start needs to be increased by 1 for cursor position
        config = tag-key-array.reduce-right @build-config-object, if is-appending then @append-text character, selection-start++, selection-length else @delete-text selection-start, selection-length

    content = react.addons.update @state.content, config
    content = @add-keys-to-tags content, @state.root-key

    @update-state content, tag-key, selection-start

  handle-character-change-for-single-line-formatted-text: (selection-model, is-appending, character) ->

    content = @state.content
    selected-node = selection-model.nodes.0

    tag-key = selected-node.tag-key
    tag-key-array = tag-key.split('.').splice(1).map (item) -> item * 1
    tag-key-array.push 0

    parent = selected-node.node.parent-node
    current-index = tag-key-array[tag-key-array.length - 2]

    tag-key-array = parent.get-attribute('data-tag-key').split('.').splice(1).map (item) -> item * 1

    c = {
      child-nodes: {
        $splice: [[current-index, 1]]
      }
    }

    config = tag-key-array.reduce-right @build-config-object, c
    content = react.addons.update @state.content, config
    # content = @remove-unnecessary-spans content

    if current-index != 0
      tag-key = selected-node.node.previous-sibling.get-attribute 'data-tag-key'
      selection-start = selected-node.node.previous-sibling.first-child.data.length
    else
      tag-key = parent.parent-node.get-attribute 'data-tag-key'
      selection-start = 'last-character'

    content = @add-keys-to-tags content, @state.root-key

    @update-state content, tag-key, selection-start

  handle-character-change-for-multiline-normal-text: (selection-model, is-appending, character) ->
    content = @state.content

    selection-nodes = selection-model.nodes

    new-node = @merge-nodes selection-nodes, character

    start-index = (selection-nodes.0.tag-key.split '.').1 * 1
    end-index = ((selection-nodes.1.tag-key.split '.').1 * 1) + 1

    console.log start-index, end-index

    config = {
      child-nodes: {
        $splice: [[start-index, end-index, new-node]]
      }
    }

    tag-key = selection-nodes.0.tag-key

    selection-start = if character == 'Backspace' || character == 'Delete' then selection-nodes.0.offset else selection-nodes.0.offset + 1

    content = react.addons.update @state.content, config
    content = @add-keys-to-tags content, @state.root-key

    @update-state content, tag-key, selection-start

  handle-character-change-for-multiline-formatted-text: (selection-model, is-appending, character) ->
    console.warn 'handle-character-change-for-multiline-formatted-text is not supported yet'

    nodes = selection-model.nodes

    start-index = (nodes.0.tag-key.split '.').1 * 1
    end-index = (nodes.1.tag-key.split '.').1 * 1

    if nodes.0.node.tag-name.to-lower-case! == 'p'
      new-node1 = (@split-node nodes.0.node, nodes.0.selection-start).0
      if is-appending
        new-node1.child-nodes.0.text-content += character

      child = new-node1.child-nodes.0
      new-node1.child-nodes.0 = {
        tag-name: 'span'
        node-type: 1
        child-nodes: [child]
      }

    if nodes.1.node.tag-name.to-lower-case! == 'p'
      new-node2 = (@split-node nodes.1.node, nodes.1.selection-end).1
      child = new-node2.child-nodes.0
      new-node2.child-nodes.0 = {
        tag-name: 'span'
        node-type: 1
        child-nodes: [child]
      }

    unless new-node1
      updated-selection-model =
        nodes: [selection-model.nodes.0]

      splitted-nodes = @handle-enter-key-for-single-line-formatted-text updated-selection-model, true

      new-node1 = splitted-nodes.0

      if is-appending
        tag-key-array = ((nodes.0.tag-key.split '.').slice 2).map (item) -> item * 1
        tag-key-array.push 0

        config = tag-key-array.reduce-right @build-config-object, @append-text character, nodes.0.selection-start

        new-node1 = react.addons.update new-node1, config

    unless new-node2
      updated-selection-model =
        nodes: [selection-model.nodes.1]

      updated-selection-model.nodes.0.selection-start = selection-model.nodes.1.selection-end

      splitted-nodes = @handle-enter-key-for-single-line-formatted-text updated-selection-model, true

      new-node2 = splitted-nodes.1

    new-node = {
      tag-name: 'p'
      node-type: 1
      child-nodes: new-node1.child-nodes.concat new-node2.child-nodes
    }

    config = {
      child-nodes: {
        $splice: [[start-index, end-index - start-index + 1, new-node]]
      }
    }

    content = react.addons.update @state.content, config
    content = @add-keys-to-tags content, @state.root-key

    tag-key = nodes.0.tag-key
    selection-start = nodes.0.selection-start
    if is-appending
      selection-start++

    @update-state content, tag-key, selection-start

  handle-character-change: (is-appending, character) ->
    selection-model = @get-selection-model!
    content = @state.content

    console.log selection-model

    if selection-model.multiline-selection
      if selection-model.normal-text-only
        @handle-character-change-for-multiline-normal-text selection-model, is-appending, character
      else
        @handle-character-change-for-multiline-formatted-text selection-model, is-appending, character
    else
      if selection-model.normal-text-only || is-appending || selection-model.nodes.0.node.first-child.data.length != 1
        @handle-character-change-for-single-line-normal-text selection-model, is-appending, character
      else
        @handle-character-change-for-single-line-formatted-text selection-model, is-appending, character

  build-config-object: (pre, cur) ->
    obj =
      child-nodes: {}

    obj.child-nodes[cur] = pre

    obj

  append-text: (character, position, length) ->
    position = if position == 0 then 0 else position || current-value.length
    length = length || 0
    text-content: $apply: (current-value) ->
      current-value = (current-value || '').split ''

      if current-value.length == 0
        current-value.push character
      else
        current-value.splice position, length, character

      current-value.join ''

  delete-text: (start, length) ->
    length = length || 1
    text-content: $apply: (current-value) ->
      current-value = current-value.split ''
      current-value.splice start, length

      current-value.join ''

  merge-nodes: (nodes, character) ->

    if character == 'Backspace' || character == 'Delete'
      character = ''

    text-first = nodes.0.node.first-child.data.substring 0, nodes.0.offset
    text-second = nodes.1.node.first-child.data.substring nodes.1.offset

    new-node = {
      tag-name: nodes.1.node.tag-name.to-lower-case!
      node-type: 1
      child-nodes: [
        node-type: 3
        text-content: text-first + character + text-second
      ]
    }

  split-node: (node, split-position) ->
    nodes = []

    nodes.push {
      tag-name: node.tag-name.to-lower-case!
      node-type: 1
      child-nodes: [{
        node-type: 3
        text-content: node.inner-text.substring(0, split-position)
      }]
    }

    nodes.push {
      tag-name: node.tag-name.to-lower-case!
      node-type: 1
      child-nodes: [{
        node-type: 3
        text-content: node.inner-text.substring(split-position)
      }]
    }

    nodes

}
