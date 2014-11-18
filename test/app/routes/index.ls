require! <[
  express
  react
  ./common
]>

module.exports = routes = express.Router!

home = (req, res, next) ->
  res.locals.title = 'React Rich Text Editor'

  res.render 'editor',
    props:
      page: 'editor'


routes.get '/' common.base-props, home

routes.get '/test' common.base-props, (req, res, next) ->
  res.locals.title = 'React Rich Text Editor'

  res.render 'editor',
    props:
      page: 'editor'
