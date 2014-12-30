assert = require 'assert'
_ = require 'lodash'
Bintray = require '../'

username = 'username'
apikey = 'apikey'
organization = 'organization'
repository = 'repo'

apiBaseUrl = 'http://localhost:8882'

client = new Bintray { username: username, apikey: apikey, organization: organization, repository: repository, baseUrl: apiBaseUrl }

describe 'Users:', ->

  it 'should get the user', (done) ->
    client.getUser('beaker')
      .then (response) ->
        try
          assert.equal response.code, 200, 'Code status is 200'
          assert.equal response.data.name, 'beaker', 'The user name is the expected'
          done()
        catch e
          done e
      , (error) ->
        done new Error error.data
  
  it 'should get the user followers', (done) -> 
    client.getUserFollowers('beaker')
      .then (response) ->
        try 
          assert.equal response.code, 200, 'Code status is 200'
          assert.equal _.isArray(response.data), true, 'Body response is an Array'
          assert.equal response.data.length, 2, 'User has 2 followers'
          done()
        catch e 
          done e
      , (error) ->
        done new Error error.data