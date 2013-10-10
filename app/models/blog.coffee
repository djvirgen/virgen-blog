mongoose = require "mongoose"

schema = new mongoose.Schema
  title:
    type: String
    default: 'Untitled Blog'

  url: String
    
  slug: String

  description: String

  content: String

  created:
    type: Date
    default: Date.now

  published:
    type: Date
    default: Date.now

  updated:
    type: Date
    default: Date.now

schema.index { slug: 1 }, { unique: true }

Blog = mongoose.model "Blog", schema

module.exports = Blog
