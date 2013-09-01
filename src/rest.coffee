Q = require 'q'
_ = require 'lodash'
rest = require 'restler'

# ìmprove!
promiseResolve = (response, data) ->
  return {
    code: response.statusCode
    response: response
    data: data
  }

wrapResponse = (rest) ->
  deferred = Q.defer()

  rest
    .on 'complete', (result, response) ->
      if result instanceof Error 
        deferred.reject promiseResolve response, result
      else if response.statusCode >= 300
        deferred.reject promiseResolve response, result
      else
        deferred.resolve promiseResolve response, result
    
    # Prevent EventEmitter memory leak
    ###
    .on 'error', (err, response) ->
      deferred.reject promiseResolve response, err
    
    .on 'abort', (err, response) ->
      deferred.reject promiseResolve response, err
    ###

  return deferred.promise

module.exports = class Rest

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
    _.extend @options, _.omit options, 'baseUrl' if options.username

  get: (path) ->
    return wrapResponse rest.get(@baseUrl + path, {
      headers: @options.headers
    })

  post: (path, options) -> 
    options = _.extend {}, @options, options
    
    return wrapResponse rest.post(@baseUrl + path, options)

  put: (path, options) ->
    options = _.extend {}, @options, options

    return wrapResponse rest.put(@baseUrl + path, options)

  del: (path, options) -> 
    options = _.extend {}, @options, options

    return wrapResponse rest.del(@baseUrl + path, options)

  head: (path, options) -> 
    options = _.extend {}, @options, options

    return wrapResponse rest.head(@baseUrl + path, options)

  patch: (path, options) -> 
    options = _.extend {}, @options, options

    return wrapResponse rest.patch(@baseUrl + path, options)
