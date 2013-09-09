assert = require 'assert'
_ = require 'lodash'
Bintray = require '../'

username = 'username'
apikey = 'apikey'
subject = 'organization'
repository = 'repo'

Bintray.apiBaseUrl = 'http://localhost:8882';

client = new Bintray username, apikey, subject, repository

describe 'Packages:', ->

  it 'should register a new package properly', (done) ->
    client.createPackage({
      name: 'my-package'
      desc: 'My package description'
      labels: [ 'JavaScript', 'Package' ]
      licenses: [ 'MIT' ]
    })
      .then (response) ->
            assert.equal response.code, 201
            done()
          , (error) ->
            done error.data

  it 'should retrieve and find the created package', (done) -> 
    client.getPackages()
      .then (response) ->
            assert.equal response.code, 200, 
            assert.deepEqual _.find(response.data, { 'name': 'node' }), { name: 'node', linked: false }
            done()
          , (error) ->
            console.log(error.code)
            done error.data

  it 'should update package information', (done) -> 
    client.updatePackage('node', {
      desc: 'Node.js rules',
      licenses: [ 'BSD' ]
    })
      .then (response) ->
            try 
              assert.equal response.code, 200
              client.getPackage('node')
                .then (response) ->
                        console.log 'Error', response.code
                        assert.equal response.code, 200
                        assert.deepEqual response.data.desc, 'Node.js rules'
                        done()
                    , (error) ->
                      done error.data
            catch
              done 'Response error:' + e.message + "(HTTP #{response.code})"
          , (error) ->
            done error.data 

  it 'should remove the package', (done) ->
      client.deletePackage('node')
        .then (response) ->
              try 
                assert.equal response.code, 200
                done()
              catch e
                done e
            , (error) ->
              done error.data