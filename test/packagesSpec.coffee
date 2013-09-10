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
            try
              assert.equal response.code, 201
              done()
            catch e
              done e
          , (error) ->
            done new Error error.data
  
  it 'should retrieve and find the created package', (done) -> 
    client.getPackages()
      .then (response) ->
            try 
              assert.equal response.code, 200, 
              assert.deepEqual _.find(response.data, { 'name': 'my-package1' }), { name: 'my-package1', linked: false }
              done()
            catch e 
              done e
          , (error) ->
            done new Error error.data

  it 'should update package information', (done) -> 
    client.updatePackage('my-package', {
      desc: 'My super package',
      licenses: [ 'BSD' ]
    })
      .then (response) ->
            try
              assert.equal response.code, 200
              assert.deepEqual response.data.desc, 'My super package'
              assert.deepEqual response.data.licenses, ['BSD']
              done()
            catch
              done new Error "Response error: #{e.message} (HTTP #{response.code})"
          , (error) ->
            done new Error error.data

  it 'should retrieve the package info', (done) ->
    client.getPackage('my-package')
      .then (response) ->
            try 
              assert.equal response.code, 200
              assert.deepEqual response.data.desc, 'My super package'
              done()
            catch e
              done e
          , (error) ->
            done new Error error.data

  it 'should remove the package', (done) ->
      client.deletePackage('my-package')
        .then (response) ->
              try 
                assert.equal response.code, 200
                done()
              catch e
                done e
            , (error) ->
              done new Error error.data