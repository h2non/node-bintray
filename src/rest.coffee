Q = require 'q'
_ = require 'lodash'
rest = require 'restler'
status = require './status'
log = require('./common').log

promiseResponse = (response, data) ->
  code = response.statusCode
  return {
    code: code
    status: status[code]
    response: response
    data: data
  }

module.exports = class Rest
  
  @defer = Q.defer

  baseUrl: null
  rateLimit: 300
  rateRemaining: 300

  options:
    headers: 
      'Content-Type': 'application/json'
      'User-Agent': 'Node.js Bintray client'
      'Content-Length': 0

  constructor: (options) -> 
    @baseUrl = options.baseUrl
    @debug = options.debug or false

    _.extend @options, _.omit options, 'baseUrl', 'debug', 'apikey'

  getRateLimit: (response) ->
    headers = response.headers
    
    if headers['x-ratelimit-limit']
      @rateLimit = headers['x-ratelimit-limit']
    if headers['x-ratelimit-remaining']
      @rateRemaining = headers['x-ratelimit-remaining']
    
    return @rateRemaining

  wrapResponse: (rest) =>
    deferred = Q.defer()

    log "[#{rest.options.method}] [#{rest.options.username or 'NoAuth'}] #{rest.url.path}".grey if @debug

    rest
      .on 'complete', (result, response) =>
        rateLimit = @getRateLimit response
        log "[#{response.statusCode}] [#{rateLimit or 'Unknown'}] #{response.req.path}".green if @debug

        if rateLimit is 0
          response.statusCode = 300
          deferred.reject promiseResponse response, 'You have exceeded your API call limit'
        else if result instanceof Error 
          deferred.reject promiseResponse response, response.raw
        else if response.statusCode >= 300
          deferred.reject promiseResponse response, result
        else
          deferred.resolve promiseResponse response, result

    return deferred.promise

  setAuth: (username, password) ->
    _.extend @options, { username: username, password: password }

  get: (path, options) ->
    options = _.extend {}, @options, options if options
    return @wrapResponse rest.get @baseUrl + path, options || @options

  post: (path, options) -> 
    options = _.extend {}, @options, options
    return @wrapResponse rest.post @baseUrl + path, options

  put: (path, options) ->
    options = _.extend {}, @options, options
    return @wrapResponse rest.put @baseUrl + path, options

  del: (path, options) -> 
    options = _.extend {}, @options, options
    return @wrapResponse rest.del @baseUrl + path, options

  head: (path, options) -> 
    options = _.extend {}, @options, options
    return @wrapResponse rest.head @baseUrl + path, options

  patch: (path, options) -> 
    options = _.extend {}, @options, options
    return @wrapResponse rest.patch @baseUrl + path, options
