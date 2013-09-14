fs = require 'fs'
path = require 'path'
_ = require 'lodash'

module.exports = class 

  @getFileSize: (path) =>
    fs.statSync(path).size

  @readFile: (filepath) =>
    data = fs.readFileSync path.resolve(path.normalize(filepath))
    
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

  @printObj: (obj) ->
    arr = []
    for prop of obj when obj.hasOwnProperty prop
      value = obj[prop]
      if (value).toString() isnt '[object Object]'
        value = value.join ', ' if _.isArray value
        arr.push (prop.charAt(0).toUpperCase() + prop.slice(1)).replace('_', ' ') + ': ' + value

    console.log arr.join '\n'