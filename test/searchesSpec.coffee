assert = require 'assert'
_ = require 'lodash'
Bintray = require '../'

username = 'username'
apikey = 'apikey'
organization = 'organization'
repository = 'repo'

apiBaseUrl = 'http://localhost:8882'

client = new Bintray { username: username, apikey: apikey, organization: organization, repository: repository, baseUrl: apiBaseUrl }

describe 'Search:', ->

  it 'should retrieve the list of available repositories', (done) ->
    client.searchRepository('repo')
      .then (response) ->
        try
          assert.equal response.code, 200, 'Code status is 200'
          assert.equal _.isArray(response.data), true, 'Body response is an Array'
          assert.equal response.data[0].name, repository, 'The repository found is correct'
          done()
        catch e
          done e
      , (error) ->
        done new Error error.data
  
  it 'should find the package by description', (done) -> 
    client.searchPackage(null, 'package')
      .then (response) ->
        try 
          assert.equal response.code, 200, 'Code status is 200'
          assert.equal _.isArray(response.data), true, 'Body response is an Array'
          assert.equal response.data[0].name, 'my-package', 'Package name is the expected'
          done()
        catch e 
          done e
      , (error) ->
        done new Error error.data

  it 'should find the user by name', (done) -> 
    client.searchUser('beaker')
      .then (response) ->
        try 
          assert.equal response.code, 200, 'Code status is 200'
          assert.equal _.isArray(response.data), true, 'Body response is an Array'
          assert.equal response.data[0].name, 'beaker', 'The username is the expected'
          done()
        catch e 
          done e
      , (error) ->
        done new Error error.data

  it 'should find the file by name', (done) -> 
    client.searchFile('my-package-?.?.?.*')
      .then (response) ->
        try 
          assert.equal response.code, 200, 'Code status is 200'
          assert.equal _.isArray(response.data), true, 'Body response is an Array'
          assert.equal response.data[0]['package'], 'my-package', 'The package name is the expected'
          done()
        catch e 
          done e
      , (error) ->
        done new Error error.data