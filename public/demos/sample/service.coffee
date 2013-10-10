class MyService
  constructor: (@foo, @bar) ->

  myMethod: ->
    console.log @foo, @bar
