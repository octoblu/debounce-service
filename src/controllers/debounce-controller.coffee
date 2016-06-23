debug = require('debug')('debounce-service:controller')
util  = require 'util'
_     = require 'lodash'

class DebounceController
  constructor: ({@waitDefault, @debounceService}) ->
    @waitDefault ?= 1.5*60*1000
    @ignoreKeys ?= [ 'host', 'content-length' ]

  _jsonParse: (objString) ->
    try
      return JSON.parse objString
    catch error
      return {}

  debounce: (request, response) =>
    {method, query, body, bodyParser} = request
    {id} = request.params
    replyTo = undefined
    requestOptions = {}
    debounce = {}
    headers = {}
    qs = {}

    _.forEach _.filter(request.rawHeaders, (item, index) => index%2 == 0), (key) =>
      lowKey = key.toLowerCase()
      headers[key] = request.headers[lowKey] unless _.includes @ignoreKeys, lowKey

    _.forEach request.query, (value, key) =>
      return replyTo = value if key == '_replyTo'
      return debounce = @_jsonParse value if key == '_debounce'
      return requestOptions = @_jsonParse value if key == '_requestOptions'
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

    options = {id, replyTo, requestOptions, debounce}
    debug JSON.stringify(options, null, 2)

    @debounceService.doDebounce options, (error) =>
      return response.status(error.code || 500).send(error: error.message) if error?
      response.sendStatus(200)

module.exports = DebounceController
