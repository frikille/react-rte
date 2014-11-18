react = require 'react/addons'
headings = require './heading.ls'
keyhandlers = require './keyhandlers.ls'
selection = require './selection.ls'
formatting = require './formatting.ls'

{div, p, button} = react.DOM

merge-test =
  tag-name: 'div'
  node-type: 1
  child-nodes: [{
    tag-name: 'p'
    node-type: 1
    child-nodes: [{
      tag-name: 'span'
      node-type: 1
      child-nodes: [{
        node-type: 3
        text-content: 'Text 1'
      }]
    }, {
      node-type: 1
      tag-name: 'b'
      child-nodes: [{
        node-type: 1
        tag-name: 'i'
        child-nodes: [{
          node-type: 3
          text-content: 'Text 2'
        }]
      }, {
        node-type: 1
        tag-name: 'i'
        child-nodes: [{
          node-type: 3
          text-content: 'Text 3'
        }]
      }]
    }]
  }, {
    tag-name: 'p'
    node-type: 1
    child-nodes: [{
      tag-name: 'span'
      node-type: 1
      child-nodes: [{
        node-type: 3
        text-content: 'Text 4'
      }]
    }, {
      node-type: 1
      tag-name: 'u'
      child-nodes: [{
        node-type: 1
        tag-name: 'b'
        child-nodes: [{
          node-type: 1
          tag-name: 'i'
          child-nodes: [{
            node-type: 3
            text-content: 'Text 5'
          }]
        }, {
          node-type: 1
          tag-name: 'i'
          child-nodes: [{
            node-type: 3
            text-content: 'Text 6'
          }]
        }]
      }]
    }, {
      tag-name: 'u'
      node-type: 1
      child-nodes: [{
        node-type: 3
        text-content: 'Text 7'
      }]
    }]
  }, {
    tag-name: 'p'
    node-type: 1
    child-nodes: [{
      node-type: 1
      tag-name: 'i'
      child-nodes: [{
        node-type: 3
        text-content: 'Text 8'
      }]
    }, {
      node-type: 1
      tag-name: 'i'
      child-nodes: [{
        node-type: 3
        text-content: 'Text 9'
      }]
    }]
  }]


test-data =
  child-nodes: [{
    tag-name: 'p'
    node-type: 1
    child-nodes: [{
      node-type: 3
      text-content: '0123456789'
    }]
  }, {
    tag-name: 'p'
    node-type: 1
    child-nodes: [{
      node-type: 3
      text-content: 'Two paragrapghs!'
    }]
  }, {
    tag-name: 'p'
    node-type: 1
    child-nodes: [{
      node-type: 3
      text-content: 'And the third for testing'
    }]
  }, {
    tag-name: 'p'
    node-type: 1
    child-nodes: [{
      tag-name: 'span'
      node-type: 1
      child-nodes: [{
        node-type: 3
        text-content: 'Here is '
      }]
    }, {
      tag-name: 'b'
      node-type: 1
      child-nodes: [{
        node-type: 3
        text-content: 'the '
      }]
    }, {
      tag-name: 'i'
      node-type: 1
      child-nodes: [{
        tag-name: 'b'
        node-type: 1
        child-nodes: [{
          node-type: 3
          text-content: 'test '
        }]
      }, {
        tag-name: 'span'
        node-type: 1
        child-nodes: [{
          node-type: 3
          text-content: 'asdfghjk '
        }]
      }, {
        tag-name: 'u'
        node-type: 1
        child-nodes: [{
          tag-name: 'del'
          node-type: 1
          child-nodes: [{
            node-type: 3
            text-content: 'foobar '
          }]
        }]
      }, {
        tag-name: 'span'
        node-type: 1
        child-nodes: [{
          node-type: 3
          text-content: 'else'
        }]
      }]
    }]
  }, {
    tag-name: 'p'
    node-type: 1
    child-nodes: [{
      node-type: 3
      text-content: 'Last line not formatted text'
    }]
  }]
  node-type: 1
  tag-name: 'div'

module.exports = react.create-class do
  display-name: 'RTEditor'
  mixins: [selection, keyhandlers, headings, formatting]

  top-level-nodes: <[
    div
    p
    h1
    h2
    h3
    h4
    ul
    ol
  ]>

  get-initial-state: ->

    root-key = 'root'
    modified-data = @add-keys-to-tags test-data, root-key

    state =
      content: modified-data
      root-key:  root-key

    state

  add-keys-to-tags: (content, previous-level) ->
    previous-level = previous-level
    item = 0
    content.child-nodes.map (item, index) ~>
      if item.node-type != 3
        key = previous-level + '.' + index
        item['key'] = key
        @add-keys-to-tags item, key
      item

    content['key'] = previous-level

    content

  convert-to-json: ->

    c = document.query-selector '#contenteditable'

    result = @traverse c

  traverse: (node) ->

    child-nodes = for child-node in node.child-nodes
      if child-node.node-type == 1
        @traverse child-node
      else
        {
          node-type: child-node.node-type
          text-content: node.text-content
        }

    {
      node-type: node.node-type
      tag-name: node.tag-name.to-lower-case!
      child-nodes: child-nodes
    }

  update-state: (content, selection-el-tag-key, selection-start) ->

    @set-state {
      content: content
      selection-el-tag-key: selection-el-tag-key
      selection-start: selection-start || 0
    }

  on-key-press: (event) ->

    content = @state.content
    event.prevent-default!
    event.stop-propagation!

    if event.key == 'Enter'

      selection-model = @get-selection-model!

      if selection-model.multiline-selection
        if selection-model.normal-text-only
          @handle-enter-key-for-multiline-normal-text selection-model
        else
          @handle-enter-key-for-multiline-formatted-text selection-model
      else
        if selection-model.normal-text-only
          @handle-enter-key-for-single-line-normal-text selection-model
        else
          @handle-enter-key-for-single-line-formatted-text selection-model

    else
      @handle-character-change true, event.key

  on-key-down: (event) ->
    console.log event.key
    content = @state.content

    if event.key == 'Backspace' || event.key == 'Delete'
      event.prevent-default!
      event.stop-propagation!

      @handle-character-change false, event.key

  component-did-update: (prev-props, prev-state) ->

    range = document.create-range!
    selection = window.get-selection!

    if @state.selection-start == 'last-character'
      el = (document.query-selector "[data-tag-key='#{@state.selection-el-tag-key}']").last-child
      range.set-start el, el.length
    else
      el = (document.query-selector "[data-tag-key='#{@state.selection-el-tag-key}']")
      if el.first-child
        el = el.first-child
        range.set-start el, @state.selection-start
      else
        range.set-start-before el

    range.collapse true

    selection.remove-all-ranges!
    selection.add-range range

  component-did-mount: ->
    /*target = document.query-selector '#contenteditable'

    observer = new MutationObserver (mutations) ->
      mutations.for-each (mutation) ->
        1

    observer.observe target, attributes: true, child-list: true, character-data: true, subtree: true*/

  render-json-to-html-two: (node) ->
    if node.child-nodes && node.child-nodes.length == 1 && node.child-nodes[0].node-type == 3
      react.DOM[node.tag-name] 'data-tag-key': node.key, node.child-nodes[0].text-content
    else if node.tag-name == 'br'
      react.DOM[node.tag-name] null
    else
      react.DOM[node.tag-name] 'data-tag-key': node.key,
        node.child-nodes.map (child-node) ~>
          @render-json-to-html-two child-node

  run-test: ->
    @merge-siblings-formatting-nodes merge-test

  render: ->

    console.log @state.content

    div class-name: 'react-rte',
      div class-name: 'rte-toolbar',
        button on-click: @apply-heading-one, 'H1'
        button on-click: @apply-heading-two, 'H2'
        button on-click: @apply-heading-three, 'H3'
        button on-click: @apply-heading-four, 'H4'
        button on-click: @apply-bold-format, 'B'
        button on-click: @apply-italic-format, 'I'
        button on-click: @apply-underline-format, 'U'
        button on-click: @apply-striketrough-format, 'S'
      div id: 'contenteditable', style: {'white-space': 'pre'}, content-editable: true, on-key-press: @on-key-press, on-key-down: @on-key-down,
        @render-json-to-html-two @state.content
      button on-click: @convert-to-json, 'Convert'
      div class-name: 'result' style: display: 'block',
        @render-json-to-html-two @state.content


/*@state.content.child-nodes.map (item) ->
  react.DOM[item.tag-name] 'data-tag-key': item.key, do
    item.child-nodes.map (cn) ->
      if cn.node-type == 3
        cn.text-content
      else
        react.DOM[cn.tag-name] 'data-tag-key': cn.key, do
          cn.child-nodes.map (cn2) ->
            if cn2.node-type == 3
              cn2.text-content*/
