# node-bintray [![Build Status](https://travis-ci.org/h2non/node-bintray.png)](https://travis-ci.org/h2non/node-bintray) [![NPM](https://img.shields.io/npm/v/bintray.svg)](https://www.npmjs.org/package/bintray)

CLI and programmatic API client for Bintray.com

## About

[Bintray](https://bintray.com) is free social service for easy OSS software packages distribution

Bintray offers developers the fastest way to publish and consume OSS software releases. Whether you are distributing software packages or downloading ones.

Click [here](https://bintray.com/howbintrayworks) for more information

## Installation

For command-line usage, is preferably you install the package globally

```bash
$ npm install bintray -g
```

For programmatic usage, install it as runtime dependency

```bash
$ npm install bintray [--save]
```

## Requirements

For full API usage, you must create an account at [Bintray.com](https://bintray.com)

When you get the account, go to your user profile, click in `Edit` and then click in `API key` option menu for getting your API token.

## Command-line interface

For easy automation, usage from other languages or from your shell scripts you can use the full supported command-line interface:

```shell
$ bintray --help

  Usage: bintray [options] [command]

  Commands:

    auth [options]         
      Defines the Bintray authentication credentials
    package [options] <action> <organization> <repository> [pkgname] [pkgfile] 
      Get, update, delete or create packages. Authentication is required
    search [options] <type> <query> 
      Search packages, repositories, files, users or attributes
    repositories [options] <organization> [repository] 
      Get information about one or more repositories. Authentication is optional
    user [options] <username> [action] 
      Get information about a user. Authentication is required
    webhook [options] <action> <organization> [repository] [pkgname] 
      Manage webhooks. Authentication is required
    package-version [options] <action> <organization> <repository> <pkgname> [versionfile] 
      Get, create, delete or update package versions. Authentication is required
    files [options] <action> <organization> <repository> <pkgname> 
      Upload or publish packages. Authentication is required
    sign [options] <organization> <repository> <pkgname> <passphrase> 
      Sign files and packages versions with GPG. Authentication is required

  Options:

    -h, --help     output usage information
    -V, --version  output the version number

  Usage Examples:

    $ bintray auth set -u username -k apikey
    $ bintray search package node.js -o myOrganization
    $ bintray repositories organizationName
    $ bintray files publish myorganization myrepository mypackage -n 0.1.0

```

Stores the authentication credentials

```shell
$ bintray auth -u myuser -k myapikey
```

Available options for the `auth` command

```shell
  Usage: auth [options]

    Options:

      -h, --help                 output usage information
      -c, --clean                Clean the stored authentication credentials
      -s, --show                 Show current stored authentication credentials
      -u, --username <username>  Bintray username
      -k, --apikey <apikey>      User API key

  Usage examples:

  $ bintray auth -u myuser -k myapikey
  $ bintray auth --show

```

## Programmatic API

The current implementation only supports the REST API version `1.0`

For more information about the current API stage, see the [Bintray API documentation](https://bintray.com/docs/api)

### Basic example usage

```js

var Bintray = require('bintray');

var repository = new Bintray({ 
  username: 'username', 
  apikey: 'apiKeyToken',
  organization: 'my-packages', 
  repository: 'stable'
});

var myPackage = {
    name: 'node',
    desc: 'Node.js event-based server-side JavaScript engine',
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

#### new Bintray (options[Object])

Creates a new Bintray instance for working with the API

Autentication is optional for some resources (see [documentation](https://bintray.com/docs/api))

```js
var Bintray = require('bintray')

var myRepository = new Bintray({ 
  username: 'username', 
  apikey: 'apiKeyToken', 
  organization: 'my-packages', 
  repository: 'stable' 
});
```

Available config options:

* `username` [String] Bintray username
* `apikey` [String] Bintray API key token
* `organization` [String] Bintray organization or subject identifier
* `repository` [String] Repository name to use
* `debug` [Boolean] Enables de console verbose mode
* `baseUrl` [String] REST API base URL (just for testing)

You can get the current API version from the following static Object property

```js
Bintray.apiVersion // "1.0"
```

### Repositories

```shell
$ bintray repositories --help

  Usage: repositories <organization> [repository]

    Options:

      -h, --help                 output usage information
      -u, --username <username>  Defines the authentication username
      -k, --apikey <apikey>      Defines the authentication API key
      -r, --raw                  Outputs the raw response (JSON)
      -d, --debug                Enables the verbose/debug output mode

  Usage examples:

  $ bintray repositories organizationName
  $ bintray repositories organizationName repoName

``` 

#### getRepositories ()

Get a list of repos writeable by subject (personal or organizational) This resource does not require authentication

[Link to documentation](https://bintray.com/docs/api#_get_repositories)

#### getRepository ()

Get general information about a repository of the specified user

[Link to documentation](https://bintray.com/docs/api#_get_repository)

#### selectRepository (repositoryName)

Switch to another repository

#### selectSubject (subject)

Switch to another subject

### Packages

```shell
  Usage: package  <list|info|create|delete|update|url> <organization> <repository> [pkgname] [pkgfile]?

    Options:

      -h, --help                       output usage information
      -s, --start-pos [number]         [list] Packages list start position
      -n, --start-name [prefix]        [list] Packages start name prefix filter
      -t, --description <description>  [create|update] Package description
      -l, --labels <labels>            [create|update] Package labels comma separated
      -x, --licenses <licenses>        [create|update] Package licenses comma separated
      -z, --norepository               [url] Get package URL from any repository
      -u, --username <username>        Defines the authentication username
      -k, --apikey <apikey>            Defines the authentication API key
      -r, --raw                        Outputs the raw response (JSON)
      -d, --debug                      Enables the verbose/debug output mode

  Usage examples:

  $ bintray package list myorganization myrepository 
  $ bintray package get myorganization myrepository mypackage
  $ bintray package create myorganization myrepository mypackage \
      --description 'My package' --labels 'package,binary' --licenses 'MIT,AGPL'
  $ bintray package delete myorganization myrepository mypackage

```

#### getPackages ([start = 0, startName])

Get general information about a specified package. This resource does not require authentication

[Link to documentation](https://bintray.com/docs/api#_get_packages)

#### getPackage (packageName)

Get general information about a specified package. This resource is rate limit free

[Link to documentation](https://bintray.com/docs/api#_get_packages)

#### createPackage (packageObject)

Creates a new package in the specified repo (user has to be an owner of the repo)

[Link to documentation](https://bintray.com/docs/api#_create_package)

#### deletePackage (packageName)

Delete the specified package

[Link to documentation](https://bintray.com/docs/api#_delete_package)

#### updatePackage (packageName, packageObject)

Update the information of the specified package.
Creates a new package in the specified repo (user has to be an owner of the repo)

[Link to documentation](https://bintray.com/docs/api#_update_package)

#### getPackageUrl (packageName[, repository])

Get the package download URL

### Package versions

```shell
$ bintray package-version --help

  Usage: package-version <get|create|delete|update> <organization> <repository> <pkgname>

    Options:

      -h, --help                   output usage information
      -n, --version <version>      Use a specific package version
      -c, --release-notes <notes>  [create] Add release note comment
      -w, --url <url>              [create] Add a releases URL notes/changelog
      -t, --date <date>            
          [create] Released date in ISO8601 format (optional)
      -f, --file <path>            
          [create|update] Path to JSON package version manifest file
      -u, --username <username>    Defines the authentication username
      -k, --apikey <apikey>        Defines the authentication API key
      -r, --raw                    Outputs the raw response (JSON)
      -d, --debug                  Enables the verbose/debug output mode

  Usage examples:

  $ bintray package-version get myorganization myrepository mypackage
  $ bintray package-version delete myorganization myrepository mypackage -n 0.1.0
  $ bintray package-version create myorganization myrepository mypackage \
      -n 0.1.0 -c 'Releases notes...' -w 'https://github.com/myorganization/mypackage/README.md'
  $ bintray package-version update myorganization myrepository mypackage \
      -n 0.1.0 -c 'My new releases notes' -w 'https://github.com/myorganization/mypackage/README.md'

```

#### getPackageVersion (packageName, version = '_latest')

Get general information about a specified version, or query for the latest version

[Link to documentation](https://bintray.com/docs/api#_get_version)

#### createPackageVersion (packageName, versionObject)

Creates a new version in the specified package (user has to be owner of the package)

[Link to documentation](https://bintray.com/docs/api#_create_version)

#### deletePackageVersion (packageName, version)

Delete the specified version Published versions may be deleted within 30 days from their publish date.

[Link to documentation](https://bintray.com/docs/api#_delete_version)

#### updatePackageVersion (packageName, version)

Update the information of the specified version

[Link to documentation](https://bintray.com/docs/api#_update_version)

#### getVersionAttrs (packageName, attributes, version = '_latest')

Get attributes associated with the specified package or version. If no attribute names are specified, return all attributes.

[Link to documentation](https://bintray.com/docs/api#_get_attributes)

#### setPackageAttrs (packageName, attributesObj [, version])

Associate attributes with the specified package or version, overriding all previous attributes.

[Link to documentation](https://bintray.com/docs/api#_set_attributes)

#### updatePackageAttrs (packageName, attributesObj [, version])

Update attributes associated with the specified package or version.

[Link to documentation](https://bintray.com/docs/api#_update_attributes)

#### deletePackageAttrs (packageName, names [, version])

Delete attributes associated with the specified repo, package or version. If no attribute names are specified, delete all attributes

[Link to documentation](https://bintray.com/docs/api#_delete_attributes)

### Search

```shell
$ bintray search --help

  Usage: search <package|user|attribute|repository|file> <query> [options]?

    Options:

      -h, --help                 output usage information
      -d, --desc                 Descendent search results
      -o, --organization <name>  
          [packages|attributes] Search only packages for the given organization
      -r, --repository <name>    
          [packages|attributes] Search only packages for the given repository (requires -o param)
      -f, --filter <value>       
          [attributes] Attribute filter rule string or JSON file path with filters
      -p, --pkgname <package>    
          [attributes] Search attributes on a specific package
      -c, --checksum             
          Query search like MD5 file checksum
      -u, --username <username>  
          Defines the authentication username
      -k, --apikey <apikey>      
          Defines the authentication API key
      -r, --raw                  
          Outputs the raw response (JSON)
      -d, --debug                
          Enables the verbose/debug output mode

  Usage examples:

  $ bintray search user john
  $ bintray search package node.js -o myOrganization
  $ bintray search repository reponame
  $ bintray search attribute os -f 'linux'
  $ bintray search file packageName -h 'linux'
  $ bintray search file d8578edf8458ce06fbc5bb76a58c5ca4 --checksum
```

#### searchRepository (repositoryName, description)

Search for a repository. At least one of the name and description search fields need to be specified. Returns an array of results, where elements are similar to the result of getting a single repository.

[Link to documentation](https://bintray.com/docs/api#_repository_search)

#### searchPackage (packageName, description [, subject = current, repository])

Search for a package. At least one of the name and description search fields need to be specified. May take an optional single subject name and if specified, and optional (exact) repo name. Returns an array of results, where elements are similar to the result of getting a single package.

[Link to documentation](https://bintray.com/docs/api#_package_search)

#### searchUser (packageName)

[Link to documentation](https://bintray.com/docs/api#_delete_attributes)

#### searchAttributes (attributesObj, name)

Search for packages/versions inside a given repository matching a set of attributes.

[Link to documentation](https://bintray.com/docs/api#_attribute_search)

#### searchFile (filename [, repository])

Search for a file by its name. name can take the * and ? wildcard characters. May take an optional (exact) repo name to search in.

[Link to documentation](https://bintray.com/docs/api#_file_search_by_name)

#### searchFileChecksum (hash [, repository])

Search for a file by its sha1 checksum. May take an optional repo name to search in.

[Link to documentation](https://bintray.com/docs/api#_file_search_by_checksum)

### User

```shell
$ bintray user --help

  Usage: user <username> [action]

    Options:

      -h, --help                 output usage information
      -u, --username <username>  Defines the authentication username
      -k, --apikey <apikey>      Defines the authentication API key
      -s, --start-pos [number]   Followers list start position
      -r, --raw                  Outputs the raw response (JSON)
      -d, --debug                Enables the verbose/debug output mode

  Usage examples:

  $ bintray user john
  $ bintray user john followers -s 1

```

#### getUser (username)

Get general information about a specified repository owner

[Link to documentation](https://bintray.com/docs/api#_get_user)

#### getUserFollowers (username [, startPosition = 0])

Get followers of the specified repository owner

[Link to documentation](https://bintray.com/docs/api#_get_followers)

### Files/Uploads

```shell
$ bintray files --help

  Usage: files <upload|publish|maven> <organization> <repository> <pkgname>

    Options:

      -h, --help                 output usage information
      -n, --version <version>    
          [publish|upload] Upload a specific package version
      -e, --explode              Explode package
      -h, --publish              Publish package
      -x, --discard              [publish] Discard package
      -f, --local-file <path>    
          [upload|maven] Package local path to upload
      -p, --remote-path <path>   
          [upload|maven] Repository remote path to upload the package
      -u, --username <username>  Defines the authentication username
      -k, --apikey <apikey>      Defines the authentication API key
      -r, --raw                  Outputs the raw response (JSON)
      -d, --debug                Enables the verbose/debug output mode

  Usage examples:

  $ bintray files upload myorganization myrepository mypackage \ 
      -n 0.1.0 -f files/mypackage-0.1.0.tar.gz -p /files/x86/mypackage/ --publish
  $ bintray files publish myorganization myrepository mypackage -n 0.1.0

```

#### uploadPackage (name, version, filePath [, remotePath = '/', publish = true, explode = false, mimeType = 'application/octet-stream'])

Upload content to the specified repository path, with package and version information (both required).

[Link to documentation](https://bintray.com/docs/api#_upload_content)

#### mavenUpload (name, version, filePath [, remotePath = '/', publish = true, explode = false, mimeType = 'application/octet-stream'])

[Link to documentation](https://bintray.com/docs/api#_maven_upload)

#### publishPackage (name, version [, discard = false])

Publish all unpublished content for a user’s package version. Returns the number of published files. Optionally, pass in a "discard” flag to discard any unpublished content, instead of publishing.

[Link to documentation](https://bintray.com/docs/api#_publish_discard_uploaded_content)

### Webhooks

```shell
$ bintray webhook --help

 Usage: webhook <list|create|test|delete> <organization> [respository] [pkgname]

  Options:

    -h, --help                 output usage information
    -w, --url <url>            
        Callback URL. May contain the %r and %p tokens for repo and package name
    -m, --method <method>      
        HTTP request method for the callback URL. Defaults to POST
    -n, --version <version>    Use a specific package version
    -u, --username <username>  Defines the authentication username
    -k, --apikey <apikey>      Defines the authentication API key
    -r, --raw                  Outputs the raw response (JSON)
    -d, --debug                Enables the verbose/debug output mode

  Usage examples:

  $ bintray webhook list myorganization myrepository
  $ bintray webhook create myorganization myrepository mypackage \ 
      -w 'http://callbacks.myci.org/%r-%p-build' -m 'GET'
  $ bintray webhook test myorganization myrepository mypackage -n '0.1.0'
  $ bintray webhook delete myorganization myrepository mypackage

```

#### getWebhooks (repositoryName)

Get all the webhooks registered for the specified subject, optionally for a specific repository.

[Link to documentation](https://bintray.com/docs/api#_get_webhooks)

#### createWebhook (packageName, configObject)

Register a webhook for receiving notifications on a new package release. By default a user can register up to 10 webhook callbacks.

[Link to documentation](https://bintray.com/docs/api#_register_a_webhook)

#### testWebhook (packageName, version, configObject)

Test a webhook callback for the specified package release. 
A webhook post request is authenticated with a authentication header that is the HMAC-MD5 of the registering subject’s API key seeded with package name, base64-encoded UTF-8 string.

[Link to documentation](https://bintray.com/docs/api#_test_a_webhook)

#### deleteWebhook (packageName)

Delete a webhook associated with the specified package.

[Link to documentation](https://bintray.com/docs/api#_delete_a_webhook)

### Signing

```shell
$ bintray sing --help

 Usage: sign <organization> <repository> <pkgname> <passphrase>

  Options:

    -h, --help                 output usage information
    -n, --version <version>    Defines a specific package version
    -u, --username <username>  Defines the authentication username
    -k, --apikey <apikey>      Defines the authentication API key
    -r, --raw                  Outputs the raw response (JSON)
    -d, --debug                Enables the verbose/debug output mode

  Usage examples:

  $ bintray sign myorganization myrepository mypackage mypassphrasevalue -n 0.1.0
  $ bintray sign myorganization myrepository /my/file/path.tag.gz mypassphrasevalue

```

#### signFile (remotePath [, passphrase])

GPG sign the specified repository file. This operation requires enabling GPG signing on the targeted repo.

[Link to documentation](https://bintray.com/docs/api#_gpg_sign_a_file)

#### signVersion (packageName, version [, passphrase])

GPG sign all files associated with the specified version.

[Link to documentation](https://bintray.com/docs/api#_gpg_sign_a_version)

### Rate limits

#### getRateLimit ()

Returns the total daily avaiable requests rate limit (defaults to 300)

#### getRateLimitRemaining ()

Returns the remaining API calls available for the current user

For more information about the usage limits, take a look to the [documentation](https://bintray.com/docs/api#_limits)


## Promises API

The library uses a promise-based wrapper elegant and made easy way to manage async tasks. It uses internally [Q.js](https://github.com/kriskowal/q)

The promise resolve/error object has the following members:

* `data` The HTTP response body or error message. It can be an object if it was served as application/json mime type
* `code` The HTTP response status code
* `status` The HTTP status string
* `response` The HTTP native response object


## Testing

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

## Changelog

* `0.1.0` 15-09-2013
  - First release (still beta)

## TODO

* Better HTTP response error handling and messages
* Upload progress status (chunk data)
* More tests and mocks for error cases
* Package creation process via prompt

## License

Code under [MIT](https://github.com/h2non/node-bintray/blob/master/LICENSE) license
