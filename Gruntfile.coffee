mongoose = require 'mongoose'
async = require 'async'
config = new (require 'configgles')("#{__dirname}/config/app.yaml", process.env.NODE_ENV || 'development')

module.exports = (grunt) ->
  log = grunt.log

  grunt.registerTask 'default', 'Default', () ->
    log.writeln('default task').ok()

  grunt.registerTask 'dbclear', 'Clear Database', () ->
    done = @async()
    mongoose.connect process.env.DB or config.db, (err) ->
      return "Error: #{err}" if err
      mongoose.connection.db.collections (err, collections) ->
        count = collections.length
        log.writeln "Clearing #{count} collections in db #{config.db}"
        return done() if count == 0
        for collection in collections
          do (collection) ->
            if collection.collectionName == 'system.users'
              log.writeln "Skipping system.users"
              --count
              done() unless count
              return
              
            collection.remove ->
              log.writeln "Cleared collection #{collection.collectionName}"
              unless --count
                log.writeln "All collections cleared!"
                done()

  grunt.registerTask 'dbpopulate', 'Populate Database', () ->
    done = @async()
    fixtures = require 'mongoose-fixtures'
    env = process.env.NODE_ENV or 'development'
    fixture = "#{process.cwd()}/db/seed/#{env}.coffee"
    log.writeln "Loading fixture #{fixture}"
    fixtures.load fixture, ->
      log.writeln "Fixture loaded into db!"
      done()

  grunt.registerTask 'dbinit', ['dbclear', 'dbpopulate']
