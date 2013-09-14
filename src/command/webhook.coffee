_ = require 'lodash'
program = require 'commander'
Bintray = require '../bintray'
auth = require '../auth'
{ die, log, error } = require '../common'

program
  .command('webhook <action> <organization> [repository] [pkgname]')
  .description('\n  Manage webhooks. Authentication required'.cyan)
  .usage('<list|create|test|delete> <organization> [respository] [pkgname]')
  .option('-w, --url <url>', '\n    Callback URL. May contain the %r and %p tokens for repo and package name'.cyan)
  .option('-m, --method <method>', '\n    HTTP request method for the callback URL. Defaults to POST'.cyan)
  .option('-n, --version <version>', 'Use a specific package version'.cyan)
  .option('-u, --username <username>', 'Defines the authentication username'.cyan)
  .option('-k, --apikey <apikey>', 'Defines the authentication API key'.cyan)
  .option('-r, --raw', 'Outputs the raw response (JSON)'.cyan)
  .option('-d, --debug', 'Enables the verbose/debug output mode'.cyan)
  .on('--help', ->
    log """
        Usage examples:

        $ bintray webhook list myorganization myrepository
        $ bintray webhook create myorganization myrepository mypackage \\ 
            -w 'http://callbacks.myci.org/%r-%p-build' -m 'GET'
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