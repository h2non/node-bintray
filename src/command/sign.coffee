program = require 'commander'
Bintray = require '../bintray'
auth = require '../auth'
{ die, log, error } = require '../common'

program
  .command('sign <organization> <repository> <pkgname> <passphrase>')
  .description('\n  Sign files and packages versions with GPG. Authentication required'.cyan)
  .usage('<organization> <repository> <pkgname> <passphrase>')
  .option('-n, --version <version>', 'Defines a specific package version'.cyan)
  .option('-u, --username <username>', 'Defines the authentication username'.cyan)
  .option('-k, --apikey <apikey>', 'Defines the authentication API key'.cyan)
  .option('-r, --raw', 'Outputs the raw response (JSON)'.cyan)
  .option('-d, --debug', 'Enables the verbose/debug output mode'.cyan)
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