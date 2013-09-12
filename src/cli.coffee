_ = require 'lodash'
program = require 'commander'
Bintray = require '../lib/bintray'
auth = require './auth'
common = require './common'
pkg = require '../package.json'

# import general usage functions
{ log, die, error } = common

program
  .version(pkg.version)

program.on '--help', ->
  log """
        Usage Examples:
      
          $ bintray auth set -u username -k apikey
          $ bintray search package node.js -o myOrganization
          $ bintray repositories organizationName
          $ bintray files publish myorganization myrepository mypackage -n 0.1.0

  """

#
# Authentication
#
program
  .command('auth')
  .description('\n  Defines the Bintray authentication credentials'.cyan)
  .usage('[options]')
  .option('-c, --clean', 'Clean the stored authentication credentials')
  .option('-s, --show', 'Show current stored authentication credentials')
  .option('-u, --username <username>', 'Bintray username')
  .option('-k, --apikey <apikey>', 'User API key')
  .on('--help', ->
    log """
        Usage examples:

        $ bintray auth -u myuser -k myapikey
        $ bintray auth --show

    """
  )
  .action (options) -> 
    storeExists = common.authDefined

    if options.clean 
      if storeExists
        auth.clean()
        log 'Authentication data cleaned'.green
      else
        log 'No authentication credentials defined, nothing to clean'.green
    else if options.show
      if storeExists
        authData = auth.get()
        log 'Username:', authData.username
        log 'API key: ', authData.apikey
      else
        log 'No authentication credentials stored'.green
    else if !options.username and !options.apikey
      if auth.exists()
        authData = auth.get()
        log 'Username:', authData.username
        log 'API key: ', authData.apikey
        log '\n', 'Type --help to see the available options'
      else
        log 'No authentication data defined. Use:'
        log '$ bintray auth -u myuser -k myapikey'.grey
    else
      if !options.username or !options.apikey
        log 'Both username and apikey params are required'.red
        die 1
      else
        auth.save options.username, options.apikey
        log 'Authentication data saved'.green

#
# Packages management
#
program
  .command('package <action> <organization> <repository> [pkgname] [pkgfile]')
  .description('\n  Get, update, delete or create packages. Authentication required'.cyan)
  .usage(' <list|info|create|delete|update|url> <organization> <repository> [pkgname] [pkgfile]?')
  .option('-s, --start-pos [number]', '[list] Packages list start position')
  .option('-n, --start-name [prefix]', '[list] Packages start name prefix filter')
  .option('-t', '--description <description>', '[create|update] Package description')
  .option('-l', '--labels <labels>', '[create|update] Package labels comma separated')
  .option('-x', '--licenses <licenses>', '[create|update] Package licenses comma separated')
  .option('-z', '--norepository', '[url] Get package URL from any repository')
  .option('-u, --username <username>', 'Defines the authentication username')
  .option('-k, --apikey <apikey>', 'Defines the authentication API key')
  .option('-r, --raw', 'Outputs the raw response (JSON)')
  .option('-d, --debug', 'Enables the verbose/debug output mode')
  .on('--help', ->
    log """
        Usage examples:
    
        $ bintray package list myorganization myrepository 
        $ bintray package get myorganization myrepository mypackage
        $ bintray package delete myorganization myrepository mypackage
    """
  )
  .action (action, repository, organization, pkgname, pkgfile, options) ->
    actions = [ 'list', 'get', 'create', 'delete', 'update' ]
    action = action.toLowerCase()

    if !organization or !repository
      log '"organization and repository command are required. Type --help for more information'.red
      die 1

    { username, apikey } = if options.username? and options.apikey? then options else auth.get()

    if username? and apikey?
      client = new Bintray { username: username, apikey: apikey, organization: organization, repository: repository, debug: options.debug }
    else
      client = new Bintray { debug: options.debug }

    if action isnt 'list'
      if !pkgname
        log '"package" name argument required. Type --help for more information'.red
        die 1

    switch action
      when 'list'
        # no auth
        options.startPos = parseInt(options.startPos, 10) or 0

        client.getPackages(options.startPos, options.startName)
          .then (response) ->
            { data } = response
            if options.raw
              log JSON.stringify data
            else
              if data.length
                log "Available packages at '#{repository}' repository:".grey
                data.forEach (pkg) ->
                  log pkg.name
              else
                log 'Packages not found'.red
          , error

      when 'get'
        client.getPackage(pkgname)
          .then (response) ->
            { data } = response
            if options.raw
              log JSON.stringify data
            else
              if data? and data.name
                log '%s %s [%s/%s] %s', data.name, data.latest_version or '(no version)', data.owner, data.repo, data.desc
              else
                log 'Package not found'.red
          , error

      when 'create'
        if options.description? and options.labels? and options.licenses?
          pkgObj = 
            name: pkgname
            desc: options.description
            labels: options.labels.split ', '
            licenses: options.licenses ', '
        else
          if not pkgfile 
            log 'No input file specified, looking for .bintray'.grey
            pkgfile = '.bintray' # default file (proposal)

          if not common.fileExists pkgfile
            log 'Package manifest JSON file not found.'.red
            die 1

        if not _.isObject pkgObj
          try 
            pkgObj = JSON.parse common.readFile(pkgfile)
          catch e
            log 'Error parsing JSON file:', e.message
            die 1
        
        client.createPackage(pkgObj)
          .then (response) ->
            if response.code is 201
              log 'Package created successfully'.green
          , error

      when 'delete'
        client.deletePackage(pkgname)
          .then (response) ->
            if response.code is 200
              log 'Package deleted successfully'.green
          , error

      when 'update'
        if options.description? and options.labels? and options.licenses?
          pkgObj = 
            name: pkgname
            desc: options.description
            labels: options.labels.split ', '
            licenses: options.licenses ', '
        else
          if not pkgfile 
            log 'No input file specified, looking for .bintray'.grey
            pkgfile = '.bintray'

          if not common.fileExists pkgfile
            log 'Package manifest JSON file not found.'.red
            die 1

        if not _.isObject pkgObj
          try 
            pkgObj = JSON.parse common.readFile(pkgfile)
          catch e
            log 'Error parsing JSON file:', e.message
            die 1

        client.updatePackage(pkgname, pkgObj)
          .then (response) ->
            if response.code is 200
              log 'Package updated successfully'.green
          , error

      when 'url'
        if options.norepository
          repository = null

        client.getPackageUrl(pkgname, repository)
          .then (response) ->
            console.log response.data
            if options.raw
              log JSON.stringify response.data
            else
              if response.code isnt 200 or not response.data
                log 'Package not found'.red
              else
                log response.data.url
          , error

      else
        log "Invalid '#{action}' action. Type --help".red
        die 1

#
# Search 
#
program
  .command('search <type> <query>')
  .description('\n  Search packages, repositories, files, users or attributes'.cyan)
  .usage('<package|user|attribute|repository|file> <query> [options]?')
  .option('-d, --desc', 'Descendent search results')
  .option('-o, --organization <name>', '[packages|attributes] Search only packages for the given organization')
  .option('-r, --repository <name>', '[packages|attributes] Search only packages for the given repository (requires -o param)')
  .option('-f, --filter <value>', '[attributes] Attribute filter rule string or JSON file path with filters')
  .option('-p, --pkgname <package>', '[attributes] Search attributes on a specific package')
  .option('-c, --checksum', 'Query search like MD5 file checksum')
  .option('-u, --username <username>', 'Defines the authentication username')
  .option('-k, --apikey <apikey>', 'Defines the authentication API key')
  .option('-r, --raw', 'Outputs the raw response (JSON)')
  .option('-d, --debug', 'Enables the verbose/debug output mode')
  .on('--help', ->
    log """
        Usage examples:

        $ bintray search user john
        $ bintray search package node.js -o myOrganization
        $ bintray search attribute os -f 'linux'
        $ bintray search file packageName -h 'linux'
        $ bintray search file d8578edf8458ce06fbc5bb76a58c5ca4 --checksum

    """
  )
  .action (type, query, options) ->

    if not auth.exists() and !options.username? and !options.apikey?
      log "Authentication credentials required. Type --help for more information".red
      die 1

    { username, apikey } = if options.username? and options.apikey? then options else auth.get()

    client = new Bintray { username: username, apikey: apikey, organization: options.organization, repository: options.repository, debug: options.debug }
    
    switch type

      when 'package'
        client.searchPackage(query, options.desc)
          .then (response) ->
            { data } = response
            if options.raw 
              log JSON.stringify data
            else
              if not data.length
                log "Package not found!"              
              else
                data.forEach (pkg) -> 
                  log pkg.name.white, "(#{pkg.latest_version}) [#{pkg.repo}, #{pkg.owner}] #{pkg.desc.green}"
          , error

      when 'repository'
        client.searchRepositories(query, options.desc)
          .then (response) ->
            { data } = response
            if not data.length
              log "Repository not found!"
            else
              if options.raw 
                log JSON.stringify data
              else
                data.forEach (repo) -> 
                  log repo.name.white, "(#{repo.package_count} packages) [#{repo.owner}] #{repo.desc.green} (#{repo.labels.join(', ')})"
          , error

      when 'user'
        client.searchUser(query)
          .then (response) ->
            { data } = response
            if not data.length
              log "User not found!"
            else
              if options.raw 
                log JSON.stringify data
              else
                data.forEach (user) -> 
                  log repo.name.white, "(#{Math.round(user.quota_used_bytes / 1024 / 1024)} MB) [#{user.organizations.join(', ')}] [#{user.repos.join(', ') || 'No repositories'}] (#{user.followers_count} followers)"
          , error

      when 'attribute'
        if query.indexOf('/') isnt -1
          query = common.readFile process.pwd() + query
        else if options.filter
          query = [{ query: options.filter }]
        else 
          log "Missing attributes filters. Type --help for more information".red
          die 1

        client.searchAttributes(query, options.pkgname)
          .then (response) ->
            { data } = response
            if options.raw 
              log JSON.stringify data
            else
              if not data.length
                log "Packages not found!"
              else
                data.forEach (pkg) -> 
                  log pkg.name.white, "(#{pkg.latest_version}) [#{pkg.repo}, #{pkg.owner}] #{pkg.desc.green}"
          , error

      when 'file'
        responseFn = (response) ->
          { data } = response
          if options.raw 
            log JSON.stringify data
          else
            if not data
              log "Packages not found!"
            else
              data.forEach (pkg) -> 
                log """
                  Filename: #{pkg['name']}
                  Remote path: #{pkg.path}
                  Package: #{pkg.package}
                  Version: #{pkg.version}
                  Repository: #{pkg.repository}
                  Owner: #{pkg.owner}
                  Created: #{pkg.created}
                """

        if options.checksum
          client.searchFileChecksum(query, options.repository)
            .then responseFn, error
        else
          client.searchFile(query, options.repository)
            .then responseFn, error
      else 
        log "Invalid search mode. Type --help for more information".red
        die 1

#
# Repositories
#
program
  .command('repositories <organization> [repository]')
  .description('\n  Get information about one or more repositories. Authentication is optional'.cyan)
  .usage('<organization> [repository]')
  .option('-u, --username <username>', 'Defines the authentication username')
  .option('-k, --apikey <apikey>', 'Defines the authentication API key')
  .option('-r, --raw', 'Outputs the raw response (JSON)')
  .option('-d, --debug', 'Enables the verbose/debug output mode')
  .on('--help', ->
    log """
        Usage examples:

        $ bintray repositories organizationName
        $ bintray repositories organizationName repoName

    """
  )
  .action (organization, repository, options) ->

    { username, apikey } = if options.username? and options.apikey? then options else auth.get()

    if username? and apikey?
      client = new Bintray { username: username, apikey: apikey, organization: organization, debug: options.debug }
    else
      client = new Bintray { debug: options.debug }

    client.selectOrganization organization if not client.organization

    if repository?
      client.getRepository(repository)
          .then (response) ->
            { data } = response
            if options.raw 
              log JSON.stringify data
            else
              if not data.length
                log "Repository not found!"
              else
                response.data.forEach (repo) -> 
                  log repo.name.white, "(#{repo.package_count} packages) [#{repo.owner}] #{repo.desc.green} - #{repo.labels.join(', ')}"
          , error
    else
      client.getRepositories()
          .then (response) ->
            { data } = response
            if options.raw
                log JSON.stringify data
            else
              if not data
                log "No repositories found!"
              else
                data.forEach (repo) -> 
                  log repo.name.white, "[#{repo.owner}]"
          , error

#
# Users
#
program
  .command('user <username> [action]')
  .description('\n  Get information about a user. Authentication required'.cyan)
  .usage('<username> [action]')
  .option('-s, --start-pos [number]', 'Followers list start position')
  .option('-u, --username <username>', 'Defines the authentication username')
  .option('-k, --apikey <apikey>', 'Defines the authentication API key')
  .option('-r, --raw', 'Outputs the raw response (JSON)')
  .option('-d, --debug', 'Enables the verbose/debug output mode')
  .on('--help', ->
    log """
        Usage examples:

        $ bintray user john
        $ bintray user john followers -s 1

    """
  )
  .action (username, action, options) ->

    if not auth.exists() and !options.username? and !options.apikey?
      log "Authentication credentials required. Type --help for more information".red
      die 1

    { username, apikey } = if options.username? and options.apikey? then options else auth.get()

    client = new Bintray { username: username, apikey: apikey, debug: options.debug }

    if action
      client.getUserFollowers(username, options.startPos)
          .then (response) ->
            { data } = response
            if options.raw
              log JSON.stringify data
            else
              if not data.length
                log "The user has no followers!"
              else
                data.forEach (follower) -> 
                  log follower.name.white
          , error
    else
      client.getUser(username)
          .then (response) ->
            { data } = response
            if options.raw 
              log JSON.stringify data
            else
              if not data
                log "User not found!"              
              else
                log data.name.white, "(#{Math.round(user.quota_used_bytes / 1024 / 1024)} MB) [#{user.organizations.join(', ')}] [#{user.repos.join(', ') || 'No repositories'}] (#{user.followers_count} followers)"
          , error

#
# Webbooks
#
program
  .command('webhook <action> <organization> [repository] [pkgname]')
  .description('\n  Manage webhooks. Authentication required'.cyan)
  .usage('<list|create|test|delete> <organization> [respository] [pkgname]')
  .option('-w, --url <url>', 'Callback URL. May contain the %r and %p tokens for repo and package name')
  .option('-m, --method <method>', 'HTTP request method for the callback URL. Defaults to POST')
  .option('-n, --version <version>', 'Use a specific package version')
  .option('-u, --username <username>', 'Defines the authentication username')
  .option('-k, --apikey <apikey>', 'Defines the authentication API key')
  .option('-r, --raw', 'Outputs the raw response (JSON)')
  .option('-d, --debug', 'Enables the verbose/debug output mode')
  .on('--help', ->
    log """
        Usage examples:

        $ bintray webhook list myorganization myrepository
        $ bintray webhook create myorganization myrepository mypackage -w 'http://callbacks.myci.org/%r-%p-build' -m 'GET'
        $ bintray webhook test myorganization myrepository mypackage -n '0.1.0'
        $ bintray webhook delete myorganization myrepository mypackage

    """
  )
  .action (action, organization, repository, pkgname, options) ->

    if not auth.exists() and !options.username? and !options.apikey?
      log "Authentication credentials required. Type --help for more information".red
      die 1

    { username, apikey } = if options.username? and options.apikey? then options else auth.get()

    client = new Bintray { username: username, apikey: apikey, organization: organization, repository: repository, debug: options.debug }

    switch action

      when 'list'

        client.getWebhooks(repository)
            .then (response) ->
              { data } = response
              if options.raw
                log JSON.stringify data
              else
                if not data.length
                  log "The organization/repository has no webhooks!"
                else
                  data.forEach (hook) -> 
                    log hook['package'].white, "(failure count: #{hook.failure_count}) [#{hook.url}]"
            , error

      when 'create'

        if not pkgname
          log "Package name param required. Type --help for more information".red
          die 1
        if not repository
          log "Repository param required. Type --help for more information".red
          die 1
        if not options.url
          log "Url param required. Type --help for more information".red
          die 1   

        client.createWebhook(pkgname, _.pick(options, 'url', 'method'))
            .then (response) ->
              if options.raw
                log JSON.stringify response.code + ' ' + response.status
              else
                if response.code isnt 201
                  error response
                else
                  log "Webhook created successfully for '#{organization}/#{repository}/#{pkgname}'".green
            , error

      when 'test'

        if not pkgname
          log "Package name param required. Type --help for more information".red
          die 1
        if not repository
          log "Repository param required. Type --help for more information".red
          die 1
        if not options.url
          log "Url param required. Type --help for more information".red
          die 1
        if not options.version
          log "Version param required. Type --help for more information".red
          die 1

        client.testWebhook(pkgname, options.version, _.pick(options, 'url', 'method'))
            .then (response) ->
              if options.raw
                log JSON.stringify response.code + ' ' + response.status
              else
                if response.code isnt 201
                  error response
                else
                  log "Webhook created successfully for '#{organization}/#{repository}/#{pkgname}'".green
            , error


      when 'delete'

        if not pkgname
          log "Package name param required. Type --help for more information".red
          die 1
        if not repository
          log "Repository param required. Type --help for more information".red
          die 1

        client.deleteWebhook(pkgname)
            .then (response) ->
              if options.raw
                log JSON.stringify response.code + ' ' + response.status
              else
                if response.code isnt 200
                  error response
                else
                  log "Webhook deleted successfully for '#{organization}/#{repository}/#{pkgname}'".green
            , error

      else
        log "Invalid '#{action}' action param. Type --help for more information".red
        die 1

#
# Package versions
#
program
  .command('package-version <action> <organization> <repository> <pkgname> [versionfile]')
  .description('\n  Get, create, delete or update package versions. Authentication required'.cyan)
  .usage('<get|create|delete|update> <organization> <repository> <pkgname>')
  .option('-n, --version <version>', 'Use a specific package version')
  .option('-c, --release-notes <notes>', '[create] Add release note comment')
  .option('-w, --url <url>', '[create] Add a releases URL notes/changelog')
  .option('-t, --date <date>', '[create] Released date in ISO8601 format (optional)')
  .option('-f, --file <path>', '[create|update] Path to JSON package version manifest file')
  .option('-u, --username <username>', 'Defines the authentication username')
  .option('-k, --apikey <apikey>', 'Defines the authentication API key')
  .option('-r, --raw', 'Outputs the raw response (JSON)')
  .option('-d, --debug', 'Enables the verbose/debug output mode')
  .on('--help', ->
    log """
        Usage examples:

        $ bintray package-version get myorganization myrepository mypackage
        $ bintray package-version delete myorganization myrepository mypackage -n 0.1.0
        $ bintray package-version create myorganization myrepository mypackage -n 0.1.0 -c 'Releases notes...' -w 'https://github.com/myorganization/mypackage/README.md'

    """
  )
  .action (action, organization, repository, pkgname, versionfile, options) ->

    if not auth.exists() and !options.username? and !options.apikey?
      log "Authentication credentials required. Type --help for more information".red
      die 1

    { username, apikey } = if options.username? and options.apikey? then options else auth.get()

    client = new Bintray { username: username, apikey: apikey, organization: organization, repository: repository, debug: options.debug }

    if action is 'update' or action is 'delete'
      if not options.version?
        log '"--version" param is required. Type --help for more information'.red
        die 1
    
    switch action
      when 'get'

        client.getPackageVersion(pkgname, options.version)
          .then (response) ->
            { data } = response
            if options.raw 
              log JSON.stringify data
            else
              if response.code isnt 200
                error response
              else
                log """
                  Package: #{data.package}
                  Version: #{data.name.green}
                  Owner: #{data.owner}
                  Repository: #{data.repo}
                  Release notes: #{data.release_notes}
                  Release URL: #{data.release_url}
                  Attributes: #{data.attribute_names.join(', ')}
                  Released date: #{data.released}
                  Ordinal: #{data.ordinal}
                """
          , error

      when 'create', 'update'

        if options.version? and options.releaseNotes? and options.url?
          versionObj = 
            name: options.version
            release_notes: options.releaseNotes
            release_url: options.url 
            released: options.released or ''
        else
          if not versionfile
            log 'No input version file specified. Type --help for more information'.grey
            die 1

          if not common.fileExists versionfile
            log 'Package manifest JSON file not found.'.red
            die 1

        if not _.isObject versionObj
          try 
            versionObj = JSON.parse common.readFile(versionfile)
          catch e
            log 'Error parsing JSON file:', e.message
            die 1

        if action is 'update'
          client.updatePackageVersion(pkgname, options.version, _.omit versionObj, 'name' )
            .then (response) ->
              { data } = response
              if options.raw 
                log JSON.stringify data
              else
                if response.code isnt 200
                  error response
                else
                  log "Version updated successfully!".green
            , error
        else
          client.createPackageVersion(pkgname, versionObj)
            .then (response) ->
              { data } = response
              if options.raw 
                log JSON.stringify data
              else
                if response.code isnt 201
                  error response
                else
                  log """
                    Package: #{data.package}
                    Version: #{data.name.green}
                    Owner: #{data.owner}
                    Repository: #{data.repo}
                    Release notes: #{data.release_notes}
                    Release URL: #{data.release_url}
                    Attributes: #{data.attribute_names.join(', ')}
                    Released date: #{data.released}
                    Ordinal: #{data.ordinal}
                  """
            , error

      when 'delete'
        client.deletePackageVersion(pkgname, options.version)
          .then (response) ->
            { data } = response
            if options.raw 
              log JSON.stringify data
            else
              if response.code isnt 200
                error response
              else
                log 'Package version deleted successfully!'.green
          , error

      else
        log "Invalid '#{action}' action param. Type --help for more information".red
        die 1

#
# Files upload
#
program
  .command('files <action> <organization> <repository> <pkgname>')
  .description('\n  Upload or publish packages. Authentication required'.cyan)
  .usage('<upload|publish|maven> <organization> <repository> <pkgname>')
  .option('-n, --version <version>', '[publish|upload] Upload a specific package version')
  .option('-e, --explode', 'Explode package')
  .option('-h, --publish', 'Publish package')
  .option('-x, --discard', '[publish] Discard package')
  .option('-f, --local-file <path>', '[upload|maven] Package local path to upload')
  .option('-p, --remote-path <path>', '[upload|maven] Repository remote path to upload the package')
  .option('-u, --username <username>', 'Defines the authentication username')
  .option('-k, --apikey <apikey>', 'Defines the authentication API key')
  .option('-r, --raw', 'Outputs the raw response (JSON)')
  .option('-d, --debug', 'Enables the verbose/debug output mode')
  .on('--help', ->
    log """
        Usage examples:

        $ bintray files upload myorganization myrepository mypackage -n 0.1.0 -f files/mypackage-0.1.0.tar.gz -p /files/x86/mypackage/ --publish
        $ bintray files publish myorganization myrepository mypackage -n 0.1.0
        
    """
  )
  .action (action, organization, repository, pkgname, options) ->

    if not auth.exists() and !options.username? and !options.apikey?
      log "Authentication credentials required. Type --help for more information".red
      die 1

    { username, apikey } = if options.username? and options.apikey? then options else auth.get()

    client = new Bintray { username: username, apikey: apikey, organization: organization, repository: repository, debug: options.debug }

    if action is 'upload' or action is 'publish'
      if not options.version?
        log '"--version" param required. Type --help for more information'.red
        die 1

    if action is 'upload' or action is 'maven'
      if not options.localFile
          log '"--local-file" param with local path required. Type --help for more information'.grey
          die 1

        if not common.fileExists options.localFile
          log 'Cannot find the local file "#{options.file}". Try using an absolute path'.red
          die 1

        if not options.remotePath
          log '"--remote-path" param with local file path required. Type --help for more information'.grey
          die 1

    switch action      

      when 'upload'

        log 'Uploading file... this may take some minutes...'

        client.uploadPackage(pkgname, options.version, options.localFile, options.remotePath, options.publish, options.explode)
          .then (response) ->
            { data } = response
            if options.raw 
              log JSON.stringify response.code
            else
              if response.code isnt 201
                error response
              else
                log "File uploaded successfully".green
          , error

      when 'publish'

        client.publishPackage(pkgname, options.version, options.discard)
          .then (response) ->
            { data } = response
            if options.raw 
              log JSON.stringify data
            else
              if response.code isnt 200
                error response
              else
                if options.discard
                  log "Files discarted: #{data.files}".green
                else
                  log "Files published: #{data.files}".green
          , error

      when 'maven'

        log 'Uploading maven packages... this may take some minutes...'

        client.uploadPackage(pkgname, options.version, options.localFile, options.remotePath, options.publish, options.explode)
          .then (response) ->
            { data } = response
            if options.raw 
              log JSON.stringify response.code
            else
              if response.code isnt 201
                error response
              else
                log "File uploaded successfully".green
          , error

      else
        log "Invalid '#{action}' action param. Type --help for more information".red
        die 1

#
# GPG signing
#
program
  .command('sign <organization> <repository> <pkgname> <passphrase>')
  .description('\n  Sign files and packages versions with GPG. Authentication required'.cyan)
  .usage('<organization> <repository> <pkgname> <passphrase>')
  .option('-n, --version <version>', 'Defines a specific package version')
  .option('-u, --username <username>', 'Defines the authentication username')
  .option('-k, --apikey <apikey>', 'Defines the authentication API key')
  .option('-r, --raw', 'Outputs the raw response (JSON)')
  .option('-d, --debug', 'Enables the verbose/debug output mode')
  .on('--help', ->
    log """
        Usage examples:

        $ bintray sign myorganization myrepository mypackage mypassphrasevalue -n 0.1.0
        $ bintray sign myorganization myrepository /my/file/path.tag.gz mypassphrasevalue

    """
  )
  .action (organization, repository, pkgname, passphrase, options) ->

    if not auth.exists() and !options.username? and !options.apikey?
      log "Authentication credentials required. Type --help for more information".red
      die 1

    { username, apikey } = if options.username? and options.apikey? then options else auth.get()

    client = new Bintray { username: username, apikey: apikey, debug: options.debug }

    if pgkname.indexOf '/' isnt -1
      client.singFile(pkgname, passphrase)
          .then (response) ->
            { data } = response
            if options.raw
              log JSON.stringify data
            else
              if response.code isnt 200
                error response
              else
                log "File signed successfully".green
          , error
    else
      if not options.version
        log "Version param required. Type --help for more information".red
        die 1

      client.singVersion(pkgname, op)
          .then (response) ->
            { data } = response
            if options.raw 
              log JSON.stringify data
            else
              if response.code isnt 200
                error response
              else
                log "File signed successfully".green
          , error

module.exports.parse = (args) -> program.parse args