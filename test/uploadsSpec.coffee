assert = require 'assert'
Bintray = require '../'
config = require './config.json'

username = config.username
token = config.apiToken
subject = config.subject
repository = config.repository

repository = new Bintray username, token, subject, repository

describe 'Uploads:', ->

  it 'should register a new package properly', (done) ->
    repository.createPackage({
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
    repository.getPackages()
      .then (response) ->
            assert.equal response.code, 200, 
            assert.deepEqual _.find(response.data, { 'name': 'beaker' }), { name: 'beaker', linked: false }
            done()
          , (error) ->
            done error.data

  it 'should creates a new package version', (done) ->
    repository.createPackageVersion('beaker', {
      name: '0.1.0',
      release_notes: 'First version',
      release_url: 'http://en.wikipedia.org/wiki/Beaker_(Muppet)'
    })
      .then (response) ->
            assert.equal response.statusCode, 201

  it 'should upload the file properly', (done) ->
    repository.uploadPackage('beaker', '0.1.0', "#{__dirname}/fixtures/beaker.gz", '0.1.0/beaker.gz')
      .then (response) ->
            repository.getPackage('beaker')
              .then (response) ->
                    console.log release.data
                    done()
            console.log(response)
          , (error) ->
            done error.data

  it 'should remove the package', (done) ->
    repository.deletePackage('beaker')
      .then (response) ->
            assert.equal response.code, 200
            done()
          , (error) ->
            done error.data