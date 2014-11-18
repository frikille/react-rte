require! <[
  path
  browserify
  envify
  gulp
  gulp-sass
  gulp-mocha
  gulp-util
  liveify
  uglifyify
  vinyl-source-stream
  watchify
  gulp-mocha
  gulp-livereload
]>

production = process.env.NODE_ENV == "production"

get-bundler = (instance) ->
  bundler = instance browserify './app/components/index.ls', { cache: {}, packageCache: {}, fullPaths: false, standalone: 'App', debug: true }
  bundler.transform liveify
  unless is-dev
    bundler.transform envify
    bundler.transform global: true, uglifyify
  #bundler.require 'react/addons'
  bundler.require './app/components/index.ls', expose: 'app'

is-dev = process.env.NODE_ENV isnt "production"
build-config =
  debug: is-dev

update = (bundler) ->
  gulp-util.log 'Bundling'
  bundler.bundle!
  .on 'error' gulp-util.log
  .on 'end' -> gulp-util.log 'Bundle complete'
  .pipe vinyl-source-stream 'index.js'
  .pipe gulp.dest 'public/scripts/'
  .pipe gulp-livereload!

gulp.task 'browserify', -> get-bundler! |> update

gulp.task 'watch' ->
  watch = watchify |> get-bundler
  watch.on 'update' -> update watch
  update watch

gulp.task 'default', ['browserify']
