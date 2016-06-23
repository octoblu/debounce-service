debug = require('debug')('debounce-service:controller')
util  = require 'util'
_     = require 'lodash'

class DebounceController
  constructor: ({@waitDefault, @debounceService}) ->
    @waitDefault ?= 1.5*60*1000

  _jsonParse: (objString) ->
    try
      return JSON.parse objString
    catch error
      debug error.message
      return {}

  debounce: (request, response) =>
    {method, query, body, bodyParser} = request
    {id} = request.params
    qs = {}
    headers = {}
    service = {}
    debounce = {}
    requestOptions = {}
    responseOptions = {}

    headers = @debounceService.filterHeaders request.headers

    _.forEach request.query, (value, key) =>
      return service = @_jsonParse value if key == '_service'
      return debounce = @_jsonParse value if key == '_debounce'
      return requestOptions = @_jsonParse value if key == '_requestOptions'
      return responseOptions = @_jsonParse value if key == '_responseOptions'
      qs[key] = value

    debounce.wait ?= @waitDefault

    if bodyParser.isUrlEncoded
      requestOptions.form ?= body
    else
      requestOptions.body ?= body

    requestOptions.json ?= bodyParser.isJson
    requestOptions.headers ?= headers
    requestOptions.method ?= method
    requestOptions.qs ?= qs

    options = {service, debounce, requestOptions, responseOptions}
    debug id, JSON.stringify(options, null, 2)

    @debounceService.doDebounce id, options, (error) =>
      return response.status(error.code || 500).send(error: error.message) if error?
      response.sendStatus(200)

module.exports = DebounceController
