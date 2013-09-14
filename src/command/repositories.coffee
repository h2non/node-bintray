program = require 'commander'
Bintray = require '../bintray'
auth = require '../auth'
{ log, error } = require '../common'

program
  .command('repositories <organization> [repository]')
  .description('\n  Get information about one or more repositories. Authentication is optional'.cyan)
  .usage('<organization> [repository]')
  .option('-u, --username <username>', 'Defines the authentication username'.cyan)
  .option('-k, --apikey <apikey>', 'Defines the authentication API key'.cyan)
  .option('-r, --raw', 'Outputs the raw response (JSON)'.cyan)
  .option('-d, --debug', 'Enables the verbose/debug output mode'.cyan)
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
