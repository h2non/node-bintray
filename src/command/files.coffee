program = require 'commander'
Bintray = require '../bintray'
auth = require '../auth'
{ fileExists, die, log, error } = require '../common'

program
  .command('files <action> <organization> <repository> <pkgname>')
  .description('\n  Upload or publish packages. Authentication required'.cyan)
  .usage('<upload|publish|maven> <organization> <repository> <pkgname>')
  .option('-n, --version <version>', '\n    [publish|upload] Upload a specific package version'.cyan)
  .option('-e, --explode', 'Explode package'.cyan)
  .option('-h, --publish', 'Publish package'.cyan)
  .option('-x, --discard', '[publish] Discard package'.cyan)
  .option('-f, --local-file <path>', '\n    [upload|maven] Package local path to upload'.cyan)
  .option('-p, --remote-path <path>', '\n    [upload|maven] Repository remote path to upload the package'.cyan)
  .option('-u, --username <username>', 'Defines the authentication username'.cyan)
  .option('-k, --apikey <apikey>', 'Defines the authentication API key'.cyan)
  .option('-r, --raw', 'Outputs the raw response (JSON)'.cyan)
  .option('-d, --debug', 'Enables the verbose/debug output mode'.cyan)
  .on('--help', ->
    log """
        Usage examples:

        $ bintray files upload myorganization myrepository mypackage \\ 
            -n 0.1.0 -f files/mypackage-0.1.0.tar.gz -p /files/x86/mypackage/ --publish
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

        if not fileExists options.localFile
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