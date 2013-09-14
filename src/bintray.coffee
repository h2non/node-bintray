_ = require "lodash"
Rest = require "./rest"
common = require "./common"
sendFile = require("restler").file

module.exports = class Bintray

  @apiBaseUrl = "https://api.bintray.com"
  @downloadsHost = "http://dl.bintray.com"
  @apiVersion = "1.0"
  
  config:
    debug: false
    baseUrl: Bintray.apiBaseUrl

  constructor: (options = {}) ->
    @rest = new Rest _.extend @config, _.assign options, { password: options.apikey }
    { @organization, @repository } = @config
    @endpointBase = if @organization? and @repository? then "#{@organization}/#{@repository}" else ""

  setEndpointBase: ->
    @endpointBase = "#{@organization}/#{@repository}"

  selectRepository: (repository) -> 
    @repository = repository
    @setEndpointBase()

  selectOrganization: (organization) ->
    @organization = organization
    @setEndpointBase()

  getRepositories: -> 
    endpoint = "/repos/#{@organization}"
    return @rest.get endpoint

  getRepository: ->
    endpoint = "/repos/#{@endpointBase}"
    return @rest.get endpoint

  getPackages: (start = 0, startName) -> 
    endpoint = "/repos/#{@endpointBase}/packages?start_pos=#{start}" + (if startName then "&start_name=" + startName else "")
    return @rest.get endpoint

  getPackage: (name) -> 
    endpoint = "/packages/#{@endpointBase}/#{name}"
    return @rest.get endpoint

  createPackage: (packageObj) -> 
    endpoint = "/packages/#{@endpointBase}" 
    return @rest.post endpoint, {
      data: JSON.stringify packageObj
    }

  deletePackage: (name) -> 
    endpoint = "/packages/#{@endpointBase}/#{name}"
    return @rest.del endpoint

  updatePackage: (name, packageObj) -> 
    endpoint = "/packages/#{@endpointBase}/#{name}"
    return @rest.patch endpoint, {
      data: JSON.stringify packageObj
    }

  getPackageVersion: (name, version = "_latest") -> 
    endpoint = "/packages/#{@endpointBase}/#{name}/versions/#{version}" 
    return @rest.get endpoint

  getPackageUrl: (pkgname, repository) ->
    deferred = Rest.defer()

    @searchFile(pkgname, repository)
      .then (response) ->
        notFound = ->
          response.code = 404
          response.status = 'Not Found'
          return response

        { data } = response
        if response isnt 200 or _.isEmpty data
          deferred.reject notFound()
        else
          if _.isArray data
            data = data[0]
            if data
              response.data = { url: "#{Bintray.downloadsHost}/#{data.owner}/#{data.repo}/#{data.path}" } 
              deferred.resolve response
            else
              deferred.reject notFound()
          else
            deferred.reject notFound()
      , (error) ->
        deferred.reject error

    return deferred.promise
 
  createPackageVersion: (name, versionObj) -> 
    endpoint = "/packages/#{@endpointBase}/#{name}/versions"
    return @rest.post endpoint, {
      data: JSON.stringify versionObj
    }

  deletePackageVersion: (name, version) -> 
    endpoint = "/packages/#{@endpointBase}/#{name}/versions/#{version}"
    return @rest.del endpoint

  updatePackageVersion: (name, version, versionObj) -> 
    endpoint = "/packages/#{@endpointBase}/#{name}/versions/#{version}"
    return @rest.post endpoint, {
      data: JSON.stringify versionObj
    }

  getPackageAttrs: (name, attributes) -> 
    endpoint = "/packages/#{@endpointBase}/#{name}/attributes?names=#{attributes}"
    return @rest.get endpoint

  getVersionAttrs: (name, attributes, version = '_latest') -> 
    endpoint = "/packages/#{@endpointBase}/#{name}/versions/#{version}/attributes?names=#{attributes}"
    return @rest.get endpoint

  setPackageAttrs: (name, attributesObj, version) -> 
    endpoint = "/packages/#{@endpointBase}/#{name}"

    if version
      endpoint += "/versions/#{version}/attributes"
    else
      endpoint += "/attributes"

    return @rest.post endpoint, {
      data: JSON.stringify attributesObj
    }

  updatePackageAttrs: (name, attributesObj, version) -> 
    endpoint = "/packages/#{@endpointBase}/#{name}"

    if version
      endpoint += "/versions/#{version}/attributes"
    else
      endpoint += "/attributes"

    return @rest.patch endpoint, {
      data: JSON.stringify attributesObj
    }

  deletePackageAttrs: (name, names, version) -> 
    endpoint = "/packages/#{@endpointBase}/#{name}"

    if version
      endpoint += "/versions/#{version}/attributes"
    else
      endpoint += "/attributes"

    endpoint += "?names=#{names}"

    return @rest.del endpoint

  searchRepository: (name, description) -> 
    endpoint = "/search/repos?"
    endpoint += "name=#{name}" if name
    endpoint += "&desc=#{description}" if description
    return @rest.get endpoint

  searchPackage:  (name, description, organization, repository) ->
    endpoint = "/search/packages?"
    endpoint += "name=#{name}" if name
    endpoint += "&desc=#{description}" if description
    endpoint += "&organization=#{organization}" if organization?
    endpoint += "&repo=#{repository}" if repository?
    return @rest.get endpoint

  searchUser: (name) -> 
    endpoint = "/search/users?name=#{name}"
    return @rest.get endpoint

  searchAttributes: (attributesObj, name) -> 
    endpoint = "/search/attributes/#{@endpointBase}"

    if name
      endpoint += "/#{name}/versions"

    return @rest.post endpoint, {
      data: JSON.stringify attributesObj
    }

  searchFile: (name, repository) -> 
    endpoint = "/search/file?name=#{encodeURIComponent(name)}"
    endpoint += "&repo=#{repository}" if repository
    return @rest.get endpoint

  searchFileChecksum: (hash, repository) -> 
    endpoint = "/search/file?sha1=#{name}"
    endpoint += "&repo=#{repository}" if repository
    return @rest.get endpoint

  getUser: (username) ->
    endpoint = "/users/#{username}"
    return @rest.get endpoint

  getUserFollowers: (username, startPosition = 0) -> 
    endpoint = "/users/#{username}/followers"
    endpoint += "?startPosition=#{startPosition}" if startPosition
    return @rest.get endpoint

  uploadPackage: (name, version, filePath, remotePath = '/', publish = false, explode = false, mimeType = "application/octet-stream") -> 
    endpoint = "/content/#{@endpointBase}/#{name}/#{version}/#{remotePath}" + (if publish then ";publish=1" else "") + (if explode then ";explode=1" else "")
    return @rest.put endpoint, {
      multipart: true
      data: 
        "package[message]": "Package upload: #{name} (#{version})"
        "package[file]": sendFile filePath, null, common.getFileSize(filePath), null, mimeType
    }

  publishPackage: (name, version, discard = false) -> 
    endpoint = "/content/#{@endpointBase}/#{name}/#{version}/publish"
    return @rest.post endpoint, {
      data: JSON.stringify { discard: discard }
    }

  mavenUpload: (name, version, filePath, remotePath = '/', publish = true, explode = false, mimeType = "application/octet-stream") -> 
    endpoint = "/maven/#{@endpointBase}/#{name}/#{remotePath}" + (if publish then ";publish=1" else "") + (if explode then ";explode=1" else "")
    return @rest.put endpoint, {
      multipart: true
      data: 
        "package[message]": "Maven package upload: #{name} (#{version})"
        "package[file]": sendFile filePath, null, common.getFileSize(filePath), null, mimeType
    }

  getWebhooks: (repository = '') -> 
    endpoint = "/webhooks/#{@organization}/#{repository}"
    return @rest.get endpoint

  createWebhook: (pkgname, configObj) -> 
    endpoint = "/webhooks/#{@endpointBase}/#{pkgname}"
    return @rest.post endpoint, {
      data: JSON.stringify config
    }

  testWebhook: (pkgname, version, configObj) -> 
    endpoint = "/webhooks/#{@endpointBase}/#{pkgname}/#{version}"
    hmac = require("crypto").createHmac("md5", @config.password).digest("hex");

    return @rest.post endpoint, {
      headers: {
        'Content-Type': 'application/json'
        'User-Agent': 'Node.js Bintray client',
        'X-Bintray-WebHook-Hmac': hmac
      },
      data: JSON.stringify configOBj
    }

  deleteWebhook: (pkgname) -> 
    endpoint = "/webhooks/#{@endpointBase}/#{pkgname}"
    return @rest.del endpoint

  singFile: (remotePath, passphrase) ->
    endpoint = "/gpg/@{@endpointBase}/#{remotePath}" + (if passphrase then "?passphrase=#{passphrase}" else "")
    return @rest.post endpoint

  singVersion: (pkgname, version, passphrase) ->
    endpoint = "/gpg/@{@endpointBase}/#{pkgname}/versions/#{version}" + (if passphrase then "?passphrase=#{passphrase}" else "")
    return @rest.post endpoint

  getRateLimit: ->
    return @rest.rateLimit

  getRateLimitRemaining: ->
    return @rest.rateRemaining
