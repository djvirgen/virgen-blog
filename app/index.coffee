express = require 'express'
connectCoffeeScript = require 'connect-coffee-script'
stylus = require 'stylus'
deepExtend = require 'deep-extend'
app = express()
Blog = require './models/blog'

app.set 'views', "#{__dirname}/views"
app.set 'view engine', 'jade'
app.use express.bodyParser()
app.use stylus.middleware
  src: "#{__dirname}/../assets"
  dest: "#{__dirname}/../public"
  compile: (str, path, fn) ->
    stylus(str)
    .set('filename', path)
    .set('compress', true)
app.use connectCoffeeScript
    src: "#{__dirname}/../assets"
    dest: "#{__dirname}/../public"
app.use express.static "#{__dirname}/../public"

app.config = new (require 'configgles')("#{__dirname}/../config/app.yaml", process.env.NODE_ENV || 'development')

mongoose = require 'mongoose'
mongoose.connect process.env.MONGOLAB_URI or app.config.db, (err) ->
  console.log "DB Connect Error: #{err}" if err?

ngApp = (req, res) -> res.render 'app'

app.get '/', ngApp

# User Login
currentUser = null

app.post '/resource/user/login', (req, res) ->
  if req.body.username is app.config.auth.username and req.body.password is app.config.auth.password
    currentUser = id: 1, username: app.config.auth.username
    res.send currentUser
  else
    res.send error: 'bad password', 401

app.post '/resource/user/logout', (req, res) ->
  currentUser = null
  res.send {}

# Current User
app.get '/resource/user/current', (req, res) -> res.send currentUser

# Create new blog
app.post '/resource/blog', (req, res) ->
  res.send error: 'Unauthorized', 401 unless currentUser?
  blog = req.body
  blog.slug = req.body.title.replace /[^a-zA-Z0-1+]/g, '-'
  blog.url = "/blog/#{blog.slug}"
  blogs.unshift blog
  res.send blog

# Get all blogs
app.get '/resource/blog', (req, res) ->
  page = parseInt(req.query.page) || 1
  limit = req.query.limit || 20
  start = (page - 1) * limit
  end = start + limit

  done = (err, blogs) ->
    res.send
      blogs: blogs
      page: page
      perPage: limit
      total: 40 # TODO: Determine actual number of entries

  Blog.find()
  .limit(limit)
  .skip(start)
  .sort(created: -1)
  .exec(done)

# Get a blog
app.get '/resource/blog/:slug', (req, res) ->
  Blog.findOne slug: req.params.slug, (err, blog) -> res.send blog

# Save a blog
app.post '/resource/blog/:slug', (req, res) ->
  # TODO: Authenticate/authorize before proceeding!!
  # TODO: Update DB
  found = false
  for blog in blogs
    do (blog) ->
      if blog.slug == req.params.slug
        found = blog
        deepExtend found, req.body
        if found.newSlug
          found.slug = found.newSlug
          found.url = "/blog/#{found.newSlug}" if found.newSlug
          delete found.newSlug

  return res.send error: 'No blog found', 404 unless found?
  res.send found

app.get '*', (req, res) -> res.redirect "/##{req.path}"

app.listen process.env.PORT or 3000
