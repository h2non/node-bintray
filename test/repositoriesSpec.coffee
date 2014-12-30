assert = require 'assert'
_ = require 'lodash'
Bintray = require '../'

username = 'username'
apikey = 'apikey'
organization = 'organization'
repository = 'repo'

apiBaseUrl = 'http://localhost:8882'

client = new Bintray { username: username, apikey: apikey, organization: organization, repository: repository, baseUrl: apiBaseUrl }

describe 'Repositories:', ->

  it 'should retrieve properly the existent repositories', (done) ->
    client.getRepositories()
      .then (response) ->
        try
          assert.equal response.code, 200, 'Code status is 200'
          assert.equal _.isArray(response.data), true, 'Body response is an Array'
          assert.equal response.data[0].name, repository, 'The first repository exists and is correct'
          done()
        catch e
          done e
      , (error) ->
        done new Error error.data
  
  it 'should retrieve data properly for the given repository', (done) -> 
    client.getRepository()
      .then (response) ->
        try 
          assert.equal response.code, 200, 'Code status is 200'
          assert.equal response.data.name, repository, "The repository name is '#{repository}'"
          assert.equal response.data.owner, organization, "The repository owner is '#{organization}'"
          done()
        catch e 
          done e
      , (error) ->
        done new Error error.data
