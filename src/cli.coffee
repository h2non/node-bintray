program = require 'commander'
Bintray = require '../lib/bintray'
auth = require './auth'
common = require './common'
pkg = require '../package.json'

{ log, die } = common
exit = 0

program
  .version pkg.version

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
      Auth usage examples:

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
        auth.save options.username, options.apikey
        log 'Authentication data saved'.green

#
# Packages management
#
program
  .command('package <subject> <repository> <action> [pkgname] [pkgfile]')
  .description('Get, update, delete or create Bintray packages')
  .usage('<subject> <repository> <list|info|create|delete|update> [pkgname] [pkgfile]?')
  #.option('-o, --organization <subject>', 'Bintray organization name')
  .option('-f, --file [path]', '[create|update] Path to JSON manifest file')
  .option('-s, --start-pos [number]', '[list] Packages list start position')
  .option('-n, --start-name [prefix]', '[list] Packages start name prefix filter')
  .option('-r, --raw', 'Outputs the raw response (JSON)')
  .on('--help', ->
    log """
      Usage examples:
    
        $ bintray package myorganization myrepository list
        $ bintray package myorganization myrepository info mypackage
    """
  )
  .action (subject, repository, action, pkgname, pkgfile, options) ->
    actions = [ 'list', 'info', 'create', 'delete', 'update' ]
    action = action.toLowerCase()

    if !subject or !repository
      log 'Subject and repository command required. Type --help'.red
      die 1

    if actions.indexOf(action) isnt -1
      log 'Invalid action. Type --help'.red
      die 1

    authStore = auth.get()
    client = new Bintray authStore.username, authStore.apikey, subject, repository if authStore
    client = new Bintray if !authStore
    
    switch action
      when 'list'
        # no auth
        options.startPos = parseInt(options.startPos, 10) or 0

        client.getPackages(options.startPos, options.startName)
          .then (response) ->
            response = response.data
            if response.length
              if options.raw
                log response
              else
                log 'Available packages at "', repository, '" repository'
                response.forEach (pkg) ->
                  log pkg.name
            else
              log 'No packages found'.red
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
            pkg = response.data
            if pkg? and pkg.name
              if options.raw
                log pkg
              else 
                log '%s %s [%s/%s] %s', pkg.name, pkg.latest_version or '(no version)', pkg.owner, pkg.repo, pkg.desc
            else
              log 'No package found'.red
            
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
  .option('-u, --username <username>', 'Defined the authentication username')
  .option('-p, --pkgname <package>', '[attributes] Search attributes on a specific package')
  .option('-k, --apikey <apikey>', 'Defines the authentication API key')
  .option('-r, --raw', 'Outputs the raw response (JSON)')
  .on('--help', ->
    log """
      Search usage examples:

        $ bintray search user john
        $ bintray search package node.js -o myOrganization
        $ bintray search attribute os -f 'linux'

    """
  )
  .action (type, query, options) ->

    if not auth.exists() and !options.user? and !options.apikey?
      log "Authentication credentials required. Type --help for more information".red
      die 1

    { username, apikey } = auth.get() or options
    
    client = new Bintray username, apikey, options.organization, options.repository

    switch type

      when 'package'
        client.searchPackage(query, options.desc)
          .then (response) ->
                if not response.data.length
                  log "No package found!"
                else
                  if options.raw 
                    log response.raw
                  else
                    response.data.forEach (pkg) -> 
                      log pkg.name.white, "(#{pkg.latest_version}) [#{pkg.repo}, #{pkg.owner}] #{pkg.desc.green}"
              , common.error

      when 'repository'
        client.searchRepositories(query, options.desc)
          .then (response) ->
                if not response.data.length
                  log "No repository found!"
                else
                  if options.raw 
                    log response.raw
                  else
                    response.data.forEach (repo) -> 
                      log repo.name.white, "(#{repo.package_count} packages) [#{repo.owner}] #{repo.desc.green} (#{repo.labels.join(', ')})"
              , common.error

      when 'user'
        client.searchUser(query)
          .then (response) ->
                if not response.data.length
                  log "No user found!"
                else
                  if options.raw 
                    log response.raw
                  else
                    response.data.forEach (user) -> 
                      log repo.name.white, "(#{Math.round(user.quota_used_bytes / 1024 / 1024)} MB) [#{user.organizations.join(', ')}] [#{user.repos.join(', ')}] (#{user.followers_count} followers)"
              , common.error

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
                if not response.data.length
                  log "No packages found!"
                else
                  if options.raw 
                    log response.raw
                  else
                    response.data.forEach (pkg) -> 
                      log pkg.name.white, "(#{pkg.latest_version}) [#{pkg.repo}, #{pkg.owner}] #{pkg.desc.green}"
              , common.error

      else 
        log "Invalid search mode. Type --help for more information".red
        die 1


process.on 'exit', -> process.exit exit

module.exports.parse = (args) -> program.parse args