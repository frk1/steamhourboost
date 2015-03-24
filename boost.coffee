_ = require 'lodash'
chalk = require 'chalk'
Steam = require 'steam'
Promise = require 'bluebird'
database = require('jsonfile').readFileSync 'db.json'

class SteamAccount
  constructor: ({@accountName, @password, @games, @shaSentryfile}) ->
    @steamClient = new Steam.SteamClient

  login: =>
    new Promise (resolve, reject) =>
      @steamClient.on 'loggedOn', resolve
      @steamClient.on 'error', reject
      try
        @shaSentryfile = new Buffer(@shaSentryfile, 'base64')
      catch e
        @shaSentryfile = null
      @steamClient.logOn {@accountName, @password, @shaSentryfile}

  boost: =>
    log(chalk.green.bold('✔ ') + chalk.white("Sucessfully logged into '#{@accountName}'"))
    log(chalk.blue.bold('► ') + chalk.white('Starting to boost games ...\n'))
    @steamClient.gamesPlayed @games
    @steamClient.setPersonaState Steam.EPersonaState.Offline
    setTimeout @restartLoop, 900000

  restartLoop: =>
    @steamClient.gamesPlayed([])
    setTimeout =>
      @steamClient.gamesPlayed(@games)
      setTimeout @restartLoop, 900000 # Restart games after 15min
    , 20000

_.each database, (data) ->
  acc = new SteamAccount(data)
  acc.login()
  .then ->
    acc.boost()
  .catch (e) ->
    log(chalk.bold.red("X ") + chalk.white.underline('ERROR'))
    if e.eresult == Steam.EResult.InvalidPassword
      log(chalk.bold.red("X ") + chalk.white("Logon failed for account '#{acc.accountName}' - invalid password\n"))
    else if e.eresult == Steam.EResult.AlreadyLoggedInElsewhere
      log(chalk.bold.red("X ") + chalk.white("Logon failed for account '#{acc.accountName}' - already logged in elsewhere\n"))
    else if e.eresult == Steam.EResult.AccountLogonDenied
      log(chalk.bold.red("X ") + chalk.white("Logon failed for account '#{acc.accountName}' - steamguard denied access\n"))

log = (message) ->
  current = new Date()
  date = current.getFullYear() + '/' + current.getMonth() + '/' + current.getDate()
  time = current.getHours() + ':' + current.getMinutes() + ':' + current.getSeconds()
  console.log chalk.bold.blue('[' + date + ' - ' + time + ']: ') + message

# Kill the script after 1 hour
setTimeout process.exit, 3600000
