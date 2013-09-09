fs = require 'fs'
path = require 'path'

module.exports = class 

  @readFile: (filepath) =>
    data = fs.readFileSync path.resolve(filepath)
    
    if /.json$/.test filepath
      data = JSON.parse data
    
    return data

  @fileExists: (filepath) =>
    fs.fileExistsSync filepath

  @error: (error) =>
    @log "Error:".red, "cannot get the resource [HTTP #{error.code} - #{error.status}]", error.response.req.path.green
    @die 1

  @log: ->
    console.log.apply null, Array::slice.call arguments

  @die: (code) ->
    process.exit code or 0