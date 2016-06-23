debug   = require('debug')('debounce-service:service')
request = require 'request'
_       = require 'lodash'

class DebounceService
  constructor: ->
    @debounceRequests = {}
    setInterval @_cleanUp, 60*1000

  _cleanUp: =>
    _.forEach @debounceRequests, (info, id) =>
      timeDiff = Date.now() - info.last
      debounceWait = info.options.debounce.wait
      debug {id, timeDiff, debounceWait}
      if timeDiff > debounceWait*2
        debug 'cleaning up id', id
        delete @debounceRequests[id]

  filterHeaders: (headers, ignoreKeys) =>
    ignoreKeys ?= [
      'host'
      'content-length'
      'transfer-encoding'
      'connection'
    ]
    return _.reduce( headers, (result, value, key) =>
      result[key] = value if !_.includes ignoreKeys, key
      return result
    , {} )

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

  _doRequest: (id) =>
    {requestOptions, responseOptions} = @debounceRequests[id].options
    debug {requestOptions}
    request requestOptions, (error, response, body) =>
      return debug requestOptions.url, error.message if error?
      return unless responseOptions?.url
      {headers, body} = response
      headers = @filterHeaders headers
      headers['response-status-code'] = response.statusCode
      responseOptions = _.merge({ method:'POST', headers, body }, responseOptions)
      debug {responseOptions}
      request responseOptions, (error, response, body) =>
        debug {error: error?.message, code: response.statusCode, body}

  doDebounce: (id, options, callback) =>
    {debounce} = options
    return callback @_createError(422, 'Id not defined') unless id?
    return callback @_createError(422, 'Debounce params not defined') unless _.isObject debounce
    return callback @_createError(422, 'Request url not defined') unless options.requestOptions?.url?

    @debounceRequests[id] ?= {}
    doUpdate = !@debounceRequests[id].options?.service?.noUpdate

    if doUpdate and !_.isEqual @debounceRequests[id].options?.debounce, debounce
      debug 'creating a new debounce for id', id
      partial = _.partial @_doRequest, id
      @debounceRequests[id].debounce = _.debounce partial, debounce.wait, debounce.options

    @debounceRequests[id].options = options if doUpdate
    @debounceRequests[id].last = Date.now()
    @debounceRequests[id].debounce()
    callback()

module.exports = DebounceService
