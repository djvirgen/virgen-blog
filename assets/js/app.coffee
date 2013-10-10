"use strict"

module = angular.module 'blog', [
  'ngResource'
  'ngRoute'
  'ngSanitize'
]

# Config

module.config ($routeProvider, $locationProvider) ->
  $routeProvider.when "/",
    templateUrl: "/templates/bloglist.html"
    controller: "BlogListController"
    resolve:
      data: (Blog, $route) ->
        Blog.query(page: $route.current.params.page or 1).$promise

  $routeProvider.when "/login",
    templateUrl: "/templates/login.html"
    controller: "UserLoginController"
    resolve:
      currentUser: "currentUser"

  $routeProvider.when "/blog",
    templateUrl: "/templates/bloglist.html"
    controller: "BlogListController"
    resolve:
      data: (Blog, $route) ->
        Blog.query(page: $route.current.params.page or 1).$promise

  $routeProvider.when "/blog/new",
    templateUrl: "/templates/blogedit.html"
    controller: "BlogEditController"
    resolve:
      blog: (Blog, $route) -> new Blog
      currentUser: "currentUser"

  $routeProvider.when "/blog/:slug/edit",
    templateUrl: "/templates/blogedit.html"
    controller: "BlogEditController"
    resolve:
      blog: (Blog, $route) -> Blog.get slug: $route.current.params.slug
      currentUser: "currentUser"

  $routeProvider.when "/blog/:slug",
    templateUrl: "/templates/blogshow.html"
    controller: "BlogShowController"
    resolve:
      blog: (Blog, $route) -> Blog.get slug: $route.current.params.slug
      currentUser: "currentUser"

  $locationProvider.html5Mode true

module.value 'config',
  disqus:
    shortname: 'virgentech'

module.run ($rootScope, config) -> $rootScope.config = config

# Services

module.factory "Blog", ($resource) ->
  $resource "/resource/blog/:slug",
    slug: "@slug"
  ,
    query:
      method: 'GET'
      # result.blogs contains list, other properties used for hypermedia
      isArray: false

module.factory "User", ($resource) ->
  methods =
    login:
      method: 'POST'
      url: '/resource/user/login'
    logout:
      method: 'POST'
      url: '/resource/user/logout'
    current:
      method: 'GET'
      url: '/resource/user/current'

  map = username: "@username"

  $resource "/resource/user/:username", map, methods

module.factory "currentUser", (User) ->
  User.current().$promise.then (user) -> user or new User

module.factory "paginator", ->
  class Paginator
    constructor: (@total, @page, @perPage) ->
      @totalPages = Math.ceil @total / @perPage
    getPages: -> [1..@totalPages]
    next: -> @page + 1
    previous: -> @page - 1
    hasPrevious: -> @page > 1
    hasNext: -> @page < @totalPages

  (total, page, perPage) -> new Paginator total, page, perPage

module.factory "cursor", ($document, $rootScope) ->
  class Cursor
    constructor: ->
      @screenX = 0
      @screenY = 0
      @x = 0
      @y = 0
      @buttonPressed = false

      $document.on 'mousemove', ($event) =>
        @screenX = $event.screenX
        @screenY = $event.screenY
        @x = $event.clientX
        @y = $event.clientY

      $document.on 'click', ($event) => $rootScope.$broadcast 'document:click'
      $document.on 'mousedown', ($event) => @buttonPressed = true
      $document.on 'mouseup', ($event) => @buttonPressed = false

  new Cursor

module.factory "head", ->
  class Head
    constructor: (@baseTitle = 'VirgenTech Blog') -> @setTitle()

    setTitle: (title = '') ->
      @title = if title.length then "#{title} | #{@baseTitle}" else @baseTitle

  new Head

# Directives

module.directive 'virgenCoffeeCompile', ($timeout) ->
  scope:
    coffee: '=virgenCoffeeCompile'
  template: '<div class="coffee-script-container"><span class="coffee-script-toggler" ng-click="toggle()">Coffee -&gt; JS</span><pre ng-if="isCoffee">{{ coffee }}</pre><pre ng-if="!isCoffee">{{ js }}</pre></div>'
  link: (scope, element, attrs) ->
    scope.js = CoffeeScript.compile scope.coffee
    scope.isCoffee = true
    scope.toggle = -> scope.isCoffee = !scope.isCoffee

module.directive 'virgenCompileUnsafe', ($compile) ->
  (scope, element, attrs) ->
    scope.$watch attrs.virgenCompileUnsafe, (value) ->
      element.html value
      $compile(element.contents())(scope)

# Usage: <div virgen-disqus shortname="'my_shortname'" identifier="'my_identifier'"></div>
module.directive 'virgenDisqus', ($location, $window, $document) ->
  scope:
    identifier: '='
    shortname: '='
  link: (scope, element, attr) ->
    # Loads Disqus comments
    load = ->
      # Disqus requires these global variables to be set
      $window.disqus_shortname = scope.shortname
      $window.disqus_identifier = scope.identifier
      dsq = document.createElement 'script'
      dsq.type = 'text/javascript'
      dsq.async = true
      dsq.src = "//#{scope.shortname}.disqus.com/embed.js"
      $document.find('head').append dsq

    # Resets Disqus comments for page navigation
    reset = ->
      $window.DISQUS.reset
        reload: true
        config: -> @page.identifier = scope.identifier

    element.attr 'id', 'disqus_thread'
    $window.disqus_element = element
    if $window.DISQUS? then reset() else load()

module.directive 'virgenDemo', ($http) ->
  scope:
    dir: '@virgenDemo'
  replace: true
  templateUrl: '/templates/demo.html'
  link: (scope, element, attrs) ->
    scope.$watch attrs.files, (filenames) ->
      files = []
      js = 0

      done = ->
        scope.files = files
        scope.file = scope.files[0]

      processScript = ->
        --js
        scope.$apply done() unless js > 0

      angular.forEach filenames, (name) ->
        file =
          name: name,
          type: name.match(/\.([a-z]+)$/)[1]
          url: "/demos/#{scope.dir}/#{name}"

        $http.get(file.url).then (contents) -> file.contents = contents.data
        
        if 'js' == file.type
          js++
          s = document.createElement 'script'
          s.type = 'text/javascript'
          s.src = file.url
          s.onload = processScript
          (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild s

        files.push file

      done() unless js > 0

    scope.show = (file) -> scope.file = file
    scope.isShown = (file) -> scope.file == file

module.directive 'virgenProcessing', ($window, $timeout) ->
  (scope, element, attrs) ->
    scope.$sketch = new Processing element[0], scope[attrs.virgenProcessing]

    onWindowResize = ->
      scope.$sketch.offsetLeft = element[0].offsetLeft
      scope.$sketch.offsetTop = element[0].offsetTop

    $timeout onWindowResize

    angular.element($window).on 'resize', onWindowResize

    scope.$on '$destroy', ->
      angular.element($window).off 'resize', onWindowResize

# Controllers

module.controller "HeaderSketchController", ($scope, cursor) ->
  class Shape
    constructor: (@sketch, @x, @y, @size, @hue) ->
      @baseSize = @size
      @delay = 10
      @baseX = @x
      @baseY = @y

    nudgeTo: (x, y) ->
      @x += (x - @x) / @delay
      @y += (y - @y) / @delay

    bumpHue: (amount = 0.5) ->
      @hue += amount
      @hue %= 255 if @hue > 255

    grow: (maxSize) ->
      maxSize = @baseSize if maxSize < @baseSize
      @size += (maxSize - @size) / @delay

    shrink: ->
      @size += (@baseSize - @size) / @delay
      @size = @baseSize if @size < @baseSize

    draw: ->
      @x += (@baseX - @x) / @delay
      @y += (@baseY - @y) / @delay
      @bumpHue()

  $scope.sketch = (sketch) ->
    shapes = []
    saturation = 255
    targetSaturation = 255

    sketch.setup = ->
      sketch.smooth()
      sketch.colorMode sketch.HSB, 255
      sketch.strokeCap sketch.ROUND
      sketch.strokeJoin sketch.ROUND
      sketch.size 1000, 300
      sketch.frameRate 30

      for i in [-2..52]
        do (i) ->
          for j in [-2..22]
            do (j) ->
              y = j * 20
              x = i * 20
              x += 10 if j % 2 == 0
              shapes.push new Shape sketch, x, y, 22, i - j / 2 + 120

    sketch.draw = ->
      sketch.background 0
      bleed = 300
      sketch.rectMode sketch.CENTER
      saturation += (targetSaturation - saturation) / 15
      ts = new Date().getTime()
      randomize() if cursor.buttonPressed

      for shape in shapes
        shape.draw()
        x2 = Math.pow shape.x - cursor.x + sketch.offsetLeft, 2
        y2 = Math.pow shape.y - cursor.y, 2
        dist = (Math.sqrt x2 + y2) / 6
        maxSize = 80 - dist
        shape.grow maxSize
        opacity = sketch.map(maxSize, shape.baseSize, 200, 150, 255)
        sketch.stroke shape.hue, saturation, 255, opacity
        sketch.fill shape.hue, saturation, 255, opacity * 0.5
        x = shape.x
        y = shape.y
        sketch.strokeWeight shape.size / 40
        offset = Math.sin(ts / 2000 + ((x - y / 2) / 200))
        sizeOffset = offset * 10
        size = sizeOffset + shape.size
        positionOffset = offset * 15
        sketch.ellipse x + positionOffset, y - positionOffset, size, size

    randomize = ->
      for shape in shapes
        xDist = shape.x - cursor.x + sketch.offsetLeft
        yDist = shape.y - cursor.y
        x2 = Math.pow xDist, 2
        y2 = Math.pow yDist, 2
        dist = (Math.sqrt x2 + y2)
        nudgeBy = Math.max(0, 500 - dist)

        nudgeX = Math.random() * nudgeBy - (nudgeBy / 2)
        nudgeY = Math.random() * nudgeBy - (nudgeBy / 2)

        nudgeX /= 2
        nudgeY /= 2
        shape.size += nudgeBy / 200
        shape.nudgeTo shape.x + nudgeX, shape.y + nudgeY

    $scope.$on 'document:click', ->
      # saturation = 127
      # randomize()

module.controller "HeadController", ($scope, head) ->
  $scope.head = head

module.controller "UserAuthController", ($scope, $location, currentUser) ->
  currentUser.then (user) ->
    $scope.user = user
    $scope.logout = -> $scope.user.$logout -> $location.path '/'

module.controller "UserLoginController", ($scope, $location, currentUser, head) ->
  $location.path '/' if currentUser.id # already logged in
  head.setTitle 'Login'
  $scope.user = currentUser
  $scope.login = -> $scope.user.$login (user) -> $location.path '/'

module.controller "BlogListController", ($scope, $q, data, paginator, head) ->
  head.setTitle 'All Blog Entries'
  $scope.blogs = data.blogs
  $scope.paginator = paginator data.total, data.page, data.perPage

module.controller "BlogShowController", ($scope, blog, currentUser, head) ->
  $scope.blog = blog
  $scope.blog.$promise.then -> head.setTitle $scope.blog.title
  $scope.currentUser = currentUser

module.controller "BlogEditController", ($scope, $location, $q, currentUser, blog) ->
  $location.path '/' unless currentUser.id?
  $scope.blog = blog
  $scope.blog.$promise.then ->
    $scope.blog.newSlug = blog.slug # To change the slug, we must POST to the old slug
    console.log 'running controller', $scope.blog

module.controller "SidebarController", ($scope, Blog) ->
  Blog.query(page: 1, limit: 5).$promise.then (data) ->
    $scope.latest = data.blogs

  $scope.save = ->
    $scope.blog.$save (blog) -> $location.path blog.url
