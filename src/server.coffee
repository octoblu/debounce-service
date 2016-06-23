cors               = require 'cors'
morgan             = require 'morgan'
express            = require 'express'
bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
debug              = require('debug')('debounce-service:server')
Router             = require './router'
DebounceService    = require './services/debounce-service'
DebounceController = require './controllers/debounce-controller'

class Server
  constructor: ({@disableLogging, @port}, {})->

  address: =>
    @server.address()

  run: (callback) =>
    app = express()

    app.use morgan 'dev', immediate: false unless @disableLogging
    app.use cors()
    app.use errorHandler()
    app.use meshbluHealthcheck()

    app.use bodyParser.urlencoded limit: '1mb', extended : true, verify: (req) =>
      req.bodyParser = { isUrlEncoded: true }

    app.use bodyParser.json limit : '1mb', verify: (req) =>
      req.bodyParser = { isJson: true }

    app.use bodyParser.text type: '*/*', verify: (req) =>
      req.bodyParser = { isText: true }

    app.options '*', cors()

    debounceService = new DebounceService
    debounceController = new DebounceController {debounceService}
    router = new Router {debounceController}

    router.route app

    @server = app.listen @port, callback

  stop: (callback) =>
    @server.close callback

module.exports = Server
