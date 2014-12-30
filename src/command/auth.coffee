program = require 'commander'
Bintray = require '../bintray'
auth = require '../auth'
common = require '../common'

{ printObj, log, die, error } = common

program
  .command('auth')
  .description('\n  Defines the Bintray authentication credentials'.cyan)
  .usage('[options]')
  .option('-c, --clean', 'Clean the stored authentication credentials'.cyan)
  .option('-s, --show', 'Show current stored authentication credentials'.cyan)
  .option('-u, --username <username>', 'Bintray username'.cyan)
  .option('-k, --apikey <apikey>', 'User API key'.cyan)
  .on('--help', ->
    log """
        Usage examples:

        $ bintray auth -u myuser -k myapikey
        $ bintray auth --show

    """
  )
  .action (options) -> 
    authExists = auth.exists()

    showAuth = () ->
      log printObj auth.get()

    if options.clean 
      if authExists
        auth.clean()
        log 'Authentication data cleaned'.green
      else
        log 'No authentication credentials defined, nothing to clean'.green
    else if options.show
      if authExists
        showAuth()
      else
        log 'No authentication credentials stored'.green
    else if !options.username and !options.apikey
      if authExists
        showAuth()
        log 'Type "auth --help" to see more available options'
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