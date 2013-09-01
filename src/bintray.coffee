fs = require "fs" 
Rest = require "./rest"
sendFile = require("restler").file

getFileSize = (path) ->
  fs.statSync(path).size

module.exports = class Bintray

  @apiBaseUrl = "https://api.bintray.com"
  @apiVersion = "1.0"

  constructor: (username, apiToken, subject, repository) -> 

    throw new Error 'Username param required' if !username
    throw new Error 'API token param required' if !apiToken

    @rest = new Rest { baseUrl: Bintray.apiBaseUrl, username: username, password: apiToken }
    @subject = subject
    @repository = repository
    @endpointBase = "#{subject}/#{repository}"

  selectRepository: (repository) -> 
    @repository = repository
    @endpointBase = "#{@subject}/#{@repository}"

  selectSubject: (subject) ->
    @subject = subject
    @endpointBase = "#{@subject}/#{@repository}"

  getRepositories: -> 
    endpoint = "/repos/#{@subject}"
    return @rest.get endpoint

  getRepository: ->
    endpoint = "/repos/#{@endpointBase}"
    return @rest.get endpoint

  getPackages: (start = 0, startName) -> 
    endpoint = "/repos/#{@endpointBase}/packages?start_pos=#{start}" + (if startName then "&start_name=" + startName else '')
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
 
  createPackageVersion: (name, versionObj) -> 
    endpoint = "/packages/#{@endpointBase}/#{name}/versions"
    return @rest.post endpoint, {
      data: JSON.stringify versionObj
    }

  deletePackageVersion: (name, version) -> 
    endpoint = "/packages/#{@endpointBase}/#{name}/versions/#{version}"
    return @rest.del endpoint

  updatePackageVersion: (name, version) -> 
    endpoint = "/packages/#{@endpointBase}/#{name}/versions/#{version}"
    return @rest.patch endpoint

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

  searchRepository: (name, descendant = false) -> 
    endpoint = "/search/repos?name=#{name}" + (if descendant then "desc=1")
    return @rest.get endpoint

  searchPackage:  (name, descendant = false, subject = @subject, repository = @repository) ->
    endpoint = "/search/packages?name=#{name}" + (if descendant then "desc=1") + "&subject=#{subject}&repo=#{repository}"
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

  searchFile: (name, repository = @repository) -> 
    endpoint = "/search/file?name=#{name}&repo=#{repository}"
    return @rest.get endpoint

  searchFileChecksum: (hash, repository = @repository) -> 
    endpoint = "/search/file?sha1=#{name}&repo=#{repository}"
    return @rest.get endpoint

  getUser: (username) -> 
    endpoint = "/users/#{username}"
    return @rest.get endpoint

  getUserFollowers: (username, startPosition = 0) -> 
    endpoint = "/users/#{username}/followers?startPosition=#{startPosition}"
    return @rest.get endpoint

  uploadPackage: (name, version, filePath, remotePath = '/', publish = true, explode = false, mimeType = "application/octet-stream") -> 
    endpoint = "/content/#{@endpointBase}/#{name}/#{version}/#{remotePath}" + (if publish then ";publish=1") + (if explode then ";explode=1")
    return @rest.put endpoint, {
      multipart: true
      data: 
        "package[message]": "Package upload: #{name} (#{version})"
        "package[file]": sendFile filePath, null, getFileSize(filePath), null, mimeType
    }

  publishPackage: (name, version, discard = false) -> 
    endpoint = "/content/#{@endpointBase}/#{name}/#{version}/publish"
    return @rest.post endpoint, {
      data: JSON.stringify { discard: discard }
    }

  mavenUpload: (name, version, filePath, remotePath = '/', publish = true, explode = false, mimeType = "application/octet-stream") -> 
    endpoint = "/maven/#{@endpointBase}/#{name}/#{remotePath}" + (if publish then ";publish=1") + (if explode then ";explode=1")
    return @rest.put endpoint, {
      multipart: true
      data: 
        "package[message]": "Maven package upload: #{name} (#{version})"
        "package[file]": sendFile filePath, null, getFileSize(filePath), null, mimeType
    }

  getWebhooks: (repository = '') -> 
    endpoint = "/webhooks/#{@subject}/#{repository}"
    return @rest.get endpoint

  createWebhook: (pkgname, configObj) -> 
    endpoint = "/webhooks/#{@endpointBase}/#{pkgname}"
    return @rest.post endpoint, {
      data: JSON.stringify config
    }

  testWebhook: (pkgname, version, configObj) -> 
    endpoint = "/webhooks/#{@endpointBase}/#{pkgname}/#{version}"
    return @rest.post endpoint, {
      data: JSON.stringify configOBj
    }

  deleteWebhook: (pkgname) -> 
    endpoint = "/webhooks/#{@endpointBase}/#{pkgname}"
    return @rest.del endpoint

  singFile: (remotePath, passphrase) ->
    endpoint = "/gpg/@{@endpointBase}/#{remotePath}" + (if passphrase then "?passphrase=#{passphrase}" else '')
    return @rest.post endpoint

  singVersion: (pkgname, version, passphrase) ->
    endpoint = "/gpg/@{@endpointBase}/#{pkgname}/versions/#{version}" + (if passphrase then "?passphrase=#{passphrase}" else '')
    return @rest.post endpoint

  # TODO
  getRateLimit: ->
    return @rest.rateLimit

  getRateLimitRemaining: ->
    return @rest.rateRemaining