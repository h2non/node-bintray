program = require 'commander'
Bintray = require '../bintray'
auth = require '../auth'
{ readFile, printObj, log, die, error } = require '../common'

program
  .command('search <type> <query>')
  .description('\n  Search packages, repositories, files, users or attributes'.cyan)
  .usage('<package|user|attribute|repository|file> <query> [options]?')
  .option('-d, --desc', 'Descendent search results'.cyan)
  .option('-o, --organization <name>', '\n    [packages|attributes] Search only packages for the given organization'.cyan)
  .option('-r, --repository <name>', '\n    [packages|attributes] Search only packages for the given repository (requires -o param)'.cyan)
  .option('-f, --filter <value>', '\n    [attributes] Attribute filter rule string or JSON file path with filters'.cyan)
  .option('-p, --pkgname <package>', '\n    [attributes] Search attributes on a specific package'.cyan)
  .option('-c, --checksum', '\n    Query search like MD5 file checksum'.cyan)
  .option('-u, --username <username>', '\n    Defines the authentication username'.cyan)
  .option('-k, --apikey <apikey>', '\n    Defines the authentication API key'.cyan)
  .option('-r, --raw', '\n    Outputs the raw response (JSON)'.cyan)
  .option('-d, --debug', '\n    Enables the verbose/debug output mode'.cyan)
  .on('--help', ->
    log """
        Usage examples:

        $ bintray search user john
        $ bintray search package node.js -o myOrganization
        $ bintray search repository reponame
        $ bintray search attribute os -f 'linux'
        $ bintray search file packageName -h 'linux'
        $ bintray search file d8578edf8458ce06fbc5bb76a58c5ca4 --checksum
    """
  )
  .action (type, query, options) ->

    if not auth.exists() and !options.username? and !options.apikey?
      log "Authentication credentials required. Type --help for more information".red
      die 1

    { username, apikey } = if options.username? and options.apikey? then options else auth.get()

    client = new Bintray { username: username, apikey: apikey, organization: options.organization, repository: options.repository, debug: options.debug }
    
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
          query = readFile process.pwd() + query
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

      when 'file'
        responseFn = (response) ->
          { data } = response
          if options.raw 
            log JSON.stringify data
          else
            if not data
              log "Packages not found!"
            else
              data.forEach printObj

        if options.checksum
          client.searchFileChecksum(query, options.repository)
            .then responseFn, error
        else
          client.searchFile(query, options.repository)
            .then responseFn, error
      else 
        log "Invalid search mode. Type --help for more information".red
        die 1