assert = require 'assert'
_ = require 'lodash'
Bintray = require '../'

username = 'username'
apikey = 'apikey'
organization = 'organization'
repository = 'repo'

Bintray.apiBaseUrl = 'http://localhost:8882'

client = new Bintray { username: username, apikey: apikey, organization: organization, repository: repository }

describe 'Uploads:', ->

  it 'should register a new package properly', (done) ->
    client.createPackage({
      name: 'beaker'
      desc: 'Another super package'
      labels: [ 'beaker', 'muppets' ]
      licenses: [ 'AGPL' ]
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
            assert.deepEqual _.find(response.data, { 'name': 'beaker' }), { name: 'beaker', linked: false }
            done()
          , (error) ->
            done error.data

  it 'should creates a new package version', (done) ->
    client.createPackageVersion('beaker', {
      name: '0.1.0',
      release_notes: 'First version',
      release_url: 'http://en.wikipedia.org/wiki/Beaker_(Muppet)'
    })
      .then (response) ->
            assert.equal response.statusCode, 201

  it 'should upload the file properly', (done) ->
    client.uploadPackage('beaker', '0.1.0', "#{__dirname}/fixtures/beaker.gz", '0.1.0/beaker.gz')
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