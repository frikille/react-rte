require! <[
  fs
  path
]>

_ = require 'lodash'
Promise = require 'bluebird'

readdir-async = Promise.promisify fs.readdir
lstat-async = Promise.promisify fs.lstat

read-dir = (dir, options, depth, messages) ->
  depth = depth || 0
  messages = messages || {
    errors: []
    warns: []
  }

  options = _.extend index: true, options

  if depth > 1
  then
    Promise.resolve null
  else
    (readdir-async dir).then (files) ->
      files = files || []

      Promis.reduce files, ((results, file) ->
        fpath = path.join dir, file

        (lstat-async fpath).then((result) ->
          if result.is-directory!
            read-dir fpath, options, depth + 1, messages
          else if depth == 1 && file == 'package.json'
            parse-package-json fpath, messages
          else
            fpath

        ).then (result) ->
          results[file] = result

          results

      ), {}

read-all = (dir, options, depth) ->
  messages =
    errors: []
    warns: []

  (read-dir dir, options, depth, messages).then( (paths) ->
    paths
  ).catch ->
    _messages: messages

module.exports =
  read-all: read-all
  read-dir: read-dir
