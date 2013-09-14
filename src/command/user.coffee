program = require 'commander'
Bintray = require '../bintray'
auth = require '../auth'
{ printObj, die, log, error } = require '../common'

program
  .command('user <username> [action]')
  .description('\n  Get information about a user. Authentication required'.cyan)
  .usage('<username> [action]')
  .option('-u, --username <username>', 'Defines the authentication username'.cyan)
  .option('-k, --apikey <apikey>', 'Defines the authentication API key'.cyan)
  .option('-s, --start-pos [number]', 'Followers list start position'.cyan)
  .option('-r, --raw', 'Outputs the raw response (JSON)'.cyan)
  .option('-d, --debug', 'Enables the verbose/debug output mode'.cyan)
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
                data.forEach printObj
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