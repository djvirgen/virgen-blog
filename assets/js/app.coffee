"use strict"

module = angular.module("blog", ["ngResource", "ngRoute", "ngSanitize"])

module.factory "Blog", ($resource) ->
  $resource "/resource/blog/:slug",
    slug: "@slug"

module.controller "BlogListController", ($scope, blogs) -> $scope.blogs = blogs

module.controller "BlogShowController", ($scope, blog) -> $scope.blog = blog

module.controller "BlogCreateController", ($scope, $location, Blog) ->
  $scope.blog = new Blog

  $scope.save = ->
    $scope.blog.$save (blog) -> $location.path blog.url

module.config ($routeProvider, $locationProvider) ->
  $routeProvider.when "/",
    templateUrl: "/templates/bloglist.html"
    controller: "BlogListController"
    resolve:
      blogs: (Blog) -> Blog.query()

  $routeProvider.when "/blog/new",
    templateUrl: "/templates/blogcreate.html"
    controller: "BlogCreateController"

  $routeProvider.when "/blog/:slug",
    templateUrl: "/templates/blogshow.html"
    controller: "BlogShowController"
    resolve:
      blog: (Blog, $route) -> Blog.get slug: $route.current.params.slug

  $locationProvider.html5Mode true
