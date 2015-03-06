Redis = require 'co-subredis'
glob = require 'glob-to-regexp'
module.exports = class RedisMemoizer extends require 'co-memoizer'
  constructor: (options, memoizers...) ->
    unless @ instanceof RedisMemoizer
      return new RedisMemoizer options
    super.apply @, memoizers
    @redis = Redis options
    @prefix = "co-memoizer:#{options.prefix or Math.random()}:"
  memoize: (key, ttl, fn) ->
    value = try JSON.parse yield @redis.get "#{@prefix}#{key}"
    if @valid value then value else yield super key, ttl, fn
  value: (key, ttl, value) ->
    @redis.psetex "#{@prefix}#{key}", ttl, JSON.stringify value
  unmemoize: (keys) ->
    search = glob keys
    search.glob = keys
    super search
  remove: (keys) ->
    if Array.isArray(keys) or typeof keys is 'string'
      @redis.del keys
    else if keys instanceof RegExp
      @redis.keys keys.glob or "#{keys}", (keys) ->
        @redis.del keys
