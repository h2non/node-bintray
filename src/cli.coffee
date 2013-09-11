_ = require 'lodash'
program = require 'commander'
Bintray = require '../lib/bintray'
auth = require './auth'
common = require './common'
pkg = require '../package.json'

{ log, die, error } = common
exit = 0

program
  .version(pkg.version)

program.on '--help', ->
  log """
      Examples:
      
      $ bintray auth set -u username -k apikey
  """

#
# Authentication
#
program
  .command('auth')
  .description('Defines the Bintray authentication credentials')
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
        exit = 1
      else
        log 'Authentication data saved'.green
        auth.save options.username, options.apikey
        log 'Authentication data saved'.green

#
# Packages management
#
program
  .command('package <organization> <repository> <action> [pkgname] [pkgfile]')
  .description('Get, update, delete or create Bintray packages')
  .usage('<organization> <repository> <list|info|create|delete|update> [pkgname] [pkgfile]?')
  .option('-f, --file [path]', '[create|update] Path to JSON manifest file')
  .option('-s, --start-pos [number]', '[list] Packages list start position')
  .option('-n, --start-name [prefix]', '[list] Packages start name prefix filter')
  .option('-u, --username <username>', 'Defines the authentication username')
  .option('-k, --apikey <apikey>', 'Defines the authentication API key')
  .option('-r, --raw', 'Outputs the raw response (JSON)')
  .option('-d, --debug', 'Enables the verbose/debug output mode')
  .on('--help', ->
    log """
        Usage examples:
    
        $ bintray package myorganization myrepository list
        $ bintray package myorganization myrepository info mypackage
    """
  )
  .action (organization, repository, action, pkgname, pkgfile, options) ->
    actions = [ 'list', 'info', 'create', 'delete', 'update' ]
    action = action.toLowerCase()

    if !organization or !repository
      log 'organization and repository command required. Type --help'.red
      die 1

    { username, apikey } = if options.username? and options.apikey? then options else auth.get()

    if username? and apikey?
      client = new Bintray { username: username, apikey: apikey, organization: organization, repository: repository, debug: options.debug }
    else
      client = new Bintray { debug: options.debug }

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
          , (error) -> 
            if error.code is 404
              log 'Repository not found'.red
            else
              log 'Error while trying to get the resource, server code:'.red, error.code or error
            exit = 1

      when 'info'

        if !pkgname
          log 'Package name option required. Type --help'.red
          die 1

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
          , (error) -> 
            if error.code is 404
              log 'Package not found'.red
            else
              log 'Error while trying to get the resource, server code:'.red, error.code or error
            exit = 1

      when 'create'
          
        if not pkgname
          log 'Package name option required. Type --help'.red
          die 1

        if not pkgfile
          log 'No input file specified, looking for .bintray'.grey
          pkgfile = '.bintray' # default file (proposal)

        if not common.fileExists pkgfile
          log 'File not found.'.red
          die 1

        try 
          pkgObj = JSON.parse common.readFile(pkgfile)
        catch e
          log 'Error parsing JSON file:', e.message
          die 1
        
        client.createPackage(pkgObj)
          .then (response) ->
            if response.code is 201
              log 'Package created successfully'.green
          , (error) ->
            if error.code is 409
              log 'The package already exists. Use --force to override it'.red
              # todo: delete package
            else
              log 'Cannot create the package, server code:'.red, error.code or error
            exit = 1

      when 'delete'

        if not pkgname
          log 'Package name option required. Type --help'.red
          die 1

        client.deletePackage(pkgname)
          .then (response) ->
            if response.code is 200
              log 'Package deleted successfully'.green
          , (error) ->
            if error.code is 404
              log 'Package not found'.red
            else
              log 'Error while trying to remove the resource, server code:'.red, error.code or error
            exit = 1

      when 'update'

        if not pkgname
          log 'Package name option required. Type --help'.red
          exit = 1
          return

        if not pkgfile
          log 'No input file specified, looking for .bintray'.grey
          pkgfile = '.bintray' # default file (proposal)

        if not common.fileExists pkgfile
          log 'File not found.'.red
          die 1

        try 
          pkgObj = JSON.parse common.readFile(path.resolve(pkgfile))
        catch e
          log 'Error parsing JSON file:', e.message
          die 1

        client.updatePackage(pkgname, pkgObj)
          .then (response) ->
            if response.code is 200
              log 'Package updated successfully'.green
          , (error) ->
            if error.code is 404
              log 'Package not found'.red
            else
              log 'Error while trying to get the resource, server code:'.red, error.code or error
            exit = 1

      else
        log "Invalid '#{action}' action. Type --help".red
        die 1

#
# Search 
#
program
  .command('search <type> <query>')
  .description('Search packages, repositories, files, users or attributes')
  .usage('<package|user|attribute|repository> <query> [options]?')
  .option('-d, --desc', 'Descendent search results')
  .option('-o, --organization <name>', '[packages|attributes] Search only packages for the given organization')
  .option('-r, --repository <name>', '[packages|attributes] Search only packages for the given repository (requires -o param)')
  .option('-f, --filter <value>', '[attributes] Attribute filter rule string or JSON file path with filters')
  .option('-p, --pkgname <package>', '[attributes] Search attributes on a specific package')
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

    """
  )
  .action (type, query, options) ->

    if not auth.exists() and !options.username? and !options.apikey?
      log "Authentication credentials required. Type --help for more information".red
      die 1

    { username, apikey } = if options.username? and options.apikey? then options else auth.get()

    client = new Bintray { username: username, apikey: apikey, organization: organization, repository: repository, debug: options.debug }
    
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

      else 
        log "Invalid search mode. Type --help for more information".red
        die 1

#
# Repositories
#
program
  .command('repositories <organization> [repository]')
  .description('Get information about one or more repositories. Authentication is optional')
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
  .description('Get information about a user. Authentication is required')
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
  .description('Manage webhooks. Authentication is required')
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
# GPG signing
#
program
  .command('sign <organization> <repository> <pkgname> <passphrase>')
  .description('Sign files and packages versions with GPG. Authentication is required')
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

process.on 'exit', -> process.exit exit

module.exports.parse = (args) -> program.parse args