# Node Bintray

A Bintray API client for Node.js (written in CoffeeScript)

## WORK IN PROGRESS!

# Installation

```shell
$ npm install bintray --save
```

# API

The current implementation only supports the Bintray REST API version `1.0`

For more information about the current API stage, see the [Bintray documentation](https://bintray.com/docs/api.html)

## Constructor

#### new Bintray (username, apiToken, subject[, repository])

## Repositories

#### getRepositories ()

#### getRepository ()

#### selectRepository (repositoryName)

#### selectSubject (subject)

## Packages

#### getPackages ([start = 0, startName])

#### getPackage (pkgname)

#### createPackage (packageObject)

#### deletePackage (pkgname)

#### updatePackage (pkgname, packageObject)

#### getPackageVersion (pkgname, version = '_latest')

#### createPackageVersion (pkgname, versionObject)

#### deletePackageVersion (pkgname, version)

#### updatePackageVersion (pkgname, version)

#### getVersionAttrs (pkgname, attributes, version = '_latest')

#### setPackageAttrs (pkgname, attributesObj [, version])

#### updatePackageAttrs (pkgname, attributesObj [, version])

#### deletePackageAttrs (pkgname, names [, version])

## Search

#### searchRepository (repositoryName [, descendant = false])

#### searchPackage (pkgname [, descendant = false, subject = current, repository = current])

#### searchUser (pkgname)

#### searchAttributes (attributesObj, name)

#### searchFile (filename [, repository = current])

#### searchFileChecksum (hash [, repository = current])

## User

#### getUser (username)

#### getUserFollowers (username [, startPosition = 0])

## Uploads

#### uploadPackage (name, version, filePath [, remotePath = '/', publish = true, explode = false, mimeType = 'application-octet-stream'])

#### mavenUpload (name, version, filePath [, remotePath = '/', publish = true, explode = false, mimeType = 'application-octet-stream'])

#### publishPackage (name, version [, discard = false])

## Webhooks

#### getWebhooks (repositoryName)

#### createWebhook (pkgname, configObject)

#### testWebhook (pkgname, version, configObject)

#### deleteWebhook (pkgname)

## Signing

#### signFile (remotePath [, passphrase])

#### signVersion (pkgname, version [, passphrase])


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

# License

Code under [MIT](https://github.com/h2non/node-bintray/blob/master/LICENSE) license
