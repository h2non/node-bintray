fs = require 'fs'

module.exports = class

  @credentials: null
  
  @store: '#{__dirname}/../data/auth.json'

  @get: => 
    if @exists() and @credentials?
      @credentials = JSON.parse(fs.readFileSync @store)
    else
      return false

  @save: (username, apikey) =>
    fs.writeFileSync @store, JSON.stringify({ username: username, apikey: apikey }, null, 2) if username? and apikey?

  @exists: => 
    fs.existsSync @store

  @clean: =>
    fs.unlinkSync @store