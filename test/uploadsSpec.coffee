assert = require 'assert'
_ = require 'lodash'
Bintray = require '../'

username = 'username'
apikey = 'apikey'
organization = 'organization'
repository = 'repo'

apiBaseUrl = 'http://localhost:8882'

client = new Bintray { username: username, apikey: apikey, organization: organization, repository: repository, baseUrl: apiBaseUrl }

describe 'Uploads:', ->

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

  it 'should creates a new package version', (done) ->
    client.createPackageVersion('my-package', {
      name: '0.1.0',
      release_notes: 'First version',
      release_url: 'http://en.wikipedia.org/wiki/Beaker_(Muppet)'
    })
      .then (response) ->
            assert.equal response.statusCode, 201

  it 'should upload the file properly', (done) ->
    client.uploadPackage('beaker', '0.1.0', "#{__dirname}/fixtures/beaker.gz", '0.1.0/beaker/')
      .then (response) ->
            client.getPackage('beaker')
              .then (response) ->
                    console.log release.data
                    done()
                  , (error) ->
                    done error.data
            console.log('status: ', response.code)
          , (error) ->
            done error.data

  it 'should remove the package', (done) ->
    client.deletePackage('beaker')
      .then (response) ->
            assert.equal response.code, 200
            done()
          , (error) ->
            done error.data