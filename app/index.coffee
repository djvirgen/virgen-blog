express = require 'express'
connectCoffeeScript = require 'connect-coffee-script'
app = express()

app.set 'views', "#{__dirname}/views"
app.set 'view engine', 'jade'
app.use express.bodyParser()
app.use connectCoffeeScript
    src: "#{__dirname}/../assets"
    dest: "#{__dirname}/../public"
app.use express.static "#{__dirname}/../public"

ngApp = (req, res) ->
  res.render 'app'

blogs = [
    title: 'title 1'
    url: '/blog/title-1'
    slug: 'title-1'
    content: '<strong>foo</strong> bar 1'
  ,
    title: 'title 2'
    url: '/blog/title-2'
    slug: 'title-2'
    content: '<strong>foo</strong> bar 2'
]

app.get '/', ngApp
app.get '/blog', ngApp
app.get '/blog/*', ngApp

# Create new blog
app.post '/resource/blog', (req, res) ->
  blog = req.body
  blog.slug = req.body.title.replace /[^a-zA-Z0-1+]/g, '-'
  blog.url = "/blog/#{blog.slug}"
  blogs.unshift blog
  res.send blog

app.get '/resource/blog', (req, res) ->
  res.send blogs

app.get '/resource/blog/:slug', (req, res) ->
  for blog in blogs
    do (blog) ->
      res.send blog if blog.slug == req.params.slug

app.listen 3000
