# Node Bintray

A [Bintray](https://bintray.com) CLI and Node.js API client for easy package management (written in CoffeeScript)

## JUST FOR TESTING, WORK IN PROGRESS!

# Installation

For CLI usage, is preferably you install the package globally

```shell
$ npm install bintray -g
```

Otherwise for JavaScript API usage, you should install it locally

```shell
$ npm install bintray --save
```

# Requirements

For full API usage, you must create an account at [Bintray.com](https://bintray.com)

When you get the account, go to your user profile, click in `Edit` and then click in `API key` option menu for getting your API token.

# CLI

Full support via command-line interface

```shell
$ bintray -h
```

# Programmatic API

The current implementation only supports the REST API version `1.0`

For more information about the current API stage, see the [Bintray API documentation](https://bintray.com/docs/api.html)

## Example usage

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

## Constructor

#### new Bintray ([username, apiToken, subject, repository])

Creates a new Bintray instance for working with the API.

Autentication is optional for some resources (see [documentation](https://bintray.com/docs/api.html))

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

#### getPackage (packageName)

Get general information about a specified package. This resource is rate limit free

[Link to documentation](https://bintray.com/docs/api.html#_get_packages)

#### createPackage (packageObject)

Creates a new package in the specified repo (user has to be an owner of the repo)

[Link to documentation](https://bintray.com/docs/api.html#_create_package)

#### deletePackage (packageName)

Delete the specified package

[Link to documentation](https://bintray.com/docs/api.html#_delete_package)

#### updatePackage (packageName, packageObject)

Update the information of the specified package.
Creates a new package in the specified repo (user has to be an owner of the repo)

[Link to documentation](https://bintray.com/docs/api.html#_update_package)

#### getPackageVersion (packageName, version = '_latest')

Get general information about a specified version, or query for the latest version

[Link to documentation](https://bintray.com/docs/api.html#_get_version)

#### createPackageVersion (packageName, versionObject)

Creates a new version in the specified package (user has to be owner of the package)

[Link to documentation](https://bintray.com/docs/api.html#_create_version)

#### deletePackageVersion (packageName, version)

Delete the specified version Published versions may be deleted within 30 days from their publish date.

[Link to documentation](https://bintray.com/docs/api.html#_delete_version)

#### updatePackageVersion (packageName, version)

Update the information of the specified version

[Link to documentation](https://bintray.com/docs/api.html#_update_version)

#### getVersionAttrs (packageName, attributes, version = '_latest')

Get attributes associated with the specified package or version. If no attribute names are specified, return all attributes.

[Link to documentation](https://bintray.com/docs/api.html#_get_attributes)

#### setPackageAttrs (packageName, attributesObj [, version])

Associate attributes with the specified package or version, overriding all previous attributes.

[Link to documentation](https://bintray.com/docs/api.html#_set_attributes)

#### updatePackageAttrs (packageName, attributesObj [, version])

Update attributes associated with the specified package or version.

[Link to documentation](https://bintray.com/docs/api.html#_update_attributes)

#### deletePackageAttrs (packageName, names [, version])

Delete attributes associated with the specified repo, package or version. If no attribute names are specified, delete all attributes

[Link to documentation](https://bintray.com/docs/api.html#_delete_attributes)

## Search

#### searchRepository (repositoryName [, descendant = false])

Search for a repository. At least one of the name and desc search fields need to be specified. Returns an array of results, where elements are similar to the result of getting a single repository.

[Link to documentation](https://bintray.com/docs/api.html#_repository_search)

#### searchPackage (packageName [, descendant = false, subject = current, repository = current])

Search for a package. At least one of the name and desc search fields need to be specified. May take an optional single subject name and if specified, and optional (exact) repo name. Returns an array of results, where elements are similar to the result of getting a single package.

[Link to documentation](https://bintray.com/docs/api.html#_package_search)

#### searchUser (packageName)

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

#### createWebhook (packageName, configObject)

Register a webhook for receiving notifications on a new package release. By default a user can register up to 10 webhook callbacks.

[Link to documentation](https://bintray.com/docs/api.html#_register_a_webhook)

#### testWebhook (packageName, version, configObject)

Test a webhook callback for the specified package release. 
A webhook post request is authenticated with a authentication header that is the HMAC-MD5 of the registering subject’s API key seeded with package name, base64-encoded UTF-8 string.

[Link to documentation](https://bintray.com/docs/api.html#_test_a_webhook)

#### deleteWebhook (packageName)

Delete a webhook associated with the specified package.

[Link to documentation](https://bintray.com/docs/api.html#_delete_a_webhook)

## Signing

#### signFile (remotePath [, passphrase])

GPG sign the specified repository file. This operation requires enabling GPG signing on the targeted repo.

[Link to documentation](https://bintray.com/docs/api.html#_gpg_sign_a_file)

#### signVersion (packageName, version [, passphrase])

GPG sign all files associated with the specified version.

[Link to documentation](https://bintray.com/docs/api.html#_gpg_sign_a_version)

## Rate limits

#### getRateLimit ()

Returns the total daily avaiable requests rate limit (defaults to 300)

#### getRateLimitRemaining ()

Returns the remaining API calls available for the current user

For more information about the usage limits, take a look to the [documentation](https://bintray.com/docs/api.html#_limits)


# Promises API

The library uses a promise-based wrapper elegant and made easy way to manage async tasks. It uses internally [Q.js](https://github.com/kriskowal/q)

The promise resolve/error object has the following members:

* `data` The HTTP response body or error message. It can be an object if it was served as application/json mime type
* `code` The HTTP response status code
* `status` The HTTP status string
* `response` The HTTP native response object


# Testing

Clone the repository

```shell
$ git clone https://github.com/h2non/node-bintray.git && cd node-bintray
```

Install dependencies

```shell
$ npm install
```

Compile and test (you should have installed grunt-cli as global package)

```shell
$ npm test
```

Add mock test cases in test/mocks/ like JSON data collection

# Changelog

* `0.1.0` 01-09-2013
  - Initial version (work in progress)

# TODO

* Better error handling
* Download progress (chunk event data)
* More tests (webhooks & searchs)
* Code usage examples

# License

Code under [MIT](https://github.com/h2non/node-bintray/blob/master/LICENSE) license
