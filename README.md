# Node Bintray

A Bintray API client for Node.js (written in CoffeeScript)

## DO NOT USE, WORK STILL IN PROGRESS!

# Installation

```shell
$ npm install bintray --save
```

# Requirements

For full API usage, you must create and account at [Bintray](https://bintray.com)

When you get and account, go to your user profile, click in `Edit` and then click in `API key` option menu for getting your API token.

# API

The current implementation only supports the Bintray REST API version `1.0`

For more information about the current API stage, see the [Bintray documentation](https://bintray.com/docs/api.html)

## Constructor

#### new Bintray (username, apiToken, subject[, repository])

Creates a new Bintray instance for working with the API.

The first three parameters are required

```js
var Bintray = require('bintray')

var myRepository = new Bintray('myUsername', 'myApiToken', 'mySubject', 'myRepository')
```

You can get the current API version from the following static Object property

```js
Bintray.apiVersion // "1.0"
```

## Repositories

#### getRepositories ()

Get a list of repos writeable by subject (personal or organizational) This resource does not require authentication

[Link to documentation](https://bintray.com/docs/api.html#_get_repositories)

#### getRepository ()

Get general information about a repository of the specified user

[Link to documentation](https://bintray.com/docs/api.html#_get_repository)

#### selectRepository (repositoryName)

Switch to another repository

#### selectSubject (subject)

Switch to another subject

## Packages

#### getPackages ([start = 0, startName])

Get general information about a specified package. This resource does not require authentication

[Link to documentation](https://bintray.com/docs/api.html#_get_packages)

#### getPackage (pkgname)

Get general information about a specified package. This resource is rate limit free

[Link to documentation](https://bintray.com/docs/api.html#_get_packages)

#### createPackage (packageObject)

Creates a new package in the specified repo (user has to be an owner of the repo)

[Link to documentation](https://bintray.com/docs/api.html#_create_package)

#### deletePackage (pkgname)

Delete the specified package

[Link to documentation](https://bintray.com/docs/api.html#_delete_package)

#### updatePackage (pkgname, packageObject)

Update the information of the specified package.
Creates a new package in the specified repo (user has to be an owner of the repo)

[Link to documentation](https://bintray.com/docs/api.html#_update_package)

#### getPackageVersion (pkgname, version = '_latest')

Get general information about a specified version, or query for the latest version

[Link to documentation](https://bintray.com/docs/api.html#_get_version)

#### createPackageVersion (pkgname, versionObject)

Creates a new version in the specified package (user has to be owner of the package)

[Link to documentation](https://bintray.com/docs/api.html#_create_version)

#### deletePackageVersion (pkgname, version)

Delete the specified version Published versions may be deleted within 30 days from their publish date.

[Link to documentation](https://bintray.com/docs/api.html#_delete_version)

#### updatePackageVersion (pkgname, version)

Update the information of the specified version

[Link to documentation](https://bintray.com/docs/api.html#_update_version)

#### getVersionAttrs (pkgname, attributes, version = '_latest')

Get attributes associated with the specified package or version. If no attribute names are specified, return all attributes.

[Link to documentation](https://bintray.com/docs/api.html#_get_attributes)

#### setPackageAttrs (pkgname, attributesObj [, version])

Associate attributes with the specified package or version, overriding all previous attributes.

[Link to documentation](https://bintray.com/docs/api.html#_set_attributes)

#### updatePackageAttrs (pkgname, attributesObj [, version])

Update attributes associated with the specified package or version.

[Link to documentation](https://bintray.com/docs/api.html#_update_attributes)

#### deletePackageAttrs (pkgname, names [, version])

Delete attributes associated with the specified repo, package or version. If no attribute names are specified, delete all attributes

[Link to documentation](https://bintray.com/docs/api.html#_delete_attributes)

## Search

#### searchRepository (repositoryName [, descendant = false])

Search for a repository. At least one of the name and desc search fields need to be specified. Returns an array of results, where elements are similar to the result of getting a single repository.

[Link to documentation](https://bintray.com/docs/api.html#_repository_search)

#### searchPackage (pkgname [, descendant = false, subject = current, repository = current])

Search for a package. At least one of the name and desc search fields need to be specified. May take an optional single subject name and if specified, and optional (exact) repo name. Returns an array of results, where elements are similar to the result of getting a single package.

[Link to documentation](https://bintray.com/docs/api.html#_package_search)

#### searchUser (pkgname)

[Link to documentation](https://bintray.com/docs/api.html#_delete_attributes)

#### searchAttributes (attributesObj, name)

Search for packages/versions inside a given repository matching a set of attributes.

[Link to documentation](https://bintray.com/docs/api.html#_attribute_search)

#### searchFile (filename [, repository = current])

Search for a file by its name. name can take the * and ? wildcard characters. May take an optional (exact) repo name to search in.

[Link to documentation](https://bintray.com/docs/api.html#_file_search_by_name)

#### searchFileChecksum (hash [, repository = current])

Search for a file by its sha1 checksum. May take an optional repo name to search in.

[Link to documentation](https://bintray.com/docs/api.html#_file_search_by_checksum)

## User

#### getUser (username)

Get general information about a specified repository owner

[Link to documentation](https://bintray.com/docs/api.html#_get_user)

#### getUserFollowers (username [, startPosition = 0])

Get followers of the specified repository owner

[Link to documentation](https://bintray.com/docs/api.html#_get_followers)

## Uploads

#### uploadPackage (name, version, filePath [, remotePath = '/', publish = true, explode = false, mimeType = 'application-octet-stream'])

Upload content to the specified repository path, with package and version information (both required).

[Link to documentation](https://bintray.com/docs/api.html#_upload_content)

#### mavenUpload (name, version, filePath [, remotePath = '/', publish = true, explode = false, mimeType = 'application-octet-stream'])

[Link to documentation](https://bintray.com/docs/api.html#_maven_upload)

#### publishPackage (name, version [, discard = false])

Publish all unpublished content for a user’s package version. Returns the number of published files. Optionally, pass in a "discard” flag to discard any unpublished content, instead of publishing.

[Link to documentation](https://bintray.com/docs/api.html#_publish_discard_uploaded_content)

## Webhooks

#### getWebhooks (repositoryName)

Get all the webhooks registered for the specified subject, optionally for a specific repository.

[Link to documentation](https://bintray.com/docs/api.html#_get_webhooks)

#### createWebhook (pkgname, configObject)

Register a webhook for receiving notifications on a new package release. By default a user can register up to 10 webhook callbacks.

[Link to documentation](https://bintray.com/docs/api.html#_register_a_webhook)

#### testWebhook (pkgname, version, configObject)

Test a webhook callback for the specified package release. 
A webhook post request is authenticated with a authentication header that is the HMAC-MD5 of the registering subject’s API key seeded with package name, base64-encoded UTF-8 string.

[Link to documentation](https://bintray.com/docs/api.html#_test_a_webhook)

#### deleteWebhook (pkgname)

Delete a webhook associated with the specified package.

[Link to documentation](https://bintray.com/docs/api.html#_delete_a_webhook)

## Signing

#### signFile (remotePath [, passphrase])

GPG sign the specified repository file. This operation requires enabling GPG signing on the targeted repo.

[Link to documentation](https://bintray.com/docs/api.html#_gpg_sign_a_file)

#### signVersion (pkgname, version [, passphrase])

GPG sign all files associated with the specified version.

[Link to documentation](https://bintray.com/docs/api.html#_gpg_sign_a_version)

## Rate limits

#### getRateLimit ()

Returns the total daily avaiable requests rate limit (defaults to 300)

#### getRateLimitRemaining ()

Returns the remaining API calls available for the current user

For more information about the usage limits, take a look to the [documentation](https://bintray.com/docs/api.html#_limits)


# Promises API

The library uses a promise-based wrapper for async tasks based on [Q.js](https://github.com/kriskowal/q)

The promise resolve/error Object has the following members:

* `data` The HTTP response body or error message. It can be an object if it was served as application/json mime type
* `code` The HTTP response status code
* `response` The HTTP native response object

# Example usage

```js

var Bintray = require('bintray');

var repository = new Bintray('username', 'apiToken', 'my-packages', 'stable')

var myPackage = {
    name: 'node',
    desc: 'Node.js event-based server-side javascript engine',
    labels: ['JavaScript', 'Server-side', 'Node'],
    licenses: ['MIT']
  };

repository.createPackage(myPackage)
  .then(function(response) {
    console.log('Package registered: ', response.code);

    repository.getPackages()
      .then(function (response) {
        console.log(response.data);
      });

  }, function(error) {
    console.error('Cannot create the package: ', error.code);
  });

```

# Changelog

* `0.1.0` 01-09-2013
  - Initial version (work in progress)

# Testing

Clone the repository

```shell
$ git clone https://github.com/h2non/node-bintray.git && cd node-bintray
```

Install dependencies

```shell
$ npm install
```

Configure the JSON file for real testing

```shell
$ echo '{ "username": "<yourUsername>", "apiToken": "<yourApiToken>", "subject": "myName", "repository": "testing" }' > test/config.json
```

Compile and test (you should have installed grunt-cli as global package and via $PATH accesible)

```shell
$ grunt 
```

# TODO

* Validate/control rate limit usage from the library
* Better handling non-JSON responses
* More testing (webhooks & searchs)
* Code usage examples

# License

Code under [MIT](https://github.com/h2non/node-bintray/blob/master/LICENSE) license
