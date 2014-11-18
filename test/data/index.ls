database = require '../config/database'
sequence = require 'when/sequence'
schema = require '../config/schema'
Promise = require 'bluebird'

{keys} = require 'prelude-ls'


create-table = (table-name, columns) ->
  database.schema.create-table table-name, (table) ->
    column-names = keys columns

    column-names.for-each (name) ->

      column-def = columns[name]

      if column-def.type == 'text' && column-def.has-own-property 'fieldtype'
        column = table[column-def['type']](name, column-def.fieldtype)
      else if column-def.type == 'string' && column-def.has-own-property 'maxlength'
        column = table[column-def['type']](name, column-def.maxlength)
      else
        column = table[column-def['type']](name)

      if column-def.has-own-property 'nullable' && column-def.nullable == true
        column.nullable!
      else
        column.not-nullable!

      if column-def.has-own-property 'primary' && column-def.primary == true
        column.primary!

      if column-def.has-own-property 'unique' && column-def.unique == true
        column.unique!

      if column-def.has-own-property 'unsinged' && column-def.unsigned == true
        column.unique!

      if column-def.has-own-property 'defaultTo'
        column.default-to column-def.default-to


create-tables = ->

  tables = (keys schema).map (item) ->
    create-table item, schema[item]

  Promise.all tables

(create-tables!).then( ->
  console.log 'Tables created'
  process.exit 0
).catch (err) ->
  throw err
