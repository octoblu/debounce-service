debug   = require('debug')('debounce-service:service')
request = require 'request'
_       = require 'lodash'

class DebounceService
  constructor: ->
    @debounceRequests = {}

  _doRequest: ({replyTo, requestOptions}) =>
    request requestOptions, (error, response, body) =>
      return debug requestOptions.url, error.message if error?
      return unless replyTo
      {headers, body} = response
      delete headers['host']
      delete headers['content-length']
      headers['response-status-code'] = response.statusCode
      request { url:replyTo, method:'POST', headers, body }

  doDebounce: ({id, replyTo, requestOptions, debounce}, callback) =>
    return callback @_createError(422, 'Not enough url!') unless requestOptions.url?
    unless @debounceRequests[id]?
      partial = _.partial @_doRequest, {replyTo, requestOptions}
      @debounceRequests[id] = _.debounce partial, debounce.wait, debounce.options
    @debounceRequests[id]()
    callback()

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = DebounceService
