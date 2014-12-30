program = require 'commander'
pkg = require '../package.json'
{ log } = require './common'

[ 
  'auth'
  'package'
  'search'
  'repositories'
  'sign'
  'version'
  'webhook'
  'files'
  'user'
].map((file) -> './command/' + file).forEach(require)

program
  .version(pkg.version)

program.on '--help', ->
  log """
      Usage Examples:
    
      $ bintray auth set -u username -k apikey
      $ bintray search package node.js -o myOrganization
      $ bintray repositories organizationName
      $ bintray files publish myorganization myrepository mypackage -n 0.1.0

  """

module.exports.parse = (args) -> program.parse args