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
          assert.equal response.code, 201, 'HTTP status should be 201'
          done()
        catch e
          done e
      , (error) ->
        done new Error error.data

  it 'should creates a new package version', (done) ->
    client.createPackageVersion('my-package', {
      name: '1.1.5',
      release_notes: 'This new version fixes...',
      release_url: 'https://github.com/user/my-package/RB-1.1.5/README.md',
      releades: 'ISO8601 (yyyy-MM-ddTHH:mm:ss.SSSZ)'
    })
      .then (response) ->
        try 
          assert.equal response.code, 201, 'HTTP status should be 201'
          done()
        catch e
          done e
      , (error) ->
        done new Error error.data

  it 'should upload the file properly', (done) ->
    client.uploadPackage('my-package', '1.1.5', "#{__dirname}/fixtures/my-package.gz", 'packages/my-package/')
      .then (response) ->
        try 
          assert.equal response.code, 201, 'HTTP status code should be 201'
          done()
        catch e
          done e
      , (error) ->
        done new Error error.data

  it 'should publish the file properly', (done) ->
    client.publishPackage('my-package', '1.1.5', true)
      .then (response) ->
        try 
          assert.equal response.code, 200, 'HTTP status should be 200'
          assert.equal response.data.files, 39, 'Discarded files should be 39'
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