assert = require "assert"
exec = require("child_process").execFile

clipath = __dirname + "/../bin/bintray"
username = 'username'
apikey = 'apikey'
subject = 'organization'
repository = 'repo'

describe "CLI authentication:", ->

  it "should store new authentication data", (done) ->
    exec(
      clipath, 
      [ "auth", "-u", "#{username}", "-k", "#{apikey}" ], 
      null,
      (error, stdout, stderr) ->
        console.log arguments
        try
          assert.equal stdout, "Data saved successfully"
          done
        catch e
          done e
    )