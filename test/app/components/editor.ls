react = require 'react/addons'
/*editor = require '../../../main'*/
editor = require './editor/editor.ls'

{div, p} = react.DOM

module.exports = react.create-class do
  display-name: 'RTEditor'
  get-initial-state: ->
    content: 'content'
  render: ->
    div class-name: 'react-content',
      editor null
