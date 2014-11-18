require! <[
  ./lib/react-view-engine
  ./app/routes
  body-parser
  express
  jade
  fs
  path
  express-session
  cookie-session
  cookie-parser
  morgan
]>


app = express!

app.use express.static path.join __dirname, 'public'
app.use body-parser.urlencoded extended: true
app.use body-parser.json!
app.use cookie-parser!


app.locals.title = 'xx'

is-dev = (app.get 'env') is 'development'

app.set 'views', path.join __dirname, 'app/components'
app.set 'view engine', 'ls'
app.engine 'ls' react-view-engine do
  layout: jade.compile do
    fs.read-file-sync do
      path.join __dirname, 'app/views/layout.jade'
      'utf8'

app.use routes

module.exports = app
