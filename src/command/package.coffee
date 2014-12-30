_ = require 'lodash'
program = require 'commander'
Bintray = require '../bintray'
auth = require '../auth'
{ fileExists, readFile, printObj, log, die, error } = require '../common'

program
  .command('package <action> <organization> <repository> [pkgname] [pkgfile]')
  .description('\n  Get, update, delete or create packages. Authentication required'.cyan)
  .usage(' <list|info|create|delete|update|url> <organization> <repository> [pkgname] [pkgfile]?')
  .option('-s, --start-pos [number]', '[list] Packages list start position'.cyan)
  .option('-n, --start-name [prefix]', '[list] Packages start name prefix filter'.cyan)
  .option('-t, --description <description>', '[create|update] Package description'.cyan)
  .option('-l, --labels <labels>', '[create|update] Package labels comma separated'.cyan)
  .option('-x, --licenses <licenses>', '[create|update] Package licenses comma separated'.cyan)
  .option('-z, --norepository', '[url] Get package URL from any repository'.cyan)
  .option('-u, --username <username>', 'Defines the authentication username'.cyan)
  .option('-k, --apikey <apikey>', 'Defines the authentication API key'.cyan)
  .option('-r, --raw', 'Outputs the raw response (JSON)'.cyan)
  .option('-d, --debug', 'Enables the verbose/debug output mode'.cyan)
  .on('--help', ->
    log """
        Usage examples:
    
        $ bintray package list myorganization myrepository 
        $ bintray package get myorganization myrepository mypackage
        $ bintray package create myorganization myrepository mypackage \\
            --description 'My package' -labels 'package,binary' --license 'MIT,AGPL'
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
                data.forEach printObj 
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
            labels: options.labels.split ','
            licenses: options.licenses ','
        else
          if not pkgfile 
            log 'No input file specified, looking for .bintray'.grey
            pkgfile = '.bintray' # default file (proposal)

          if not fileExists pkgfile
            log 'Package manifest JSON file not found.'.red
            die 1

        if not _.isObject pkgObj
          try 
            pkgObj = JSON.parse readFile(pkgfile)
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
            labels: options.labels.split ','
            licenses: options.licenses ','
        else
          if not pkgfile 
            log 'No input file specified, looking for .bintray'.grey
            pkgfile = '.bintray'

          if not fileExists pkgfile
            log 'Package manifest JSON file not found.'.red
            die 1

        if not _.isObject pkgObj
          try 
            pkgObj = JSON.parse readFile(pkgfile)
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
