YAML = require 'yamljs'

ObjectId = require('mongodb').ObjectID
BlogModel = require "#{process.cwd()}/app/models/blog"

blogData = YAML.load "#{process.cwd()}/db/seed/virgentech-blog.yaml"

console.log "Loading #{blogData.length} blog entries..."

Blog = {}
for blog in blogData
  console.log "Loading \"#{blog.title}\"..."
  Blog["blog-#{blog.url}"] =
    title: blog.title
    slug: blog.url
    url: "/blog/#{blog.url}"
    description: blog.description
    content: blog.content
    created: blog.created
    published: blog.published
    updated: blog.updated

module.exports.Blog = Blog
