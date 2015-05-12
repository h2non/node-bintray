_ = require 'lodash'
program = require 'commander'
Bintray = require '../bintray'
auth = require '../auth'
{ readFile, fileExists, printObj, log, die, error } = require '../common'

program
  .command('package-version <action> <organization> <repository> <pkgname> [versionfile]')
  .description('\n  Get, create, delete or update package versions. Authentication required'.cyan)
  .usage('<get|create|delete|update> <organization> <repository> <pkgname>')
  .option('-n, --version <version>', 'Use a specific package version'.cyan)
  .option('-c, --release-notes <notes>', '[create] Add release note comment'.cyan)
  .option('-w, --url <url>', '[create] Add a releases URL notes/changelog'.cyan)
  .option('-t, --date <date>', '\n    [create] Released date in ISO8601 format (optional)'.cyan)
  .option('-f, --file <path>', '\n    [create|update] Path to JSON package version manifest file'.cyan)
  .option('-u, --username <username>', 'Defines the authentication username'.cyan)
  .option('-k, --apikey <apikey>', 'Defines the authentication API key'.cyan)
  .option('-r, --raw', 'Outputs the raw response (JSON)'.cyan)
  .option('-d, --debug', 'Enables the verbose/debug output mode'.cyan)
  .on('--help', ->
    log """
        Usage examples:

        $ bintray package-version get myorganization myrepository mypackage
        $ bintray package-version delete myorganization myrepository mypackage -n 0.1.0
        $ bintray package-version create myorganization myrepository mypackage \\
            -n 0.1.0 -c 'Releases notes...' -w 'https://github.com/myorganization/mypackage/README.md'
        $ bintray package-version update myorganization myrepository mypackage \\
            -n 0.1.0 -c 'My new releases notes' -w 'https://github.com/myorganization/mypackage/README.md'

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
                printObj data
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

          if not fileExists versionfile
            log 'Package manifest JSON file not found.'.red
            die 1

        if not _.isObject versionObj
          try 
            versionObj = JSON.parse readFile(versionfile)
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
                  printObj data
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
