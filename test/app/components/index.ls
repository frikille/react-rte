require! 'react'

get = document.document-element~get-attribute
props-json = get 'data-props'
props = JSON.parse props-json if props-json

components =
  'editor': -> require './editor.ls'
  # needed for browserify's static analysis

module.exports.start = ->
  mount-point = document.get-element-by-id \content
  self.React = react
  if mount-point?
    component = components[mount-point.className]!
    instance = component props
    self.React.render-component instance, mount-point
    html = (document.get-elements-by-tag-name 'html')[0]
    html.remove-attribute 'data-props'
