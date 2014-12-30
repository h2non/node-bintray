fs = require 'fs'

module.exports = class

  @credentials: null
  
  @store: ".bintray.json"

  @get: => 
    if @exists() and not @credentials
      @credentials = JSON.parse(fs.readFileSync @store)

    return @credentials

  @save: (username, apikey) =>
    fs.writeFileSync @store, JSON.stringify({ username: username, apikey: apikey }, null, 2) if username? and apikey?

  @exists: => 
    fs.existsSync @store

  @clean: =>
    fs.unlinkSync @store
